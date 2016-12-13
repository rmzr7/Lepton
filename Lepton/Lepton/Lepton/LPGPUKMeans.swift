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
    var k:Int32
}

struct debug {
    var idx:Int
}

class LPGPUKMeans {
    var metalContext:LPMetalContext
    
    init(metalContext:LPMetalContext) {
        self.metalContext = metalContext
    }
    
    // TODO: finish making necessary changes to squaresError, other stuff
    func generateClusters(inputTexture:MTLTexture, k:Int) -> ([UInt32],[Int])  {
        let threshold:Float = 0.01;
        
        let width = inputTexture.width
        let height = inputTexture.height
        
        let n = width*height

//        var centroids = uniqueRandoms(numberOfRandoms: k, minNum: Int(UInt32.max)/2, maxNum: UInt32.max)
//        var centroids = [Int32](repeating: 429496719, count:k)
        var centroids = [UInt32](repeating: 0, count:k)
         
        var error:Float = 0
        let commandBuffer = metalContext.commandQueue.makeCommandBuffer()

        let threadGroupCounts = MTLSizeMake(8,8,1)
        let threadGroupWidth = threadGroupCounts.width
        let threadGroupHeight = threadGroupCounts.height
        let numRegionsWidth = (width + threadGroupWidth - 1) / threadGroupWidth
        let numRegionsHeight = (height + threadGroupHeight - 1) / threadGroupHeight
        let threadGroups = MTLSizeMake(numRegionsWidth, numRegionsHeight, 1);
        let regions = numRegionsWidth * numRegionsHeight
        let bufferSize = k * regions;
        let memberships = [Int](repeating: -1, count: n)
        var squaresError = [Int](repeating: 0, count: n)
        
        repeat {
            error = 0
            
            var clusterSizes = [UInt32](repeating: 0, count: bufferSize)
            var centroidRed = [Float](repeating: 0,count:bufferSize)
            var centroidGreen = [Float](repeating: 0,count:bufferSize)
            var centroidBlue = [Float](repeating: 0,count:bufferSize)
            
//            squaresError = [
            
            var membershipBuf = metalContext.createIntArray(array: memberships)
            var redBuf = metalContext.createFloatArray(array: centroidRed)
            var greenBuf = metalContext.createFloatArray(array: centroidGreen)
            var blueBuf = metalContext.createFloatArray(array: centroidBlue)
            var centroidsBuf = metalContext.createInt32Array(array:centroids)
            var sizesBuf = metalContext.createInt32Array(array: clusterSizes)
            var membershipChangedBuf = metalContext.createIntArray(array: squaresError)
            
            var clusterCE = commandBuffer.makeComputeCommandEncoder()
            let clusterPipleline = metalContext.createComputePipeline(function: "findNearestCluster")!
            clusterCE.setComputePipelineState(clusterPipleline)
            clusterCE.setTexture(inputTexture, at:0)
            clusterCE.setBuffer(membershipBuf, offset: 0, at: 0)
            clusterCE.setBuffer(redBuf, offset: 0, at: 1)
            clusterCE.setBuffer(greenBuf, offset: 0, at: 2)
            clusterCE.setBuffer(blueBuf, offset: 0, at: 3)
            clusterCE.setBuffer(centroidsBuf, offset: 0, at: 4)
            clusterCE.setBuffer(sizesBuf, offset:0,at: 5)
            clusterCE.setBuffer(membershipChangedBuf, offset:0, at: 6)
            
            var kmeansparams = KMeansParams(k: Int32(k))
            let params = metalContext.device.makeBuffer(bytes: &kmeansparams, length: MemoryLayout<KMeansParams>.size, options: .cpuCacheModeWriteCombined)
            clusterCE.setBuffer(params, offset:0, at:7)
            

            var debug = [Float](repeating: 0,count:threadGroups.width * threadGroups.height)

            var debugBuffer = metalContext.device.makeBuffer(bytes: &debug, length:MemoryLayout<Int32>.size * debug.count, options: [])
            clusterCE.setBuffer(debugBuffer, offset: 0, at: 8)
            

            clusterCE.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCounts)
            clusterCE.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            clusterSizes = Array(UnsafeBufferPointer(start: unsafeBitCast(sizesBuf.contents(), to:UnsafeMutablePointer<UInt32>.self), count: bufferSize))
            centroidRed = Array(UnsafeBufferPointer(start: unsafeBitCast(redBuf.contents(), to:UnsafeMutablePointer<Float>.self), count: bufferSize))
            centroidGreen = Array(UnsafeBufferPointer(start: unsafeBitCast(greenBuf.contents(), to:UnsafeMutablePointer<Float>.self), count: bufferSize))
            centroidBlue = Array(UnsafeBufferPointer(start: unsafeBitCast(blueBuf.contents(), to:UnsafeMutablePointer<Float>.self), count: bufferSize))
            
            squaresError = Array(UnsafeBufferPointer(start: unsafeBitCast(membershipChangedBuf.contents(), to:UnsafeMutablePointer<Int>.self), count: n))
            
            for i in 0..<n {
                if squaresError[i] == 1 {
                    error += 1
                }
            }
            
            for i in 0..<k {
                var red:Float = 0
                var green:Float = 0
                var blue:Float = 0
                var size:UInt32 = 0
                for j in 0..<regions {
                    let idx = i * regions + j
                    red += centroidRed[idx]
                    green += centroidGreen[idx]
                    blue += centroidBlue[idx]
                    size += clusterSizes[idx]
                }
                if size > 0 {
                    let newCentroid = Int.fromRGB(
                        r:(red / Float(size)).toUInt8(),
                        g:(green / Float(size)).toUInt8(),
                        b:(blue / Float(size)).toUInt8())
                    centroids[i] = UInt32(newCentroid)
                }
            }
            
        } while (error / Float(n) > threshold)
        
