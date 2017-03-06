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

class FaceCaptureViewController: UIViewController {
    
    @IBOutlet weak var cameraPreview: UIView!
    @IBOutlet weak var captureImage: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var uploadProgress: UIProgressView!
    
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var activeInput: AVCaptureDeviceInput!
    let imageOutput = AVCapturePhotoOutput()
    let metadataOutput = AVCaptureMetadataOutput()
    let videoQueue = DispatchQueue.global()
    
    var sessionQueue:DispatchQueue = DispatchQueue(label: "com.tw.heyoffice.session_access_queue", attributes: [])
    var faceViews = [UIView]()
    var faceDetected = false {
        didSet {
            captureButton.isEnabled = faceDetected
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSession()
        setupPreview()
        startSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraPreview.bounds
    }
    
    func setupSession() {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        guard let deviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.front),
            let camera = deviceDiscoverySession.devices.first else {
                print("No front camera available")
                return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch (let error) {
            print("Error setting device input: \(error)")
        }
        
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        }
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
        }
        if (metadataOutput.availableMetadataObjectTypes as! [NSString]).contains(AVMetadataObjectTypeFace as NSString) {
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        }
    }
    
    func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
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
        uploadProgress.isHidden = true
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
        
        uploadProgress.isHidden = false
        
        let fileName = UUID().uuidString
        let fileExt = "jpeg"
        
        guard let data = UIImageJPEGRepresentation(photo, 0.8) else {
            return
        }
        let expression = AWSS3TransferUtilityUploadExpression()
        let progressBlock: AWSS3TransferUtilityProgressBlock = { (task: AWSS3TransferUtilityTask, progress:Progress) in
            DispatchQueue.main.async(execute: {
                self.uploadProgress.progress = Float(progress.completedUnitCount/progress.totalUnitCount)
            })
        }
        expression.progressBlock = progressBlock
        
        let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = { (task, error) -> Void in
            if let err = error {
                print("upload error: \(err)")
            }
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.uploadData(data, bucket: AWSS3BucketName, key: "\(fileName).\(fileExt)", contentType: "image/\(fileExt)", expression: expression, completionHandler: completionHandler).continueWith { (task) -> Any? in
            if let error = task.error {
                print("error: \(error)")
            }
            if let _ = task.result {
                
            }
            return nil
        }

    }
}

extension FaceCaptureViewController: AVCapturePhotoCaptureDelegate {
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            print("error occure : \(error.localizedDescription)")
        }
        
        if let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            print(UIImage(data: dataImage)?.size as Any)
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            self.captureImage.image = image
            uploadPhoto(photo: image)
            stopSession()
        } else {
            print("some error here")
        }
    }
}

extension FaceCaptureViewController: AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        var faces = Array<(id:Int, frame: CGRect)>()
        for metadataObject in metadataObjects as! [AVMetadataObject] {
            if metadataObject.type == AVMetadataObjectTypeFace {
                if let faceObject = metadataObject as? AVMetadataFaceObject {
                    if let transformedMetadataObject = previewLayer.transformedMetadataObject(for: metadataObject) {
                        let face:(id: Int, frame: CGRect) = (faceObject.faceID, transformedMetadataObject.bounds)
                        faces.append(face)
                    }
                }
            }
        }
        faceDetected = faces.count > 0
        
        DispatchQueue.main.async {
            self.drawFaceBoxes(faces: faces)
        }
    }
    
    func drawFaceBoxes(faces:Array<(id:Int, frame: CGRect)>) {
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
        }
        else {
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
