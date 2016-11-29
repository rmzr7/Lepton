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
        
        let pixels = RGBA(image:image)!
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
        let stddev = Float(1.5)
        let stddev_squared_times_2 = Float(2) * stddev * stddev
        var mask = [[Float]]()
        let pi = Float(M_PI)
        let e = Float(2.78)
        var sum:Float = 0.0
        for y in -1 * radius...radius {
            let float_y = Float(y)
            let y_squared = float_y * float_y
            var row = [Float]()
            for x in -1 * radius...radius {
                let float_x = Float(x)
                let x_squared = float_x * float_x
                let exp = -1.0 * (x_squared + y_squared) / stddev_squared_times_2
                let val = 1/(pi * stddev_squared_times_2) * pow(e, exp)
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
        
        //        get pixel data
        //        get channels
        //        apply img to col each channel
        
        let kernel = mask.mask!
        
        let pixels = RGBA(image: image)!
        let filter = Matrix<Float>(kernel)
        let width = pixels.width
        let height = pixels.height
        
        
        let (red, green, blue) = extractChannels(pixels)
        let kernelWidth = kernel.count
        
//        let redColMat = img2col(red, filterLen: kernelWidth)
//        let greenColMat = img2col(green, filterLen: kernel.count)
//        let blueColMat = img2col(blue, filterLen: kernel.count)
//        let filtColMat = filter2col(filter)

        let redColMat = Matrix<Float>(rows: red.rows * red.columns, columns: kernelWidth*kernelWidth, repeatedValue: 0)
        let greenColMat = Matrix<Float>(rows: red.rows * red.columns, columns: kernelWidth*kernelWidth, repeatedValue: 0)
        let blueColMat = Matrix<Float>(rows: red.rows * red.columns, columns: kernelWidth*kernelWidth, repeatedValue: 0)
        let filtColMat = Matrix<Float>(rows: filter.rows*filter.rows, columns: 1, repeatedValue: 0)
        
        
        let redProd = redColMat * filtColMat
        let greenProd = greenColMat * filtColMat
        let blueProd = blueColMat * filtColMat
        
        var redArr = redProd.grid
        var gArr = greenProd.grid
        var bArr = blueProd.grid
        
        var zeros = [Float](repeating: 0.0, count: width*height)
        var TFF = [Float](repeating: 255.0, count: width*height)
        
        let len = UInt(width * height)
        
        vDSP_vmax(redArr, 1, zeros, 1, &redArr, 1, len)
        vDSP_vmax(gArr, 1, zeros, 1, &gArr, 1, len)
        vDSP_vmax(bArr, 1, zeros, 1, &bArr, 1, len)
        
        vDSP_vmin(redArr, 1, TFF, 1, &redArr, 1, len)
        vDSP_vmin(gArr, 1, TFF, 1, &gArr, 1, len)
        vDSP_vmin(bArr, 1, TFF, 1, &bArr, 1, len)
        
        var redRes = [UInt8](repeating: 0, count: width*height)
        var greRes = [UInt8](repeating: 0, count: width*height)
        var BluRes = [UInt8](repeating: 0, count: width*height)
        
        vDSP_vfixu8(redArr, 1, &redRes, 1, len)
        vDSP_vfixu8(gArr, 1, &greRes, 1, len)
        vDSP_vfixu8(bArr, 1, &BluRes, 1, len)
        
        /*var redShift:Float = pow(2.0, 24.0)
        var greenShift:Float = pow(2.0, 16.0)
        var blueShift:Float = pow(2.0, 8.0)
        vDSP_vsmul(redRes, 1, &redShift, &redRes, 1, len)
        vDSP_vsmul(greRes, 1, &greenShift, &greRes, 1, len)
        vDSP_vsmul(BluRes, 1, &blueShift, &BluRes, 1, len)
        
        var res = add(redRes, y: greRes)
        var res2 = add(res, y: BluRes)*/
        
        return combineChannels(pixels, redValues: redRes, greenValues: greRes, blueValues: BluRes).toUIImage()
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
