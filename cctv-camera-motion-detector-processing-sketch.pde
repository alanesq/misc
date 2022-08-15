/*
    
              Processing jpg image change monitor - 15Aug22
              Monitors jpg images loaded via a URL and makes a sound if movement is detected
              
              NOTES: It requires some sound files to use (see 'load audio files' in 'setup()')
                     Video on writing motion detection code: https://www.youtube.com/watch?v=QLHMtE5XsMs
              
              Libraries used:
                OpenCV - https://opencv-java-tutorials.readthedocs.io/en/latest/
                 Minim - https://code.compartmental.net/minim/ 
  
              Keyboard controls:  T = enable exit program timer
                                  C = disable timer
                                  Z = clear messages
                                  S = toggle sound
                                  D = toggle save image
                                  F = toggle face detection 
                                +/- = Adjust trigger level
                            numbers = enable/disable cameras
  
    https://github.com/alanesq/misc/blob/main/cctv-camera-motion-detector-processing-sketch.pde
                                                                            alanesq@disroot.org
*/

// ----------------------------------------------------------------------------------
// ---------------------------------- S E T T I N G S -------------------------------  
// ----------------------------------------------------------------------------------

  String sTitle = "CCTV Movement Detector";   // Sketch title
  boolean saveImages = false;                 // default save images when motion detected (true or false)
  boolean soundEnabled = true;                // default enable sound 
  boolean faceDetectionEnabled = false;       // default enable face detection
  int refresh = 2000;                         // how often to refresh image
  int timeoutSetting = 10;                    // default timeout (in minutes), activated by pressing 't' on keyboard
  
  // display
  int border = 8;                             // screen border
  int sTextSize = 14;                         // text size
  color sTextColor = color(0, 0, 255);        // text colour  
  
  // message area settings
  int messageWidth = 180;
  int messageHeight = 320;
  int messageX = border;
  int messageY = border;
  int maxMessages = messageHeight / 20;   
  
  // camera screen display settings   
  int _mainTop = border;
  int _camTop = border;
  int _mainLeft = messageWidth + (2 * border);
  int _imageWidth = 200;
  int _imageHeight = _imageWidth / 4 * 3;
  int _changeWidth = 150;
  int _changeHeight = _changeWidth / 4 * 3;  
  int _imageSpacing = _imageWidth + border;
  int _changePad = abs((_imageWidth - _changeWidth) / 2);   
  
  // screen size
  int windowWidth = (border * 5) + messageWidth + (3 * _imageWidth);  
  int windowHeight = messageHeight + 40;  
  
  // motion detection
  int motionImageTrigger = 200;     // default trigger level min (triggers if between min and max)
  int triggerStep = 25;             // trigger level adjustment step size
  int motionPixeltrigger = 50;      // trigger level for movement detection of pixels                    

// ----------------------------------------------------------------------------------  

ArrayList<camera> cameras = new ArrayList<camera>();    

// opencv
  import gab.opencv.*;
  OpenCV opencv;
  import java.awt.Rectangle;                           // used for face detection

// sound
  import ddf.minim.*;
  Minim minim;
  AudioPlayer movementSound;
  AudioPlayer faceSound;
  AudioPlayer alarmSound;
  
// log file
  PrintWriter logFile;

int timer = millis();                                   // timer for updating the image
int timeoutTimer = -1;                                  // timeout counter
ArrayList<String> message = new ArrayList<String>();    // messages stored in this array
Rectangle[] faces;                                      // used by face detection

// ----------------------------------------------------------------------------------  

// custom screen settings - called from 'setup()' - new version of processing only
  void settings() {
    size(windowWidth, windowHeight);     // set window size
  }
  void settingsAdnl() {
    try {
        surface.setTitle(sTitle);                            // set window title
        surface.setResizable(true);                          // make window resizable
        surface.setLocation(max(displayWidth - windowWidth - 20, 0), max(displayHeight - windowHeight - 55, 0) );   // location on screen  
        surface.setResizable(true);                          // make window resizable
    } catch (Exception e) { }
  }

