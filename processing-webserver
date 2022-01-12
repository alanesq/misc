
  // Receive data from client - 29Nov20
  // trigger with       http://localhost?trigger1      or       http://localhost?trigger2
  
  // ---------------------------------------------------------------------------------
  // original code from: https://processing.org/discourse/beta/num_1231628867.html

import processing.net.*;

String HTTP_GET_REQUEST = "GET /";
String HTTP_HEADER = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n";

Server s;
Client c;
String input;

void setup() 
{
  // set up display window
    size(300 , 200 );                // size of application window
    background(0);                   // black background
    textSize(14);
    text("WEB SERVER DEMO", 60, 25);
    text("trigger with: http://localhost?trigger1", 10, 70);
    text("or: http://localhost?trigger2", 75, 90);
    
  s = new Server(this, 8080);        // start server on http-alt
}

void draw() 
{ 
  c = s.available();
  if (c != null) {
    input = c.readString();
    input = input.substring(0, input.indexOf("\n")); // Only up to the newline
    
    if (input.indexOf(HTTP_GET_REQUEST) == 0) // starts with ...
    {
      c.write(HTTP_HEADER);  // answer that we're ok with the request and are gonna send html    
      // reply html
        c.write("<html><head><title>Processing demo</title></head><body>\n");
        c.write("<h3>Processing trigger from web demo</h3>\n");
        c.write("</body></html>\n");
      // close connection to client, otherwise it's gonna wait forever
        c.stop();   
    }
    
    // actions triggered by web page request
      // trigger by     http://localhost?trigger1
        if (input.indexOf("?trigger1") > 0) {
          javax.swing.JOptionPane.showMessageDialog(null, "trigger 1 received");       // show a popup message
        }
      // trigger by     http://localhost?trigger2
        if (input.indexOf("?trigger2") > 0) {
          javax.swing.JOptionPane.showMessageDialog(null, "trigger 2 received");       // show a popup message
        }      
  }
  
}
