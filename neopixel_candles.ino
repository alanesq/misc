//
//    neopixel canle effect - 27oct21
//

const bool serialDebug = 1;
#include <vector>      // https://github.com/janelia-arduino/Vector/blob/master

#define FASTLED_INTERNAL                      // Suppress build banner
#include <FastLED.h>                          // https://github.com/FastLED/FastLED


//            --------------------------- settings -------------------------------

// see also settings in class candle


  #define NUM_NEOPIXELS   60              // Maximum number of LEDs available
  
  #define NEOPIXEL_PIN    5               // Neopixel data gpio pin - Notes: should have 330k resistor ideally, 5 = D1 on esp8266

  const int g_PowerLimit =      800;      // power limit in milliamps for Neopixels (USB usually good for 800)

  const int g_Brightness =      255;      // LED maximum brightness scale (1-255)

  const int iLED = 22;                    // onboard indicator led gpio pin
  
  
//            --------------------------------------------------------------------


// colour palette for candles to use 
  DEFINE_GRADIENT_PALETTE( heatmap_gp ) {
      0,   255, 154, 0,
      128,  255, 206, 0,
      255,  255, 232, 8  };  
  CRGBPalette16 candlePal = heatmap_gp;


CRGB g_LEDs[NUM_NEOPIXELS] = {0};             // Frame buffer for FastLED


// ----------------------------------------------------------------
//                             -candles
// ---------------------------------------------------------------- 
// produce a candle effect on individual neopixels

class candle {
  
  private:

    // settings
      const int randomDelayMin = 50;       // min delay between led changes
      const int randomDelayMax = 150;      // max delay between led changes
      const int randomJump = 60;           // probability of a sudden random change
      const int colourChange = 10;         // max size of standard colour change step
      const int randomOff = 30;            // probability of blinking
      const int offTime = 40;              // max time to stay off when blinking
      const int blinkFadeRate = 4;         // how fast to dim when blinking

  
    CRGB* oLEDarray;               // led data location
    std::vector<int> oColour;      // led colour (in palette)
    std::vector<int> oPosition;    // led position
    std::vector<uint32_t> oDelay;  // delay until next colour change allowed
    std::vector<uint32_t> oTime;   // time last colour change occured

    void show() {       // display the candles
      int noCandles = oColour.size();
      FastLED.clear(false); 
      for(int i=0; i<noCandles; i++) {
        if (oColour[i] == 0) oLEDarray[oPosition[i]].fadeToBlackBy(blinkFadeRate);    // if blinking
        else oLEDarray[oPosition[i]] = ColorFromPalette(candlePal, oColour[i]);     
      }
      FastLED.show(g_Brightness);
    }

    void setall(CRGB LEDcol) {      // set all available LEDS to suplied colour
      FastLED.clear(true); 
      for(int i=0; i<NUM_NEOPIXELS; i++) 
        oLEDarray[i] = LEDcol;
      FastLED.show(g_Brightness);
    }
    
  public:
    candle(CRGB* o_LEDarray) {
      this->oLEDarray = o_LEDarray;
      //addone();
    }

    ~candle() {
    }

    // add a candle (provide neopixel position)
    void addone(int _position) {
      int noCandles = oColour.size();
      if (noCandles == NUM_NEOPIXELS || _position > NUM_NEOPIXELS) {
        if (serialDebug) Serial.println("Error adding a candle");
        return;
      }
      if (serialDebug) Serial.println("Adding candle #" + String(noCandles));
      oColour.push_back(0);
      oPosition.push_back(_position);
      oDelay.push_back(0);
      oTime.push_back(millis());
    }

    // remove last candle added 
    void removeone(int _position) {
      int noCandles = oColour.size();
      if (noCandles == 0) {
        if (serialDebug) Serial.println("Error removing a candle");
        return;
      }
      if (serialDebug) Serial.println("Removing candle #" + String(_position));
      oColour.pop_back();
      oPosition.pop_back();
      oDelay.pop_back();
      oTime.pop_back();
    }    

    // update all candles state and display
    void update() {   
      int noCandles = oColour.size();
      uint32_t timeNow = millis();
      for(int i=0; i<noCandles; i++) {
        if ( (unsigned long)(timeNow - oTime[i]) > oDelay[i] ) {    // check if there is a delay set for this candle
          oColour[i] = oColour[i] + random(-colourChange, colourChange);      // add or remove random amount from colour
          if (oColour[i] < 0 || oColour[i] > 255 || random(randomJump) == 0) oColour[i] = random(255);   // check colour is still valid
          oTime[i] = timeNow;                                       // flag time of last change
          oDelay[i] = random(randomDelayMin, randomDelayMax);       // set a delay until next change
          // randomly blink
            if (random(randomOff) == 1) {
              oDelay[i] = random(offTime);  
              oColour[i] = 0;
            }         
        }
      }
      show();   // display results
    }

    // test all leds in string
    void colourShow() { 
      setall(CRGB::Red); 
      delay(500);
      setall(CRGB::Green); 
      delay(500);
      setall(CRGB::Blue); 
      delay(500);
      FastLED.clear(true); 
    }
}; 

candle candles(&g_LEDs[0]);        // create the candle neopixel strip


// ----------------------------------------------------------------
//                            -Setup
// ---------------------------------------------------------------- 

void setup() {
  Serial.begin(115200); while (!Serial); delay(50);       // start serial comms   
  Serial.println("\n\n\n\Starting candles\n");

  pinMode(iLED, OUTPUT);     // onboard indicator led
  
  if (serialDebug) Serial.println("Initialising neopixels");
  pinMode(NEOPIXEL_PIN, OUTPUT);
  FastLED.addLeds<WS2812B, NEOPIXEL_PIN, GRB>(g_LEDs, NUM_NEOPIXELS);   // Add the LED strip to the FastLED library
  FastLED.setBrightness(g_Brightness);
  //set_max_power_indicator_LED(2);                                       // Light the builtin LED if we power throttle
  FastLED.setMaxPowerInMilliWatts(g_PowerLimit);                        // Set the power limit, above which brightness will be throttled

  // test leds
    candles.colourShow();

  // create a couple of candles
    candles.addone(1);  
    candles.addone(8);  

//// set all available neopixels as a candle
//  for (int i=0; i<NUM_NEOPIXELS; i++) 
//    candles.addone(i);

}


// ----------------------------------------------------------------
//                            -Loop
// ---------------------------------------------------------------- 

void loop() {

  candles.update();    // update and show candles

  EVERY_N_MILLISECONDS(1000) digitalWrite(iLED, !digitalRead(iLED));   // flash indicator led
    
}

// ---------------------------------------------------------------- 
