/*
    
              Processing jpg image change monitor - 08Aug22
              Monitors jpg images loaded via a URL and makes a sound if movement is detected
              
              Libraries used:
                OpenCV - https://opencv-java-tutorials.readthedocs.io/en/latest/
                Sound 
  
              Keyboard controls:  T = enable exit program timer
                                  C = disable timer
                                  Z = clear messages
                                  S = toggle sound
                                  D = toggle save image
                                  F = toggle face detection 
                                +/- = Adjust trigger level
  
    from: https://github.com/alanesq/misc/blob/main/cctv-camera-motion-detector-processing-sketch.pde
                                                                                  alanesq@disroot.org
*/

// ---------------------------------- S E T T I N G S -------------------------------  

  String sTitle = "CCTV Movement Detector";          // Sketch title
  boolean saveImages = false;                        // default save images when motion detected (true or false)
  boolean soundEnabled = true;                       // default enable sound 
  int refresh = 2000;                                // how often to refresh image
  int timeoutSetting = 10;                           // default timeout (in minutes), activated by pressing 't' on keyboard
  int cDetections = 2;                               // consecutive motion detections required to trigger movement detected
  
  // face detection
  boolean faceDetectionEnabled = false;              // default enable face detection
  
  // motion detection
  int motionImageTriggerMin = 200;                   // default trigger level min (triggers if between min and max)
  int triggerStep = 50;                              // trigger level adjustment step size
  int motionImageTriggerMax = 99999;                 // default trigger level max
  int motionPixeltrigger = 50;                       // trigger level for movement detection of pixels
  
  // display
  int border = 8;                                    // screen border
  int sTextSize = 14;                                // on screen text size
    
  // message area on screen
    int messageWidth = 200;
    int messageHeight = 410;
    int messageX = border;
    int messageY = 55;
    int maxMessages = 18;
    
    
  // camera settings
    
    int noOfCams = 3;                             // number of cameras in use
    // Note: to add or remove a camera modify the "noOfCams" value above, add or remove a settings section for the camera below and 
    //       add or remove a line for the camera in "setup()"

    // used below to size and position the images on the screen
      int _mainTop = 55;
      int _camTop = 20;
      int _mainLeft = messageWidth + (2 * border);
      int _imageWidth = 240;
      int _imageHeight = _imageWidth / 4 * 3;
      int _changeWidth = 180;
      int _changeHeight = _changeWidth / 4 * 3;  
      int _imageSpacing = _imageWidth + border;
      int _changePad = abs((_imageWidth - _changeWidth) / 2);
      
    camera[] cameras = new camera[noOfCams];      //  used to pass the settings to the camera object

    //  camera 0 settings
      String cam0name = "Door";                            // camera 0 name (must be suitable for use in file name)
      String cam0loc = "http://door.jpg";  // camera 0 url
      int[] cam0 = {
                  _imageWidth,                             // main image                            imageWidth
                  _imageHeight,                            //                                       imageHeight
                  _mainLeft + _imageSpacing*0,             //                                       imageX
                  _mainTop + _camTop,                      //                                       imageY
                  _changeWidth,                            // change image                          changeWidth
                  _changeHeight,                           //                                       changeHeight
                  _mainLeft + _changePad + _imageSpacing*0,//                                       changeX
                  _mainTop + _camTop + _imageHeight + 24,  //                                       changeY
                  0,                                       // Select part of image to use           roiX
                  0,                                       //                                       roiY
                  _imageWidth,                             //                                       roiW
                  _imageHeight                             //                                       roiH
                 };    
           
    //  camera 1 settings
      String cam1name = "Front";                            // camera 1 name (must be suitable for use in file name)
      String cam1loc = "http://front.jpg";  // camera 1 url
      int[] cam1 = {
                  _imageWidth,                             // main image                            imageWidth
                  _imageHeight,                            //                                       imageHeight
                  _mainLeft + _imageSpacing*1,             //                                       imageX
                  _mainTop + _camTop,                      //                                       imageY
                  _changeWidth,                            // change image                          changeWidth
                  _changeHeight,                           //                                       changeHeight
                  _mainLeft + _changePad + _imageSpacing*1,//                                       changeX
                  _mainTop + _camTop + _imageHeight + 24,  //                                       changeY
                  0,                                       // Select part of image to use           roiX
                  0,                                       //                                       roiY
                  _imageWidth,                             //                                       roiW
                  _imageHeight                             //                                       roiH
                 };    

    //  camera 2 settings
      String cam2name = "Side";                            // camera 2 name (must be suitable for use in file name)
      String cam2loc = "http://side.jpg";  // camera 2 url
      int[] cam2 = {
                  _imageWidth,                             // main image                            imageWidth
                  _imageHeight,                            //                                       imageHeight
                  _mainLeft + _imageSpacing*2,             //                                       imageX
                  _mainTop + _camTop,                      //                                       imageY
                  _changeWidth,                            // change image                          changeWidth
                  _changeHeight,                           //                                       changeHeight
                  _mainLeft + _changePad + _imageSpacing*2,//                                       changeX
                  _mainTop + _camTop + _imageHeight + 24,  //                                       changeY
                  int(_imageWidth * 0.40),                 // Select part of image to use           roiX
                  int(_imageHeight * 0.05),                //                                       roiY
                  int(_imageWidth * 0.40),                 //                                       roiW
                  int(_imageHeight * 0.35)                 //                                       roiH
                 };                  

