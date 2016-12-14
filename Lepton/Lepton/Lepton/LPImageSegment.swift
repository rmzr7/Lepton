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
    
    
    open func kmeansSegment (_ image:UIImage, k:Int, threshold:Float) -> UIImage? {
        let img = LPImage(image:image)!
        let imageWidth = img.width
        let imageHeight = img.height
        let numPixels = imageWidth * imageHeight
        let points = Array<LPPixel>(img.pixels)
        //let (clusters, memberships) = kMeans(points: points, k: k, threshold: kMeansThreshhold)
        let (centroids, memberships) = kMeans(points: points, k: k, threshold: threshold)

        
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
    
    open func KMeansGPU(_ image:UIImage, k:Int, threshold: Float) -> UIImage? {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("no GPU, aborting");
            return nil;
        }
        let metalContext = LPMetalContext(device: device)
        let img = LPImage(image:image)!
        let pixels = img.pixels
        let initialPoints = uniqueRandoms(numberOfRandoms: UInt32(k), minNum: 0, maxNum: UInt32(img.width) * UInt32(img.height))
        let initialCentroids = initialPoints.map{pixels[Int($0)].value}
        
        let imageTexture = metalContext.imgToMetalTexture(image:img)!
        
        var kmeans = LPGPUKMeans(metalContext:metalContext)
        
        let (centroids, memberships) = kmeans.generateClusters(inputTexture:imageTexture,k: k, initialCentroids:initialCentroids)
        
        let outputTexture = kmeans.assignClusters(centroids: centroids, memberships: memberships, inputTexture: imageTexture)
        
        return metalContext.imageFromTexture(texture: outputTexture)
    }
    
    func uniqueRandoms(numberOfRandoms: UInt32, minNum: UInt32, maxNum: UInt32) -> [UInt32] {
        var uniqueNumbers = Set<UInt32>()
        while UInt32(uniqueNumbers.count) < numberOfRandoms {
            let random = UInt32(arc4random_uniform(maxNum-minNum)) + minNum
            uniqueNumbers.insert(random)
        }
        return Array(uniqueNumbers)
    }
}
