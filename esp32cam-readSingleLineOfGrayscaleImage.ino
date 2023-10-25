/*******************************************************************************************************************
*
*                                              Spectrometer for esp32Cam 
*
*                                     Tested with ESP32 board manager version  2.0.11
*
*     
* 
*     If ota.h file is in the sketch folder you can enable OTA updating of this sketch by setting '#define ENABLE_OTA 1'
*        in settings section.  You can then update the sketch with a BIN file via OTA by accessing page   http://x.x.x.x/ota
*        This can make updating the sketch more convenient, especially if you have installed the camera in a case etc.
*
*     GPIO:
*        You can use io pins 13 and 12 for input or output (but 12 must not be high at boot)
*        You could also use pins 1 & 3 if you do not use Serial (disable serialDebug in the settings below)
*        Pins 14, 2 & 15 should be ok to use if you are not using an SD Card
*        More info:   https://randomnerdtutorials.com/esp32-cam-ai-thinker-pinout/
*
*     You can use a MCP23017 io expander chip to give 16 gpio lines by enabling 'useMCP23017' in the setup section and connecting
*        the i2c pins to 12 and 13 on the esp32cam module.  Note: this requires the adafruit MCP23017 library to be installed.
*
*     Created using the Arduino IDE with ESP32 module installed, no additional libraries required
*        ESP32 support for Arduino IDE: https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
*
*     Info on the esp32cam board:  https://randomnerdtutorials.com/esp32-cam-video-streaming-face-recognition-arduino-ide/
*                                  https://github.com/espressif/esp32-camera
*                                  https://randomnerdtutorials.com/esp32-cam-troubleshooting-guide/
*
*
*                                                                                 https://alanesq.github.io/
*
*******************************************************************************************************************/

#if !defined ESP32
 #error This sketch is only for an ESP32 Camera module
#endif

#include "esp_camera.h"         // https://github.com/espressif/esp32-camera
#include <Arduino.h>
#include "wifiSettings.h" 


//   ---------------------------------------------------------------------------------------------------------



//                          ====================================== 
//                                   Enter your wifi settings
//                          ====================================== 


            /*                // delete this line //


                        #define SSID_NAME "<WIFI SSID>"
                        
                        #define SSID_PASWORD "<WIFI PASSWORD>"
                        
                        #define ENABLE_OTA 0                         // If OTA updating of this sketch is enabled (requires ota.h file)
                        const String OTAPassword = "password";       // Password for performing OTA update (i.e. http://x.x.x.x/ota)



            */                // delete this line //


//   ---------------------------------------------------------------------------------------------------------

    // Required by PlatformIO

    // forward declarations
      bool captureFrame();                    // capture an image frame and extract data from it
      bool initialiseCamera(bool);            // this sets up and enables the camera (if bool=1 standard settings are applied but 0 allows you to apply custom settings)
      bool cameraImageSettings();             // this applies the image settings to the camera (brightness etc.)
      String localTime();                     // returns the current time as a String
      void flashLED(int);                     // flashes the onboard indicator led
      void handleRoot();                      // the root web page
      void handleNotFound();                  // if invalid web page is requested
      bool getNTPtime(int);                   // handle the NTP real time clock
      void handleTest();                      // test procedure for experimenting with bits of code etc.
      void handleData();                      // the root web page requests this periodically via Javascript in order to display updating information
      void resize_esp32cam_image_buffer(uint8_t*, int, int, uint8_t*, int, int);    // this resizes a captured grayscale image 


// ---------------------------------------------------------------
//                           -SETTINGS
// ---------------------------------------------------------------

 char* stitle = "Spectrometer";                        // title of this sketch
 char* sversion = "25oct23";                            // Sketch version
 
 uint16_t dataRefresh = 2;                              // how often to refresh data on root web page (seconds)
 uint16_t imagerefresh = 2;                             // how often to refresh the image on root web page (seconds)

 const bool serialDebug = 1;                            // show debug info. on serial port (1=enabled, disable if using pins 1 and 3 as gpio)

 #define useMCP23017 0                                  // set if MCP23017 IO expander chip is being used (on pins 12 and 13)

 // Camera frame size setitngs
   const int imageWidth = 320;                          // width of captured image (relates to framesize below)
   const int imageHeight = 240;                         // height of captured image (relates to framesize below)
   const framesize_t frameSize = FRAMESIZE_QVGA;        // resolutions setting for camera to use
                                                        // Image resolutions available:
                                                        //               default = "const framesize_t FRAME_SIZE_IMAGE = FRAMESIZE_VGA"
                                                        //               160x120 (QQVGA), 128x160 (QQVGA2), 176x144 (QCIF), 240x176 (HQVGA), 240X240,
                                                        //               320x240 (QVGA), 400x296 (CIF), 640x480 (VGA, default), 800x600 (SVGA),
                                                        //               1024x768 (XGA), 1280x1024 (SXGA), 1600x1200 (UXGA)   

  // camera image settings
   int cameraImageExposure = 0;                         // Camera exposure (0 - 1200)   If gain and exposure both set to zero then auto adjust is enabled
   int cameraImageGain = 0;                             // Image gain (0 - 30)
   int cameraImageBrightness = 0;                       // Image brightness (-2 to +2)
   const int camChangeDelay = 200;                      // delay when deinit camera executed

 const int TimeBetweenStatus = 600;                     // speed of flashing system running ok status light (milliseconds)

 const int indicatorLED = 33;                           // onboard small LED pin (33)

 const int iopinA = 13;                                 // general io pin 13
 const int iopinB = 12;                                 // general io pin 12 (must not be high at boot)

 const int serialSpeed = 115200;                        // Serial data speed to use


