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
        let points = Array<LPPixel>(pixels)
        let clusters = kMeans(points: points, k: 2, seed: 0)
        
        var newPoints = points
        let size = img.height * img.width
        
//        for i in 0..<size {
//            newPoints[i].red = clusters
//        }
//        for
//        for(i=0; i<size; i++){
//            int idx = clusters->data.i[i];
//            dst_img->imageData[i*3+0] = (char)centers->data.fl[idx*3+0];
//            dst_img->imageData[i*3+1] = (char)centers->data.fl[idx*3+1];
//            dst_img->imageData[i*3+2] = (char)centers->data.fl[idx*3+2];
//        }
        return img.toUIImage()
    }
}
