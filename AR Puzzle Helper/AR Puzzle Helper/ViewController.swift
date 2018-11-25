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

    var puzzlePreviewNode: SCNNode?
    var puzzleImage: UIImage?
    var puzzleSize: CGSize?

    @IBAction func scanBoxTapped(_ sender: Any) {
        let image = sceneView.snapshot()
        let finalImage = cropToRectangle(image)
        puzzleImage = finalImage
        getPuzzleSize()
    }

    @IBAction func tapHappened(tap: UITapGestureRecognizer) {
        let location = tap.location(ofTouch: 0, in: sceneView)
        let hit = sceneView.hitTest(location, types: [.existingPlaneUsingGeometry])
        // if the node exists, rotate it. Otherwise add an anchor so the node will be added.
        if let node = puzzlePreviewNode?.childNodes.first {
            node.eulerAngles.y += 0.1
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
        let hitNode = anchorHit.node
        hitNode.worldPosition = anchorHit.worldCoordinates
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

    func cropToRectangle(_ image: UIImage) -> UIImage {
        let context = CIContext()
        let detectorOptions = [CIDetectorAccuracy: CIDetectorAccuracyHigh] as [String: Any]
        guard let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: context, options: detectorOptions)
            else {
                print("detector could not be created. Returning original image")
                return image
            }
        guard let ciImage = CIImage(image: image)
            else {
                print("CIImage could not be created from UIImage. Returning original image")
                return image
            }
        guard let feature = detector.features(in: ciImage).first as? CIRectangleFeature
        else {
            print("detector did not find features. Returning original image.")
            return image
        }
        let perspectiveCornerParameters = [
            "inputTopLeft": CIVector(cgPoint: feature.topLeft),
            "inputTopRight": CIVector(cgPoint: feature.topRight),
            "inputBottomLeft": CIVector(cgPoint: feature.bottomLeft),
            "inputBottomRight": CIVector(cgPoint: feature.bottomRight)
        ]
        guard let newImage = CIImage(image: image)?.applyingFilter("CIPerspectiveCorrection",
                                                                   parameters: perspectiveCornerParameters)
            else {
                print("new image could not be creted from old image with perspective filter. Returning original image.")
                return image
            }
        return getUiImage(from: newImage)
    }

    func getUiImage(from image: CIImage) -> UIImage {
        let context: CIContext = CIContext.init(options: nil)
        if let cgImage: CGImage = context.createCGImage(image, from: image.extent) {
            return UIImage.init(cgImage: cgImage)
        } else {
            print("could not create UIImage from CGImage. returning a simple UIImage that probably won't work")
            return UIImage(ciImage: image)
        }
    }

    func getPuzzleSize() {
        let enterSizeMessage = "Please insert the dimensions of the puzzle. This can usually be found on the box"
        let sizeController = UIAlertController(title: "Puzzle Size",
                                               message: enterSizeMessage, preferredStyle: .alert)
        sizeController.addTextField { (field) in
            field.placeholder = "width (cm)"
            field.keyboardType = UIKeyboardType.decimalPad
        }
        sizeController.addTextField { (field) in
            field.placeholder = "height (cm)"
            field.keyboardType = UIKeyboardType.decimalPad
        }

        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in
            guard let fields = sizeController.textFields else { return }
            // If the user enters an invalid number, just default to 1.0
            let width = Double(fields[0].text ?? "") ?? 1.0
            let height = Double(fields[1].text ?? "") ?? 1.0
            self.puzzleSize = CGSize(width: width / 100.0, height: height / 100.0)
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel) { (_) in  }
        sizeController.addAction(confirmAction)
        sizeController.addAction(cancelAction)
        self.present(sizeController, animated: true, completion: nil)
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if anchor.name == "puzzleHelp" {
            let material = SCNMaterial()
            guard let image = puzzleImage, let size = puzzleSize else {return nil}
            let plane = SCNPlane(width: size.width, height: size.height)
            material.diffuse.contents = image

            material.isDoubleSided = true
            plane.firstMaterial = material

            let parentNode = SCNNode(geometry: nil)
            let planeNode = SCNNode(geometry: plane)
            planeNode.transform = SCNMatrix4MakeRotation(Float(-Double.pi / 2.0), 1.0, 0.0, 0.0)
            planeNode.opacity = 0.5

            parentNode.addChildNode(planeNode)
            puzzlePreviewNode = parentNode
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