// camera settings (for the standard - OV2640 - CAMERA_MODEL_AI_THINKER)
// see: https://randomnerdtutorials.com/esp32-cam-camera-pin-gpios/
// set camera resolution etc. in 'initialiseCamera()' and 'cameraImageSettings()'
 #define CAMERA_MODEL_AI_THINKER
 #define PWDN_GPIO_NUM     32      // power to camera (on/off)
 #define RESET_GPIO_NUM    -1      // -1 = not used
 #define XCLK_GPIO_NUM      0
 #define SIOD_GPIO_NUM     26      // i2c sda
 #define SIOC_GPIO_NUM     27      // i2c scl
 #define Y9_GPIO_NUM       35
 #define Y8_GPIO_NUM       34
 #define Y7_GPIO_NUM       39
 #define Y6_GPIO_NUM       36
 #define Y5_GPIO_NUM       21
 #define Y4_GPIO_NUM       19
 #define Y3_GPIO_NUM       18
 #define Y2_GPIO_NUM        5
 #define VSYNC_GPIO_NUM    25      // vsync_pin
 #define HREF_GPIO_NUM     23      // href_pin
 #define PCLK_GPIO_NUM     22      // pixel_clock_pin
 camera_config_t config;           // camera settings


// ******************************************************************************************************************


byte imageData[imageWidth];     // array captured image data will be stored in

//#include "esp_camera.h"       // https://github.com/espressif/esp32-camera
// #include "camera_pins.h"
#include <WString.h>            // this is required for base64.h otherwise get errors with esp32 core 1.0.6 - jan23
#include <base64.h>             // for encoding buffer to display image on page
#include <WiFi.h>
#include <WebServer.h>
#include <HTTPClient.h>
#include "driver/ledc.h"        // used to configure pwm on illumination led

// NTP - Internet time - see - https://randomnerdtutorials.com/esp32-ntp-timezones-daylight-saving/
  #include "time.h"
  struct tm timeinfo;
  const char* ntpServer = "pool.ntp.org";
  const char* TZ_INFO    = "GMT+0BST-1,M3.5.0/01:00:00,M10.5.0/02:00:00";  // enter your time zone (https://remotemonitoringsystems.ca/time-zone-abbreviations.php)
  long unsigned lastNTPtime;
  time_t now;

WebServer server(80);           // serve web pages on port 80

// Used to disable brownout detection
 #include "soc/soc.h"
 #include "soc/rtc_cntl_reg.h"

// MCP23017 IO expander on pins 12 and 13 (optional)
 #if useMCP23017 == 1
   #include <Wire.h>
   #include "Adafruit_MCP23017.h"
   Adafruit_MCP23017 mcp;
   // Wire.setClock(1700000); // set frequency to 1.7mhz
 #endif

// Define some global variables:
 uint32_t lastStatus = millis();           // last time status light changed status (to flash all ok led)

// OTA Stuff
  bool OTAEnabled = 0;                   // flag to show if OTA has been enabled (via supply of password in http://x.x.x.x/ota)
  #if ENABLE_OTA
      void sendHeader(WiFiClient &client, char* hTitle);      // forward declarations
      void sendFooter(WiFiClient &client);
      #include "ota.h"                       // Over The Air updates (OTA)
  #endif

// ---------------------------------------------------------------
//    -SETUP     SETUP     SETUP     SETUP     SETUP     SETUP
// ---------------------------------------------------------------

