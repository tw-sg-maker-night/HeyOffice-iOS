//
//  FaceCaptureViewController.swift
//  HeyOffice
//
//  Created by Cheng Yao on 3/6/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AVFoundation
import AWSS3
import PKHUD

class FaceCaptureViewController: UIViewController {
    
    @IBOutlet weak var cameraPreview: UIView!
    @IBOutlet weak var captureImage: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var activeInput: AVCaptureDeviceInput!
    let imageOutput = AVCapturePhotoOutput()
    let metadataOutput = AVCaptureMetadataOutput()
    let videoQueue = DispatchQueue.global()
    
    var sessionQueue: DispatchQueue = DispatchQueue(label: "com.tw.heyoffice.session_access_queue", attributes: [])
    var faceViews = [UIView]()
    var faceDetected = false {
        didSet {
            captureButton.isEnabled = faceDetected
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !UIImagePickerController.isCameraDeviceAvailable(.front) {
            print("No camera available")
            return
        }
        
        setupSession()
        setupPreview()
        startSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let layer = previewLayer {
            layer.frame = cameraPreview.bounds
        }
    }
    
    func setupSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
            mediaType: AVMediaType.video,
            position: AVCaptureDevice.Position.front
        )
        
        guard let camera = deviceDiscoverySession.devices.first else {
            print("No front camera available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch let error {
            print("Error setting device input: \(error)")
        }
        
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        }
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
        }
        if (metadataOutput.availableMetadataObjectTypes as [NSString]).contains(AVMetadataObject.ObjectType.face as NSString) {
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.face]
        }
    }
    
    func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreview.layer.addSublayer(previewLayer)
    }
    
    func startSession() {
        if !captureSession.isRunning {
            videoQueue.async {
                self.captureSession.startRunning()
            }
        }
        cameraPreview.isHidden = false
        captureButton.isHidden = false
    }
    
    func stopSession() {
        if captureSession.isRunning {
            videoQueue.async {
                self.captureSession.stopRunning()
            }
        }
        cameraPreview.isHidden = true
        captureButton.isHidden = true
    }
    
    @IBAction func captureButtonTapped(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
        ]
        settings.previewPhotoFormat = previewFormat
        imageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func uploadPhoto(photo: UIImage) {
        HUD.show(.progress)
        
        let fileName = UUID().uuidString
        let fileExt = "jpeg"
        
        guard let data = UIImageJPEGRepresentation(photo, 0.8) else {
            return
        }
        let expression = AWSS3TransferUtilityUploadExpression()
        let progressBlock: AWSS3TransferUtilityProgressBlock = { (task: AWSS3TransferUtilityTask, progress: Progress) in
            DispatchQueue.main.async(execute: {
                // update progress bar
            })
        }
        expression.progressBlock = progressBlock
        
        let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = { (task, error) -> Void in
            if let err = error {
                print("upload error: \(err)")
            }
            DispatchQueue.main.async {
                HUD.flash(.success, delay: 0.5)
            }
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.uploadData(
            data,
            bucket: AWSS3BucketName,
            key: "\(fileName).\(fileExt)",
            contentType: "image/\(fileExt)",
            expression: expression,
            completionHandler: completionHandler
        ).continueWith { task -> Any? in
            if let error = task.error {
                print("error: \(error)")
            }
            if task.result != nil {
            }
            return nil
        }

    }
}

extension FaceCaptureViewController: AVCapturePhotoCaptureDelegate {
    
    //swiftlint:disable:next function_parameter_count
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        
        if let error = error {
            print("error occure : \(error.localizedDescription)")
        }
        
        if let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
                forJPEGSampleBuffer: sampleBuffer,
                previewPhotoSampleBuffer: previewBuffer) {
            print(UIImage(data: dataImage)?.size as Any)
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(
                jpegDataProviderSource: dataProvider!,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            DispatchQueue.main.async {
                self.captureImage.image = image
            }
            uploadPhoto(photo: image)
            stopSession()
        } else {
            print("some error here")
        }
    }
}

extension FaceCaptureViewController: AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        var faces = [(id: Int, frame: CGRect)]()
        for metadataObject in metadataObjects as! [AVMetadataObject] where metadataObject.type == AVMetadataObject.ObjectType.face {
            if let faceObject = metadataObject as? AVMetadataFaceObject {
                if let transformedMetadataObject = previewLayer.transformedMetadataObject(for: metadataObject) {
                    let face:(id: Int, frame: CGRect) = (faceObject.faceID, transformedMetadataObject.bounds)
                    faces.append(face)
                }
            }
        }
        faceDetected = faces.count > 0
        
        DispatchQueue.main.async {
            self.drawFaceBoxes(faces: faces)
        }
    }
    
    func drawFaceBoxes(faces: [(id: Int, frame: CGRect)]) {
        let diff = faces.count - faceViews.count
        if diff > 0 {
            for _ in 0..<diff {
                let faceView = UIView(frame: CGRect.zero)
                faceView.backgroundColor = UIColor.clear
                faceView.layer.borderColor = UIColor.yellow.cgColor
                faceView.layer.borderWidth = 3.0
                
                faceViews.append(faceView)
                cameraPreview.addSubview(faceView)
            }
        } else {
            for _ in 0..<abs(diff) {
                faceViews[0].removeFromSuperview()
                faceViews.remove(at: 0)
            }
        }
        
        for (idx, face) in faces.enumerated() {
            faceViews[idx].frame = face.frame
        }
    }
}
