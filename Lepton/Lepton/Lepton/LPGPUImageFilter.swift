//
//  LPGPUImageFilter.swift
//  Lepton
//
//  Created by Rameez Remsudeen  on 11/29/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Foundation
import Metal

class LPGPUImageFilter {
    var kernel:MTLFunction
//    var textur:eMTLTexture
    var pipelineState:MTLPipelineState
    
    init(function:String, device:MTLDevice, library:MTLLibrary) {
        kernel = library.makeFunction(name: function)
        do {
            try pipelineState = device.makeComputePipelineState(function: kernel)
        }
        catch {
            fatalError("error while create compute pipline for function \(function)")
        }
    }
    
    
    func applyFilter(inputTexture:MTLTexture, withFilter filterTexture:MTLTexture) {
        
        var outputDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Uint, width: width, height: height, mipmapped: false)
        var outputTexture = MTLTextureDescriptor

        var threadGroupCounts = MTLSizeMake(8,8,1)
        var threadGroups = MTLSizeMake(inputTexture.width/threadGroupCounts.width, inputTexture.height/threadGroupCounts.height, 1);
        
        var commandBuffer = commandQueue.makeCommandBuffer()
        
        var commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setTexture(inputTexture, index:0)
        commandEncoder.setTexture(filterTexture, index:1)
        
    }
}
