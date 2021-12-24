/*********************************************************************************************

                             ESp8266-01 Neopixel string effects
                                     for Arduino IDE or PlatformIO

                 uses libraries:  	adafruit/Adafruit NeoPixel@^1.10.3
                                    kitesurfer1404/WS2812FX@^1.3.5


**********************************************************************************************

pins are:   GPIO0 = flash
            GPIO1 = Tx (and onboard led)
            GPIO2 = NEOPIXEL DATA PIN
            GPIO3 = Rx

*********************************************************************************************/


#include <Arduino.h>         // required by platformIO
#include <EEPROM.h>          // for storing settings in eeprom


//   -----------------------------------------------------------------------------------------
//                                    S e t t i n g s
//   -----------------------------------------------------------------------------------------


//  #define SSID_NAME "Wifi SSID"              // set in platformio.ini
//  #define SSID_PASWORD "wifi password"

  const char* stitle = "NeoPixels";       // title of this sketch
  const char* sversion = "24Dec21";       // version of this sketch

  const bool serialDebug = 0;             // debug info on serial port

  #define ONBOARD_LED     1               // onboard led gpio

  // Neopixels
  #define NUM_NEOPIXELS   195             // Number of LEDs in the string
  #define NEOPIXEL_PIN    2               // Neopixel gpio pin (Note: should have 330k resistor ideally) (5 = D1 on esp8266)
  byte maxEffect = 55;                    // number of effects available


  //   -----------------------------------------------------------------------------------------


// forward declarations (required by PlatformIO)
  void handleRoot();
  void handleTest();
  void handleNotFound();
  void setEffect();
  void readSettings();
  void writeSettings();

// neopixels
  #include <WS2812FX.h>
  WS2812FX ws2812fx = WS2812FX(NUM_NEOPIXELS, NEOPIXEL_PIN, NEO_GRB + NEO_KHZ800);
  //#define FASTLED_INTERNAL                      // Suppress build banner
  //#include <FastLED.h>                          // https://github.com/FastLED/FastLED
  //CRGB g_LEDs[NUM_NEOPIXELS] = {0};             // Frame buffer for FastLED
  byte g_Brightness = 32;                         // LED maximum brightness scale (1-255) - stored in eeprom
  byte selectedEffect1 = 1;                       // active effect1
  byte selectedEffect2 = 1;                       // active effect2 (if split)
  uint16_t neopixelSplit = 0;                     // if neopixel display is split at what led (0=not split)
  byte maxBrightness = 20;                        // maximum brightness allowed (up to 100)
  uint16_t ledSpeed = 1000;                       // display speed

// wifi
  #if defined ESP8266
      //Esp8266
          #include <ESP8266WiFi.h>
          #include <ESP8266WebServer.h>
          #include "ESP8266HTTPClient.h"
          ESP8266WebServer server(80);
  #else
        #error "This sketch only works with the ESP8266"
  #endif

// html text colour codes (obsolete html now and should really use CSS)
  const char colRed[] = "<font color='#FF0000'>";           // red text
  const char colGreen[] = "<font color='#00FF00'>";         // green text
  const char colBlue[] = "<font color='#0000FF'>";          // blue text
  const char colEnd[] = "</font>";                          // end coloured text


// ----------------------------------------------------------------
//                         -header (html)
// ----------------------------------------------------------------
// HTML at the top of each web page
// @param   client    the http client
// @param   adnlStyle additional style settings to included
// @param   refresh   enable page auto refreshing

