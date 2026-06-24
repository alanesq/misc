/*

 Arduino sketch for Nidec 24H055M020 motor using PFM (Pulse Frequency Modulation)
 using Arduino UNO  (motor requires 5v logic I have read but not tested) - 23Jun26

 Enter required RPM on serial console (150 to 3900)
 Pin 1 on motor is yellow

 Note: Numbers below 150 will be interpreted as MPH which is used when calibrating a speedo from a classic car
       which is what I bought this motor for.  For this to work your speedo needs to be 1600 times per mile which is
       often shown on the dial (i.e. 30mph = 800rpm)

 see - https://www.reddit.com/r/Motors/comments/1ixdyp4/how_to_use_this_12_pin_variant_nidec_24h/
       https://www.youtube.com/watch?v=TdrySOXRl-Y


Motor pins:
    1 = RPM - Pulse frequency modulation (Every 1000hz adds 150rpm with 150 being minimum)
    2 = enable pin (active high)
    3 = Brake (ground to stop motor)
    4 = Direction (ground = anti clockwise)
    5, 6 & 7 = speed feedback but not of much use apparently
    8 = connected to gnd
    9 & 10 = GND
    11 & 12 = +12v around 200ma in normal operaion
 

Arduino pins used:
      Motor                     Arduino UNO
      --------------------------------------------
        1       PFM Pin         9   Pulse frequency modulation
        2       Enable          7   Digital Output.
        3       Brake           6   Digital Output.
        4       Direction       5   Digital Output.
        9&10    GND             GND connect to motor and Arduino
        11&12   +12V            External PSU


 ---------------------------------------------------------------------------------------------------- */


const int pinPFM = 9;             // Motor pin 1 (Speed)
const int pinEnable = 7;          // Motor pin 2 (Start/Stop)
const int pinBrake = 6;           // Motor pin 3 (Brake)
const int pinDirection = 5;       // Motor pin 4 (Direction)

const int minVal = 1000;          // min value allowed (150rpm) - Note: may go down to 250?
const int maxVal = 26000;         // max value allowed (3900rpm)
const int startSpeed = 20000;     // startup motor rpm (should be high to get motor turning)
const bool motorDirection = 0;    // mnotor direction


// sketch variables
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
// when number entered on serial console motor speed is changed

void loop() {

  int qrpm = recNumFromSerial();       // receive input from Serial
  if (qrpm > 0) {                      // if a number has been received
    if (qrpm < 100) {
      // input is MPH
      int mphRPM = (int)((float)qrpm * 26.6666);                    // convert MPH to required RPM
      Serial.println("Setting motor to " + String(qrpm) + "MPH which is an RPM of " + String(mphRPM));
      setMotorRPM(mphRPM);
    } else {
      // input is RPM
      Serial.println ("MPH = " + String(convertRPMToMPH(qrpm)));    // for calibrating an Austin A35 speedo
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
    String line = Serial.readStringUntil('\n');   // Read until newline
    line.trim();
    if (line.length() == 0) return 0;
    int value = line.toInt(); 
    if (line == "0" || value != 0) {
      Serial.print("Received: ");
      Serial.println(value);
      return value;
    } else {
      Serial.println("Invalid input. Send an integer like 1000");
      return 0;
    }
  } 
}


// ******************************************************
//                    Set motor by RPM
// ******************************************************
// Note: every 1000 adds 150rpm

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
  unsigned long qFreq = (unsigned long)((float)reqRPM / 150.0 * 1000.0);
  return qFreq;
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
// for a classic car speedo which turns 1600 times per mile (30mph = 800rpm)

int convertRPMToMPH(unsigned long freq) {
  int mph = (int)((float)freq / 26.6666);  
  return mph;
}


// end