void setup() {

 if (serialDebug) {
   Serial.begin(serialSpeed);                     // Start serial communication
   // Serial.setDebugOutput(true);

   Serial.println("\n\n\n");                      // line feeds
   Serial.println("-----------------------------------");
   Serial.printf("Starting - %s - %s \n", stitle, sversion);
   Serial.println("-----------------------------------");
   // Serial.print("Reset reason: " + ESP.getResetReason());
 }

 WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);     // Turn-off the 'brownout detector'

 // small indicator led on rear of esp32cam board
   pinMode(indicatorLED, OUTPUT);
   digitalWrite(indicatorLED,HIGH);

 // Connect to wifi
   digitalWrite(indicatorLED,LOW);               // small indicator led on
   if (serialDebug) {
     Serial.print("\nConnecting to ");
     Serial.print(SSID_NAME);
     Serial.print("\n   ");
   }
   WiFi.begin(SSID_NAME, SSID_PASWORD);
   while (WiFi.status() != WL_CONNECTED) {
       delay(500);
       if (serialDebug) Serial.print(".");
   }
   if (serialDebug) {
     Serial.print("\nWiFi connected, ");
     Serial.print("IP address: ");
     Serial.println(WiFi.localIP());
   }
   server.begin();                               // start web server
   digitalWrite(indicatorLED,HIGH);              // small indicator led off

 // define the web pages (i.e. call these procedures when url is requested)
   server.on("/", handleRoot);                   // root page
   server.on("/data", handleData);               // suplies data to periodically update root (AJAX)
   server.on("/test", handleTest);               // Testing procedure
   server.on("/reboot", handleReboot);           // restart device
   server.onNotFound(handleNotFound);            // invalid url requested
#if ENABLE_OTA   
  server.on("/ota", handleOTA);                 // ota updates web page
#endif  

 // NTP - internet time
   if (serialDebug) Serial.println("\nGetting real time (NTP)");
   configTime(0, 0, ntpServer);
   setenv("TZ", TZ_INFO, 1);
   if (getNTPtime(10)) {  // wait up to 10 sec to sync
   } else {
     if (serialDebug) Serial.println("Time not set");
   }
   lastNTPtime = time(&now);

 // set up camera
     if (serialDebug) Serial.print(("\nInitialising camera: "));
     if (initialiseCamera(1)) {           // apply settings from 'config' and start camera
       if (serialDebug) Serial.println("OK");
     }
     else {
       if (serialDebug) Serial.println("failed");
     }

 // define i/o pins
   pinMode(indicatorLED, OUTPUT);            // defined again as sd card config can reset it
   digitalWrite(indicatorLED,HIGH);          // led off = High
   pinMode(iopinA, INPUT);                   // pin 13 - free io pin, can be used for input or output
   pinMode(iopinB, OUTPUT);                  // pin 12 - free io pin, can be used for input or output (must not be high at boot)

 // MCP23017 io expander (requires adafruit MCP23017 library)
 #if useMCP23017 == 1
   Wire.begin(12,13);             // use pins 12 and 13 for i2c
   mcp.begin(&Wire);              // use default address 0
   mcp.pinMode(0, OUTPUT);        // Define GPA0 (physical pin 21) as output pin
   mcp.pinMode(8, INPUT);         // Define GPB0 (physical pin 1) as input pin
   mcp.pullUp(8, HIGH);           // turn on a 100K pullup internally
   // change pin state with   mcp.digitalWrite(0, HIGH);
   // read pin state with     mcp.digitalRead(8)
 #endif

 // startup complete
   if (serialDebug) Serial.println("\nStarted...");
   flashLED(2);     // flash the onboard indicator led

}  // setup


// ----------------------------------------------------------------
//   -LOOP     LOOP     LOOP     LOOP     LOOP     LOOP     LOOP
// ----------------------------------------------------------------


void loop() {

 server.handleClient();          // handle any incoming web page requests

 
 

 // flash status LED to show sketch is running ok
   if ((unsigned long)(millis() - lastStatus) >= TimeBetweenStatus) {
     lastStatus = millis();                                               // reset timer
     digitalWrite(indicatorLED,!digitalRead(indicatorLED));               // flip indicator led status
   }

}  // loop



// ----------------------------------------------------------------
//                 -capture and process a frame
// ----------------------------------------------------------------
// returns 1 if image was captured and processed ok
// results are stored in global variable 'imageData[]'