void setup() {
  // size(820, 360);    // set up screen - old version of processing (delete 'void settings' procedures above)
  settingsAdnl();    // set up screen - new  version of processing only
  
  // create camera objects (name, URL to the jpg, image detection maskx, masky, maskw, maskh)
    cameras.add(new camera("Door", "http://door.jpg"));                 // where to access a live jpg image from your camera
    //cameras.add(new camera("Front", "http://front.jpg"));             // second camera (for more cameras just add more lines like this)
    //cameras.add(new camera("RoofCam", "http://192.168.1.19/jpg"));    // esp32cam using https://github.com/alanesq/esp32cam-demo
    
  // turn camera 3 off
    camera cam = cameras.get(3);
    cam.enabled = false; 
    
  // load audio files
    minim = new Minim(this);
    movementSound = minim.loadFile("sounds/movement.wav");
    faceSound = minim.loadFile("sounds/face.wav");
    alarmSound = minim.loadFile("sounds/alarm.wav");
  background(color(255, 255 , 0));        // yellow screen
  refresh();                              // prevent delay before screen first displays
  if (soundEnabled) {                     // if sound enabled demonstrate it is working
      alarmSound.rewind();
      alarmSound.play();    
  }
  // create log text file
    logFile = createWriter("log.txt"); 
    logFile.println(currentTime(":") + " - Started");
  message.add("Started at " + currentTime(":"));
  println("Started - Screen resolution: " + windowWidth + " x " + windowHeight);
}

// called when app is exited
void exit() {
    logFile.println(currentTime(":") + " - Stopped");
    logFile.flush(); // Writes the remaining data to the file
    logFile.close(); // Finishes the file  
    super.exit();
}

// ----------------------------------------------------------------------------------  
// returns the current real time as a string

String currentTime(String sep) {
  return nf(hour(),2) + sep + nf(minute(),2) + sep + nf(second(),2);
}

// ----------------------------------------------------------------------------------  
// motion detect and update display, called periodically by 'draw()'

void refresh() {
      
  // clear screen
    background(color(255, 255 , 0));    // yellow screen   
    stroke(sTextColor); fill(sTextColor); strokeWeight(1);
    
  //// show screen Title
  //  stroke(sTextColor); fill(sTextColor); strokeWeight(1);
  //  textSize(sTextSize * 2); 
  //  text(sTitle, (width/2) - (sTitle.length() * 8), 40);     
  
  // draw the information box 
    stroke(100, 100, 0); fill(220, 220, 0); strokeWeight(2);
    rect(messageX, messageY, messageWidth,messageHeight);
    stroke(sTextColor); fill(sTextColor); strokeWeight(1);
    textSize(sTextSize); 
    if (message.size() > maxMessages) { message.remove(0); }                               // limit number of messages
    for (int i = 0; i < message.size(); i++) {
      text(message.get(i), messageX + border, messageY + border + (20 * i) + 7 );   
    }
            
  // show the status info
    String tMes = "";
    // exit timer 
      if (timeoutTimer > 0) {
        // timer is enabled
          int mins = timeoutTimer / 60;
          int secs = timeoutTimer - (mins * 60);
          if (timeoutTimer < 60) {
            tMes += "PROGRAM WILL EXIT IN " + timeoutTimer + " SECONDS(T/C)";
          } else {
            tMes += "Program will exit in " + mins + " minutes and " + secs + " seconds(T/C)";   
          }
      } else {
        tMes += "Timer disabled(T)";
      }
    // sound
      if (soundEnabled) { tMes+= ", Sound enabled(S)"; } else { tMes += ", Sound disabled(S)"; };
    // face detection
      if (faceDetectionEnabled) { tMes+= ", Face detection enabled(F)"; } else { tMes += ", Face detection disabled(F)"; };        
    // saving images to disk
      if (saveImages) { 
        tMes+= ", Images will be saved(D)"; 
        // display image file location info.
          stroke(sTextColor); fill(sTextColor); strokeWeight(1);
          textSize(sTextSize); 
          String tText = "Images will be stored in '" + sketchPath(""); 
          text(tText, width - textWidth(tText) - border, height -8 - sTextSize);               
      } else { 
        tMes += ", Image saving disabled(D)"; 
      }  
    // send to screen
      stroke(sTextColor); fill(sTextColor); strokeWeight(1);
      textSize(sTextSize);
      text(tMes, border , height -5 );     // show total motion detected on screen
      
    // Motion detection settings
      tMes = "Triggers at: " + motionImageTrigger + "(+/-)"; 
      stroke(sTextColor); fill(sTextColor); strokeWeight(1);
      text(tMes, width - textWidth(tMes) - border, height -5);        

    // compare old and new camera images using OpenCV and display images
      for (int i = 0; i < cameras.size(); i++) {                                     // step through all cameras
        camera cam = cameras.get(i);
        if (!cam.enabled) continue;                                                  // skip camera if not enabled
        if (!cam.update()) continue;                                                 // refresh image (skip camera if there was an error)
        cam.image.resize(_imageWidth, _imageHeight);                                 // resize image
        opencv = new OpenCV(this, cam.image);                                        // load image in to OpenCV - NOTE: I suspect this is not the best way to do this but I can't find a better way to refresh the image
        image(opencv.getOutput(), _mainLeft + _imageSpacing*i, _mainTop + _camTop);  // display image on screen 
        faceDetect(i);                                                               // face detect 
        int mRes = motionDetect(i);                                                  // motion detect
       
        // display changes image and title
          if (mRes != -1) {                                                          // -1 = problem with an image
              cam.grayDiff.resize(_changeWidth, _changeHeight);      // resize differences image for display
              image(cam.grayDiff, _mainLeft + _changePad + _imageSpacing*i, _mainTop + _camTop + _imageHeight + 24, _changeWidth, _changeHeight);               // show differences image on screen
            // display image title
              stroke(sTextColor); fill(sTextColor); strokeWeight(1);
              if (cam.currentDetectionLevel >= motionImageTrigger) fill(128, 0, 128);  // change colour if above trigger level
              tMes = cam.cameraName + ": " + cam.currentDetectionLevel + "/" + cam.cumulativeDetectionLevel;
              text(tMes, _mainLeft + (_imageSpacing * (i)) + ( int((_imageWidth - textWidth(tMes)) / 2) ), _mainTop + _camTop + _imageHeight + 18);
          }   
      }   //for loop
}

