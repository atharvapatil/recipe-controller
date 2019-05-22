//
//  ViewController.swift
//  0520_VideoPlayer
//
//  Created by Anna Oh on 19/5/2019.
//  Copyright © 2019 Anna Oh. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import CoreBluetooth
import Foundation

// UUID to identify the arduino device which in this case is the same as the service
//let SERVICE_LED_UUID = "4cc4513b-1b63-4c93-a419-dddaeae3fdc7"
let APRON_SERVICE_UUID = "4cc4513b-1b63-4c93-a419-dddaeae3fdc7"

// UUID's to identify the charecteristics of the sensors
//let LED_CHARACTERISTIC_UUID = "ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4"
//let BUTTON_CHARACTERISTIC_UUID = "db07a43f-07e3-4857-bccc-f01abfb8845c"

let PLAY_PAUSE_BUTTON_UUID = "ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4"
let REVERSE_BUTTON_UUID = "9400449a-cf66-4652-976a-7e162c785a66"
let VIDEO_SCRUB_UUID = "6635d693-9ad2-408e-ad48-4d8f88810dee"
let AUDIO_CONTROL_UUID = "099af204-5811-4a15-8ffb-4f127ffdfcd7"

var myAudioFloat: Float = 100

class ViewController: UIViewController {
   
    // DECLARING BLUETOOTH VARIABLES: BEGINS HERE
    
    // Initialising the Bluetooth manager object
    var centralManager: CBCentralManager?
    
    // Initialising Peripheral object which is responsible for discovering a nerby Accessory
    var arduinoPeripheral: CBPeripheral?
    
    // Variables to identify different sensors on the arduino as individual services which have chareteristics attached to them
    //    var ledService: CBService?
    var apronService: CBService?
    
    // Variables to communicate the state of a charecteristic to and from the arduino
    //    var charOne: CBCharacteristic?
    //    var charTwo: CBCharacteristic?
    
    var playPauseChar: CBCharacteristic?
    var reverseChar: CBCharacteristic?
    var videoScrubChar: CBCharacteristic?
    var audioControlChar: CBCharacteristic?
    
    // DECLARING BLUETOOTH VARIABLES: ENDS HERE
    
    //----------------------------------------------------
    
    // REFERENCING VIDEO PLAYER CONTROLS FROM STORYBOARD BEGINS HERE
    
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var videoView: UIView!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    
    var isVideoPlaying = false
    
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    
    @IBOutlet weak var playButt: UIButton!
    @IBOutlet weak var revButt: UIButton!
    
    @IBOutlet weak var bleState: UILabel!
    
    // REFERENCING VIDEO PLAYER CONTROLS FROM STORYBOARD ENDS HERE
    
    //----------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //volumeSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
        
        // Initiating bluetooth
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Text values at different states.
        // When the view loads the device starts connecting to Arduino
        bleState.text = "Searching for Apron"
        
        
        //Defining the video URL of the video to import
        let url = URL(string: "https://firebasestorage.googleapis.com/v0/b/sprinshow19.appspot.com/o/Binging%20with%20Babish%20Master%20of%20None%20Carbonara.mp4?alt=media&token=1ff742a1-7e7e-47f6-86b9-2bdfb9b3ba40")!
        
        // Referencing it to the video player
        player = AVPlayer(url: url)
        
        //Slider setting///
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        addTimeObserver()
        playerLayer = AVPlayerLayer(player: player)
       /// lotated change layout
        playerLayer.videoGravity = .resize
        videoView.layer.addSublayer(playerLayer)
        
       
        player.volume = 1
        
    }
    
    
    override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()
          playerLayer.frame = videoView.bounds
        
        