bool captureFrame() {

    // capture frame from camera (grayscale)
        camera_fb_t * fb = NULL;
        fb = esp_camera_fb_get();
        // there is a bug where this buffer can be from previous capture so as workaround it is discarded and captured again
          esp_camera_fb_return(fb); // dispose the buffered image
          fb = NULL; // reset to capture errors
          fb = esp_camera_fb_get(); // get fresh image
        if(!fb) {
          return 0;   // failed to capture an image
        }  
 
    // read center horizontal line from image and store in array 'line'
      int centLine = fb->height / 2;
      for (int x=0; x<fb->width; x++) {
        int pixelPos = centLine * fb->width + x;
        imageData[x] = fb->buf[pixelPos];
      }
    
    esp_camera_fb_return(fb);          // return frame so memory can be released
    
    // print result on Serial
      if (serialDebug) {
        Serial.print("\nFrame: ");
        for (int x=0; x<fb->width; x++) {
          Serial.print(imageData[x]);
          Serial.print(",");          
        }
        Serial.println(".");
      }
        
        
    return 1;

/* 
      fb->width, fb->height, fb->len = length in bytes, data = buf[i]
      const uint8_t block_x = floor(x / BLOCK_SIZE_X);        // calculate which block this pixel is in
      const uint8_t block_y = floor(y / BLOCK_SIZE_Y);
      
      for (int y=0; y < fb->height; y++) {
        for (int x=0; x < fb->width; x++) {   
        
      image x = i % fb->width, image y = floor(i / fb->width)

*/
}


// ----------------------------------------------------------------
//                        Initialise the camera
// ----------------------------------------------------------------
// returns TRUE if successful
// reset - if set to 1 all settings are reconfigured
//         if set to zero you can change the settings and call this procedure to apply them

bool initialiseCamera(bool reset) {

// set the camera parameters in 'config'
if (reset) {
   config.ledc_channel = LEDC_CHANNEL_0;
   config.ledc_timer = LEDC_TIMER_0;
   config.pin_d0 = Y2_GPIO_NUM;
   config.pin_d1 = Y3_GPIO_NUM;
   config.pin_d2 = Y4_GPIO_NUM;
   config.pin_d3 = Y5_GPIO_NUM;
   config.pin_d4 = Y6_GPIO_NUM;
   config.pin_d5 = Y7_GPIO_NUM;
   config.pin_d6 = Y8_GPIO_NUM;
   config.pin_d7 = Y9_GPIO_NUM;
   config.pin_xclk = XCLK_GPIO_NUM;
   config.pin_pclk = PCLK_GPIO_NUM;
   config.pin_vsync = VSYNC_GPIO_NUM;
   config.pin_href = HREF_GPIO_NUM;
   config.pin_sscb_sda = SIOD_GPIO_NUM;
   config.pin_sscb_scl = SIOC_GPIO_NUM;
   config.pin_pwdn = PWDN_GPIO_NUM;
   config.pin_reset = RESET_GPIO_NUM;
   config.xclk_freq_hz = 20000000;               // XCLK 20MHz or 10MHz for OV2640 double FPS (Experimental)
   config.pixel_format = PIXFORMAT_GRAYSCALE;    // set camera in to grayscale image mode
   config.frame_size = frameSize;                // resolution (set in settings at top of sketch)
   config.jpeg_quality = 12;                     // 0-63 lower number means higher quality (can cause failed image capture if set too low at higher resolutions)
   config.fb_count = 1;                          // if more than one, i2s runs in continuous mode. Use only with JPEG
}

   // check the esp32cam board has a psram chip installed (extra memory used for storing captured images)
   //    Note: if not using "AI thinker esp32 cam" in the Arduino IDE, PSRAM must be enabled
   if (!psramFound()) {
     if (serialDebug) Serial.println("Warning: No PSRam found so defaulting to image size 'CIF'");
     config.frame_size = FRAMESIZE_CIF;
   }

   //#if defined(CAMERA_MODEL_ESP_EYE)
   //  pinMode(13, INPUT_PULLUP);
   //  pinMode(14, INPUT_PULLUP);
   //#endif

   esp_err_t camerr = esp_camera_init(&config);  // initialise the camera
   if (camerr != ESP_OK) {
     if (serialDebug) Serial.printf("ERROR: Camera init failed with error 0x%x", camerr);
   }

   cameraImageSettings();                        // apply the camera image settings

   return (camerr == ESP_OK);                    // return boolean result of camera initialisation
}


// ----------------------------------------------------------------
//                   -Change camera image settings
// ----------------------------------------------------------------
// Adjust image properties (brightness etc.)
// Defaults to auto adjustments if exposure and gain are both set to zero
// - Returns TRUE if successful
// More info: https://randomnerdtutorials.com/esp32-cam-ov2640-camera-settings/
//            interesting info on exposure times here: https://github.com/raduprv/esp32-cam_ov2640-timelapse