// ----------------------------------------------------------------------------------  
// face detection

void faceDetect(int i) {
  if (!faceDetectionEnabled) return;   // face detection is disabled
                                     
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 
  faces = opencv.detect();
  //faces = opencv.detect(100 , 0 , 0, 25, 9999);    // , , , min, max
  if (faces.length > 0) {              // if at least one face was detected
      // show details on console
        camera cam = cameras.get(i);
        logFile.println(currentTime(":") + " - Face detection on camera '" + cam.cameraName);
        for (int j = 0; j < faces.length; j++) {
          logFile.println("   face#" + (j+1) + ": x=" + faces[j].x + ", y=" + faces[j].y + ", width=" + faces[j].width + ", height=" + faces[j].height);
          // draw area on screen
            stroke(0, 255, 0);  noFill();    
            // note - image location on screen = _mainLeft + _imageSpacing*i, _mainTop + _camTop
            rect( (_mainLeft + _imageSpacing*i) + faces[j].x, (_mainTop + _camTop) + faces[j].y, faces[j].width, faces[j].height);          
        }      
      message.add("Face on '" + cam.cameraName + "' at " + currentTime(":"));    // + " Size: " + faces[0].width + ", " + faces[0].height);
      if (saveImages) {
        cam.image.save( "images/" + currentTime("-") + "_" + cam.cameraName + "-2.jpg");         // save current image to disk
      }
      if (soundEnabled) {
          faceSound.rewind();
          faceSound.play();    
      }    
    }      
}
          
// ----------------------------------------------------------------------------------  
// motion detect 

int motionDetect(int i) {      
 
      camera cam = cameras.get(i);
      int mRes = cam.motion();           // perform motion detection
       if (mRes == 1) {                  // if motion detected
          logFile.println(currentTime(":") + " - Motion detected on camera '" + cam.cameraName + "' level:" + cam.currentDetectionLevel);
          message.add(cam.cameraName + ": " + cam.currentDetectionLevel + " at " + currentTime(":") );
          if (soundEnabled) {
              movementSound.rewind();
              movementSound.play();    
          }              
          if (saveImages) cam.image.save( "images/" + currentTime("-") + "_" + cam.cameraName + ".jpg");         // save current image to disk
        }  
        return mRes;
}
          
// ----------------------------------------------------------------------------------  

