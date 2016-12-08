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
    var kernel:MTLFunction
    var pipelineState:MTLComputePipelineState
    var metalContext:LPMetalContext
    
    init(function:String, metalContext:LPMetalContext) {
        self.metalContext = metalContext
        self.kernel = (metalContext.library.makeFunction(name: function)!)
        do {
            try self.pipelineState = metalContext.device.makeComputePipelineState(function: kernel)
        }
        catch {
            fatalError("error while create compute pipline for function \(function)")
        }
    }
    
    
    func applyKMeans(inputTexture:MTLTexture, withFilter filterTexture:MTLTexture) -> MTLTexture {
        
        let outputDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: inputTexture.width, height: inputTexture.height, mipmapped: false)
        let outputTexture = metalContext.device.makeTexture(descriptor: outputDesc)
        
        let threadGroupCounts = MTLSizeMake(8,8,1)
        let threadGroups = MTLSizeMake(inputTexture.width/threadGroupCounts.width, inputTexture.height/threadGroupCounts.height, 1);
        
        let commandBuffer = metalContext.commandQueue.makeCommandBuffer()
        
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setTexture(inputTexture, at:0)
        commandEncoder.setTexture(filterTexture, at:1)
        commandEncoder.setTexture(outputTexture, at:2)
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCounts)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return outputTexture
    }
}