void webheader(WiFiClient &client, String adnlStyle = " ", int refresh = 0) {

  // html header
    client.write("HTTP/1.1 200 OK\r\n");
    client.write("Content-Type: text/html\r\n");
    client.write("Connection: close\r\n");
    client.write("\r\n");
    client.write("<!DOCTYPE HTML>\n");
    client.write("<html lang='en'>\n");
    client.write("<head>\n");
    client.write("<meta name='viewport' content='width=device-width, initial-scale=1.0'>\n");

  // page refresh
    if (refresh > 0) client.printf("<meta http-equiv='refresh' content='%c'>\n", refresh);

  // page title
    client.printf("<title> %s </title>\n", stitle);

  // CSS
    client.write("<style>\n");
    client.write("ul {list-style-type: none; margin: 0; padding: 0; overflow: hidden; background-color: rgb(128, 64, 0);}\n");
    client.write("li {float: left;}\n");
    client.write("li a {display: inline-block; color: white; text-align: center; padding: 30px 20px; text-decoration: none;}\n");
    client.write("li a:hover { background-color: rgb(100, 0, 0);}\n");
    client.print(adnlStyle);
    client.write("</style>\n");

  client.write("</head>\n");
  client.write("<body style='color: rgb(0, 0, 0); background-color: yellow; text-align: center;'>\n");

  // top of screen menu
    client.write("<ul>\n");                                                // log menu button
    client.printf("<h1> <font color='#FF0000'>%s</h1></font>\n", stitle);                                 // sketch title
    client.print("</ul>\n");
}


// ----------------------------------------------------------------
//                             -footer (html)
// ----------------------------------------------------------------
// HTML at the end of each web page
// @param   client    http client

void webfooter(WiFiClient &client) {

   // get mac address
     byte mac[6];
     WiFi.macAddress(mac);

   client.print("<br>\n");

   /* Status display at bottom of screen */
     client.write("<div style='text-align: center;background-color:rgb(128, 64, 0)'>\n");
     client.printf("<small> %s", colRed);
     client.printf("%s %s", stitle, sversion);

     client.printf(" | Memory: %dK", ESP.getFreeHeap() /1000);

     client.printf(" | Wifi: %ddBm", WiFi.RSSI());

     // client.printf(" | Spiffs: %dK", ( SPIFFS.totalBytes() - SPIFFS.usedBytes() / 1000 ) );             // if using spiffs

     // client.printf(" | MAC: %2x%2x%2x%2x%2x%2x", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);       // mac address

     client.printf("%s </small>\n", colEnd);
     client.write("</div>\n");

  /* end of HTML */
   client.write("</body>\n");
   client.write("</html>\n");

}


// ----------------------------------------------------------------
//                               -setup
// ----------------------------------------------------------------

void setup() {

  if (serialDebug) {
    delay(3000);
    Serial.begin(115200); while (!Serial); delay(50);       // start serial comms
    Serial.println("\n\n\nStarting\n");
  }

  pinMode(ONBOARD_LED, OUTPUT);       // onboard led pin
  digitalWrite(ONBOARD_LED, LOW);     // led on

  if (serialDebug) Serial.println("Initialising neopixels");
  ws2812fx.init();
  ws2812fx.setBrightness(100);
  ws2812fx.setSpeed(200);
  //ws2812fx.setMode(FX_MODE_RAINBOW_CYCLE);
  ws2812fx.start();

  // Connect to Wifi
    if (serialDebug) {
      Serial.print("Connecting to ");
      Serial.println(SSID_NAME);
    }
    WiFi.begin(SSID_NAME, SSID_PASWORD);        // can be set in platformio.ini
    while (WiFi.status() != WL_CONNECTED) {
      if (serialDebug) Serial.print(".");
      delay(500);
    }
    if (serialDebug) {
      Serial.print("\nConnected - IP: ");
      Serial.println(WiFi.localIP());
    }

  // set up web server pages to serve
    server.on("/", handleRoot);                   // root web page (i.e. when root page is requested run procedure 'handleroot')
    //server.on("/test", handleTest);               // test web page
    server.onNotFound(handleNotFound);            // if invalid url is requested

  // start web server
    server.begin();                               // start web server
    WiFi.setSleepMode(WIFI_NONE_SLEEP);           // stop the wifi being turned off if not used for a while
    WiFi.mode(WIFI_STA);                          // turn off access point - options are WIFI_AP, WIFI_STA, WIFI_AP_STA or WIFI_OFF

  readSettings();                                 // read settings from eeprom
  setEffect();                                    // activate selected LED effects
  digitalWrite(ONBOARD_LED, HIGH);                // onboard led off

}  // setup


