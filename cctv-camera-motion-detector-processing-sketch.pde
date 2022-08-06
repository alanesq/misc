/*
    
              Processing jpg image change monitor - 06Aug22
              Monitors jpg images loaded via a URL and makes a sound if movement is detected
              
              Libraries used:
                OpenCV - https://opencv-java-tutorials.readthedocs.io/en/latest/
                Sound 
  
              Keyboard controls:  T = enable exit program timer
                                  C = disable timer
                                  Z = clear messages
                                  S = toggle sound
                                  D = toggle save image
  
                                                           alanesq@disroot.org
*/

// ---------------------------------- S E T T I N G S -------------------------------  

  String sTitle = "CCTV Movement Detector";          // Sketch title
  boolean saveImages = false;                        // save images when motion detected (true or false)
  boolean soundEnabled = true;                       // enable sound 
  int timeoutSetting = 10;                           // timeout (in minutes), activated by pressing 't' on keyboard
  int motionImageTriggerMin = 300;                   // trigger level min (triggers if between min and max)
  int motionImageTriggerMax = 99999;                 // trigger level max
  int motionPixeltrigger = 60;                       // trigger level for movement detection of pixels
  int refresh = 2000;                                // how often to refresh image
  
  int border = 8;                                    // screen border
  
  // screen size   -  Note: also change in "setup()"
    int screenWidth = 1120;
    int screenHeight = 500;
    
  // message area on screen
    int messageWidth = 240;
    int messageHeight = 410;
    int messageX = border;
    int messageY = 55;
    int maxMessages = 18;
    
    
  // camera settings
    
    // global image settings, used below to position images on screen
      int _mainTop = 55;
      int _mainLeft = messageWidth + (2 * border);
      int _imageWidth = 280;
      int _imageHeight = _imageWidth / 4 * 3;
      int _changeWidth = 220;
      int _changeHeight = _changeWidth / 4 * 3;  
      int _imageSpacing = _imageWidth + border;
      int _changePad = abs((_imageWidth - _changeWidth) / 2);
  
    // Set number of cameras used here (you will also need to modify "setup()")
      camera[] cameras = new camera[3];                    // create camera objects array 
  
    //  camera 0
      String cam0name = "Door";                            // camera 0 name (must be suitable for use in file name)
      String cam0loc = "http://door.jpg";  // camera 0 url
      int[] cam0 = {
                  _imageWidth,                             // main image                            imageWidth
                  _imageHeight,                            //                                       imageHeight
                  _mainLeft + _imageSpacing*0,             //                                       imageX
                  _mainTop,                                //                                       imageY
                  _changeWidth,                            // change image                          changeWidth
                  _changeHeight,                           //                                       changeHeight
                  _mainLeft + _changePad + _imageSpacing*0,//                                       changeX
                  _mainTop + _imageHeight + 24,            //                                       changeY
                  0,                                       // Select part of image to use           roiX
                  0,                                       //                                       roiY
                  320,                                     //                                       roiW
                  240                                      //                                       roiH
                 };    
           
    //  camera 1
      String cam1name = "Front";                            // camera 1 name (must be suitable for use in file name)
      String cam1loc = "http://front.jpg";  // camera 1 url
      int[] cam1 = {
                  _imageWidth,                             // main image                            imageWidth
                  _imageHeight,                            //                                       imageHeight
                  _mainLeft + _imageSpacing*1,             //                                       imageX
                  _mainTop,                                //                                       imageY
                  _changeWidth,                            // change image                          changeWidth
                  _changeHeight,                           //                                       changeHeight
                  _mainLeft + _changePad + _imageSpacing*1,//                                       changeX
                  _mainTop + _imageHeight + 24,            //                                       changeY
                  0,                                       // Select part of image to use           roiX
                  0,                                       //                                       roiY
                  320,                                     //                                       roiW
                  240                                      //                                       roiH
                 };    

    //  camera 2
      String cam2name = "Side";                            // camera 2 name (must be suitable for use in file name)
      String cam2loc = "http://side.jpg";  // camera 2 url
      int[] cam2 = {
                  _imageWidth,                             // main image                            imageWidth
                  _imageHeight,                            //                                       imageHeight
                  _mainLeft + _imageSpacing*2,             //                                       imageX
                  _mainTop,                                //                                       imageY
                  _changeWidth,                            // change image                          changeWidth
                  _changeHeight,                           //                                       changeHeight
                  _mainLeft + _changePad + _imageSpacing*2,//                                       changeX
                  _mainTop + _imageHeight + 24,            //                                       changeY
                  int(320 * 0.35),                         // Select part of image to use           roiX
                  int(240 * 0.04),                         //                                       roiY
                  int(320 * 0.33),                         //                                       roiW
                  int(240 * 0.30)                          //                                       roiH
                 };                  

