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
    var skewBox: skewBox?
    var image: UIImage?
    weak var delegate: boxAdjustDelegate?
    override func viewDidLoad() {
        imageView.image = image
    }
}

protocol skewBox {
    init(topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint)
}

protocol boxAdjustDelegate: class {
    func finishedAdjusting(with newSkewBox: skewBox)
}
