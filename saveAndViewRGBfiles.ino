/*

                esp32cam sketch to capture an RGB585 image and save to sd card - 18oct23

the resulting image can be viewed by using:  https://rawpixels.net/
                                  setting:        Predefined format: RGB565
                                                  set image resolution (240x240 in this case)
                                                  remove the tick on Litle Endian

                                  You can then right click on the image and select download to save it
                                  
                                  
Notes: RGB888 does not seem to work, it just causes the esp32cam to restart
       I have tried capturing an XGA image (1024x768) which works but takes a long time - the resulting image is 1.5mb


*/

#include "esp_camera.h"
#include <Arduino.h>

// sd-card
 #include "SD_MMC.h"                         // sd card - see https://randomnerdtutorials.com/esp32-cam-take-photo-save-microsd-card/
 #include <SPI.h>
 #include <FS.h>                             // gives file access
 #define SD_CS 5                             // sd chip select pin = 5


#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27

#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

void setup() {
  Serial.begin(115200);
  Serial.println("\n\n\n\n\Starting...");
  
  // Initialize the camera
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.frame_size = FRAMESIZE_240X240;
          //               160x120 (QQVGA), 128x160 (QQVGA2), 176x144 (QCIF), 240x176 (HQVGA), 240X240,
          //               320x240 (QVGA), 400x296 (CIF), 640x480 (VGA, default), 800x600 (SVGA),
          //               1024x768 (XGA), 1280x1024 (SXGA), 1600x1200 (UXGA)  
  config.pixel_format = PIXFORMAT_RGB565; 
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 12;
  config.fb_count = 1;

  // Initialize the camera
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    while (1==1);
  }

  // Check if the card is present and can be initialized:
  if (!SD_MMC.begin("/sdcard", false)) {
    Serial.println("Card failed, or not present");
    while (1==1);
  }
}

void loop() {
  // Capture an image
  camera_fb_t * fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    while (1==1);
  }

  // Open a file in write mode
  File file = SD_MMC.open("/image.rgb", FILE_WRITE);
  if(!file){
    Serial.println("Failed to open file for writing");
    while (1==1);
  }

  // Write the image data to the file
  size_t imgSize = fb->len;
  file.write(fb->buf, imgSize);

  // Close the file
  file.close();

  // Return the frame buffer back to the camera for reuse
  esp_camera_fb_return(fb);

  Serial.println("Image saved");
  while (1==1);
}