// ----------------------------------------------------------------------------------  

import gab.opencv.*;
OpenCV opencv;

import processing.sound.*;
SoundFile alarmSound;

int timer = millis();   // timer for updating the image
int motionLevel = 0;    // current motion trigger level
int timeoutTimer = -1;  // timeout counter
//String[] message = { "Started at " + currentTime(":") };
ArrayList<String> message = new ArrayList<String>();
boolean keyReady = true;  // flag to stop repeats on keyboard press

// ----------------------------------------------------------------------------------  

void setup() {
  // create camera objects
    cameras[0] = new camera(cam0, cam0loc, cam0name);      // create camera 0 object
    cameras[1] = new camera(cam1, cam1loc, cam1name);      // create camera 1 object
    cameras[2] = new camera(cam2, cam2loc, cam2name);      // create camera 2 object

  alarmSound = new SoundFile(this, "sound.wav");
  size(1120, 500);                         // create canvas
  background(color(255, 255 , 0));        // yellow screen
  reloadImage();                          // prevent delay before screen first displays
  if (soundEnabled) {alarmSound.play();}   
  
  message.add("Started at " + currentTime(":"));
}

// ----------------------------------------------------------------------------------  
// returns the current real time as a string

String currentTime(String sep) {
  return nf(hour(),2) + sep + nf(minute(),2) + sep + nf(second(),2);
}

// ----------------------------------------------------------------------------------  
// check for changes in images and update screen

void reloadImage() {
    
  // clear screen
    background(color(255, 255 , 0));    // yellow screen    
    
  // compare old and new camera images
    motionLevel = 0;                                                                        // reset total motion detected counter
    for (int i = 0; i < cameras.length; i++) {                                              // step through all cameras
      if ( (cameras[i].update()) == false ) { return; }                                     // refresh image (exit procedure on error)
      opencv = new OpenCV(this, cameras[i].image);                                          // load image in to OpenCV
      image(opencv.getOutput(), cameras[i].imageX, cameras[i].imageY);                      // show image on screen 
      boolean iok = true;                                                                   // if previous image is ok detect differences between them
      try {                         
        if (cameras[i].imageOld.width < 1) { iok = false; }
      } catch (Exception e) { iok = false;  }      
      if (iok) { opencv.diff(cameras[i].imageOld); }
      //opencv.brightness(30);                                                               // adjust image brightness
      opencv.setROI(cameras[i].roiX, cameras[i].roiY, cameras[i].roiW, cameras[i].roiH);    // mask the resulting image
      cameras[i].grayDiff = opencv.getSnapshot();                                           // store resulting image
      cameras[i].grayDiff.resize(cameras[i].changeWidth, cameras[i].changeHeight);          // resize image
      cameras[i].motion();                                                                  // decide if enough change in images to count as movement detected
    }    
     
  // show screen Title
    noFill();  textSize(30); fill(255, 0, 0);
    text(sTitle, (width/2) - (sTitle.length() * 8), 40);     
  
  // draw the information box 
    strokeWeight(1);  fill(220, 220, 0);
    rect(messageX, messageY, messageWidth,messageHeight);
    textSize(14); fill(128, 128, 0); 
    if (message.size() > maxMessages) { message.remove(0); }                               // limit number of messages
    for (int i = 0; i < message.size(); i++) {
      text(message.get(i), 12, 70 + (20 * i) );   
    }
            
  // show status info on screen
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
      // saving images to disk
        if (saveImages) { tMes+= ", Images will be saved(D)"; } else { tMes += ", Image saving disabled(D)"; };  
      // send to screen
        fill(0, 0, 255);  textSize(16);
        text(tMes, border , height -5 );     // show total motion detected on screen
      // Motion detected level
        text("Combined motion = " + motionLevel, width - 215, height -5);
}

// ----------------------------------------------------------------------------------  

