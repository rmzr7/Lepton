//
//  LPMetalPipeline.swift
//  Lepton
//
//  Created by Rameez Remsudeen  on 11/26/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Foundation
import Metal

class LPMetalContext {
    var device:MTLDevice
    var library:MTLLibrary?
    var commandQueue:MTLCommandQueue
    
    init(device:MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.library = device.newDefaultLibrary()
    }
    
    // Turns an LPImage into a Metal texture
    func imageToMetalTexture(image:LPImage) -> MTLTexture? {
        
        let height = image.height
        let width = image.width
        
        let textureDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Uint, width: width, height: height, mipmapped: false)
        
        let region = MTLRegionMake2D(0, 0, height, width)
        let imageTexture = device.makeTexture(descriptor: textureDesc)
        
        guard let rawData = image.pixels.baseAddress else {
            return nil
        }
        
        let bytesPerRow = MemoryLayout<Pixel>.size * width
        
        imageTexture.replace(region: region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow);
        
        return imageTexture
    }
    
    // Turns a mask into a Metal texture
    func maskToMetalTexture(mask:LPMask) -> MTLTexture {
        
        let textureDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: mask.width, height: mask.height, mipmapped: false)
        
        let region = MTLRegionMake2D(0, 0, mask.height, mask.width)
        let maskTexture = device.makeTexture(descriptor: textureDesc)
        
        maskTexture.replace(region: region, mipmapLevel: 0, withBytes: mask.mask, bytesPerRow: MemoryLayout<Float>.size * mask.width)
        
        return maskTexture
    }
    

}