        //let clusters = zip(centroids, clusterSizes).map { Cluster(centroid: $0, size: $1) }
        return (centroids, memberships)
    }
    
    func assignClusters (centroids:[UInt32], memberships:[Int], inputTexture:MTLTexture) -> MTLTexture {
        
        let outputDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: inputTexture.width, height: inputTexture.height, mipmapped: false)
        let outputTexture = metalContext.device.makeTexture(descriptor:outputDesc)
        
        let threadGroupCounts = MTLSizeMake(8,8,1)
        let threadGroupWidth = threadGroupCounts.width
        let threadGroupHeight = threadGroupCounts.height
        let threadGroups = MTLSizeMake((inputTexture.width + threadGroupWidth - 1)/threadGroupWidth, (inputTexture.height + threadGroupHeight - 1)/threadGroupHeight, 1);
        

        let assignPipeline = metalContext.createComputePipeline(function: "applyClusterColors")!
        let commandBuffer = metalContext.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        let centroidsBuf = metalContext.createInt32Array(array:centroids)
        let membershipBuf = metalContext.createIntArray(array:memberships)

        commandEncoder.setComputePipelineState(assignPipeline)
        commandEncoder.setTexture(inputTexture, at:0)
        commandEncoder.setBuffer(centroidsBuf, offset:0, at:1)
        commandEncoder.setBuffer(membershipBuf, offset:0, at:2)
        commandEncoder.setTexture(outputTexture, at:3)
        
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCounts)
        commandEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return outputTexture
    }
}

func uniqueRandoms(numberOfRandoms: Int, minNum: Int, maxNum: UInt32) -> [Int] {
    var uniqueNumbers = Set<Int>()
    while uniqueNumbers.count < numberOfRandoms {
        var random = Int(arc4random_uniform(maxNum)) + minNum
        uniqueNumbers.insert(random)
    }
    return Array(uniqueNumbers)
}

extension Int {
    static func fromRGB(r:UInt8, g:UInt8, b:UInt8) -> Int32 {
        var pixel:Int32 = 0
        pixel = Int32(UInt32(r) | (UInt32(pixel) & 0xFFFFFF00))
        pixel = Int32((UInt32(g) << 8) | (UInt32(pixel) & 0xFFFF00FF))
        pixel = Int32((UInt32(b) << 16) | (UInt32(pixel) & 0xFF00FFFF))
        pixel = Int32((UInt32(1) << 24) | (UInt32(pixel) & 0x00FFFFFF))
        return pixel
    }
}