bool cameraImageSettings() {

  if (serialDebug) Serial.println("Applying camera settings");

   sensor_t *s = esp_camera_sensor_get();
   // something to try?:     if (s->id.PID == OV3660_PID)
   if (s == NULL) {
     if (serialDebug) Serial.println("Error: problem reading camera sensor settings");
     return 0;
   }

   // if both set to zero enable auto adjust
   if (cameraImageExposure == 0 && cameraImageGain == 0) {
     // enable auto adjust
       s->set_gain_ctrl(s, 1);                       // auto gain on
       s->set_exposure_ctrl(s, 1);                   // auto exposure on
       s->set_awb_gain(s, 1);                        // Auto White Balance enable (0 or 1)
       s->set_brightness(s, cameraImageBrightness);  // (-2 to 2) - set brightness
   } else {
     // Apply manual settings
       s->set_gain_ctrl(s, 0);                       // auto gain off
       s->set_awb_gain(s, 1);                        // Auto White Balance enable (0 or 1)
       s->set_exposure_ctrl(s, 0);                   // auto exposure off
       s->set_brightness(s, cameraImageBrightness);  // (-2 to 2) - set brightness
       s->set_agc_gain(s, cameraImageGain);          // set gain manually (0 - 30)
       s->set_aec_value(s, cameraImageExposure);     // set exposure manually  (0-1200)
   }

   return 1;
}  // cameraImageSettings


//    // More camera settings available:
//    // If you enable gain_ctrl or exposure_ctrl it will prevent a lot of the other settings having any effect
//    // more info on settings here: https://randomnerdtutorials.com/esp32-cam-ov2640-camera-settings/
//    s->set_gain_ctrl(s, 0);                       // auto gain off (1 or 0)
//    s->set_exposure_ctrl(s, 0);                   // auto exposure off (1 or 0)
//    s->set_agc_gain(s, 1);                        // set gain manually (0 - 30)
//    s->set_aec_value(s, 1);                       // set exposure manually  (0-1200)
//    s->set_vflip(s, 1);                           // Invert image (0 or 1)
//    s->set_quality(s, 10);                        // (0 - 63)
//    s->set_gainceiling(s, GAINCEILING_32X);       // Image gain (GAINCEILING_x2, x4, x8, x16, x32, x64 or x128)
//    s->set_brightness(s, 0);                      // (-2 to 2) - set brightness
//    s->set_lenc(s, 1);                            // lens correction? (1 or 0)
//    s->set_saturation(s, 0);                      // (-2 to 2)
//    s->set_contrast(s, 0);                        // (-2 to 2)
//    s->set_sharpness(s, 0);                       // (-2 to 2)
//    s->set_hmirror(s, 0);                         // (0 or 1) flip horizontally
//    s->set_colorbar(s, 0);                        // (0 or 1) - show a testcard
//    s->set_special_effect(s, 0);                  // (0 to 6?) apply special effect
//    s->set_whitebal(s, 0);                        // white balance enable (0 or 1)
//    s->set_awb_gain(s, 1);                        // Auto White Balance enable (0 or 1)
//    s->set_wb_mode(s, 0);                         // 0 to 4 - if awb_gain enabled (0 - Auto, 1 - Sunny, 2 - Cloudy, 3 - Office, 4 - Home)
//    s->set_dcw(s, 0);                             // downsize enable? (1 or 0)?
//    s->set_raw_gma(s, 1);                         // (1 or 0)
//    s->set_aec2(s, 0);                            // automatic exposure sensor?  (0 or 1)
//    s->set_ae_level(s, 0);                        // auto exposure levels (-2 to 2)
//    s->set_bpc(s, 0);                             // black pixel correction
//    s->set_wpc(s, 0);                             // white pixel correction


// ----------------------------------------------------------------
//             returns the current time as a String
// ----------------------------------------------------------------
//   see: https://randomnerdtutorials.com/esp32-date-time-ntp-client-server-arduino/
String localTime() {
 struct tm timeinfo;
 char ttime[40];
 if(!getLocalTime(&timeinfo)) return"Failed to obtain time";
 strftime(ttime,40,  "%A %B %d %Y %H:%M:%S", &timeinfo);
 return ttime;
}


// ----------------------------------------------------------------
//        flash the indicator led 'reps' number of times
// ----------------------------------------------------------------
void flashLED(int reps) {
 for(int x=0; x < reps; x++) {
   digitalWrite(indicatorLED,LOW);
   delay(1000);
   digitalWrite(indicatorLED,HIGH);
   delay(500);
 }
}


