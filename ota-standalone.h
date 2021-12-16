/**************************************************************************************************
 *
 *      Over The Air updates (to add ota to wifi enabled sketches) - 16Dec21
 *
 *      required in main code:
 *                          server.on("/ota", handleOTA);           // in setup
 *                          const char* stitle = "NeoPixels";       // title of the sketch
 *                          const char* sversion = "16Dec21";       // version of the sketch
 *                          #include "ota-standalone.h"             // after wifi includes
 *
 *
 **************************************************************************************************/


//          S e t t i n g s

   const String OTAPassword = "12345678";      // Password to enable OTA service -  via http://x.x.x.x/ota


//**************************************************************************************************/


#include <WiFiUdp.h>
bool OTAEnabled = 0;    // flag to show if OTA has been enabled

// forward declarations (i.e. details of all functions in this file)
  void otaSetup();
  void handleOTA();


// html text colour codes (obsolete html now and should really use CSS)
  const char colRed[] = "<font color='#FF0000'>";           // red text
  const char colGreen[] = "<font color='#006F00'>";         // green text
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
//     -enable OTA
// ----------------------------------------------------------------
//
//   Enable OTA updates, called when correct password has been entered

void otaSetup() {

    OTAEnabled = 1;          // flag that OTA has been enabled

    // esp32 version (using webserver.h)
    #if defined ESP32
        server.on("/update", HTTP_POST, []() {
          server.sendHeader("Connection", "close");
          server.send(200, "text/plain", (Update.hasError()) ? "Update Failed!, rebooting..." : "Update complete, rebooting...");
          delay(2000);
          ESP.restart();
          delay(2000);
        }, []() {
          HTTPUpload& upload = server.upload();
          if (upload.status == UPLOAD_FILE_START) {
            if (serialDebug) Serial.setDebugOutput(true);
            if (serialDebug) Serial.printf("Update: %s\n", upload.filename.c_str());
            if (!Update.begin()) {        //start with max available size
              if (serialDebug) Update.printError(Serial);
            }
          } else if (upload.status == UPLOAD_FILE_WRITE) {
            if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
              if (serialDebug) Update.printError(Serial);
            }
          } else if (upload.status == UPLOAD_FILE_END) {
            if (Update.end(true)) {      //true to set the size to the current progress
              if (serialDebug) Serial.printf("Update Success: %u\nRebooting...\n", upload.totalSize);
            } else {
              if (serialDebug) Update.printError(Serial);
            }
            if (serialDebug) Serial.setDebugOutput(false);
          } else {
            if (serialDebug) Serial.printf("Update Failed Unexpectedly (likely broken connection): status=%d\n", upload.status);
          }
        });
    #endif

    // esp8266 version  (using ESP8266WebServer.h)
    #if defined ESP8266
        server.on("/update", HTTP_POST, []() {
          server.sendHeader("Connection", "close");
          server.send(200, "text/plain", (Update.hasError()) ? "Update Failed!, rebooting..." : "Update complete, rebooting...");
          delay(2000);
          ESP.restart();
          delay(2000);
        }, []() {
          HTTPUpload& upload = server.upload();
          if (upload.status == UPLOAD_FILE_START) {
            if (serialDebug) Serial.setDebugOutput(true);
            WiFiUDP::stopAll();
            if (serialDebug) Serial.printf("Update: %s\n", upload.filename.c_str());
            uint32_t maxSketchSpace = (ESP.getFreeSketchSpace() - 0x1000) & 0xFFFFF000;
            if (!Update.begin(maxSketchSpace)) { //start with max available size
              if (serialDebug) Update.printError(Serial);
            }
          } else if (upload.status == UPLOAD_FILE_WRITE) {
            if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
              if (serialDebug) Update.printError(Serial);
            }
          } else if (upload.status == UPLOAD_FILE_END) {
            if (Update.end(true)) { //true to set the size to the current progress
              if (serialDebug) Serial.printf("Update Success: %u\nRebooting...\n", upload.totalSize);
            } else {
              if (serialDebug) Update.printError(Serial);
            }
            if (serialDebug) Serial.setDebugOutput(false);
          }
          yield();
        });
    #endif

}


// ----------------------------------------------------------------
//     -OTA web page requested     i.e. http://x.x.x.x/ota
// ----------------------------------------------------------------
//
//   Request OTA password or implement OTA update

void handleOTA(){

  WiFiClient client = server.client();          // open link with client

  // check if valid password supplied
    if (server.hasArg("pwd")) {
      if (server.arg("pwd") == OTAPassword) otaSetup();    // Enable over The Air updates (OTA)
    }



  // -----------------------------------------

  if (OTAEnabled == 0) {

    // OTA is not enabled so request password to enable it

      webheader(client);                            // add the standard html header

      client.print (R"=====(
         <form name='loginForm'>
            <table width='20%' bgcolor='A09F9F' align='center'>
                <tr>
                    <td colspan=2>
                        <center><font size=4><b>Enter OTA password</b></font></center><br>
                    </td>
                        <br>
                </tr><tr>
                    <td>Password:</td>
                    <td><input type='Password' size=25 name='pwd'><br></td><br><br>
                </tr><tr>
                    <td><input type='submit' onclick='check(this.form)' value='Login'></td>
                </tr>
            </table>
        </form>
        <script>
            function check(form)
            {
              window.open('/ota?pwd=' + form.pwd.value , '_self')
            }
        </script>
      )=====");

      webfooter(client);                          // add the standard web page footer

  }

  // -----------------------------------------

  if (OTAEnabled == 1) {

    // OTA is enabled so implement it

      webheader(client);                            // add the standard html header

      client.write("<br><H1>Update firmware</H1><br>\n");
      client.printf("Current version =  %s, %s \n\n", stitle, sversion);

      client.write("<form method='POST' action='/update' enctype='multipart/form-data'>\n");
      client.write("<input type='file' style='width: 300px' name='update'>\n");
      client.write("<br><br><input type='submit' value='Update'></form><br>\n");

      client.write("<br><br>Device will reboot when upload complete");
      client.printf("%s <br>To disable OTA restart device<br> %s \n", colRed, colEnd);

      webfooter(client);                          // add the standard web page footer
  }

  // -----------------------------------------


  // close html page
    delay(3);
    client.stop();

}

// ---------------------------------------------- end ----------------------------------------------
