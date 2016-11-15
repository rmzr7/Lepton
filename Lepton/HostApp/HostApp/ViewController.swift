//
//  ViewController.swift
//  HostApp
//
//  Created by William Tong on 11/14/16.
//  Copyright © 2016 William Tong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImage(named: "rainbow")
        let imageView = UIImageView(image: image)
        view.addSubview(imageView)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

