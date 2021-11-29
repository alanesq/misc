  
// example of repeating operations periodically using CLASS



// ----------------------------------------------------------------
//                            -repeatTimer
// ---------------------------------------------------------------- 
// repeat an operation periodically 

class repeatTimer {

  private:
    uint32_t  _lastTime;                                              // store of last time this event triggered
    bool _enabled;                                                    // if timer is enabled

  public:
    repeatTimer() {
      reset();
      _enabled = 1;
    }

    bool check(uint32_t timerInterval, bool timerReset=1) {           // check if provided time has passed 
      if ( (unsigned long)(millis() - _lastTime) >= timerInterval ) {
        if (timerReset) reset(); 
        if (_enabled) return 1;
      } 
      return 0;
    }

    void disable() {                                                  // disable the timer
      _enabled = 0;
    } 

    void enable() {                                                   // re-enable the timer
      _enabled = 1;
    }    
    
    void reset() {                                                    // reset the timer
      _lastTime = millis();
    }
};


// ---------------------------------------------------------------- 


void setup() {
  
    Serial.begin(115200); while (!Serial); delay(100);       // start serial comms   
    Serial.println("\n\n\nStarting: ");
    
}


// ---------------------------------------------------------------- 


void loop() {

  // timer example #1
  static repeatTimer timer1;    // set up a timer which triggers every 3 seconds   
  if (timer1.check(3000)) {
    Serial.println("Timer1, repeats every 3 seconds");
  }


  // timer example #2
  static repeatTimer timer2;    // set up a timer which triggers every 11 seconds   
  if (timer2.check(11000)) {
    Serial.println("Timer2, triggers every 11 seconds");
  }  
  if (timer2.check(3000, 0)) {
    // only do this if it is over 3 seconds since timer2 was reset (do not reset the timer)
  } 

  
  // timer example #3
  static repeatTimer timer3;    // set up a timer which triggers once after 15 seconds  
  if (timer3.check(15000)) {
    timer3.disable();
    Serial.println("Timer3, triggers once after 15 seconds");
  }

}


// ---------------------------------------------------------------- 
