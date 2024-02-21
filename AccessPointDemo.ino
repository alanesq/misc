/* -------------------------------------------------------------------------------


      ESP32 Acess Point communications demo sketch - 21Feb24

      Creates a wifi access point, serves a web page 
      it also serves a /test web page which when accessed increments a variable


   ------------------------------------------------------------------------------- */


#include <Arduino.h>

// Load the esp32 wifi stuff
  #include <WiFi.h>
  #include <WebServer.h>
  #include <HTTPClient.h>
  WebServer server(80);                          // serve web pages on port 80


// access point settings
  #define AP_SSID "DEMO"                         // access point name
  #define AP_PASS "password"                     // password
  IPAddress Ip(192, 168, 4, 1);                  // ip address
  IPAddress NMask(255, 255, 255, 0);             // net mask  

int theVariable = 0;                             // demonstaration variable


// ----------------------------------------------------------------
//                             setup
// ----------------------------------------------------------------

void setup() {
  Serial.begin(115200);                          // Start serial communication
  Serial.println("\n\n\nAccess Point Demo Sketch");

  // start wifi access point
    WiFi.softAP(AP_SSID, AP_PASS, 1, 0, 8);      // access point settings (ssid, password, channel, ssid_hidden, max_connections)
    delay(150);
    WiFi.softAPConfig(Ip, Ip, NMask);
    WiFi.mode(WIFI_AP);                           // enable as access point only - options are WIFI_AP, WIFI_STA, WIFI_AP_STA or WIFI_OFF
    IPAddress myIP = WiFi.softAPIP();
    Serial.print(" Access point started - IP ");
    Serial.println(myIP);
    server.begin();

  // define web pages to serve
    server.on("/", handleRoot);                   // root page  (when root page is requested the procedure 'handleroot' is called)
    server.on("/test", handleTest);               // demo of how a web page request can be used to perform an action
    //server.onNotFound(handleNotFound);          // invalid page requested

  server.begin();                                 // start web server

}


// ----------------------------------------------------------------
//                             loop
// ----------------------------------------------------------------

void loop() {
  server.handleClient();                         // service any web page requests

  delay(10);
}


// ----------------------------------------------------------------
//                           root web page
// ----------------------------------------------------------------

void handleRoot() {
  WiFiClient client = server.client();           // open link with client

  // log page request including clients IP address
    IPAddress cip = client.remoteIP();
    Serial.println("root page requested from: " + cip);  

  // send standard html header
    sendHeader(client, "Root Page");
    client.write("<FORM action='/' method='post'>\n");            // used by the buttons in the html (action = the web page to send it to

  // body of web page (put your html here)
    client.println("<h2>HELLO THERE!</h2>");
    client.println("The variable is: " + String(theVariable) + "<br>");

  // send standard html footer and close connection
    sendFooter(client);     // close web page

}


// ----------------------------------------------------------------
//                           test web page
// ----------------------------------------------------------------
// this shows how a web page request can be used to perform an action
// it shows a simpler way to send basic replies, in this case as plain text

void handleTest() {
  WiFiClient client = server.client();             // open link with client

  // log page request including clients IP address
    IPAddress cip = client.remoteIP();
    Serial.println("test page requested from: " + cip);

  // perform an action when this page is requested
    theVariable += 1;

  server.send(200, "text/plain", "ok");   // send reply as plain text
}


// ----------------------------------------------------------------
//      send standard html header (i.e. start of web page)
// ----------------------------------------------------------------
// This sends the HTML to start a web page, set screen colours etc.

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
// this sends the html to finish the web page and closes the connection

void sendFooter(WiFiClient &client) {
  client.write("</body></html>\n");
  delay(3);
  client.stop();
}


// -------------------------------------------------------------------------------
// end
