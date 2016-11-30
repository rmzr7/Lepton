//
//  LPMetalPipeline.swift
//  Lepton
//
//  Created by Rameez Remsudeen  on 11/26/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Foundation
import Metal

class LPMetalPipeline {
    var device:MTLDevice
    var library:MTLLibrary?
    
    let commandQueue:MTLCommandQueue
    
    init(device:MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.library = device.newDefaultLibrary()
    }
    
    func textureForImage(image:LPImage) -> MTLTexture? {
        let height = image.height
        let width = image.width
        
        let textureDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Uint, width: width, height: height, mipmapped: false)
        
        let region = MTLRegionMake2D(0, 0, height, width)
        let texture = device.makeTexture(descriptor: textureDesc)
        
        guard let rawData = image.pixels.baseAddress else {
            return nil
        }
        
        let bytesPerRow = MemoryLayout<Pixel>.size*width
        
        texture.replace(region: region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow);
        
        return texture
    }
    
    func textureForMask(mask:LPMask) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: mask.width, height: mask.height, mipmapped: false)
        
        let maskTexture = device.makeTexture(descriptor: textureDescriptor)
        let region = MTLRegionMake2D(0, 0, mask.height, mask.width)
        maskTexture.replace(region: region, mipmapLevel: 0, withBytes: mask.mask, bytesPerRow: MemoryLayout<Float>.size * mask.width)
        
        return maskTexture
        
    }
    

}
