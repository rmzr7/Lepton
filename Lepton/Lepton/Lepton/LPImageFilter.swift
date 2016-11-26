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
    var mask:[[Double]]!
    
    init(height:Int=3, width:Int=3, mask:[[Double]] = [
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
        
        let pixels = RGBA(image:image)!
        let width = pixels.width
        let height = pixels.height
        let factor = 1.0
        let bias = 0.0
        for y in 0..<pixels.height {
            for x in 0..<pixels.width {
                let idx = y*pixels.width+x
                var red = 0.0, green = 0.0, blue = 0.0


                for fy in 0..<mask.height {
                    for fx in 0..<mask.width {
                        let imageX:Int = (x - mask.width / 2 + fx + pixels.width) % width
                        let imageY:Int = (y - mask.height / 2 + fy + pixels.height) % height
                        let pixel = pixels.pixels[(imageY * width + imageX)]
                        red += Double(pixel.red) * mask.mask[fy][fx]
                        green += Double(pixel.green) * mask.mask[fy][fx]
                        blue += Double(pixel.blue) * mask.mask[fy][fx]
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
        let stddev = 1.5
        var mask = [[Double]]()
        let pi = M_PI
        let e = 2.78
        var sum = 0.0
        for y in -1 * radius...radius {
            let double_y = Double(y)
            var row = [Double]()
            for x in -1 * radius...radius {
                let double_x = Double(x)
                let exp = -1 * (double_x * double_x + double_y * double_y) / (2 * stddev * stddev)
                let val = 1/(2 * pi * stddev * stddev) * pow(e, exp)
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
    
    open func acceleratedBlurImageCPU(_ image:UIImage, kernel:[[Float]]) {
        
        
        //        get pixel data
        //        get channels
        //        apply img to col each channel
        
        let pixels = RGBA(image: image)!
        let filter = Matrix<Float>(kernel)
        let width = pixels.width
        let height = pixels.height
        
        
        let (red, green, blue) = extractChannels(pixels)
        let kernelWidth = kernel.count
        
        let redColMat = img2col(red, filterLen: kernelWidth)
        let greenColMat = img2col(green, filterLen: kernel.count)
        let blueColMat = img2col(blue, filterLen: kernel.count)
        let filtColMat = filter2col(filter)
        
        
        let redProd = redColMat * filtColMat
        let greenProd = greenColMat * filtColMat
        let blueProd = blueColMat * filtColMat
        
        let redArr = redProd.grid
        let gArr = greenProd.grid
        let bArr = blueProd.grid
        
        let zeros = [Float](repeating: 0, count: width*height)
        let TFF = [Float](repeating: 255, count: width*height)
        
        var redRes = [Float](repeating: 0, count: width*height)
        var greRes = [Float](repeating: 0, count: width*height)
        var BluRes = [Float](repeating: 0, count: width*height)
        
        let len = UInt(width * height)
        
        vDSP_vmax(redArr, 1, zeros, 1, &redRes, 1, len)
        vDSP_vmax(gArr, 1, zeros, 1, &greRes, 1, len)
        vDSP_vmax(bArr, 1, zeros, 1, &BluRes, 1, len)
        
        vDSP_vmin(redRes, 1, TFF, 1, &redRes, 1, len)
        vDSP_vmin(greRes, 1, TFF, 1, &greRes, 1, len)
        vDSP_vmin(BluRes, 1, TFF, 1, &BluRes, 1, len)
        
        var redShift:Float = pow(2.0, 24.0)
        var greenShift:Float = pow(2.0, 16.0)
        var blueShift:Float = pow(2.0, 8.0)
        vDSP_vsmul(redRes, 1, &redShift, &redRes, 1, len)
        vDSP_vsmul(greRes, 1, &greenShift, &greRes, 1, len)
        vDSP_vsmul(BluRes, 1, &blueShift, &BluRes, 1, len)
        
        var res = add(redRes, y: greRes)
        var res2 = add(res, y: BluRes)
        
//        col2img(res2, width: width, height: height)
    }
    
    open func acceleratedImageBlurGPU() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("no GPU, aborting");
            return;
        }
        
//        Synchronous
//        device.newComputePipelineStateWithFunction
//        newComputePipelineStateWithFunction()
        
        
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
