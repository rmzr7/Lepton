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
    var maskWidth:Int
    public var mask:[Float]
    
    init(maskWidth:Int=3, mask:[Float] =
        [0.2, 0.2, 0.0,
        0.2, 0.2, 0.2,
        0.0, 0.2, 0.0])
    {
        assert(maskWidth * maskWidth == mask.count)
        self.maskWidth = maskWidth
        self.mask = mask
    }
}

open class LPImageFilter: NSObject {
    public override init() {
        super.init()
    }
    
    open func blurImage(_ image:UIImage, mask:LPMask = LPMask()) -> UIImage? {
        
        let pixels = LPImage(image:image)!
        let imageWidth = pixels.width
        let imageHeight = pixels.height
        let factor:Float = 1.0
        let bias:Float = 0.0
        
        for y in 0..<imageHeight {
            for x in 0..<imageWidth {
                
                let imageIdx = y * imageWidth + x
                var red:Float = 0.0, green:Float = 0.0, blue:Float = 0.0
                let maskWidth = mask.maskWidth

                for fy in 0..<maskWidth {
                    for fx in 0..<maskWidth {
                        let maskIdx = fy * maskWidth + fx
                        let imageX:Int = (x - maskWidth / 2 + fx + imageWidth) % imageWidth
                        let imageY:Int = (y - maskWidth / 2 + fy + imageHeight) % imageHeight
                        let pixel = pixels.pixels[(imageY * imageWidth + imageX)]
                        red += Float(pixel.red) * mask.mask[maskIdx]
                        green += Float(pixel.green) * mask.mask[maskIdx]
                        blue += Float(pixel.blue) * mask.mask[maskIdx]
                    }
                }
                
                let newR = (factor * red + bias).toUInt8()
                let newG = (factor * green + bias).toUInt8()
                let newB = (factor * blue + bias).toUInt8()
                var pixel = pixels.pixels[imageIdx]
                pixel.red = newR
                pixel.green = newG
                pixel.blue = newB
                pixels.pixels[imageIdx] = pixel
            }
        }
        
        return pixels.toUIImage()
    }
    
    open func GaussianFilterGenerator (_ sigma:Float) -> LPMask {

        let radius:Int = Int(3.0 * sigma);
        let size:Int = radius * 2 + 1;
    
        let delta:Float = (Float(radius) * 2.0) / (Float(size) - 1.0)
        let expScale:Float = -1 / (2 * sigma * sigma)
    
        var weights:[Float] = [Float](repeating: 0.0, count: size * size)
    
        var weightSum:Float = 0;
        var y:Float = -1.0 * Float(radius);
    
        for j in 0..<size {
            var x:Float = -1.0 * Float(radius);
            for i in 0..<size {
                let weight:Float = expf((x * x + y * y) * expScale);
                weights[j * size + i] = weight;
                weightSum += weight;
                x += delta
            }
            y += delta
        }
    
        let weightScale:Float = 1.0 / weightSum;
        for j in 0..<size {
            for i in 0..<size {
                weights[j * size + i] *= weightScale;
            }
        }
        
        return LPMask(maskWidth: size, mask: weights)
    }

    
    open func acceleratedBlurImageCPU(_ image:UIImage, mask:LPMask = LPMask()) -> UIImage? {
        
        
        // 0. Get pixel data
        let pixels = LPImage(image: image)!
        let filterLen = mask.maskWidth
        let filter = mask.mask
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
    
    open func acceleratedImageBlurGPU(_ image:UIImage, mask:LPMask = LPMask()) -> UIImage? {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("no GPU, aborting");
            return nil;
        }

        let img = LPImage(image:image)!
        let metalContext = LPMetalContext(device: device)
        let imageTexture = metalContext.imageToMetalTexture(image:img)!
        let maskTexture = metalContext.maskToMetalTexture(mask: mask)

        
        let gpufilter = LPGPUImageFilter(function: "gaussian_filter", metalContext: metalContext)
        let outputTexture = gpufilter.applyFilter(inputTexture: imageTexture, withFilter: maskTexture)
        
        return metalContext.imageFromTexture(texture: outputTexture)
        
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
