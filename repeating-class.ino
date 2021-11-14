  
// example of repeating operations periodically using CLASS



// ----------------------------------------------------------------
//                            -repeatTimer
// ---------------------------------------------------------------- 
// repeat an operation periodically 

class repeatTimer {

  private:
    uint32_t  _lastTime;                                              // store of last time this event triggered

  public:
    repeatTimer() {
      reset();
    }

    bool check(uint32_t timerInterval, bool timerReset=1) {           // check if provided time has passed 
      if ( (unsigned long)(millis() - _lastTime) >= timerInterval ) {
        if (timerReset) reset(); 
        return 1;
      } 
      return 0;
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
  
  static repeatTimer timer1;    // set up a timer     
  if (timer1.check(2000)) {
    Serial.println("This repeats every 2 seconds");
  }
  
  static repeatTimer timer2;    // set up a second timer     
  if (timer2.check(5000)) {
    Serial.println("This repeats every 5 seconds");
  }  

}


// ---------------------------------------------------------------- 
