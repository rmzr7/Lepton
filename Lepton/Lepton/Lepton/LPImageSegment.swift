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
    
    let kMeansThreshhold:Float = 0.002
    let k = 8
    
    open func kmeansSegment (_ image:UIImage) -> UIImage? {
        let img = LPImage(image:image)!
        let imageWidth = img.width
        let imageHeight = img.height
        let numPixels = imageWidth * imageHeight
        let points = Array<LPPixel>(img.pixels)
//        let (clusters, memberships) = kMeans(points: points, k: k, threshold: kMeansThreshhold)

        let (clusters, memberships) = kMeans(points: points, k: 6, threshold: 0)
        
        for i in 0..<numPixels {
            let membership = memberships[i]
            let centroid = clusters[membership].centroid
            let newR = centroid.red
            let newG = centroid.green
            let newB = centroid.blue
            var pixel = img.pixels[i]
            pixel.red = newR
            pixel.green = newG
            pixel.blue = newB
            img.pixels[i] = pixel
        }
    
        return img.toUIImage()
    }
}
