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
    var library:MTLLibrary
    var commandQueue:MTLCommandQueue
    
    init(device:MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.library = device.newDefaultLibrary()!
    }
    
    // Turns an LPImage into a Metal texture
    func imageToMetalTexture(image:LPImage) -> MTLTexture? {
        
        let height = image.height
        let width = image.width
        
        let textureDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        
        let region = MTLRegionMake2D(0, 0, width, height)
        let imageTexture = device.makeTexture(descriptor: textureDesc)
        
        guard let rawData = image.LPPixelToInt().baseAddress else {
            return nil
        }
        
        let bytesPerRow = 4 * width
        
        imageTexture.replace(region: region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow);
        
        return imageTexture
    }
    
    // Turns a mask into a Metal texture
    func maskToMetalTexture(mask:LPMask) -> MTLTexture {
        
        let maskWidth = mask.maskWidth
        
        let textureDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: maskWidth, height: maskWidth, mipmapped: false)
        
        let region = MTLRegionMake2D(0, 0, maskWidth, maskWidth)
        let maskTexture = device.makeTexture(descriptor: textureDesc)
        
        maskTexture.replace(region: region, mipmapLevel: 0, withBytes: mask.mask, bytesPerRow: MemoryLayout<Float>.size * mask.maskWidth)
        
        return maskTexture
    }
    
    // Turns a texture into a UIImage
    func imageFromTexture(texture: MTLTexture) -> UIImage {
        let bytesPerPixel = 4
        // The total number of bytes of the texture
        let imageByteCount = texture.width * texture.height * bytesPerPixel
        
        // The number of bytes for each image row
        let bytesPerRow = texture.width * bytesPerPixel
        
        // An empty buffer that will contain the image
        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
        
        // Gets the bytes from the texture
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        texture.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        // Creates an image context
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        let bitsPerComponent = 8
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &src, width: texture.width, height: texture.height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue);
        
        // Creates the image from the graphics context
        let dstImage = context!.makeImage();
        
        // Creates the final UIImage
        return UIImage(cgImage: dstImage!, scale: 0.0, orientation: UIImageOrientation.downMirrored)
    }
}

extension LPMetalContext {
    
    func createPointer(f:UnsafeMutablePointer<Float>) -> MTLBuffer {
        return device.makeBuffer(bytes: f, length: 4, options: .cpuCacheModeWriteCombined)
    }
    
    func createFloatArray(array:[Float]) -> MTLBuffer  {
        let length = array.count * MemoryLayout<Float>.size
//        device.makeBuffer(bytes: array, length: length, options: .cpuCacheModeWriteCombined)
        return device.makeBuffer(bytes: array, length: length, options: .cpuCacheModeWriteCombined)
    }
    
    func createIntArray(array:[Int]) ->MTLBuffer {
        let length = array.count * MemoryLayout<Int>.size
        return device.makeBuffer(bytes: array, length: length, options: .cpuCacheModeWriteCombined)
    }
    
    func createComputePipeline(function:String) -> MTLComputePipelineState? {
        let computeFunction = (library.makeFunction(name: function)!)
        do {
            let pipeline = try device.makeComputePipelineState(function: computeFunction)
            return pipeline
        }
        catch {
            fatalError("error while create compute pipline for function \(function)")
        }
        return nil
    }
}
