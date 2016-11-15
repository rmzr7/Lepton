//
//  LPImageFilter.swift
//  Lepton
//
//  Created by Rameez Remsudeen on 11/14/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import UIKit
import Accelerate

class LPImageFilter: NSObject {
    override init() {
        super.init()
    }
    
    func mask8(x:UInt32) -> UInt32 {
        return x & 0xFF
    }
    func getRed(x:UInt32) -> UInt32 {
        return mask8(x)
    }
    func getGreen(x:UInt32) -> UInt32 {
        return mask8(x >> 8 )
    }
    func getBlue(x:UInt32) -> UInt32 {
        return mask8(x >> 16)
    }
    
    func loadImage(image:CGImageRef) -> CGImage? {
        
        let width = CGImageGetWidth(image)
        let height = CGImageGetHeight(image)
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel*width
        let bitsPerComponent = 8
        
        var pixels = [UInt32](count: height*width, repeatedValue: 0)
        
        var colorSpace = CGColorSpaceCreateDeviceRGB()
        var context = CGBitmapContextCreate(&pixels, width, height, bitsPerComponent, bytesPerRow, colorSpace, 0)
        
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), image)
        blurImage(pixels, width: width, height: height)
        
        var realImage = CGBitmapContextCreateImage(context)
        return realImage
    }
    
    func blurImage(image:[UInt32], width:Int, height:Int) -> [UInt32] {
        
        var result = [UInt32](count: height*width, repeatedValue: 0)
        let factor = 1.0
        let bias = 0.0

        
        for x in 0...width {
            for y in 0...height {
                var red = 0.0, green = 0.0, blue = 0.0
                
                for fx in 0...3 {
                    for fy in 0...3 {
                        let imageX:Int = (x - 3 / 2 + fx + width) % width
                        let imageY:Int = (y - 3 / 2 + fy + height) % height
                        red += Double(getRed(image[(imageY * width + imageX)])) * filter[fy][fx]
                        green += Double(getGreen(image[imageY * width + imageX])) * filter[fy][fx]
                        blue += Double(getBlue(image[imageY * width + imageX])) * filter[fy][fx]

                    }
                }
                
                let newR = min(max(UInt32(factor * red + bias), 0), 255)
                let newG = min(max(UInt32(factor * green + bias), 0), 255)
                let newB = min(max(UInt32(factor * blue + bias), 0), 255)
                let newPixel = newB << 16 | newG << 8 | newR
                
                result[y * width + x] = newPixel
                
            }
        }
        
        return result
    }
    
//    pixel helpers

    
    
    var filter = [
        [0.0, 0.2, 0.0],
        [0.2, 0.2, 0.2],
        [0.0, 0.2, 0.0]
    ]
    
    
}

extension Int {
    public var toU8: UInt8{ get{return UInt8(truncatingBitPattern:self)} }
    public var to8: Int8{ get{return Int8(truncatingBitPattern:self)} }
    public var toU16: UInt16{get{return UInt16(truncatingBitPattern:self)}}
    public var to16: Int16{get{return Int16(truncatingBitPattern:self)}}
    public var toU32: UInt32{get{return UInt32(truncatingBitPattern:self)}}
    public var to32: Int32{get{return Int32(truncatingBitPattern:self)}}
    public var toU64: UInt64{get{
        return UInt64(self) //No difference if the platform is 32 or 64
        }}
    public var to64: Int64{get{
        return Int64(self) //No difference if the platform is 32 or 64
        }}
}

extension Int32 {
    public var toU8: UInt8{ get{return UInt8(truncatingBitPattern:self)} }
    public var to8: Int8{ get{return Int8(truncatingBitPattern:self)} }
    public var toU16: UInt16{get{return UInt16(truncatingBitPattern:self)}}
    public var to16: Int16{get{return Int16(truncatingBitPattern:self)}}
    public var toU32: UInt32{get{return UInt32(self)}}
    public var to32: Int32{get{return self}}
    public var toU64: UInt64{get{
        return UInt64(self) //No difference if the platform is 32 or 64
        }}
    public var to64: Int64{get{
        return Int64(self) //No difference if the platform is 32 or 64
        }}
}

extension UInt32 {
    public subscript(index: Int) -> UInt32 {
        get {
            precondition(index<4,"Byte set index out of range")
            return (self & (0xFF << (index.toU32*8))) >> (index.toU32*8)
        }
        set(newValue) {
            precondition(index<4,"Byte set index out of range")
            self = (self & ~(0xFF << (index.toU32*8))) | (newValue << (index.toU32*8))
        }
    }
}