// ----------------------------------------------------------------
//      send standard html header (i.e. start of web page)
// ----------------------------------------------------------------
void sendHeader(WiFiClient &client, char* hTitle) {
    // Start page
      client.write("HTTP/1.1 200 OK\r\n");
      client.write("Content-Type: text/html\r\n");
      client.write("Connection: close\r\n");
      client.write("\r\n");
      client.write("<!DOCTYPE HTML><html lang='en'>\n");
    // HTML / CSS
      client.printf(R"=====(
        <head>
          <meta name='viewport' content='width=device-width, initial-scale=1.0'>
          <title>%s</title>
          <style>
            body {
              color: black;
              background-color: #FFFF00;
              text-align: center;
            }
            input {
              background-color: #FF9900;
              border: 2px #FF9900;
              color: blue;
              padding: 3px 6px;
              text-align: center;
              text-decoration: none;
              display: inline-block;
              font-size: 16px;
              cursor: pointer;
              border-radius: 7px;
            }
            input:hover {
              background-color: #FF4400;
            }
          </style>
        </head>
        <body>
        <h1 style='color:red;'>%s</H1>
      )=====", hTitle, hTitle);
}


// ----------------------------------------------------------------
//      send a standard html footer (i.e. end of web page)
// ----------------------------------------------------------------
void sendFooter(WiFiClient &client) {
  client.write("</body></html>\n");
  delay(3);
  client.stop();
}


// ----------------------------------------------------------------
//                        reset the camera
// ----------------------------------------------------------------
// either hardware(1) or software(0)
void resetCamera(bool type = 0) {
  if (type == 1) {
    // power cycle the camera module (handy if camera stops responding)
      digitalWrite(PWDN_GPIO_NUM, HIGH);    // turn power off to camera module
      delay(300);
      digitalWrite(PWDN_GPIO_NUM, LOW);
      delay(300);
      initialiseCamera(1);
    } else {
    // reset via software (handy if you wish to change resolution or image type etc. - see test procedure)
      esp_camera_deinit();
      delay(camChangeDelay);
      initialiseCamera(1);
    }
}




// ----------------------------------------------------------------
//            -Action any user input on root web page
// ----------------------------------------------------------------

void rootUserInput(WiFiClient &client) {

    // if button1 was pressed (toggle io pin A)
    //        Note:  if using an input box etc. you would read the value with the command:    String Bvalue = server.arg("demobutton1");

    // if button1 was pressed (toggle io pin B)
      if (server.hasArg("button1")) {
        if (serialDebug) Serial.println("Button 1 pressed");
        digitalWrite(iopinB,!digitalRead(iopinB));             // toggle output pin on/off
      }

    // if brightness was adjusted - cameraImageBrightness
        if (server.hasArg("bright")) {
          String Tvalue = server.arg("bright");   // read value
          if (Tvalue != NULL) {
            int val = Tvalue.toInt();
            if (val >= -2 && val <= 2 && val != cameraImageBrightness) {
              if (serialDebug) Serial.printf("Brightness changed to %d\n", val);
              cameraImageBrightness = val;
              cameraImageSettings();           // Apply camera image settings
            }
          }
        }

    // if exposure was adjusted - cameraImageExposure
        if (server.hasArg("exp")) {
          if (serialDebug) Serial.println("Exposure has been changed");
          String Tvalue = server.arg("exp");   // read value
          if (Tvalue != NULL) {
            int val = Tvalue.toInt();
            if (val >= 0 && val <= 1200 && val != cameraImageExposure) {
              if (serialDebug) Serial.printf("Exposure changed to %d\n", val);
              cameraImageExposure = val;
              cameraImageSettings();           // Apply camera image settings
            }
          }
        }

     // if image gain was adjusted - cameraImageGain
        if (server.hasArg("gain")) {
          if (serialDebug) Serial.println("Gain has been changed");
          String Tvalue = server.arg("gain");   // read value
            if (Tvalue != NULL) {
              int val = Tvalue.toInt();
              if (val >= 0 && val <= 31 && val != cameraImageGain) {
                if (serialDebug) Serial.printf("Gain changed to %d\n", val);
                cameraImageGain = val;
                cameraImageSettings();          // Apply camera image settings
              }
            }
         }
  }




// ----------------------------------------------------------------
//       -root web page requested    i.e. http://x.x.x.x/
// ----------------------------------------------------------------
// web page with control buttons, links etc.

