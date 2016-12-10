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
    
    let kMeansThreshhold:Float = 0.00001
    let k = 6
    
    open func kmeansSegment (_ image:UIImage) -> UIImage? {
        let img = LPImage(image:image)!
        let imageWidth = img.width
        let imageHeight = img.height
        let numPixels = imageWidth * imageHeight
        let points = Array<LPPixel>(img.pixels)
        //let (clusters, memberships) = kMeans(points: points, k: k, threshold: kMeansThreshhold)
        let (centroids, memberships) = kMeans(points: points, k: k, threshold: kMeansThreshhold)

        
        for i in 0..<numPixels {
            let membership = memberships[i]
            let centroid = centroids[membership]
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
    
    // TODO: finish this
    open func KMeansGPU(_ image:UIImage) -> UIImage? {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("no GPU, aborting");
            return nil;
        }
        let metalContext = LPMetalContext(device: device)
        let img = LPImage(image:image)!
        let imageTexture = metalContext.imageToMetalTexture(image:img)!
        
        
        
    }
}
