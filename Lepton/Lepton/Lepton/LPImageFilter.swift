//
//  LPImageFilter.swift
//  Lepton
//
//  Created by Rameez Remsudeen on 11/14/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import UIKit
import Accelerate
import Metal

public struct LPMask {
    var height = 0
    var width = 0
    public var mask:[[Float]]!
    
    init(height:Int=3, width:Int=3, mask:[[Float]] = [
        [0.2, 0.2, 0.0],
        [0.2, 0.2, 0.2],
        [0.0, 0.2, 0.0]
        ]) {
        assert(height == mask.count)
        self.height = height
        self.width = width
        self.mask = mask
    }
}




open class LPImageFilter: NSObject {
    public override init() {
        super.init()
    }
    
    open func blurImage(_ image:UIImage, mask:LPMask = LPMask()) -> UIImage? {
        
        let pixels = LPImage(image:image)!
        let width = pixels.width
        let height = pixels.height
        let factor:Float = 1.0
        let bias:Float = 0.0
        for y in 0..<pixels.height {
            for x in 0..<pixels.width {
                let idx = y*pixels.width+x
                var red:Float = 0.0, green:Float = 0.0, blue:Float = 0.0


                for fy in 0..<mask.height {
                    for fx in 0..<mask.width {
                        let imageX:Int = (x - mask.width / 2 + fx + pixels.width) % width
                        let imageY:Int = (y - mask.height / 2 + fy + pixels.height) % height
                        let pixel = pixels.pixels[(imageY * width + imageX)]
                        red += Float(pixel.red) * mask.mask[fy][fx]
                        green += Float(pixel.green) * mask.mask[fy][fx]
                        blue += Float(pixel.blue) * mask.mask[fy][fx]
                    }
                }
                
                let newR = (factor * red + bias).toUInt8()
                let newG = (factor * green + bias).toUInt8()
                let newB = (factor * blue + bias).toUInt8()
                var pixel = pixels.pixels[idx]
                pixel.red = newR
                pixel.green = newG
                pixel.blue = newB
                pixels.pixels[idx] = pixel
            }
        }
        
        return pixels.toUIImage()

    }

    
    open func makeGaussianFilter(_ radius:Int) -> LPMask {
        let stddev:Float = 1.5
        let stddev_squared_times_2:Float = 2.0 * stddev * stddev
        var mask = [[Float]]()
        let pi = Float(M_PI)
        let e = Float(M_E)
        var sum:Float = 0.0
        for y in -1 * radius...radius {
            let float_y = Float(y)
            let y_squared = float_y * float_y
            var row = [Float]()
            for x in -1 * radius...radius {
                let float_x = Float(x)
                let x_squared = float_x * float_x
                let exp = -1.0 * (x_squared + y_squared) / stddev_squared_times_2
                let val = 1.0/(pi * stddev_squared_times_2) * pow(e, exp)
                row.append( val )
                sum += val
            }
            mask.append(row)
        }
        
        for r in 0..<(radius * 2 + 1) {
            for c in 0..<(radius * 2 + 1) {
                mask[r][c] /= sum
            }
        }
        return LPMask(height: (radius * 2 + 1), width: (radius * 2 + 1), mask:mask)
    }
    
    open func acceleratedBlurImageCPU(_ image:UIImage, mask:LPMask = LPMask()) -> UIImage? {
        
        
        // 0. Get pixel data
        let pixels = LPImage(image: image)!
        let kernel = mask.mask!
        let filterLen = mask.height
        let filter = Matrix<Float>(kernel).grid
        let imageWidth = pixels.width
        let imageHeight = pixels.height
        
        // 1. Split into channels
        var (red, green, blue) = extractChannels(pixels)
        
        // 2. Convolve each channel
        vDSP_imgfir(red, vDSP_Length(imageHeight), vDSP_Length(imageWidth), filter, &red, vDSP_Length(filterLen), vDSP_Length(filterLen))
        vDSP_imgfir(green, vDSP_Length(imageHeight), vDSP_Length(imageWidth), filter, &green, vDSP_Length(filterLen), vDSP_Length(filterLen))
        vDSP_imgfir(blue, vDSP_Length(imageHeight), vDSP_Length(imageWidth), filter, &blue, vDSP_Length(filterLen), vDSP_Length(filterLen))
        
        // 3. Clamp the values
        let len = imageWidth * imageHeight
        let zeros = [Float](repeating: 0.0, count: len)
        let TFF = [Float](repeating: 255.0, count: len)
        
        let unsigned_len = UInt(len)
        
        vDSP_vmax(red, 1, zeros, 1, &red, 1, unsigned_len)
        vDSP_vmax(green, 1, zeros, 1, &green, 1, unsigned_len)
        vDSP_vmax(blue, 1, zeros, 1, &blue, 1, unsigned_len)
        
        vDSP_vmin(red, 1, TFF, 1, &red, 1, unsigned_len)
        vDSP_vmin(green, 1, TFF, 1, &green, 1, unsigned_len)
        vDSP_vmin(blue, 1, TFF, 1, &blue, 1, unsigned_len)
        
        // 4. Convert the values back to integers
        var redRes = [UInt8](repeating: 0, count: len)
        var greenRes = [UInt8](repeating: 0, count: len)
        var blueRes = [UInt8](repeating: 0, count: len)
        
        vDSP_vfixu8(red, 1, &redRes, 1, unsigned_len)
        vDSP_vfixu8(green, 1, &greenRes, 1, unsigned_len)
        vDSP_vfixu8(blue, 1, &blueRes, 1, unsigned_len)
        
        // 5. Combine the channels and return the result
        return combineChannels(pixels, redValues: redRes, greenValues: greenRes, blueValues: blueRes).toUIImage()
    }
    
    open func acceleratedImageBlurGPU(_ image:UIImage, mask:LPMask = LPMask()) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("no GPU, aborting");
            return;
        }
        var metalContext = LPMetalPipeline(device: device)
        
        let pixels = LPImage(image:image)!
        var imageTexture = metalContext.textureForImage(pixels)!
        
        var maskTexture = metalContext.textureForMask(mask)
        
        
        
        
        
    }
    
    open func oneDtoTwoD(_ oneD:[Float], height:Int, width:Int) -> Matrix<Float>{
        var mat = Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
        
        for i in 0..<height {
            for j in 0..<width {
            mat[i, j] = oneD[(j*height)+i]
            }
        }
        return mat
    }
}