void handleRoot() {

 getNTPtime(2);                                             // refresh current time from NTP server
 WiFiClient client = server.client();                       // open link with client

 rootUserInput(client);                                     // Action any user input from this web page

 // html header
   sendHeader(client, stitle);
   client.write("<FORM action='/' method='post'>\n");            // used by the buttons in the html (action = the web page to send it to


 // --------------------------------------------------------------------

 // html main body
 //                    Info on the arduino ethernet library:  https://www.arduino.cc/en/Reference/Ethernet
 //                                            Info in HTML:  https://www.w3schools.com/html/
 //     Info on Javascript (can be inserted in to the HTML):  https://www.w3schools.com/js/default.asp
 //                               Verify your HTML is valid:  https://validator.w3.org/


  // ---------------------------------------------------------------------------------------------
  //  info which is periodically updated using AJAX - https://www.w3schools.com/xml/ajax_intro.asp

    // empty lines which are populated via vbscript with live data from http://x.x.x.x/data in the form of comma separated text
      int noLines = 3;      // number of text lines to be populated by javascript
      for (int i = 0; i < noLines; i++) {
        client.println("<span id='uline" + String(i) + "'></span><br>");
      }

    // Javascript - to periodically update the above info lines from http://x.x.x.x/data
    // Note: You can compact the javascript to save flash memory via https://www.textfixer.com/html/compress-html-compression.php
    //       The below = client.printf(R"=====(  <script> function getData() { var xhttp = new XMLHttpRequest(); xhttp.onreadystatechange = function() { if (this.readyState == 4 && this.status == 200) { var receivedArr = this.responseText.split(','); for (let i = 0; i < receivedArr.length; i++) { document.getElementById('uline' + i).innerHTML = receivedArr[i]; } } }; xhttp.open('GET', 'data', true); xhttp.send();} getData(); setInterval(function() { getData(); }, %d); </script> )=====", dataRefresh * 1000);

      // get a comma seperated list from http://x.x.x.x/data and populate the blank lines in html above
      client.printf(R"=====(
         <script>
            function getData() {
              var xhttp = new XMLHttpRequest();
              xhttp.onreadystatechange = function() {
              if (this.readyState == 4 && this.status == 200) {
                var receivedArr = this.responseText.split(',');
                for (let i = 0; i < receivedArr.length; i++) {
                  document.getElementById('uline' + i).innerHTML = receivedArr[i];
                }
              }
            };
            xhttp.open('GET', 'data', true);
            xhttp.send();}
            getData();
            setInterval(function() { getData(); }, %d);
         </script>
      )=====", dataRefresh * 1000);


  // ---------------------------------------------------------------------------------------------


//    // touch input on the two gpio pins
//      client.printf("<p>Touch on pin 12: %d </p>\n", touchRead(T5) );
//      client.printf("<p>Touch on pin 13: %d </p>\n", touchRead(T4) );

   // OTA
      if (OTAEnabled) client.write("<br>OTA IS ENABLED!"); 

   // Control buttons
     client.write("<br><br>");
     client.write("<input style='height: 35px;' name='button1' value='Toggle pin 12' type='submit'> \n");

   // Image setting controls
     client.println("<br>CAMERA SETTINGS: ");
     client.printf("Brightness: <input type='number' style='width: 50px' name='bright' title='from -2 to +2' min='-2' max='2' value='%d'>  \n", cameraImageBrightness);
     client.printf("Exposure: <input type='number' style='width: 50px' name='exp' title='from 0 to 1200' min='0' max='1200' value='%d'>  \n", cameraImageExposure);
     client.printf("Gain: <input type='number' style='width: 50px' name='gain' title='from 0 to 30' min='0' max='30' value='%d'>\n", cameraImageGain);
     client.println(" <input type='submit' name='submit' value='Submit change / Refresh Image'>");
     client.println("<br>Set exposure and gain to zero for auto adjust");

   // links to the other pages available
     client.write("<br><br>LINKS: \n");
     client.write("<a href='/test'>Test procedure</a>\n");
     #if ENABLE_OTA
        client.write(" - <a href='/ota'>Update via OTA</a>\n");
     #endif

    client.println("<br><br><a href='https://github.com/alanesq'>Sketch Author's Github</a>");


 // --------------------------------------------------------------------


 sendFooter(client);     // close web page

}  // handleRoot


// ----------------------------------------------------------------
//     -data web page requested     i.e. http://x.x.x.x/data
// ----------------------------------------------------------------
// the root web page requests this periodically via Javascript in order to display updating information.
// information in the form of comma seperated text is supplied which are then inserted in to blank lines on the web page
// This makes it very easy to modify the data shown without having to change the javascript or root page html
// Note: to change the number of lines displayed update variable 'noLines' in handleroot()

