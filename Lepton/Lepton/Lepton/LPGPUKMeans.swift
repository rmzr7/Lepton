//
//  LPGPUKMeans.swift
//  Lepton
//
//  Created by William Tong on 12/7/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Foundation
import Metal

struct KMeansParams {
    var k:Int
}

class LPGPUKMeans {
    var metalContext:LPMetalContext
    
    init(metalContext:LPMetalContext) {
        self.metalContext = metalContext
    }
    
    // TODO: finish making necessary changes to squaresError, other stuff
    func generateClusters(inputTexture:MTLTexture, k:Int) -> ([Int],[Int])  {
        let threshold:Float = 0.01;
        let n = inputTexture.arrayLength
        
        let width = inputTexture.width
        let height = inputTexture.height
        
        var centroids = uniqueNumbers(0, Int(UInt32.max)/2, UInt32.max)
//        for i in 0..<k {
//            centroids[i] = randomNumberInRange(0..<Int(UInt32.max))
//        }
//        
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
            let clusterPipleline = metalContext.createComputePipeline(function: "findNearestCluster")!
            clusterCE.setComputePipelineState(clusterPipleline)
            clusterCE.setTexture(inputTexture, at:0)
            clusterCE.setBuffer(membershipBuf, offset: 0, at: 1)
            clusterCE.setBuffer(redBuf, offset: 0, at: 2)
            clusterCE.setBuffer(greenBuf, offset: 0, at: 3)
            clusterCE.setBuffer(blueBuf, offset: 0, at: 4)
            clusterCE.setBuffer(centroidsBuf, offset: 0, at: 5)
            clusterCE.setBuffer(sizesBuf, offset:0,at: 6)
            clusterCE.setBuffer(membershipChangedBuf, offset:0, at: 7)
            
            var kmeansparams = KMeansParams(k: k)
            let params = metalContext.device.makeBuffer(bytes: &kmeansparams, length: MemoryLayout<KMeansParams>.size, options: .cpuCacheModeWriteCombined)
            clusterCE.setBuffer(params, offset:0, at:8)
            

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
    
    func assignClusters (centroids:[Int], memberships:[Int], inputTexture:MTLTexture) -> MTLTexture {
        
        let outputDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: inputTexture.width, height: inputTexture.height, mipmapped: false)
        let outputTexture = metalContext.device.makeTexture(descriptor:outputDesc)
        
        let threadGroupCount = MTLSizeMake(8,8,1)
        let threadGroups = MTLSizeMake(inputTexture.width/threadGroupCount.width, inputTexture.height/threadGroupCount.height, 1);
        

        let assignPipeline = metalContext.createComputePipeline(function: "applyClusterColors")!
        let commandBuffer = metalContext.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        let centroidsBuf = metalContext.createIntArray(array:centroids)
        let membershipBuf = metalContext.createIntArray(array:memberships)

        commandEncoder.setComputePipelineState(assignPipeline)
        commandEncoder.setTexture(inputTexture, at:0)
        commandEncoder.setBuffer(centroidsBuf, offset:0, at:1)
        commandEncoder.setBuffer(membershipBuf, offset:0, at:2)
        commandEncoder.setTexture(outputTexture, at:3)
        
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        commandEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return outputTexture
    }
}

func uniqueRandoms(numberOfRandoms: Int, minNum: Int, maxNum: UInt32) -> [Int] {
    var uniqueNumbers = Set<Int>()
    while uniqueNumbers.count < numberOfRandoms {
        uniqueNumbers.insert(Int(arc4random_uniform(maxNum + 1)) + minNum)
    }
    return Array(uniqueNumbers)
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