//        player.pause()
        
    }
    
    
    
    func addTimeObserver(){
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        _=player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue, using: { [weak self]
            time in
            guard let currentItem = self?.player.currentItem else {return}
            self?.timeSlider.maximumValue = Float(currentItem.duration.seconds)
            self?.timeSlider.minimumValue = 0
            self?.timeSlider.value = Float(currentItem.currentTime().seconds)
            self?.currentTimeLabel.text = self?.getTimeString(from:currentItem.currentTime())
        })
    }
        
 
    @IBAction func playpressed(_ sender: UIButton) {
        
        if isVideoPlaying {
             player.pause()
            sender.setTitle("PLAY", for: .normal)
            revButt.setTitle("<<", for: .normal)
        } else  {
            player.play ()
            sender.setTitle("PAUSE", for: .normal)
            revButt.setTitle("<<", for: .normal)
        }
          isVideoPlaying =  !isVideoPlaying
    }
    
    
    @IBAction func rewindepressed(_ sender: Any) {
        
        revButt.setTitle("<<", for: .normal)
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - 5.0
        
        if newTime < 0 {
           newTime = 0
        }
        let time: CMTime = CMTimeMake(value: Int64(newTime*1000), timescale: 1000)
        player.seek(to: time)
    }
    
    
 
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        player.seek(to: CMTimeMake(value: Int64(sender.value*1000),timescale: 1000))
    
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        if keyPath == "duration", let duration = player.currentItem?.duration.seconds, duration > 0.0 {
            self.durationLabel.text = getTimeString(from: player.currentItem!.duration)
            }
        }
    
    @IBAction func vloumeSliderValueChange(_sender:UISlider){
        player.volume = volumeSlider.value
        
        
    }
 
    func getTimeString(from time : CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int (totalSeconds/3600)
        let minutes = Int(totalSeconds/60)%60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours,minutes,seconds])
        } else {
            return String(format: "%02i:%02i", arguments: [minutes,seconds])
        }
        
    }
}

extension ViewController: CBCentralManagerDelegate{
    
    // Scanning for a Peripherial with a Unique accessory UUID. This id the arduino UUID
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            
            // The commented statement below searches for all discoverable peripherals, turn on for testing
            // central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            
            // Scanning for a specific UUID peripheral
            central.scanForPeripherals(withServices: [CBUUID(string: APRON_SERVICE_UUID)], options: nil)
            
            // Logging to see of Bluetooth is scanning for the defined UUID peripheral
            print("Scanning for peripheral with UUID: ", APRON_SERVICE_UUID)
            
        }
    }
    
    // This function handles the cases when the Bluetooth device we are looking for is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // If the peripheral is discovered log the details
        print("Discovered peripheral", peripheral)
        
        // Reference it
        arduinoPeripheral = peripheral
        
        // Connect to the Arduino peripheral
        centralManager?.connect(arduinoPeripheral!, options: nil)
        
        // print out the connection attempt
        print("Connecting to: ", arduinoPeripheral!)
        
    }
    
    // This function hadles the cases when the connection is successful
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        // Check if we are connected to the same peripheral
        guard let peripheral = arduinoPeripheral else {
            return
        }
        
        // Delegating
        peripheral.delegate = self
        
        // the connected peripheral's properties
        print("Connected to: ", arduinoPeripheral!)
        
        // Also the same feeback on the screen
        bleState.text = "Connecting to Apron"
        
        // Now that the device is connected start loooking for services attached to it.
        peripheral.discoverServices([CBUUID(string: APRON_SERVICE_UUID)])
        
        // Test statement to discover all the services attached to the peripheral
        // peripheral.discoverServices(nil)
        
    }
    
}


// Now that is the a periphral discovered and referenced to start looking for properties attached to it.
extension ViewController: CBPeripheralDelegate{
    
    // This function handles the cases when there are services discovered for the peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        
        // Logging the discovered services
        print("Discovered services:", peripheral.services!)
        
        // Feedback on screen
        bleState.text = "Apron connection successful"
        