// ----------------------------------------------------------------------------------  

import gab.opencv.*;
OpenCV opencv;
import java.awt.Rectangle;        // used for face detection

import processing.sound.*;
SoundFile alarmSound, faceSound, movementSound;

int timer = millis();             // timer for updating the image
int timeoutTimer = -1;            // timeout counter
ArrayList<String> message = new ArrayList<String>();        // messages stored in this array
boolean keyReady = true;          // flag to stop repeats on keyboard press
Rectangle[] faces;                // used by face detection

// ----------------------------------------------------------------------------------  

void setup() {
  // create camera objects
    cameras[0] = new camera(cam0, cam0loc, cam0name);      // create camera 0 object
    cameras[1] = new camera(cam1, cam1loc, cam1name);      // create camera 1 object
    cameras[2] = new camera(cam2, cam2loc, cam2name);      // create camera 2 object
  // load wav files
    movementSound = new SoundFile(this, "sounds/movement.wav");
    faceSound = new SoundFile(this, "sounds/face.wav");
    alarmSound = new SoundFile(this, "sounds/alarm.wav");
  size(960, 500);                         // create canvas
  background(color(255, 255 , 0));         // yellow screen
  reloadImage();                           // prevent delay before screen first displays
  if (soundEnabled) alarmSound.play(); 
  
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
    
  // compare old and new camera images using OpenCV
    for (int i = 0; i < cameras.length; i++) {                                            // step through all cameras
      if ( (cameras[i].update()) == false ) { return; }                                   // refresh image (exit procedure if error)
      opencv = new OpenCV(this, cameras[i].image);                                        // load image in to OpenCV
      image(opencv.getOutput(), cameras[i].imageX, cameras[i].imageY);                    // display image on screen 
      faceDetect(i);                                                                      // face detect  

    // make sure previous image is valid       
      boolean iok = true;
      try {                         
        if (cameras[i].imageOld.width < 1) { iok = false; }
      } catch (Exception e) { iok = false; }
    
      if (iok == true) {
        // compare images
          opencv.diff(cameras[i].imageOld);                                                     // compare the two images
          opencv.setROI(cameras[i].roiX, cameras[i].roiY, cameras[i].roiW, cameras[i].roiH);    // mask the resulting differences image
          cameras[i].grayDiff = opencv.getSnapshot();                                           // get the differences image
          cameras[i].grayDiff.resize(cameras[i].changeWidth, cameras[i].changeHeight);          // resize differences image
          if (cameras[i].motion() == cDetections) {        
            // motion detected
              message.add(cameras[i].cameraName + ": " + cameras[i].camMotionLevel + " at " + currentTime(":") );
              if (soundEnabled) movementSound.play(); 
              if (saveImages) { 
                cameras[i].image.save( currentTime("-") + "_" + cameras[i].cameraName + "-2.jpg");         // save current image to disk
            }
          }
          // display image title
            fill(0, 0, 255);  textSize(sTextSize);
            text(cameras[i].cameraName + ": " + cameras[i].camMotionLevel, cameras[i].imageX + (cameras[i].imageWidth/2) - ((cameras[i].cameraName.length()/2)*8), cameras[i].imageY + cameras[i].imageHeight + 18 );
      }
    }
  
  // show screen Title
    noFill();  textSize(sTextSize * 2); fill(255, 0, 0);
    text(sTitle, (width/2) - (sTitle.length() * 8), 40);     
  
  // draw the information box 
    strokeWeight(1);  fill(220, 220, 0);
    rect(messageX, messageY, messageWidth,messageHeight);
    textSize(sTextSize); fill(128, 128, 0); 
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
      // face detection
        if (faceDetectionEnabled) { tMes+= ", Face detection enabled(F)"; } else { tMes += ", Face detection disabled(F)"; };        
      // saving images to disk
        if (saveImages) { tMes+= ", Images will be saved(D)"; } else { tMes += ", Image saving disabled(D)"; };  
      // send to screen
        fill(0, 0, 255);  textSize(sTextSize);
        text(tMes, border , height -5 );     // show total motion detected on screen
      // Motion detected level
        text("Trigger at: " + motionImageTriggerMin + "(+/-)", width - (sTextSize * 11), height -5);
}

