//
//  ViewController.swift
//  AR Puzzle Helper
//
//  Created by Benjamin Kindle on 11/11/18.
//  Copyright © 2018 Benjamin Kindle. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var mappingStatusLabel: UILabel!

    var node: SCNNode?
    var puzzleImage: UIImage?
    var puzzleSize: CGSize?

    @IBAction func scanBoxTapped(_ sender: Any) {
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 0.77])
        let image = sceneView.snapshot()

        guard let feature = (detector!.features(in: CIImage(image: image)!).first as? CIRectangleFeature) else {print("fail"); return}
        let newImage = CIImage(image: image)?.applyingFilter("CIPerspectiveCorrection",
                                              parameters: [
                                                "inputTopLeft" : CIVector(cgPoint: feature.topLeft),
                                                "inputTopRight" : CIVector(cgPoint: feature.topRight),
                                                "inputBottomLeft" : CIVector(cgPoint: feature.bottomLeft),
                                                "inputBottomRight" : CIVector(cgPoint: feature.bottomRight),
                                                ])
        let contexty:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = contexty.createCGImage(newImage!, from: newImage!.extent)!
        let finalImage:UIImage = UIImage.init(cgImage: cgImage)

        puzzleImage = finalImage


        let sizeController = UIAlertController(title: "Puzzle Size", message: "Please insert the dimensions of the puzzle. This can usually be found on the box", preferredStyle: .alert)
        sizeController.addTextField { (field) in
            field.placeholder = "width (meters)"
            field.keyboardType = UIKeyboardType.decimalPad
        }
        sizeController.addTextField { (field) in
            field.placeholder = "height (meters)"
            field.keyboardType = UIKeyboardType.decimalPad
        }

        let confirmAction = UIAlertAction(title: "Okay", style: .default) { (action) in
            let width = Double(sizeController.textFields![0].text!)
            let height = Double(sizeController.textFields![1].text!)
            self.puzzleSize = CGSize(width: width!, height: height!)
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel) { (_) in  }
        sizeController.addAction(confirmAction)
        sizeController.addAction(cancelAction)
        self.present(sizeController, animated: true, completion: nil)
    }

    @IBAction func tapHappened(tap: UITapGestureRecognizer) {
        let location = tap.location(ofTouch: 0, in: sceneView)
        let hit = sceneView.hitTest(location, types: [.existingPlaneUsingGeometry])
        if let node = node {
            node.childNodes.first!.eulerAngles.y = node.childNodes.first!.eulerAngles.y + 0.1
        } else {
            if let hit = hit.first {
                let position = hit.worldTransform
                self.sceneView.session.add(anchor: ARAnchor(name: "puzzleHelp", transform: position))
            }
        }
    }
    @IBAction func panHappened(pan: UIPanGestureRecognizer) {
        let location = pan.location(in: sceneView)
        let hit = sceneView.hitTest(location, options: nil)
        guard let anchorHit = hit.first else { return }
        let node = anchorHit.node
        node.worldPosition = anchorHit.worldCoordinates


    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let status = session.currentFrame?.worldMappingStatus else { return }
        switch status {
        case .extending:
            mappingStatusLabel.text = "Extending"
        case .limited:
            mappingStatusLabel.text = "Limited"
        case .mapped:
            mappingStatusLabel.text = "Mapped"
        case .notAvailable:
            mappingStatusLabel.text = "Not Available"
        }
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if anchor.name == "puzzleHelp" {
            let material = SCNMaterial()
            guard let image = puzzleImage else {return nil}
            let plane = SCNPlane(width: puzzleSize!.width, height: puzzleSize!.height)
            material.diffuse.contents = image

            print("is image? \(material.diffuse.contents! is UIImage)" )
            material.isDoubleSided = true;
            plane.firstMaterial = material


            let parentNode = SCNNode(geometry: nil)
            let node = SCNNode(geometry: plane)
            print(node.worldOrientation, node.orientation)
            node.transform = SCNMatrix4MakeRotation(Float(-Double.pi / 2.0), 1.0, 0.0, 0.0);
            print(node.worldOrientation, node.orientation)
            node.opacity = 0.5

            parentNode.addChildNode(node)
            self.node = parentNode
            return parentNode
        } else {
            return nil
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