void draw() {
     
  // action cameras periodically
    if (millis() > (timer + refresh) ) {
      timer = millis();
      refresh();            // refresh images / display
      actionTimer();        // timed program exit (when 'T' key is pressed)  
    }
}

// ---------------------------------------------------------------------------------- 
// countdown timer to program exit

void actionTimer() {
  if (timeoutTimer < 0) return;    // timer is disabled
  timeoutTimer = timeoutTimer - (refresh / 1000);
  if (timeoutTimer > 0) {
    return;
  }
    logFile.println(currentTime(":") + " - Stopped by timer");
    logFile.flush(); // Writes the remaining data to the file
    logFile.close(); // Finishes the file  
    exit();   // timer expired so quit 
}

// ----------------------------------------------------------------------------------
// action on keyboard input

void keyPressed() {
//void actionKeyboardInput() {
  // check for keyboard press
    if (keyPressed) {
      // enable/increase timeout, c=disable timeout
      if (key == 't' || key == 'T') {
        if (timeoutTimer < 0) timeoutTimer = 0;
        timeoutTimer += (timeoutSetting * 60); 
        logFile.println(currentTime(":") + " - Timer set to " + timeoutTimer);
      }
      // disable timeout
      if (key == 'c' || key == 'C') {
        timeoutTimer = -1;
        logFile.println(currentTime(":") + " - Timer disabled");
      }
      // clear messages
      if (key == 'z' || key == 'Z') {
        while (message.size() > 0) { 
          message.remove(0); 
        }
        message.add("Cleared at " + currentTime(":"));
        logFile.println(currentTime(":") + " - Messages cleared");
      }
      // toggle sound
      if (key == 's' || key == 'S') {
        soundEnabled = !soundEnabled;
        logFile.println(currentTime(":") + " - sound enabled changed to " + soundEnabled);
      }
      // toggle save images to disk
      if (key == 'd' || key == 'D') {
        saveImages = !saveImages;     
        logFile.println(currentTime(":") + " - save images changed to  " + saveImages);
      }
      // change trigger level
      if (key == '+') {
        motionImageTrigger += triggerStep;
        logFile.println(currentTime(":") + " - motion trigger level changed to " + motionImageTrigger);
      }      
      if (key == '-') {
        if (motionImageTrigger > triggerStep) {
          motionImageTrigger -= triggerStep;
        } else {
          motionImageTrigger = 5;   // minimum setting
        }
        logFile.println(currentTime(":") + " - motion trigger level changed to " + motionImageTrigger);
      }         
      // toggle face detection
      if (key == 'f' || key == 'F') {
        faceDetectionEnabled = !faceDetectionEnabled;  
        logFile.println(currentTime(":") + " - face detection enabled changed to " + faceDetectionEnabled);
      }      
      // toggle cameras enabled flag
        if (int(key) >= 49 && int(key) <= 57) {    // if it is a number key (1 to 9)
          int camNum = int(key) - 49;              // which camera this button relates to
          if (camNum < cameras.size()) {           // if this is a valid camera  
            camera cam = cameras.get(camNum);
            cam.enabled = !cam.enabled;
            logFile.println(currentTime(":") + " - camera '" + cam.cameraName + "' enabled set to " + cam.enabled);            
          }
        }
    }
}  

// ----------------------------------------------------------------------------------
// ---------------------------------- Camera Objects --------------------------------  
// ----------------------------------------------------------------------------------

class camera{

  boolean enabled;                     // if this camera is enabled
  PImage image, imageOld, grayDiff;    // stores for camera images
  String iloc;                         // URL of image being monitored
  String iExt = "jpg";                 // type of image file
  String cameraName;                   // name of the camera
  int currentDetectionLevel;           // the detection level of the current image
  int cumulativeDetectionLevel;        // the cumulative detection level (combines current and previous levels)
    
  // detection image mask
    int roiX;   // -1 = mask is disabled
    int roiY;
    int roiW;
    int roiH;
  
  // new object creation with detection mask
  camera(String camName, String camURL, int maskX, int maskY, int maskW, int maskH) {         
    iloc = camURL; 
    cameraName = camName;
    cumulativeDetectionLevel = 0;
    enabled = true;
    // detection image mask
      roiX = maskX;
      roiY = maskY;
      roiW = maskW;
      roiH = maskH;      
  }   // camera
  
