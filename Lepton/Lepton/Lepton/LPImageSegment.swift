//
//  LPImageSegment.swift
//  Lepton
//
//  Created by William Tong on 11/30/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import UIKit
import Accelerate
import Metal

open class LPImageSegment: NSObject{
    public override init() {
        super.init()
    }
    
    open func kmeansSegment (_ image:UIImage) -> UIImage? {
        let img = LPImage(image:image)!
        let pixels = img.pixels
        
        
        return img.toUIImage()
    }
}
