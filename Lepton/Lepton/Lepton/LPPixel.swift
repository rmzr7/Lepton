//
//  LPPixel.swift
//  Lepton
//
//  Created by Rameez Remsudeen on 11/15/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import UIKit
import Metal

struct LPPixel {
    var value: UInt32
    var red: UInt8 {
        get { return UInt8(value & 0xFF) }
        set { value = UInt32(newValue) | (value & 0xFFFFFF00) }
    }
    var green: UInt8 {
        get { return UInt8((value >> 8) & 0xFF) }
        set { value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF) }
    }
    var blue: UInt8 {
        get { return UInt8((value >> 16) & 0xFF) }
        set { value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF) }
    }
    var alpha: UInt8 {
        get { return UInt8((value >> 24) & 0xFF) }
        set { value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF) }
    }
    
    func rgb() -> (Float, Float, Float) {
        return (Float(red), Float(green), Float(blue))
    }
    
    static func + (left:LPPixel, right:LPPixel) -> LPPixel {
        let r3 = (Float(left.red) + Float(right.red)).toUInt8()
        let g3 = (Float(left.green) + Float(right.green)).toUInt8()
        let b3 = (Float(left.blue) + Float(right.blue)).toUInt8()
        var px = LPPixel(value: 0)
        px.red = r3
        px.blue = b3
        px.green = g3
        return px
    }
    
    static func / (left:LPPixel, right:Int) -> LPPixel {
        let r3 = (Float(left.red) / Float(right)).toUInt8()
        let g3 = (Float(left.green) / Float(right)).toUInt8()
        let b3 = (Float(left.blue) / Float(right)).toUInt8()
        var px = LPPixel(value: 0)
        px.red = r3
        px.blue = b3
        px.green = g3
        return px
    }
}

public struct LPImage {
    var pixels:UnsafeMutableBufferPointer<LPPixel>
    var width:Int
    var height:Int
    
    init? (image:UIImage) {
        guard let cgImage = image.cgImage else { return nil } // 1
        
        width = Int(image.size.width)
        height = Int(image.size.height)
        let bitsPerComponent = 8 // 2
        
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let imageData = UnsafeMutablePointer<LPPixel>.allocate(capacity: width * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB() // 3
        
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        guard let imageContext = CGContext(data: imageData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
        imageContext.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: image.size)) // 4
        
        pixels = UnsafeMutableBufferPointer<LPPixel>(start: imageData, count: width * height)
    }
    
    func LPPixelToInt() -> UnsafeMutableBufferPointer<UInt32> {
        var metal_pixels = UnsafeMutablePointer<UInt32>.allocate(capacity: width * height)
        for idx in 0..<width * height {
            metal_pixels[idx] = pixels[idx].value
        }
        return UnsafeMutableBufferPointer<UInt32>(start: metal_pixels, count: width * height)
    }
    
    func toUIImage() -> UIImage? {
        let bitsPerComponent = 8 // 1
        
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB() // 2
        
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        let imageContext = CGContext(data: pixels.baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, releaseCallback: nil, releaseInfo: nil)
        guard let cgImage = imageContext?.makeImage() else {return nil} // 3
        
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
    
}

extension Float {
    func toUInt8()->UInt8 {
        return UInt8(min(max(self, 0), 255))
    }
}

extension Double {
    func toUInt8() -> UInt8 {
        return UInt8(min(max(self, 0), 255))
    }
}