// ----------------------------------------------------------------
//                    -read settings from eeprom
// ----------------------------------------------------------------

void readSettings(){

  EEPROM.begin(16);

  // selectedEffect (split 1) - byte
    EEPROM.get(0, selectedEffect1);
    if (selectedEffect1 < 0 || selectedEffect1 > maxEffect) selectedEffect1=0;
    if (serialDebug) Serial.println("Effect1: " + String(selectedEffect1));

  // selectedEffect (split 2) - byte
    EEPROM.get(1, selectedEffect2);
    if (selectedEffect2 < 0 || selectedEffect2 > maxEffect) selectedEffect2=0;
    if (serialDebug) Serial.println("Effect2: " + String(selectedEffect2));

  // LED Brightness - byte
    EEPROM.get(2, g_Brightness);
    if (g_Brightness < 1 || g_Brightness > maxBrightness) g_Brightness=10;
    ws2812fx.setBrightness(g_Brightness);
    if (serialDebug) Serial.println("Brightness: " + String(g_Brightness));

  // led split point - byte
    EEPROM.get(3, neopixelSplit);
    if (neopixelSplit < 0 || neopixelSplit > NUM_NEOPIXELS-1) neopixelSplit=0;
    if (serialDebug) Serial.println("Led split: " + String(neopixelSplit));

  // LED display speed - uint16_t
    EEPROM.get(5, ledSpeed);    // uint16_t
    if (ledSpeed < 10) ledSpeed=1000;
    if (serialDebug) Serial.println("Led speed: " + String(ledSpeed));
}


// ----------------------------------------------------------------
//                    -write settings to eeprom
// ----------------------------------------------------------------

void writeSettings(){

    EEPROM.put(0, selectedEffect1);   // byte
    EEPROM.put(1, selectedEffect2);   // byte
    EEPROM.put(2, g_Brightness);      // byte
    EEPROM.put(3, neopixelSplit);     // uint16_t
    EEPROM.put(5, ledSpeed);          // uint16_t
    // next = 7

    EEPROM.commit();    // write out data
}


// ----------------------------------------------------------------
//                             -loop
// ----------------------------------------------------------------

void loop() {

  yield();                      // allow esp8266 to carry out wifi tasks (may restart randomly without this)
  server.handleClient();        // service any web page requests
  ws2812fx.service();           // service neopixel effects

}  // loop


// ----------------------------------------------------------------
//                 -set the currently selected effect
// ----------------------------------------------------------------
// see: https://github.com/kitesurfer1404/WS2812FX
//      setSegment(segment index, start LED, stop LED, mode, colors[], speed, reverse);

void setEffect() {

  static uint32_t colors[] = {RED, GREEN, BLUE};    // colours to use in the effects
  if (selectedEffect1 > maxEffect) selectedEffect1=0;
  if (selectedEffect2 > maxEffect) selectedEffect2=0;

  if (neopixelSplit == 0) {
    // no split
      ws2812fx.setSegment(0, 0, NUM_NEOPIXELS-1, selectedEffect1, colors, ledSpeed, false);
  } else {
    // divide the string of LEDs into two independent segments
      ws2812fx.setSegment(0, 0, neopixelSplit-1, selectedEffect1, colors, ledSpeed, false);
      ws2812fx.setSegment(1, neopixelSplit, NUM_NEOPIXELS-1, selectedEffect2, colors, ledSpeed, false);
  }
}


// ----------------------------------------------------------------
//      -root web page requested     i.e. http://x.x.x.x
// ----------------------------------------------------------------

