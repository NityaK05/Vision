//
//  Camera.swift
//  Vision
//
//  Created by Maggie Lam on 11/21/24.
//

import SwiftUI
import AVFoundation
import Photos

class Camera : NSObject, ObservableObject, AVCapturePhotoCaptureDelegate{
    
    @Published var isTaken: Bool = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer?
    @Published var isPreviewReady: Bool = false
    @Published var capturedPhoto: UIImage? = nil
    @Published var currentPosition: AVCaptureDevice.Position = .back
    @Published var request = URLRequest(url: URL(string: "https://api-inference.huggingface.co/models/Salesforce/blip-image-captioning-large")!,timeoutInterval: Double.infinity)
    @Published var caption = ""
    @Published var synthesizer = AVSpeechSynthesizer()

    
    func check() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setup()
            checkPhotoLibraryAccess()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                if success {
                    DispatchQueue.main.async {
                        self.setup()
                        self.checkPhotoLibraryAccess()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alert.toggle()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.alert.toggle()
            }
        @unknown default:
            DispatchQueue.main.async {
                self.alert.toggle()
            }
        }
    }
    
    func setup() {
        do {
            self.session.beginConfiguration()
            var device: AVCaptureDevice?
            
            device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
            
            let input = try AVCaptureDeviceInput(device: device!)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            } else {
                self.session.commitConfiguration()
                return
            }
            
            if self.session.canAddOutput(self.output){
                self.session.addOutput(self.output)
            } else {
                self.session.commitConfiguration()
                return
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.preview = AVCaptureVideoPreviewLayer(session: self.session)
                self.isPreviewReady = true
            }
            
            startSession()
        } catch{
            print("error setting up camera")
        }
        
        request.addValue("Bearer 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", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

    }

    func getCaption() -> String {
        let postData = capturedPhoto?.pngData()
        request.httpBody = postData
        var cap = ""
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            cap = String(data: data, encoding: .utf8)!
            let startIndex = (cap.range(of: ":")!.lowerBound)
            cap = String(cap.suffix(from: startIndex))
            cap = cap.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            print(cap)
            self.caption = cap
            
            let utterance = AVSpeechUtterance(string: self.caption)
            utterance.rate = 0.3
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_en-GB_compact")
            self.synthesizer.speak(utterance)
        }
        
        task.resume()
        return cap
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    func endSession() {
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }
    
    func takePic() {
        let settings = AVCapturePhotoSettings()
        
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: settings, delegate: self)
            
            DispatchQueue.main.async{
                withAnimation{
                    self.isTaken.toggle()
                }
            }
        }
    }
    
    func retakePic() {
        self.capturedPhoto = nil
        self.isTaken = false
        
        startSession()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let photoData = photo.fileDataRepresentation() {
            self.capturedPhoto = UIImage(data: photoData)
            caption = getCaption()
            print("captured photo")
        }
    }
    
    
    func checkPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                return
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { newStatus in
                    if newStatus != .authorized {
                        print("photo library acccessed denied")
                    }
                }
            case .denied, .restricted, .limited:
                print("denied")
            @unknown default:
                print("unknown")
            }
        }
        
    }
        
        
    }

