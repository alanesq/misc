/*
    
              Processing jpg image change monitor - 10Aug22
              Monitors jpg images loaded via a URL and makes a sound if movement is detected
              
              Libraries used:
                OpenCV - https://opencv-java-tutorials.readthedocs.io/en/latest/
                 Minim - https://code.compartmental.net/minim/ 
  
              Keyboard controls:  T = enable exit program timer
                                  C = disable timer
                                  Z = clear messages
                                  S = toggle sound
                                  D = toggle save image
                                  F = toggle face detection 
                                  N = change consecutive detections to trigger
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
  int cDetections = 2;                               // consecutive motion detections on camera required to trigger movement detected

  
  // face detection
  boolean faceDetectionEnabled = false;              // default enable face detection
  
  // motion detection
  int motionImageTriggerMin = 250;                   // default trigger level min (triggers if between min and max)
  int triggerStep = 25;                              // trigger level adjustment step size
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

// opencv
  import gab.opencv.*;
  OpenCV opencv;
  import java.awt.Rectangle;        // used for face detection

// sound
  import ddf.minim.*;
  Minim minim;
  AudioPlayer movementSound;
  AudioPlayer faceSound;
  AudioPlayer alarmSound;

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
  // load audio files
    minim = new Minim(this);
    movementSound = minim.loadFile("sounds/movement.wav");
    faceSound = minim.loadFile("sounds/face.wav");
    alarmSound = minim.loadFile("sounds/alarm.wav");
  size(960, 500);                         // create canvas
  background(color(255, 255 , 0));        // yellow screen
  refresh();                              // prevent delay before screen first displays
  if (soundEnabled) {                     // if sound enabled demonstrate it is working
      alarmSound.rewind();
      alarmSound.play();    
  }
  
  message.add("Started at " + currentTime(":"));
}

// ----------------------------------------------------------------------------------  
// returns the current real time as a string

String currentTime(String sep) {
  return nf(hour(),2) + sep + nf(minute(),2) + sep + nf(second(),2);
}

// ----------------------------------------------------------------------------------  
// check for changes in images and update screen

void refresh() {
    
  // clear screen
    background(color(255, 255 , 0));    // yellow screen    
    
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
        if (saveImages) { 
          tMes+= ", Images will be saved(D)"; 
          // display image file location info.
            textSize(sTextSize); fill(0, 0, 255);
            String tText = "Image files will be stored in '" + sketchPath("") + "/images/'"; 
            text(tText, width - (tText.length() * sTextSize * 0.5) , height -8 - sTextSize);               
        } else { 
          tMes += ", Image saving disabled(D)"; 
        }  
      // send to screen
        fill(0, 0, 255);  textSize(sTextSize);
        text(tMes, border , height -5 );     // show total motion detected on screen
        
      // Motion detection settings
        tMes = "Triggers at: " + motionImageTriggerMin + "(+/-) x " + cDetections + "(N)";       
        text(tMes, width - (tMes.length() * sTextSize * 0.5), height -5);
    
  // compare old and new camera images using OpenCV
    for (int i = 0; i < cameras.length; i++) {                                            // step through all cameras
      if ( (cameras[i].update()) == false ) {                                             // refresh image (exit procedure if error)
        break; 
      }     
      opencv = new OpenCV(this, cameras[i].image);                                        // load image in to OpenCV
      image(opencv.getOutput(), cameras[i].imageX, cameras[i].imageY);                    // display image on screen 
      faceDetect(i);                                                                      // face detect  if enabled

    // make sure previous image is valid       
      boolean _iok = true;
      try {                         
        if (cameras[i].imageOld.width < 1) { _iok = false; }
      } catch (Exception e) { _iok = false; }
    
      if (_iok == true) {
        // compare images
          opencv.diff(cameras[i].imageOld);                                                     // compare the two images
          opencv.setROI(cameras[i].roiX, cameras[i].roiY, cameras[i].roiW, cameras[i].roiH);    // mask the resulting differences image
          cameras[i].grayDiff = opencv.getSnapshot();                                           // get the differences image
          if (cameras[i].motion() >= cDetections) {        
            // motion detected
              message.add(cameras[i].cameraName + ": " + cameras[i].camMotionLevel + " at " + currentTime(":") );
              if (soundEnabled) {
                  movementSound.rewind();
                  movementSound.play();    
              }              
              if (saveImages) cameras[i].image.save( "images/" + currentTime("-") + "_" + cameras[i].cameraName + ".jpg");         // save current image to disk
          }
          // display compare image on screen
            cameras[i].grayDiff.resize(cameras[i].changeWidth, cameras[i].changeHeight);          // resize differences image for display
            image(cameras[i].grayDiff, cameras[i].changeX, cameras[i].changeY);                   // show differences image on screen
          // display image title
            fill(0, 0, 255);  textSize(sTextSize);
            text(cameras[i].cameraName + ": " + cameras[i].camMotionLevel, cameras[i].imageX + (cameras[i].imageWidth/2) - ((cameras[i].cameraName.length()/2)*8), cameras[i].imageY + cameras[i].imageHeight + 18 );
      }
    }   //for
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
        cameras[i].image.save( "images/" + currentTime("-") + "_" + cameras[i].cameraName + "-2.jpg");         // save current image to disk
      }
      if (soundEnabled) {
          faceSound.rewind();
          faceSound.play();    
      }    
    }      
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
      // cycle consecutive detections
      if (key == 'n' || key == 'N') {
        cDetections++;
        if (cDetections > 4) cDetections = 1;
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
         
      imageOld = image;             // replace the old image with the current one  
      
      // load image from camera and check it is ok
        int iError = 0;
        try {  
          image = loadImage(iloc);    // load the image
        } catch (Exception e) {
          iError = 1;
        }
        try {                         // test if image loaded ok
          if (image.width < 1) { iError = 2; }
        } catch (Exception e) {
          iError = 2;
        }
        if (iError != 0) {
          camError(iError);          
          return false;       
        }
      
      if (image.width != imageWidth || image.height != imageHeight) image.resize(imageWidth, imageHeight);   // resize if required
      return true;
  }   // update
  
  
  void camError(int ecode) {        // error with camera image
        message.add( cameraName + ": error(" + ecode + ") at " + currentTime(":") );  
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
        if (grayDiff.width < 1) { iError = 8; }
      } catch (Exception e) { iError = 7; }        
      if (iError != 0) {    // problem with one of the images so abort
        camError(iError); 
        return 0;     
      }

    grayDiff.loadPixels();
    
    // get a single trigger level value from the whole image
      int dimension = grayDiff.width * grayDiff.height;
      camMotionLevel = 0;                        // reset changed pixel counter
      for (int i = 0; i < dimension; i++) { 
        int pix = grayDiff.pixels[i];
        float pixVal = (red(pix)+green(pix)+blue(pix)) / 3;     // average brightness of this pixel
        if (pixVal > motionPixeltrigger) {
          camMotionLevel++;                      // increment changed pixel counter
        }
      }
      // weight the result to compensate for the mask reducing effective image resolution (so all camera results are comparable)
        float ratioOfFullImage = 1.0;
        if (roiW * roiH != 0) ratioOfFullImage = (image.width * image.height) / (roiW * roiH);
        camMotionLevel = int(camMotionLevel * ratioOfFullImage);    
      if (camMotionLevel >= motionImageTriggerMin && camMotionLevel <= motionImageTriggerMax) {
        cDetect++;                               // increment consecutive detection counter
        return cDetect;                          // motion detected
      }
      cDetect = 0;                               // reset consecutive detection counter
      return 0;        
  }   // motion
  
}  // camera object

// ------------------------------------- E N D --------------------------------------  
