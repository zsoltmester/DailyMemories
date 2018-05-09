//
//  ViewController.swift
//  DailyMemories
//
//  Created by Meghan Kane on 9/3/17.
//  Copyright © 2017 Meghan Kane. All rights reserved.
//

import UIKit
import Vision
import CoreML

class ViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var captionLabel: UILabel!
    let imagePickerController = UIImagePickerController()
    let formatter = DateFormatter()
    
    var currentDateString: String {
        let now = Date()
        return formatter.string(from:now)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 10
        imagePickerController.delegate = self
        
        formatter.dateFormat = "MMM dd, YYYY"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        dateLabel.text = currentDateString
    }
    
    
    @IBAction func takePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            imagePickerController.cameraDevice = .front
        }
        
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // 👀🤖 VISION + CORE ML WORK STARTS HERE
    private func classifyScene(from image: UIImage) {
        
        // 1. Create Vision Core ML model

        let model = FlowerClassifier()
        guard let visionCoreMLModel = try? VNCoreMLModel(for: model.model) else { return }
        
        // 2. Create Vision Core ML request

        let request = VNCoreMLRequest(model: visionCoreMLModel, completionHandler: handleClassificationResults)

        // 3. Create request handler
        // *First convert image: UIImage to CGImage + get CGImagePropertyOrientation (helper method)*

        guard let cgImage = image.cgImage else { return }
        let cgImageOrientation = convertToCGImageOrientation(from: image)

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgImageOrientation)

        // 4. Perform request on handler
        // Ensure that it is done on an appropriate queue (not main queue)

        captionLabel.text = "Classifying scene..."
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                return
            }
        }
    }
    
    // 5. Do something with the results
    // - Update the caption label
    // - Ensure that it is dispatched on the main queue, because we are updating the UI
    private func handleClassificationResults(for request: VNRequest, error: Error?) {
        
        DispatchQueue.main.async {
            guard let classifications = request.results as? [VNClassificationObservation], classifications.isEmpty != true else {
                self.captionLabel.text = "Unable to classify facial expression.\n\(error!.localizedDescription)"
                return
            }
            self.updateCaptionLabel(classifications)
        }
    }
    
    // MARK: Helper methods
    
    private func updateCaptionLabel(_ classifications: [VNClassificationObservation]) {
        let topTwoClassifications = classifications.prefix(2)
        let descriptions = topTwoClassifications.map { classification in
            return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
        }
        self.captionLabel.text = "Classification:\n" + descriptions.joined(separator: "\n")
    }
    
    private func convertToCGImageOrientation(from uiImage: UIImage) -> CGImagePropertyOrientation {
        let cgImageOrientation = CGImagePropertyOrientation(rawValue: UInt32(uiImage.imageOrientation.rawValue))!
        return cgImageOrientation
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let imageSelected = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.imageView.image = imageSelected
            
            // Kick off Vision + Core ML task with image as input 🚀
            classifyScene(from: imageSelected)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
