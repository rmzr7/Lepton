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
    
    
    
    func generateClusters(inputTexture:MTLTexture, k:Int) {
        let threshold:Float = 0.01;
        let n = inputTexture.arrayLength
        
        let width = inputTexture.width
        let height = inputTexture.height
        
        var centroids = [Int](repeating:0, count:k)
        for i in 0..<k {
            let rand = randomNumberInRange(0..<Int(UInt32.max))
            centroids[i] = rand
        }
        
        var memberships = [Int](repeating: -1, count: n)
        var clusterSizes = [Int](repeating: 0, count: k)
        
        var squaresError:Float = 0
        let commandBuffer = metalContext.commandQueue.makeCommandBuffer()

        repeat {
            squaresError = 0
            var newCentroidRed = [Float](repeating: 0,count:k)
            var newCentroidGreen = [Float](repeating: 0,count:k)
            var newCentroidBlue = [Float](repeating: 0,count:k)
            
            var newClusterSizes = [Float](repeating: 0, count: k)
            
            let threadGroupCounts = MTLSizeMake(8,8,1)

            let threadGroups = MTLSizeMake(inputTexture.width/threadGroupCounts.width, inputTexture.height/threadGroupCounts.height, 1);
            
            let redBuffer = metalContext.createFloatArray(array: newCentroidRed)
            let greenBuf = metalContext.createFloatArray(array: newCentroidGreen)
            let blueBuf = metalContext.createFloatArray(array: newCentroidBlue)
            let membershipBuf = metalContext.createIntArray(array:memberships)
            let sizesBuf = metalContext.createIntArray(array: clusterSizes)
            
            let clusterCE = commandBuffer.makeComputeCommandEncoder()
            clusterCE.setComputePipelineState(clusterPipelineState)
            clusterCE.setTexture(inputTexture, at:0)
            clusterCE.setBuffer(membershipBuf, offset: 0, at: 1)
            
            clusterCE.setBuffer(redBuffer, offset: 0, at: 2)
            clusterCE.setBuffer(greenBuf, offset: 0, at: 3)
            clusterCE.setBuffer(blueBuf, offset: 0, at: 4)

            clusterCE.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCounts)
            clusterCE.endEncoding()
            
            
        
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            for i in 0..<k {
                let size = newClusterSizes[i]
                if size > 0 {
                    
                    centroids[i].red = (Float(newCentroidRed[i]) / Float(size)).toUInt8()
                    centroids[i].green = (Float(newCentroidGreen[i]) / Float(size)).toUInt8()
                    centroids[i].blue = (Float(newCentroidBlue[i]) / Float(size)).toUInt8()
                    
                }
            }
            
        } while (squaresError / Float(n) > threshold)
        
    }
}