// ----------------------------------------------------------------------------------  
// face detection on image

void faceDetect(int i) {
  if (!faceDetectionEnabled) return;                    // face detection is disabled
                                     
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 
  faces = opencv.detect();
  if (faces.length > 0) {
    message.add("Face detected on " + cameras[i].cameraName + " at " + currentTime(":"));    // + " Size: " + faces[0].width + ", " + faces[0].height);
    if (saveImages) {
      cameras[i].image.save( currentTime("-") + "_" + cameras[i].cameraName + "-2.jpg");         // save current image to disk
    }
    if (soundEnabled) faceSound.play(); 
    }      
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
    if (keyPressed) {
      // enable/increase timeout, c=disable timeout
      if (key == 't' || key == 'T') {
        println("Timer increased");
        if (timeoutTimer < 0) timeoutTimer = 0;
        timeoutTimer += (timeoutSetting * 60); 
      }
      // disable timeout
      if (key == 'c' || key == 'C') {
        timeoutTimer = -1;
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
        soundEnabled = !soundEnabled;
      }
      // toggle save images to disk
      if (key == 'd' || key == 'D') {
        saveImages = !saveImages;     
      }
      // change trigger level
      if (key == '+') {
        motionImageTriggerMin += triggerStep;
      }      
      if (key == '-') {
        if (motionImageTriggerMin > triggerStep) {
          motionImageTriggerMin -= triggerStep;
        }
      }         
      // toggle face detection
      if (key == 'f' || key == 'F') {
        faceDetectionEnabled = !faceDetectionEnabled;  
      }      
    }
}  

// ---------------------------------- Camera Objects --------------------------------  

class camera{

  PImage image, imageOld, grayDiff;               // stores for images
  String iloc;                                    // URL of image to monitor 
  String cameraName;                              // name of the camera
  int camMotionLevel;                             // motion level of this camera
  int cDetect;                                    // consecutive change detection counter
  
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
      cDetect = 0;
  }   // camera
   
   
  boolean update() {                // update image via url
      
      //if (cDetect > cDetections) cDetect = 0;                   // in case the count runs away
      imageOld = image;     // replace the old image with the current one 
      //if ( cDetect == 0 || image != null) imageOld = image;     // replace the old image with the current one 
      
      try {  
        image = loadImage(iloc);    // load the image
      } catch (Exception e) {
        camError(2);          
        return false; 
      }
      
      try {                         // test if image loaded ok
        if (image.width < 1) { return false; }
      } catch (Exception e) {
        camError(1);
        return false;
      }
      
      if (image.width != imageWidth || image.height != imageHeight) image.resize(imageWidth, imageHeight);
      return true;
  }   // update
  
  
  void camError(int ecode) {        // error with camera image
        message.add( cameraName + ": error(" + ecode + ") at " + currentTime(":") );  
        //if (soundEnabled) alarmSound.play(); 
        if (ecode < 3) {
          timer = millis();           // reset retry timer     
        }
  }   // camError
  
  
int motion() {       // decide if enough change in images to count as movement detected
  
    // check the images are ok
      int iError = 0;    
      try {                 // main image
        if (image.width < 1) { iError = 4; }
      } catch (Exception e) { iError = 3; }
      try {                 // old image
        if (imageOld.width < 1 || imageOld == null) { iError = 6; }
      } catch (Exception e) { iError = 5; }   
      try {                 // differences image
        if (imageOld.width < 1) { iError = 8; }
      } catch (Exception e) { iError = 7; }        
      if (iError != 0) {    // problem with one of the images so abort
        camError(iError); 
        return 0;     
      }

    grayDiff.resize(changeWidth, changeHeight);
    grayDiff.loadPixels();
    image(grayDiff, changeX, changeY);               // show differences image on screen
    
    // get a single trigger level value from the whole image
      int dimension = grayDiff.width * grayDiff.height;
      camMotionLevel = 0;                            // reset change count
      for (int i = 0; i < dimension; i++) { 
        int pix = grayDiff.pixels[i];
        float pixVal = (red(pix)+green(pix)+blue(pix)) / 3;     // average brightness of this pixel
        if (pixVal > motionPixeltrigger) camMotionLevel++;   
      }
      if (camMotionLevel >= motionImageTriggerMin && camMotionLevel <= motionImageTriggerMax) {
        cDetect++;                               // increment consecutive detection counter
        return cDetect;                          // motion detected
      }
      cDetect = 0;                               // reset consecutive detection counter
      return 0;        
  }   // motion
  
}  // camera object

// ------------------------------------- E N D --------------------------------------  
