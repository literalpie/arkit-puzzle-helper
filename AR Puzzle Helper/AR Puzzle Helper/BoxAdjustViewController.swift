//
//  BoxAdjustViewController.swift
//  AR Puzzle Helper
//
//  Created by Benjamin Kindle on 11/18/18.
//  Copyright © 2018 Benjamin Kindle. All rights reserved.
//

import Foundation
import UIKit

class BoxAdjustViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var topLeftDragger: UIView!
    @IBOutlet weak var bottomLeftDragger: UIView!
    @IBOutlet weak var topRightDragger: UIView!
    @IBOutlet weak var bottomRightDragger: UIView!

    var startingSkewBox: SkewBox?
    var editedSkewBox: SkewBox?
    var image: UIImage?
    var draggingCorner: UIView?

    override func viewDidLoad() {
        imageView.image = image
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { }

    override func viewDidAppear(_ animated: Bool) {
        if let skewBox = startingSkewBox {
            topLeftDragger.center = skewBox.topLeft.imagePointToScreenPoint(in: view.frame)
            topRightDragger.center = skewBox.topRight.imagePointToScreenPoint(in: view.frame)
            bottomLeftDragger.center = skewBox.bottomLeft.imagePointToScreenPoint(in: view.frame)
            bottomRightDragger.center = skewBox.bottomRight.imagePointToScreenPoint(in: view.frame)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(touches.first!.location(in: imageView))
        let tlLocation = touches.first!.location(in: topLeftDragger)
        print(tlLocation)
        let touchLocation = touches.first!.location(in: view)
        draggingCorner = getTouchedCorner(touchedPoint: touchLocation)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: imageView)
        draggingCorner?.center = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if editedSkewBox == nil {
            editedSkewBox = startingSkewBox
        }
        switch draggingCorner {
        case topLeftDragger:
            editedSkewBox!.topLeft = topLeftDragger.center.screenPointToImagePoint(in: view.frame)
        case topRightDragger:
            editedSkewBox!.topRight = topRightDragger.center.screenPointToImagePoint(in: view.frame)
        case bottomLeftDragger:
            editedSkewBox!.bottomLeft = bottomLeftDragger.center.screenPointToImagePoint(in: view.frame)
        case bottomRightDragger:
            editedSkewBox!.bottomRight = bottomRightDragger.center.screenPointToImagePoint(in: view.frame)
        default:
            break
        }
        draggingCorner = nil
    }

    private func getTouchedCorner(touchedPoint: CGPoint) -> UIView? {
        if touchedPoint.hasMaxProximity(of: 50, to: topLeftDragger.center) {
            return topLeftDragger
        }
        if touchedPoint.hasMaxProximity(of: 50, to: topRightDragger.center) {
            return topRightDragger
        }
        if touchedPoint.hasMaxProximity(of: 50, to: bottomLeftDragger.center) {
            return bottomLeftDragger
        }
        if touchedPoint.hasMaxProximity(of: 50, to: bottomRightDragger.center) {
            return bottomRightDragger
        }
        return nil
    }
}

struct SkewBox {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint
}

extension CGPoint {
    func imagePointToScreenPoint(in screenFrame: CGRect) -> CGPoint {
        return CGPoint(x: self.x / 2, y: screenFrame.height - self.y / 2)
    }

    func screenPointToImagePoint(in screenFrame: CGRect) -> CGPoint {
        return CGPoint(x: self.x * 2.0,
                       y: 2 * (screenFrame.height - self.y))
    }

    func hasMaxProximity(of maxProximity: CGFloat, to targetPoint: CGPoint) -> Bool {
        return abs(self.x - targetPoint.x) < maxProximity &&
               abs(self.y - targetPoint.y) < maxProximity
    }
}
