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
    var croppedPuzzleImage: UIImage?
    var puzzleSize: CGSize?

    var needPuzzleSize = false

    @IBAction func scanBoxTapped(_ sender: Any) {
        puzzleImage = sceneView.snapshot()
        self.performSegue(withIdentifier: "showImageCornerAdjustment", sender: nil)
    }

    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
        if let source = segue.source as? BoxAdjustViewController {
            needPuzzleSize = true // cannot show popup during transition, so mark it as needed later
            let skewBox = source.editedSkewBox!
            let perspectiveCornerParameters = [
                "inputTopLeft": CIVector(cgPoint: skewBox.topLeft),
                "inputTopRight": CIVector(cgPoint: skewBox.topRight),
                "inputBottomLeft": CIVector(cgPoint: skewBox.bottomLeft),
                "inputBottomRight": CIVector(cgPoint: skewBox.bottomRight)
            ]
            guard let croppedImage = CIImage(image: puzzleImage!)?.applyingFilter("CIPerspectiveCorrection",
                                                                       parameters: perspectiveCornerParameters)
                else {
                    print("""
                        new image could not be creted from old image with perspective filter.
                        Returning original image.
                    """)
                    croppedPuzzleImage = puzzleImage
                    return
                }
            croppedPuzzleImage = getUiImage(from: croppedImage)

        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dest = segue.destination as? BoxAdjustViewController,
            let puzzleImage = puzzleImage
            else { return }
        dest.image = puzzleImage
        var skewBox: SkewBox?

        if let rect = getRectangle(in: puzzleImage) {
            skewBox = rect
        } else {
            skewBox = SkewBox(topLeft: CGPoint(x: 0.0, y: 0.0),
                              topRight: CGPoint(x: puzzleImage.size.width, y: 0.0),
                              bottomLeft: CGPoint(x: 0.0, y: puzzleImage.size.height - 50),
                              bottomRight: CGPoint(x: puzzleImage.size.width, y: puzzleImage.size.height - 50))
        }
        dest.startingSkewBox = skewBox

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

        if needPuzzleSize {
            getPuzzleSize()
        }
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

    func getRectangle(in image: UIImage) -> SkewBox? {
        let context = CIContext()
        let detectorOptions = [CIDetectorAccuracy: CIDetectorAccuracyHigh] as [String: Any]
        guard let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: context, options: detectorOptions)
            else {
                print("detector could not be created. Returning original image")
                return nil
            }
        guard let ciImage = CIImage(image: image)
            else {
                print("CIImage could not be created from UIImage. Returning original image")
                return nil
            }
        guard let feature = detector.features(in: ciImage).first as? CIRectangleFeature
        else {
            print("detector did not find features. Returning original image.")
            return nil
        }
        UIGraphicsBeginImageContext(ciImage.extent.size)
        let currentContext = UIGraphicsGetCurrentContext()!
        let topLeft = currentContext.convertToUserSpace(feature.topLeft)
        let topRight = currentContext.convertToUserSpace(feature.topRight)
        let bottomLeft = currentContext.convertToUserSpace(feature.bottomLeft)
        let bottomRight = currentContext.convertToUserSpace(feature.bottomRight)
        UIGraphicsEndImageContext()
        return SkewBox(topLeft: CGPoint(x: topLeft.x, y: topLeft.y),
                       topRight: CGPoint(x: topRight.x, y: topRight.y),
                       bottomLeft: CGPoint(x: bottomLeft.x, y: bottomLeft.y),
                       bottomRight: CGPoint(x: bottomRight.x, y: bottomRight.y))
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
        print("getPuzzleSize")
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
        print("about to present")
        self.present(sizeController, animated: true, completion: nil)
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if anchor.name == "puzzleHelp" {
            let material = SCNMaterial()
            guard let image = croppedPuzzleImage, let size = puzzleSize else {print("no image or size"); return nil}
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
