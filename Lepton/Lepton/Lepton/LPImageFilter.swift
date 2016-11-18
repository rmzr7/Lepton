//
//  LPImageFilter.swift
//  Lepton
//
//  Created by Rameez Remsudeen on 11/14/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import UIKit
import Accelerate


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


public class LPImageFilter: NSObject {
    public override init() {
        super.init()
    }
    
    public func blurImage(image:UIImage, mask:LPMask = LPMask()) -> UIImage? {
        
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

    
    public func makeGaussianFilter(radius:Int) -> LPMask {
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
    
    public func acceleratedBlurImageCPU(image:UIImage, kernel:[[Float]]) {
        
        
        //        get pixel data
        //        get channels
        //        apply img to col each channel
        
        var pixels = RGBA(image: image)!
        var filter = Matrix<Float>(kernel)
        let width = pixels.width
        let height = pixels.height
        
        
        var (red, green, blue) = extractChannels(pixels)
        let kernelWidth = kernel.count
        
        var redColMat = img2col(red, filterLen: kernelWidth)
        var greenColMat = img2col(green, filterLen: kernel.count)
        var blueColMat = img2col(blue, filterLen: kernel.count)
        var filtColMat = filter2col(filter)
        
        
        var redProd = redColMat * filtColMat
        var greenProd = greenColMat * filtColMat
        var blueProd = blueColMat * filtColMat
        
        var redArr = redProd.grid
        var gArr = greenProd.grid
        var bArr = blueProd.grid
        
        var zeros = [Float](count: width*height, repeatedValue: 0)
        var TFF = [Float](count: width*height, repeatedValue: 255)
        
        var redRes = [Float](count: width*height, repeatedValue: 0)
        var greRes = [Float](count: width*height, repeatedValue: 0)
        var BluRes = [Float](count: width*height, repeatedValue: 0)
        
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
    
    public func oneDtoTwoD(oneD:[Float], height:Int, width:Int) -> Matrix<Float>{
        var mat = Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
        
        for i in 0..<height {
            for j in 0..<width {
            mat[i, j] = oneD[(j*height)+i]
            }
        }
        return mat
    }
}