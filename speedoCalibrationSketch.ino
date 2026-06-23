/*

 demo sketch for Nidec 24H055M020 motor using PFM (Pulse Frequency Modulation)

 using Arduino UNO  (as motor requires 5v logic)     - 23Jun26

 Enter required RPM on serial console (150 to 3900)
 Pin 1 on motor is yellow

 Note: Numbers below 150 will be interpreted as MPH which is used when calibrating a speedo from a classic car
       which is what I bought this motor for.  For this to work your speedo needs to be 1600 times per mile which is
       often shown on the dial (i.e. 30mph = 800rpm)


 see - https://www.reddit.com/r/Motors/comments/1ixdyp4/how_to_use_this_12_pin_variant_nidec_24h/
       https://www.youtube.com/watch?v=TdrySOXRl-Y


Pins:
  Motor                     Arduino UNO
  --------------------------------------------
    1       (PWM)Pin        9   Use analogWrite() (Supports PWM).
    2       (Start/Stop)    7   Digital Output.
    3       (Brake)         6   Digital Output.
    4       (Direction)     5   Digital Output.
    5       (Feedback)      
    9&10    (GND)           GND Common Ground with Arduino GND.
    11&12   (+12V)          External PSU


 ---------------------------------------------------------------------------------------------------- */


const int pinPFM = 9;             // Motor pin 1
const int pinEnable = 7;          // Motor pin 2 (Start/Stop)
const int pinBrake = 6;           // Motor pin 3 (Brake)
const int pinDirection = 5;       // Motor pin 4 (Direction)

const int minVal = 1000;          // min value allowed (150rpm)
const int maxVal = 26000;         // max value allowed (3900rpm)
const int startSpeed = 3000;      // startup motor rpm (should be high to get motor turning)
const bool motorDirection = 0;    // mnotor direction


// variables
unsigned long frequency;
int rpm;


// ******************************************************
//                        -setup
// ******************************************************
void setup() {
  Serial.begin(115200);
  Serial.println("\n\nSTARTING");

  pinMode(pinPFM, OUTPUT);
  pinMode(pinEnable, OUTPUT);
  pinMode(pinBrake, OUTPUT);
  pinMode(pinDirection, OUTPUT);

  // Initial State
  digitalWrite(pinEnable, HIGH); // Enable/Start (Assuming 12V high is enabled)
  digitalWrite(pinBrake, HIGH);  // Brake Off (Usually HIGH = Off, GND = Brake ON)
  digitalWrite(pinDirection, motorDirection); // Set Direction

  // Initialize Motor
  setMotorRPM(startSpeed);
}


// ******************************************************
//                        -loop
// ******************************************************
void loop() {
  int qrpm = recNumFromSerial();       // receive input from Serial
  if (qrpm > 0) {
    if (qrpm < 100) {
      // input is MPH
      int mphRPM = (int)((float)qrpm * 26.6666);  
      Serial.println("Setting motor to " + String(qrpm) + "MPH which is a RPM of " + String(mphRPM));
      setMotorRPM(mphRPM);
    } else {
      // input is RPM
      Serial.println ("MPH = " + String(convertRPMToMPH(qrpm)));    // for calibrating A35 speedo
      setMotorRPM(qrpm);
    }
  }

  delay(50);
}


// ******************************************************
//               Receive number from serial
// ******************************************************
int recNumFromSerial() {
  if (Serial.available() > 0) {
    // Read until newline
    String line = Serial.readStringUntil('\n');
    line.trim();
    if (line.length() == 0) return 0;
    int value = line.toInt(); 
    if (line == "0" || value != 0 || line == "0") {
      Serial.print("Received: ");
      Serial.println(value);
      return value;
    } else {
      Serial.println("Invalid input. Send an integer like 1000");
    }
  } 
  return 0; 
}


// ******************************************************
//                    Set motor by RPM
// ******************************************************
void setMotorRPM(int newrpm) {
  unsigned long newfrequency = (unsigned long)((float)newrpm / 150.0 * 1000.0);
  if (newfrequency < minVal || newfrequency > maxVal) {
    Serial.println("Error: requested RPM outide of limits (" + String(newrpm) + ")");
    return;
  }
  setMotorFrequency(newfrequency);
}


// ******************************************************
//                 Set motor by frequency
// ******************************************************
void setMotorFrequency(unsigned long newfrequency) {
  if (newfrequency < minVal || newfrequency > maxVal) {
    Serial.println("Error: requested frequency outide of limits (" + String(newfrequency) + ")");
    return;
  }
  rpm = convertFrequencyToRPM(newfrequency);
  frequency = newfrequency;
  tone(pinPFM, (unsigned int)frequency);
  Serial.println("Motor set to " + String(rpm) + "rpm (" + String(frequency) +")");
}


// ******************************************************
//               convert RPM to frequency
// ******************************************************
unsigned long convertRPMtoFrequency(int reqRPM) {
  unsigned long freq = reqRPM / 150 * 1000;    // convert rpm to frequency
  return freq;
}


// ******************************************************
//               convert frequency to RPM
// ******************************************************
int convertFrequencyToRPM(unsigned long reqFrequency) {
  int qRPM = reqFrequency * 150 / 1000;    
  return qRPM;
}


// ******************************************************
//          convert RPM to MPH (speedo)
// ******************************************************
int convertRPMToMPH(unsigned long freq) {
  int mph = (int)((float)freq / 26.6666);  
  return mph;
}


// end