void draw() {
     
  // action cameras periodically
    if (millis() > (timer + refresh) ) {
      timer = millis();
      reloadImage();        // refresh images
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
    exit();   // timer expired so quit 
}

// ----------------------------------------------------------------------------------
// action on keyboard input

void keyPressed() {
//void actionKeyboardInput() {
  // check for keyboard press
    if (keyPressed && keyReady) {
      // enable/increase timeout, c=disable timeout
      if (key == 't' || key == 'T') {
        println("Timer increased");
        if (timeoutTimer < 0) timeoutTimer = 0;
        timeoutTimer += (timeoutSetting * 60); 
        keyReady = false;   // flag keyboard in use
      }
      // disable timeout
      if (key == 'c' || key == 'C') {
        timeoutTimer = -1;
        keyReady = true;   // flag keyboard in use
      }
      // clear messages
      if (key == 'z' || key == 'Z') {
        while (message.size() > 0) { 
          message.remove(0); 
        }
        message.add("Cleared at " + currentTime(":"));
      }
      // toggle sound
      if (key == 's' || key == 'S') {
        if (soundEnabled) {
          soundEnabled = false;
        } else {
          soundEnabled = true;
        }
      }
      // toggle save images to disk
      if (key == 'd' || key == 'D') {
        if (saveImages) {
          saveImages = false;
        } else {
          saveImages = true;
        }        
      }
    }
}  

void keyReleased() {
  keyReady = true;   // flag keyboard now ready
}

// ---------------------------------- Camera Objects --------------------------------  

class camera{

  PImage image, imageOld, grayDiff;          // store for images
  String iloc;                               // URL of image to monitor 
  String cameraName;                         // name of the camera
  
  // main image position on screen   
    int imageWidth;
    int imageHeight;
    int imageX;
    int imageY;
    
  // change detection image position on screen
    int changeWidth;
    int changeHeight;
    int changeX;
    int changeY;
    
  // detection image mask
    int roiX;
    int roiY;
    int roiW;
    int roiH;
  
  
  camera(int[] cam, String camLoc, String camName) {         // new object creation  
    // main image position on screen   
      imageWidth = cam[0];
      imageHeight = cam[1];
      imageX = cam[2];
      imageY = cam[3];
      
    // change detection image position on screen
      changeWidth = cam[4];
      changeHeight = cam[5];
      changeX = cam[6];
      changeY = cam[7];
      
    // detection image mask
      roiX = cam[8];
      roiY = cam[9];
      roiW = cam[10];
      roiH = cam[11]; 
      
    // Misc
      iloc = camLoc;                // url of camera
      cameraName = camName;         // name of camera
  }   // camera
   
   
  boolean update() {                // update image via url
      if (image != null && image.width > 0) { imageOld = image; }    // replace the old image with the current one
      
      try {  
        image = loadImage(iloc);    // load the image
      } catch (Exception e) {
        camError(1);          
        return false; 
      }
      
      try {                         // test if image loaded ok
        if (image.width < 1) { return false; }
      } catch (Exception e) {
        camError(2);
        return false;
      }
      
      image.resize(imageWidth, imageHeight);
      return true;
  }   // update
  
  
  void camError(int ecode) {        // error with camera image
        message.add( cameraName + ": error(" + ecode + ") at " + currentTime(":") );  
        if (ecode < 3) {
          timer = millis();           // reset retry timer     
        }
  }   // camError
  
  
  void motion() {       // decide if enough change in images to count as movement detected
  
    // check image is ok
      try {     
        if (image.width < 1) { 
          camError(3);
          return; 
        }
      } catch (Exception e) {
        camError(4);
        return;
      }    
  
    if (imageOld == null || image.width < 1) {return;}   // no old image yet to compare
    grayDiff.resize(changeWidth, changeHeight);
    grayDiff.loadPixels();
    image(grayDiff, changeX, changeY);    // show differences image on screen
    // get a single trigger level value from the whole image
      int dimension = grayDiff.width * grayDiff.height;
      int tcnt = 0;
      for (int i = 0; i < dimension; i++) { 
        int pix = grayDiff.pixels[i];
        float pixVal = (red(pix)+green(pix)+blue(pix)) / 3;     // average brightness of this pixel
        if (pixVal > motionPixeltrigger) {tcnt++;};   
      }
      motionLevel += tcnt;   // update combined motion trigger counter      
      if (tcnt >= motionImageTriggerMin && tcnt <= motionImageTriggerMax) {
        // motion detected
          message.add(cameraName + ": " + tcnt + " at " + currentTime(":") );
          if (soundEnabled) {alarmSound.play();}
          if (saveImages) {
            image.save( currentTime("-") + "_" + cameraName + ".jpg");     // save image to disk
          }
      }
      // display image title
        fill(0, 0, 255);  textSize(18);
        text(cameraName, imageX + (imageWidth/2) - ((cameraName.length()/2)*8), imageY + imageHeight + 18 );      
  }   // motion
  
}  // camera object

// ------------------------------------- E N D --------------------------------------  
