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
                
                let newR = UInt8(min(max((factor * red + bias), 0), 255))
                let newG = UInt8(min(max((factor * green + bias), 0), 255))
                let newB = UInt8(min(max((factor * blue + bias), 0), 255))
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
}