void handleRoot(){

  WiFiClient client = server.client();     // open link with client

  if (serialDebug) Serial.println("Root webpage requested");


  // handle any user input

    // if value for brightness has been entered
      if (server.hasArg("brightness")) {
        String Tvalue = server.arg("brightness");   // read value
        int val = Tvalue.toInt();
        if (val > 0 && val <= maxBrightness) {
          g_Brightness = val;
          ws2812fx.setBrightness(g_Brightness);
          if (serialDebug) Serial.println("Brightness changed to: " + Tvalue);
          writeSettings();     // store in eeprom
        }
      }

    // if value for display speed has been entered
      if (server.hasArg("speed")) {
        String Tvalue = server.arg("speed");   // read value
        int val = Tvalue.toInt();
        if (val > 0) {
          ledSpeed = val;
          setEffect();  // activate the effect
          if (serialDebug) Serial.println("Speed changed to: " + Tvalue);
          writeSettings();     // store in eeprom
        }
      }

      // if change effect 1 has been entered
        if (server.hasArg("effect1")) {
          String Tvalue = server.arg("effect1");   // read value
          int val = Tvalue.toInt();
          if (val >= 0 && val <= maxEffect) {
            selectedEffect1 = val;
            setEffect();  // activate the effect
            if (serialDebug) Serial.println("Effect1 changed to: " + Tvalue);
            writeSettings();     // store in eeprom
          }
        }

      // if change effect 2 has been entered
        if (server.hasArg("effect2")) {
          String Tvalue = server.arg("effect2");   // read value
          int val = Tvalue.toInt();
          if (val >= 0 && val <= maxEffect) {
            selectedEffect2 = val;
            setEffect();  // activate the effect
            if (serialDebug) Serial.println("Effect1 changed to: " + Tvalue);
            writeSettings();     // store in eeprom
          }
        }

      // if change in split has been entered
        if (server.hasArg("split")) {
          String Tvalue = server.arg("split");   // read value
          int val = Tvalue.toInt();
          if (val >= 0 && val <= NUM_NEOPIXELS-2) {
            neopixelSplit = val;
            setEffect();      // activate the effects
            if (serialDebug) Serial.println("LED split changed to: " + Tvalue);
            writeSettings();     // store in eeprom
          }
        }


    // build html reply

      // header
        webheader(client);                                       // add the standard html header
        client.print("<FORM action='/' method='post'>\n");       // used by the buttons in the html (action = the web page to send it to

      // body

        // status info.
          client.print("<br>Available effects: " + String(maxEffect));
          client.print("<br>Number of neopixels: " + String(NUM_NEOPIXELS));

        // brightness
          client.printf("<br>Brightness <input type='number' style='width: 35px' name='brightness' value='%d' title='LED brightness (1 to %d)'>\n", g_Brightness, maxBrightness);

        // split position
          client.printf("<br>LED effects split point <input type='number' style='width: 35px' value='%d' name='split' title='LED effects split point'> (0=no split)\n", neopixelSplit);

        // effect (main)
          client.printf("<br>Active effect <input type='number' style='width: 35px' value='%d' name='effect1' title='change effect (0 - %d)'>\n", selectedEffect1, maxEffect);

        // effect (split)
          if (neopixelSplit > 0) {
            client.printf("<br>Active effect after split <input type='number' style='width: 35px' value='%d' name='effect2' title='change effect (0 - %d)'>\n", selectedEffect2, maxEffect);
          }

        // speed
          client.printf("<br>Effect speed <input type='number' style='width: 55px' value='%d' name='speed' title='change effect speed (higher=slower)'>\n", ledSpeed);

        // submit button
          client.print("<br><br><input type='submit' name='submit'><BR>\n");

      // end html
        webfooter(client);                          // add the standard web page footer
        delay(3);
        client.stop();

}  // handleRoot


// ----------------------------------------------------------------
//                      -invalid web page requested
// ----------------------------------------------------------------
// send this reply to any invalid url requested

void handleNotFound() {

  String tReply;

  tReply = "File Not Found\n\n";
  tReply += "URI: ";
  tReply += server.uri();
  tReply += "\nMethod: ";
  tReply += ( server.method() == HTTP_GET ) ? "GET" : "POST";
  tReply += "\nArguments: ";
  tReply += server.args();
  tReply += "\n";

  for ( uint8_t i = 0; i < server.args(); i++ ) {
    tReply += " " + server.argName ( i ) + ": " + server.arg ( i ) + "\n";
  }

  server.send ( 404, "text/plain", tReply );
  tReply = "";      // clear variable

}  // handleNotFound

// ----------------------------------------------------------------
// end