void handleData(){

   String reply = "";

  // line1 - Current real time
    reply += "Current time: " + localTime();
    reply += ",";

  // line2 - gpio pin status
    reply += "GPIO output pin 12 is: ";
    reply += (digitalRead(iopinB)==1) ? "ON" : "OFF";
    reply += " &ensp; GPIO input pin 13 is: ";
    reply += (digitalRead(iopinA)==1) ? "ON" : "OFF";
    reply += ",";

  // line3 - misc info
    reply += "Free memory: " + String(ESP.getFreeHeap() /1000) + "K, ";
    reply += "Image width: " + String(imageWidth);

   server.send(200, "text/plane", reply); //Send millis value only to client ajax request
}


// ----------------------------------------------------------------
//                      -invalid web page requested
// ----------------------------------------------------------------
// Note: shows a different way to send the HTML reply

void handleNotFound() {

 String tReply;

 if (serialDebug) Serial.print("Invalid page requested");

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
//                      -get time from ntp server
// ----------------------------------------------------------------

bool getNTPtime(int sec) {

   uint32_t start = millis();      // timeout timer

   do {
     time(&now);
     localtime_r(&now, &timeinfo);
     if (serialDebug) Serial.print(".");
     delay(100);
   } while (((millis() - start) <= (1000 * sec)) && (timeinfo.tm_year < (2016 - 1900)));

   if (timeinfo.tm_year <= (2016 - 1900)) return false;  // the NTP call was not successful
   if (serialDebug) {
     Serial.print("now ");
     Serial.println(now);
   }

   // Display time
   if (serialDebug)  {
     char time_output[30];
     strftime(time_output, 30, "%a  %d-%m-%y %T", localtime(&now));
     Serial.println(time_output);
     Serial.println();
   }
 return true;
}


// ----------------------------------------------------------------
//                     resize grayscale image
// ----------------------------------------------------------------
// Thanks to Bard A.I. for writing this for me ;-)
//   src_buf: The source image buffer.
//   src_width: The width of the source image buffer.
//   src_height: The height of the source image buffer.
//   dst_buf: The destination image buffer.
//   dst_width: The width of the destination image buffer.
//   dst_height: The height of the destination image buffer.
void resize_esp32cam_image_buffer(uint8_t* src_buf, int src_width, int src_height,
                                   uint8_t* dst_buf, int dst_width, int dst_height) {
  // Calculate the horizontal and vertical resize ratios.
  float h_ratio = (float)src_width / dst_width;
  float v_ratio = (float)src_height / dst_height;

  // Iterate over the destination image buffer and write the resized pixels.
  for (int y = 0; y < dst_height; y++) {
    for (int x = 0; x < dst_width; x++) {
      // Calculate the source pixel coordinates.
      int src_x = (int)(x * h_ratio);
      int src_y = (int)(y * v_ratio);

      // Read the source pixel value.
      uint8_t src_pixel = src_buf[src_y * src_width + src_x];

      // Write the resized pixel value to the destination image buffer.
      dst_buf[y * dst_width + x] = src_pixel;
    }
  }
}


// ----------------------------------------------------------------
//   -reboot web page requested        i.e. http://x.x.x.x/reboot
// ----------------------------------------------------------------
// note: this can fail if the esp has just been reflashed and not restarted

void handleReboot(){

      String message = "Rebooting....";
      server.send(200, "text/plain", message);   // send reply as plain text

      // rebooting
        delay(500);          // give time to send the above html
        ESP.restart();
        delay(5000);         // restart fails without this delay
}


// ----------------------------------------------------------------
//       -test procedure    i.e. http://x.x.x.x/test
// ----------------------------------------------------------------

void handleTest() {

 WiFiClient client = server.client();                                                        // open link with client

 // log page request including clients IP
   IPAddress cIP = client.remoteIP();
   if (serialDebug) Serial.println("Test page requested by " + cIP.toString());

 // html header
   sendHeader(client, "Testing");


 // html body


 // -------------------------------------------------------------------




                          // test code goes here

  // capture data from camera and display
    captureFrame();       // capture and process a frame
    client.print("<br>Image data (vertical centre horizontal line):<br> ");
    for (int x=0; x<imageWidth; x++) {
      client.print(imageData[x]);
      client.print(", ");
    }
    client.print("<br>");

  /*
  //  // demo useage of the mcp23017 io chipnote: this stops PWM on the flash working for some reason
      #if useMCP23017 == 1
        while(1) {
            mcp.digitalWrite(0, HIGH);
            int q = mcp.digitalRead(8);
            client.print("<p>HIGH, input =" + String(q) + "</p>");
            delay(1000);
            mcp.digitalWrite(0, LOW);
            client.print("<p>LOW</p>");
            delay(1000);
        }
      #endif
  */


 // -------------------------------------------------------------------

 client.println("<br><br><a href='/'>Return</a>");       // link back
 sendFooter(client);     // close web page

}  // handleTest


// ******************************************************************************************************************
// end
