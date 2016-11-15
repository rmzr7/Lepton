//
//  LPImageFilter.swift
//  Lepton
//
//  Created by Rameez Remsudeen on 11/14/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import UIKit
import Accelerate

class LPImageFilter: NSObject {
    override init() {
        super.init()
    }
    
    func loadImage(image:CGImageRef) -> vImage_Buffer {
//        let width = CGImageGetWidth(image)
//        let height = CGImageGetHeight(image)
        
        
    }
    
    
    var blurFilter = [
        [0.0, 0.2, 0.0],
        [0.2, 0.2, 0.2],
        [0.0, 0.2, 0.0]
    ]
    
    
}