        // iterating through the services to retrive the one we are looking for
        guard let LEDService = peripheral.services?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: APRON_SERVICE_UUID)
        }) else {
            return
        }
        
        // Referencing it
        apronService = LEDService
        
        // & Logging it's UUID to make sure it's the right one
        print("LED Service UUID", apronService!.uuid)
        
        // Now that the service is discovered and referenced to. Search for the charecteristics attached to it.
        peripheral.discoverCharacteristics([CBUUID(string: PLAY_PAUSE_BUTTON_UUID)], for: LEDService)
        peripheral.discoverCharacteristics([CBUUID(string: REVERSE_BUTTON_UUID)], for: LEDService)
        peripheral.discoverCharacteristics([CBUUID(string: VIDEO_SCRUB_UUID)], for: LEDService)
        peripheral.discoverCharacteristics([CBUUID(string: AUDIO_CONTROL_UUID)], for: LEDService)
        
    }
    
    // This function handles the cases when charecteristics are discovered(the ones we are looking for just above)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        // Log all the charecteristics for test
        // print("Charecteristics Discovered", service.characteristics!)
        
        // Look for a specific charecteristic
        guard let playPauseCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: PLAY_PAUSE_BUTTON_UUID)
        }) else {
            return
        }
        
        // If discovered, reference it
        playPauseChar = playPauseCharecteristic
        

        
        
        
        // Look for a specific charecteristic
        guard let reverseCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: REVERSE_BUTTON_UUID)
        }) else {
            return
        }
        
        // If discovered, reference it
        reverseChar = reverseCharecteristic
        
        // Log the properties of the charecteristic
        print("Reverse char info", reverseCharecteristic)
        
        
        
        
        // Look for a specific charecteristic
        guard let videoScrubCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: VIDEO_SCRUB_UUID)
        }) else {
            return
        }
        
        // If discovered, reference it
        videoScrubChar = videoScrubCharecteristic
        
        // Log the properties of the charecteristic
        print("Video Scrub char info ", videoScrubCharecteristic)
        
        
        
        
        // Look for a specific charecteristic
        guard let audioControlCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: AUDIO_CONTROL_UUID)
        }) else {
            return
        }
        
        // If discovered, reference it
        audioControlChar = audioControlCharecteristic
        
        // Log the properties of the charecteristic
        print("Audio control char info ", audioControlCharecteristic)
        
        
        // If the propter can send/notify (BLENotify on arduino) then we need to reference a listener for it
        // This is the listenter event for that
        peripheral.setNotifyValue(true, for: playPauseCharecteristic)
        peripheral.setNotifyValue(true, for: reverseCharecteristic)
        peripheral.setNotifyValue(true, for: videoScrubCharecteristic)
        peripheral.setNotifyValue(true, for: audioControlCharecteristic)
        
        
        // Now that the charectertistic is discovered it's time to press the button
//        bleState.text = "Player Volume: " + "\(player.volume)"
        
    }
    
    
    // This function handles the cases when the sensor is sending some data
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        // SB Notes:
        // Return if there's an error
        if let error = error {
            print("Error receiving characteristic value:", error.localizedDescription)
            return
        }
        
        // Look into received bytes
        //        let byteArray = [UInt8](updatedData)
        //        print("Received:", byteArray)
        //        print(byteArray, String(bytes: byteArray, encoding: .utf8)!)
        
        
        
        guard let playState = playPauseChar!.value else {
            return
        }
        
        var playPauseValue = playState.int8Value()
        
        print("Play Value:", playPauseValue)
        
        
        if playPauseValue == 0 {
            player.pause()
            
            playButt.setTitle("PLAY", for: .normal)
            revButt.setTitle("<<", for: .normal)
            
//            isVideoPlaying = false
//            bleState.text = "Video Paused"
            
//            sender.setTitle("PLAY", for: .normal)
            
//            let data = Data(bytes: &playPauseValue, count: MemoryLayout.size(ofValue: playPauseValue))
//            arduinoPeripheral?.writeValue(data, for: playPauseChar!, type: .withResponse)
            
            
        } else if playPauseValue == 1  {
            player.play()
            
            playButt.setTitle("PAUSE", for: .normal)
            revButt.setTitle("<<", for: .normal)
//            isVideoPlaying = true
            
//            bleState.text = "Video Playing"
            
      
        }
        
    
        guard let reverseState = reverseChar!.value else {
            return
        }
        
        let reverseValue = reverseState.int8Value()
        
        print("Reverse Value:", reverseValue)
        
        
        if reverseValue == 1{
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - 5.0
        
        if newTime < 0 {
            newTime = 0
        }
        let time: CMTime = CMTimeMake(value: Int64(newTime*1000), timescale: 1000)
        player.seek(to: time)
        
        revButt.setTitle("<<", for: .normal)
            
        } else if reverseValue == 0 {
            
            print("Video Reversed")
            
            revButt.setTitle("<<", for: .normal)
            
        }
        
        
//        guard let videoState = videoScrubChar!.value else {
//            return
//        }
//
//        let videoValue = videoState.int8Value()
//
//        print("Video Value:", videoValue)
        
//        videoCompleteText.text = "Volume level: " + "\(videoValue)"
        
        
        guard let audioState = audioControlChar!.value else {
            return
            
        }
        
        var audioValue = audioState.int8Value()
        
        print("Audio Value:", audioValue)
        
        myAudioFloat = Float(audioValue)
        
        player.volume = myAudioFloat/100
            
        bleState.text = "Volume : " + "\(audioValue)"
        
    }
    
}

// Functions to convert raw data to other formats
extension Data {
    func int8Value() -> Int8 {
        return Int8(bitPattern: self[0])
    }
    
    
}
