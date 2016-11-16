//
//  LPImageFilter.swift
//  Lepton
//
//  Created by Rameez Remsudeen on 11/14/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import UIKit
import Accelerate

struct LPMask:NSObject {
    var height
    
}

public class LPImageFilter: NSObject {
    public override init() {
        super.init()
    }
    
    public func blurImage(image:UIImage) -> UIImage? {
        
        let pixels = RGBA(image:image)!
        let width = pixels.width
        let height = pixels.height
        let factor = 1.0
        let bias = 0.0
        for y in 0..<pixels.height {
            for x in 0..<pixels.width {
                let idx = y*pixels.width+x
                var red = 0.0, green = 0.0, blue = 0.0


                for fy in 0..<3 {
                    for fx in 0..<3 {
                        let imageX:Int = (x - 3 / 2 + fx + pixels.width) % width
                        let imageY:Int = (y - 3 / 2 + fy + pixels.height) % height
                        let pixel = pixels.pixels[(imageY * width + imageX)]
                        red += Double(pixel.red) * filter[fy][fx]
                        green += Double(pixel.green) * filter[fy][fx]
                        blue += Double(pixel.blue) * filter[fy][fx]
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

    var filter = [
        [0.2, 0.2, 0.0],
        [0.2, 0.2, 0.2],
        [0.0, 0.2, 0.0]
    ]
    
    
}