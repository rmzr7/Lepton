//
//  ViewController.swift
//  HostApp
//
//  Created by William Tong on 11/14/16.
//  Copyright © 2016 William Tong. All rights reserved.
//

import UIKit
import Lepton

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImage(named: "rainbow")
        
        var lepton = LPImageFilter()
        var x = lepton.blurImage(image!)!
        let imageView = UIImageView(image: x)
        imageView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        view.addSubview(imageView)
        let newImageView = UIImageView(image: image)
        newImageView.frame = CGRect(x: 0, y: 310, width: 300, height: 300)
        view.addSubview(newImageView)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

