/*
    
              Processing jpg image change monitor - 11Aug22
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
                                +/- = Adjust trigger level
                            numbers = enable/disable cameras
  
    from: https://github.com/alanesq/misc/blob/main/cctv-camera-motion-detector-processing-sketch.pde
                                                                                  alanesq@disroot.org
*/

// ---------------------------------- S E T T I N G S -------------------------------  

  String sTitle = "CCTV Movement Detector";          // Sketch title
  int windowWidth = 970;                              // screen size
  int windowHeight = 460;
  boolean saveImages = false;                        // default save images when motion detected (true or false)
  boolean soundEnabled = true;                       // default enable sound 
  boolean faceDetectionEnabled = false;              // default enable face detection
  int refresh = 2000;                                // how often to refresh image
  int timeoutSetting = 10;                           // default timeout (in minutes), activated by pressing 't' on keyboard
  
  // motion detection
  int motionImageTrigger = 150;                      // default trigger level min (triggers if between min and max)
  int triggerStep = 25;                              // trigger level adjustment step size
  int motionPixeltrigger = 60;                       // trigger level for movement detection of pixels
  
  // display
  int border = 8;                                    // screen border
  int sTextSize = 14;                                // on screen text size
    
  // message area on screen
    int messageWidth = 200;
    int messageHeight = 410;
    int messageX = border;
    int messageY = border;
    int maxMessages = 18;
    
  // camera settings
    int noOfCams = 4;      // number of cameras available
    // Note: to add or remove a camera modify the "noOfCams" value above, add or remove a settings section for the camera below and 
    //       add or remove a line for the camera in "setup()"

    // used below to size and position the images on the screen
      int _mainTop = border;
      int _camTop = border + 5;
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
                 
    //  camera 3 settings
      String cam3name = "Back";                            // camera 3 name (must be suitable for use in file name)
      String cam3loc = "http://back.jpg";  // camera 3 url
      int[] cam3 = {
                  _imageWidth,                             // main image                            imageWidth
                  _imageHeight,                            //                                       imageHeight
                  _mainLeft + _imageSpacing*3,             //                                       imageX
                  _mainTop + _camTop,                      //                                       imageY
                  _changeWidth,                            // change image                          changeWidth
                  _changeHeight,                           //                                       changeHeight
                  _mainLeft + _changePad + _imageSpacing*3,//                                       changeX
                  _mainTop + _camTop + _imageHeight + 24,  //                                       changeY
                  0,                                       // Select part of image to use           roiX
                  0,                                       //                                       roiY
                  _imageWidth,                             //                                       roiW
                  _imageHeight                             //                                       roiH
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

void settings() {
  size(windowWidth, windowHeight);     // set window size
}

void setup() {
  surface.setTitle(sTitle);       // set window title
  // create camera objects
    cameras[0] = new camera(cam0, cam0loc, cam0name);      // create camera 0 object
    cameras[1] = new camera(cam1, cam1loc, cam1name);      // create camera 1 object
    cameras[2] = new camera(cam2, cam2loc, cam2name);      // create camera 2 object
    cameras[3] = new camera(cam3, cam3loc, cam3name);      // create camera 2 object
    cameras[3].enabled = false;   // disable camera 3
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
  surface.setResizable(true);        // make window resizable
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
    //text(sTitle, (width/2) - (sTitle.length() * 8), 40);     
  
  // draw the information box 
    strokeWeight(1);  fill(220, 220, 0);
    rect(messageX, messageY, messageWidth,messageHeight);
    textSize(sTextSize); fill(128, 128, 0); 
    if (message.size() > maxMessages) { message.remove(0); }                               // limit number of messages
    for (int i = 0; i < message.size(); i++) {
      text(message.get(i), messageX + border, messageY + border + (20 * i) + 7 );   
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
          String tText = "Images will be stored in '" + sketchPath("") + "images/'"; 
          text(tText, width - textWidth(tText) - border, height -8 - sTextSize);               
      } else { 
        tMes += ", Image saving disabled(D)"; 
      }  
    // send to screen
      fill(0, 0, 255);  textSize(sTextSize);
      text(tMes, border , height -5 );     // show total motion detected on screen
      
    // Motion detection settings
      tMes = "Triggers at: " + motionImageTrigger + "(+/-)"; 
      text(tMes, width - textWidth(tMes) - border, height -5);        
  
    // compare old and new camera images using OpenCV and display images
      for (int i = 0; i < cameras.length; i++) {                                            // step through all cameras
        if (!cameras[i].enabled) continue;                                                  // skip camera if not enabled
        if (!cameras[i].update()) continue;                                                 // refresh image (skip camera if there was an error)
        opencv = new OpenCV(this, cameras[i].image);                                        // load image in to OpenCV   
        image(opencv.getOutput(), cameras[i].imageX, cameras[i].imageY);                    // display image on screen 
        faceDetect(i);                                                                      // face detect 
        int mRes = motionDetect(i);                                                         // motion detect
        
        // display changes image
          if (mRes != -1) {                                                                     // -1 = problem with an image
            // display compare image on screen
              cameras[i].grayDiff.resize(cameras[i].changeWidth, cameras[i].changeHeight);      // resize differences image for display
              image(cameras[i].grayDiff, cameras[i].changeX, cameras[i].changeY);               // show differences image on screen
            // display image title
              fill(0, 0, 255);  textSize(sTextSize);
              if (cameras[i].currentDetectionLevel >= motionImageTrigger) fill(128, 0, 128);  // change colour if above trigger level
              tMes = cameras[i].cameraName + ": " + cameras[i].currentDetectionLevel + "/" + cameras[i].cumulativeDetectionLevel;
              text(tMes, (cameras[i].imageX + (cameras[i].imageWidth - textWidth(tMes)) / 2), cameras[i].imageY + cameras[i].imageHeight + 18);
          }   
      }   //for loop
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
// motion detect on image

int motionDetect(int i) {      
 
      int mRes = cameras[i].motion();           // perform motion detection
       if (mRes == 1) {                         // if motion detected
          message.add(cameras[i].cameraName + ": " + cameras[i].currentDetectionLevel + " at " + currentTime(":") );
          if (soundEnabled) {
              movementSound.rewind();
              movementSound.play();    
          }              
          if (saveImages) cameras[i].image.save( "images/" + currentTime("-") + "_" + cameras[i].cameraName + ".jpg");         // save current image to disk
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
        motionImageTrigger += triggerStep;
      }      
      if (key == '-') {
        if (motionImageTrigger > triggerStep) {
          motionImageTrigger -= triggerStep;
        }
      }         
      // toggle face detection
      if (key == 'f' || key == 'F') {
        faceDetectionEnabled = !faceDetectionEnabled;  
      }      
      // toggle cameras enabled/disabled
      if (key == '1') {
        cameras[0].enabled = !cameras[0].enabled;
        if (cameras[0].enabled) cameras[3].enabled = false;
      }
      if (key == '1') cameras[0].enabled = !cameras[0].enabled;
      if (key == '2') cameras[1].enabled = !cameras[1].enabled;
      if (key == '3') cameras[2].enabled = !cameras[2].enabled;
      if (key == '4') cameras[3].enabled = !cameras[3].enabled;

    }
}  

// ---------------------------------- Camera Objects --------------------------------  

class camera{

  boolean enabled;                                // if camera is enabled
  PImage image, imageOld, grayDiff;               // stores for images
  String iloc;                                    // URL of image to monitor 
  String cameraName;                              // name of the camera
  int currentDetectionLevel;                      // current detection level
  int cumulativeDetectionLevel;                   // cumulative detection level
  
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
      cumulativeDetectionLevel = 0;
      enabled = true;
  }   // camera
   
   
  boolean update() {                        // update image via url
  
    if (enabled == false) return false;   // skip camera if not enabled
         
    imageOld = image;                     // replace the old image with the current one  
    
    // load image from camera and check it is ok
      int iError = 0;
      try {  
        image = loadImage(iloc);          // load the image
      } catch (Exception e) {
        iError = 1;
      }
      try {                               // test if image loaded ok
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
  if (enabled == false) return 0;      // skip camera if not enabled

  // check old image is ok
  try {                         
    if (imageOld.width < 1) { return -1; }
  } catch (Exception e) { return -1; }

  // compare images
    opencv.diff(imageOld);                                                     // compare the two images
    opencv.setROI(roiX, roiY, roiW, roiH);    // mask the resulting differences image
    grayDiff = opencv.getSnapshot();                                           // get the differences image

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
      currentDetectionLevel = 0;                              d  // reset changed pixel counter
      for (int i = 0; i < dimension; i++) { 
        int pix = grayDiff.pixels[i];
        float pixVal = brightness(pix);     // average brightness of this pixel
        if (pixVal > motionPixeltrigger) {
          currentDetectionLevel++;                              // increment changed pixel counter
        }
      }
 //     // weight the result to compensate for the mask reducing effective image resolution (so all camera results are comparable)
 //       float ratioOfFullImage = 1.0;
 //       if (roiW * roiH != 0) ratioOfFullImage = (image.width * image.height) / (roiW * roiH);
 //       currentDetectionLevel = int(currentDetectionLevel * ratioOfFullImage);   
      // control trigger level 
        if (currentDetectionLevel > int(motionImageTrigger * 3)) currentDetectionLevel=motionImageTrigger;        // limit maximum 
        cumulativeDetectionLevel = int( (cumulativeDetectionLevel * 0.75) + (currentDetectionLevel * 0.25) );  // limit rate of change by mixing with previous levels
        //if (currentDetectionLevel == 0) cumulativeDetectionLevel = 0;                                          // if current level is zero clear previous readings
      if (cumulativeDetectionLevel >= motionImageTrigger) {
        cumulativeDetectionLevel = 0;                                                                          // reset previous trigger level
        return 1;  
      }
      return 0;        
  }   // motion
  
}  // camera object

// ------------------------------------- E N D -------------------------------------- }