  // new object creation without detection mask
    camera(String camName, String camURL) {         
    iloc = camURL; 
    cameraName = camName;
    cumulativeDetectionLevel = 0;
    enabled = true;
    roiX = -1;   // flag detection mask disabled
  }   // camera
   
  
  // refresh the camera image
  boolean update() {       
    if (enabled == false) return false;   // abort if camera is disabled
    imageOld = image;                     // first store the present image
    
    // load new image from camera and check it is ok
      int iError = 0;
      for (int i=0; i<3; i++) {           // try up to 3 times
        iError = 0;
        try {  
          image = loadImage(iloc, iExt);        // load the image
        } catch (Exception e) {
          iError = 1;
        }
        if (iError == 0) break;           // image has loaded ok so quit for loop
        delay(200);                       // wait then try again
      }
      try {                               // test if image loaded ok
        if (image.width < 1) { iError = 2; }
      } catch (Exception e) {
        iError = 2;
      }
      if (iError != 0) {                  // if error loading image abort
        camError(iError);          
        return false;       
      }
    return true;
  }   // update
  
  // error with a camera image
  void camError(int ecode) {        // error with camera 
        logFile.println(currentTime(":") + " - Camera error on '" + cameraName + "' - code: " + ecode);    // NOTE: causes error 
        //message.add( cameraName + ": error(" + ecode + ") at " + currentTime(":") );  
        if (ecode < 3) {
          timer = millis();           // reset retry timer     
        }
  }   // camError
  
// motion detect image returning number of changed pixels
int motion() {       // decide if enough change in images to count as movement detected
  if (enabled == false) return 0;      // skip camera if not enabled

  // check old image is ok
  try {                         
    if (imageOld.width < 1) { return -1; }
  } catch (Exception e) { return -1; }

  // compare images
    opencv.diff(imageOld);                                   // compare the two images
    if (roiX != -1) opencv.setROI(roiX, roiY, roiW, roiH);   // mask the resulting differences image  
    grayDiff = opencv.getSnapshot();                         // get the differences image

  // check the images are ok
    int iError = 0;    
    try {                 // main image
      if (image.width < 1) { iError = 4; }
    } catch (Exception e) { iError = 3; }
    try {                 // old image
      if (imageOld.width < 1 || imageOld == null) { iError = 6; }
    } catch (Exception e) { iError = 5; }   
    try {                 // differences image
      if (grayDiff.width < 1) { iError = 8; }
    } catch (Exception e) { iError = 7; }        
    if (iError != 0) {    // problem with one of the images so abort
      camError(iError); 
      return 0;     
    }

    // get a single trigger level value from the whole image
      grayDiff.loadPixels();
      int dimension = grayDiff.width * grayDiff.height;
      currentDetectionLevel = 0;              // reset changed pixel counter
      for (int i = 0; i < dimension; i++) {
        int pix = grayDiff.pixels[i];
        float pixVal = brightness(pix);       // average brightness of this pixel
        if (pixVal > motionPixeltrigger) {
          currentDetectionLevel++;            // increment changed pixel counter
        }
      }
 //     // weight the result to compensate for the mask reducing effective image resolution (so all camera results are comparable)
 //       float ratioOfFullImage = 1.0;
 //       if (roiW * roiH != 0) ratioOfFullImage = (image.width * image.height) / (roiW * roiH);
 //       currentDetectionLevel = int(currentDetectionLevel * ratioOfFullImage);  
 
      // control trigger level     
        currentDetectionLevel = min(motionImageTrigger * 2, currentDetectionLevel);                            // limit maximum 
        cumulativeDetectionLevel = int((cumulativeDetectionLevel * 0.6) + (currentDetectionLevel * 0.4));      // limit rate of change by mixing with previous levels
        //if (currentDetectionLevel == 0) cumulativeDetectionLevel = 0;                                        // if current level is zero clear previous readings      
      if (cumulativeDetectionLevel >= motionImageTrigger) {
        cumulativeDetectionLevel = 0;                                                                          // reset cumulative trigger level
        return 1;  
      }
      return 0;        
  }   // motion
  
}  // camera object

// ------------------------------------- E N D -------------------------------------- }
