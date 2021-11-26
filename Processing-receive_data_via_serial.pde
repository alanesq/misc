/*--------------------------------------------------------------

        STARTING POINT SKETCH 

        Detect which serial port the arduino is on then         
        receives list of integers on serial port (comma separated)
        Arduino code example:
                                  void setup() {
                                    Serial.begin(115200);
                                  }
                                  
                                  void loop() {
                                      Serial.print(random(255), DEC);
                                      Serial.print(",");
                                      Serial.print(random(255), DEC);
                                      Serial.print(",");
                                      Serial.println(random(255), DEC);
                                    delay(1000);
                                  }

                       
--------------------------------------------------------------*/

// Misc variables
  String sketchTitle = "Starting point sketch - 26Nov21";     // sketch title
  int[] inVal = new int[10];                                  // data received from serial port (max 10 per line)
  char keyPressed = 0;                                        // key pressed on keyboard
  
  
// Serial port
  import processing.serial.*;
  Serial ser_port; 
  int num_ports;
  boolean device_detected = false;
  String[] port_list;
  String detected_port = "";
  

// ---------------------------------------------------------------------------------------------

void setup() {
    size(displayWidth, 300);                // size of application window
    background(0);                          // black background
    
    println (sketchTitle);
       
    // serial port
      println("serial ports detected:");
      println(Serial.list());     // display all detected serial ports
      // get the number of detected serial ports
        num_ports = Serial.list().length;
      // save the current list of serial ports
        port_list = new String[num_ports];
        for (int i = 0; i < num_ports; i++) {
            port_list[i] = Serial.list()[i];
        }
        
}

// ---------------------------------------------------------------------------------------------

void draw()
{
    background(0);
    textSize(18);
    int lineHeight = 20;      // hight of text line
    
    text(sketchTitle, 20, 1*lineHeight);
        
    // see if new Arduino device has been connected
      if (!device_detected) {
        detectSerial();
        // display instructions to user
          text("1. Arduino or serial device must be unplugged.", 20, 3*lineHeight);
          text("    (unplug device and restart this application if not)", 20, 4*lineHeight);
          text("2. Plug the Arduino or serial device into a USB port.", 20, 6*lineHeight);
      } else {
        // display serial port name
          text("Device detected: " + detected_port, 20, 3*lineHeight);
          text("Last numbers received: " + inVal[0] + ", " + inVal[1] + ", " + inVal[2], 20, 5*lineHeight);
      }
      
    // if a key has been pressed
      if (keyPressed != 0) {
        text("Last key pressed: '" + keyPressed + "'", 20, 8*lineHeight);
        // keyPressed = 0;    // clear keyboard entry
      }  
 
     // change text colour based on received data
       if (inVal[0] != 0) {
         fill(inVal[0], inVal[1], inVal[2]);
       }
 
}


// ---------------------------------------------------------------------------------------------

// Line received from serial port (several numbers)

 void serialEvent (Serial ser_port) {
   String inString = ser_port.readStringUntil('\n');
   if (inString != null) {
     print("Data received:" + inString);
     // extract numbers from the string                
       String[] a = split(inString, ',');              // split comma separated values in to an array
       for (int i = 0; i < a.length; i++) {
        try { inVal[i] = Integer.parseInt(a[i].trim()); }   // store received data in array of integers
        catch (NumberFormatException e) { inVal[i] = 0; }   // if there was an error converting to integer
       }
   }
   // inString = inString.replace('\n', ' ');           // remove line feed from string
 }

// ---------------------------------------------------------------------------------------------

// detect which serial port Arduino has been connected via
// Author:       W.A. Smith, http://startingelectronics.com

void detectSerial() {
      if (!device_detected && (Serial.list().length > num_ports)) {
        device_detected = true;
        // determine which port the device was plugged into
        boolean str_match = false;
        if (num_ports == 0) {
            detected_port = Serial.list()[0];
        }
        else {
            for (int i = 0; i < Serial.list().length; i++) {  // go through the current port list
                for (int j = 0; j < num_ports; j++) {             // go through the saved port list
                    if (Serial.list()[i].equals(port_list[j])) {
                        break;
                    }
                    if (j == (num_ports - 1)) {
                        str_match = true;
                        detected_port = Serial.list()[i];
                    }
                }
            }
        }
        // connect to the new serial port
        ser_port = new Serial(this, detected_port, 115200);      
        delay(500);
        ser_port.clear();                   // clear buffer
        ser_port.bufferUntil('\n');         // don't generate a serialEvent() unless you get a newline character:
    }
}

// ---------------------------------------------------------------------------------------------

// if a key on keyboard is pressed

 void keyReleased() {
    keyPressed = key;     // store which key was pressed
 }

// ---------------------------------------------------------------------------------------------

// end
