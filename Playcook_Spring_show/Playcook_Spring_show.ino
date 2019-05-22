/* Mobile Lab class final project

  Playcook a wearable cooking assistant

  By Atharva Patil & Anna Oh - May 2019

  Hardware used Arduino mkr 1010

*/
#include <SPI.h>
// Using the ArduinoBLE library for Bluetooth communication by advertising Arduino as a discoverable peripheral
#include <ArduinoBLE.h>
// Using Capacitive sensing library to check for touches against the fabric
#include <CapacitiveSensor.h>
#include <Scheduler.h>

CapacitiveSensor   playPausePin = CapacitiveSensor(2, 5);     //  resistor between pins 2 & 4. To check for interaction for play/pause
CapacitiveSensor   backwardScrubPin = CapacitiveSensor(2, 4); // 10M resistor between pins 2 & 5. To check for interaction for 10 sec backward scrub

const int videoScrubPin = A3;   // to scrub the video based on the chain position on the apron
const int audioScrubPin = A4;   // to control the audio of the iOS device.

// mapped potentiometer value need to change by +/- this amount to be considered a change
const int POT_THRESHOLD = 15;

const int ON = 1;
const int OFF = 0;

// code had 50,000 - changing to 20,000 since I only have 1M resistors
const int CAP_TOUCH_THRESHOLD = 20000;

// Creating a service which will act as the accessory advertiser & the primary service
BLEService apronService("4cc4513b-1b63-4c93-a419-dddaeae3fdc7");

// Creating Digital characteristics to allow remote device to get notifications

BLEByteCharacteristic playPauseCharacteristic("ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4", BLERead | BLENotify);
BLEDescriptor playPauseDescriptor("2901", "Play / Pause");
BLEByteCharacteristic backwardCharacteristic("9400449a-cf66-4652-976a-7e162c785a66", BLERead | BLENotify);
BLEDescriptor backwardDescriptor("2901", "Backward");

// Creating Analog characteristics to allow remote device to get notifications

BLEByteCharacteristic videoScrubCharacteristic("6635d693-9ad2-408e-ad48-4d8f88810dee", BLERead | BLENotify);
BLEDescriptor videoScrubDescriptor("2901", "Video Scrub");
BLEByteCharacteristic audioScrubCharacteristic("099af204-5811-4a15-8ffb-4f127ffdfcd7", BLERead | BLENotify);
BLEDescriptor audioScrubDescriptor("2901", "Volume");

void setup() {

  Serial.begin(9600);
//  while (!Serial);

  playPausePin.set_CS_AutocaL_Millis(0xFFFFFFFF);     // turn off autocalibrate on channel 1 - just as an example
  backwardScrubPin.set_CS_AutocaL_Millis(0xFFFFFFFF);     // turn off autocalibrate on channel 1 - just as an example

  pinMode(videoScrubPin, INPUT); // use the slide potentiometer as a input
  pinMode(audioScrubPin, INPUT); // use the slide potentiometer as a input

  // begin initialization
  if (!BLE.begin()) {
    Serial.println("starting BLE failed!");
    //    while (1);
  }

  // set the local name peripheral advertises
  BLE.setLocalName("Playcook");

  // set the UUID for the service this peripheral advertises:
  BLE.setAdvertisedService(apronService);

  // add the characteristics to the service
  apronService.addCharacteristic(playPauseCharacteristic);
  playPauseCharacteristic.addDescriptor(playPauseDescriptor);
  apronService.addCharacteristic(backwardCharacteristic);
  backwardCharacteristic.addDescriptor(backwardDescriptor);

  apronService.addCharacteristic(videoScrubCharacteristic);
  videoScrubCharacteristic.addDescriptor(videoScrubDescriptor);
  apronService.addCharacteristic(audioScrubCharacteristic);
  audioScrubCharacteristic.addDescriptor(audioScrubDescriptor);

  // add the service
  BLE.addService(apronService);

  playPauseCharacteristic.writeValue(0);
  backwardCharacteristic.writeValue(0);

  videoScrubCharacteristic.writeValue(100);
  audioScrubCharacteristic.writeValue(100);

  // start advertising
  BLE.advertise();

  Serial.println("Bluetooth device active, waiting for connections...");
}

void loop() {
  // poll for BLE events
  BLE.poll();

  long start = millis();

  long total1 =  playPausePin.capacitiveSensor(80);
  long total2 =  backwardScrubPin.capacitiveSensor(80);

  int videoScrubValue = analogRead(videoScrubPin);
  int audioScrubValue = analogRead(audioScrubPin);

  int videoScrubState = map(videoScrubValue, 0, 1023, 0, 100);
  int audioControlState = map(audioScrubValue, 0, 1023, 0, 100);

  
  
    // only send the values when they change
  if (total1 >= CAP_TOUCH_THRESHOLD && playPauseCharacteristic.value() == OFF) {
    Serial.println("Play Pause ON");
    playPauseCharacteristic.writeValue(ON);
    delay(300);
  } else if (total1 >= CAP_TOUCH_THRESHOLD && playPauseCharacteristic.value() == ON) {
    Serial.println("Play Pause OFF");
    playPauseCharacteristic.writeValue(OFF);
    delay(300);
  }



  if (total2 >= CAP_TOUCH_THRESHOLD && backwardCharacteristic.value() == OFF) {
    Serial.println("Backward ON");
    backwardCharacteristic.writeValue(ON);
  } else if (total2 < CAP_TOUCH_THRESHOLD && backwardCharacteristic.value() == ON) {
    Serial.println("Backward OFF");
    backwardCharacteristic.writeValue(OFF);
  }

  if (videoScrubValueChanged(videoScrubState)) {
//      Serial.print("Video Scrub ");
//      Serial.println(videoScrubState);
      videoScrubCharacteristic.writeValue(videoScrubState);
  }

  if (audioScrubValueChanged(audioControlState)) {
      Serial.print("Audio Control State ");
      Serial.println(audioControlState);
      audioScrubCharacteristic.writeValue(audioControlState);
  }

}

// my potentiometer readings jump around a bit this ensures they move a certian amount
// before sending a new value. Adust POT_THRESHOLD to change sensitivity.
boolean audioScrubValueChanged(int audioScrub) {
  return (
    (audioScrub < (audioScrubCharacteristic.value() - POT_THRESHOLD)) ||
    (audioScrub > (audioScrubCharacteristic.value() + POT_THRESHOLD))
   );
}

boolean videoScrubValueChanged(int videoScrub) {
  return (
    (videoScrub < (videoScrubCharacteristic.value() - POT_THRESHOLD)) ||
    (videoScrub > (videoScrubCharacteristic.value() + POT_THRESHOLD))
  );
}
