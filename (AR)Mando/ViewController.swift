//
//  ViewController.swift
//  (AR)Mando
//
//  Created by Carmine on 01/04/2019.
//  Copyright © 2019 PapaNoel. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    var centeredNode: SCNNode?
    @IBOutlet var sceneView: ARSCNView!
    var sceneController = MainScene()
    let currentMLModel = findGesture().model
    private let serialQueue = DispatchQueue(label: "com.aboveground.dispatchqueueml")
    private var visionRequests = [VNRequest]()
    private var timer = Timer()
    
    @objc private func loopCoreMLUpdate() {
        serialQueue.async {
            self.updateCoreML()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        if let scene = sceneController.scene {
            // Set the scene to the view
            sceneView.scene = scene
        }
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTapScreen))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(tapRecognizer)

        
    }
    
    @objc func didTapScreen(recognizer: UITapGestureRecognizer) {
        if let camera = sceneView.session.currentFrame?.camera {
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -5.0
            let transform = camera.transform * translation
            let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            sceneController.addSphere(parent: sceneView.scene.rootNode, position: position)
        }
    }
    
    private func setupCoreML() {
        guard let selectedModel = try? VNCoreMLModel(for: currentMLModel) else {
            fatalError("Could not load model.")
        }
        
        let classificationRequest = VNCoreMLRequest(model: selectedModel,
                                                    completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
    }
    
          func updateCoreML() {
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
            let pepp = VNImageRequestHandler(cvPixelBuffer: pixbuff!, options: [:])
        do {
            try pepp.perform(self.visionRequests)
        } catch {
            print(error)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        setupCoreML()
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.loopCoreMLUpdate), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Check all the nodes if they are inside our frustrum
        for node in sceneView.scene.rootNode.childNodes {
            guard let pointOfView = renderer.pointOfView else { return }
            let isVisible = renderer.isNode(node, insideFrustumOf: pointOfView)
            
            if isVisible, let sphere = node as? Sphere {
                // get the extents of the screen
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                
                // Define a length for determining if an object is within a certain distance from the center of the screen
                let buffer: CGFloat = 100
                
                // Define the rectangle that serves as the "center" area
                let topLeftPoint = CGPoint(x: screenWidth/2 - buffer, y: screenHeight/2 - buffer)
                let screenRect = CGRect(origin: topLeftPoint, size: CGSize(width: buffer * 2, height: buffer * 2))
                
                // Get the world position of the object in screen space, strip out the Z, and create a CGPoint
                let screenPos = renderer.projectPoint(sphere.worldPosition)
                let xyPos = CGPoint(x: CGFloat(screenPos.x), y: CGFloat(screenPos.y))
                
                // If this object is centered, then set it to the centeredNode var
                let isCentered = screenRect.contains(xyPos)
                if isCentered {
                    centeredNode = sphere
                }
            }
        }
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            return
        }
        
        let classifications = observations[0...2]
            .compactMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:" : %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        print("Classifications: \(classifications)")
        
        DispatchQueue.main.async {
            let topPrediction = classifications.components(separatedBy: "\n")[0]
            let topPredictionName = topPrediction.components(separatedBy: ":")[0].trimmingCharacters(in: .whitespaces)
            guard let topPredictionScore: Float = Float(topPrediction.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)) else { return }
            
            if (topPredictionScore > 0.5) {
                guard let nodeToOperateOn = (self.centeredNode ?? self.sceneView.scene.rootNode.childNode(withName: "Sphere", recursively: true)),
                    let sphere = nodeToOperateOn as? Sphere else {
                        return
                }
                
                if topPredictionName == "Abierta" {
                    sphere.animate()
                }
                
                if topPredictionName == "Cerrada" {
                    sphere.stopAnimating()
                }
            }
            
        }
    }
    
}

