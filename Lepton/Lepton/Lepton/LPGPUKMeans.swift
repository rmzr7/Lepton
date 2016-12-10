//
//  LPGPUKMeans.swift
//  Lepton
//
//  Created by William Tong on 12/7/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Foundation
import Metal

class LPGPUKMeans {
    var clusterPipelineState:MTLComputePipelineState
    var metalContext:LPMetalContext
    
    init(clusterFunction:String, metalContext:LPMetalContext) {
        self.metalContext = metalContext
        let kernel = (metalContext.library.makeFunction(name: clusterFunction)!)
        do {
            try self.clusterPipelineState = metalContext.device.makeComputePipelineState(function: kernel)
        }
        catch {
            fatalError("error while create compute pipline for function \(clusterFunction)")
        }
    }
    
    // TODO: finish this function. We shouldn't init a pipeline because we have two functions this time.
    func createComputePipeline() {
        
    }
    
    // TODO: finish making necessary changes to squaresError, other stuff
    func generateClusters(inputTexture:MTLTexture, k:Int) -> ([Int],[Int])  {
        let threshold:Float = 0.01;
        let n = inputTexture.arrayLength
        
        let width = inputTexture.width
        let height = inputTexture.height
        
        var centroids = [Int](repeating:0, count:k)
        for i in 0..<k {
            centroids[i] = randomNumberInRange(0..<Int(UInt32.max))
        }
        
        let memberships = [Int](repeating: -1, count: n)
        let membershipChanged = [Int](repeating: 0, count: n)
        
        var error:Float = 0
        let commandBuffer = metalContext.commandQueue.makeCommandBuffer()

        repeat {
            error = 0
            let clusterSizes = [Int](repeating: 0, count: k)
            var newCentroidRed = [Float](repeating: 0,count:k)
            var newCentroidGreen = [Float](repeating: 0,count:k)
            var newCentroidBlue = [Float](repeating: 0,count:k)
            
            let membershipBuf = metalContext.createIntArray(array: memberships)
            let redBuf = metalContext.createFloatArray(array: newCentroidRed)
            let greenBuf = metalContext.createFloatArray(array: newCentroidGreen)
            let blueBuf = metalContext.createFloatArray(array: newCentroidBlue)
            let centroidsBuf = metalContext.createIntArray(array:centroids)
            let sizesBuf = metalContext.createIntArray(array: clusterSizes)
            let membershipChangedBuf = metalContext.createIntArray(array: membershipChanged)
            
            let clusterCE = commandBuffer.makeComputeCommandEncoder()
            clusterCE.setComputePipelineState(clusterPipelineState)
            clusterCE.setTexture(inputTexture, at:0)
            clusterCE.setBuffer(membershipBuf, offset: 0, at: 1)
            clusterCE.setBuffer(redBuf, offset: 0, at: 2)
            clusterCE.setBuffer(greenBuf, offset: 0, at: 3)
            clusterCE.setBuffer(blueBuf, offset: 0, at: 4)
            clusterCE.setBuffer(centroidsBuf, offset: 0, at: 5)
            clusterCE.setBuffer(sizesBuf, offset:0,at: 6)
            clusterCE.setBuffer(membershipChangedBuf, offset:0, at: 7)

            let threadGroupCounts = MTLSizeMake(8,8,1)
            let threadGroups = MTLSizeMake(width/threadGroupCounts.width, height/threadGroupCounts.height, 1);
            clusterCE.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCounts)
            clusterCE.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            for i in 0..<n {
                if membershipChanged[i] == 1 {
                    error += 1
                }
            }
            
            for i in 0..<k {
                let size = clusterSizes[i]
                if size > 0 {
                    
                    let newCentroid = Int.fromRGB(
                        r:(Float(newCentroidRed[i]) / Float(size)).toUInt8(),
                        g:(Float(newCentroidGreen[i]) / Float(size)).toUInt8(),
                        b:(Float(newCentroidBlue[i]) / Float(size)).toUInt8())
                    centroids[i] = newCentroid
                }
            }
            
        } while (error / Float(n) > threshold)
        
        //let clusters = zip(centroids, clusterSizes).map { Cluster(centroid: $0, size: $1) }
        return (centroids, memberships)
    }
    
    //TODO: finish this function 
    func assignClusters () {
        
    }
}

extension Int {
    static func fromRGB(r:UInt8, g:UInt8, b:UInt8) -> Int {
        var pixel = 0
        pixel = Int(UInt32(r) | (UInt32(pixel) & 0xFFFFFF00))
        pixel = Int((UInt32(g) << 8) | (UInt32(pixel) & 0xFFFF00FF))
        pixel = Int((UInt32(b) << 16) | (UInt32(pixel) & 0xFF00FFFF))
        pixel = Int((UInt32(1) << 24) | (UInt32(pixel) & 0x00FFFFFF))
        return pixel
    }
}

