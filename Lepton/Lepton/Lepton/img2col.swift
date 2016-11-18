//
//  img2col.swift
//  Lepton
//
//  Created by William Tong on 11/17/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Accelerate

/// Extracting RGB channels from RGBA representation
public func extractChannels(imageRGBA:RGBA)-> (redMatrix:Matrix<Float>, blueMatrix:Matrix<Float>, greenMatrix:Matrix<Float>) {
    
    let width = imageRGBA.width
    let height = imageRGBA.height

    var redMatrix = Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
    var greenMatrix = Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
    var blueMatrix = Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
    for y in 0..<height {
        for x in 0..<width {
            let idx = y*width + x
            let pixel = imageRGBA.pixels[idx]
            redMatrix[y,x] = Float(pixel.red)
            greenMatrix[y,x] = Float(pixel.green)
            blueMatrix[y,x] = Float(pixel.blue)
        }
    }
    
    return (redMatrix, greenMatrix, blueMatrix)
}

public func img2col(channel:Matrix<Float>, filterLen:Int) -> Matrix<Float> {
    
    let imageHeight = channel.rows
    let imageWidth = channel.columns
    var imgMatrix = Matrix<Float>(rows: imageHeight * imageWidth, columns: filterLen * filterLen, repeatedValue: 0)
    let radius = filterLen / 2
    for row in 0..<imageHeight {
        for col in 0..<imageWidth {
            
//            let start_x = col - radius
//            let end_x = col + radius
//            let start_y = row - radius
//            let end_y = row + radius
            
            
            for r in -1 * radius...radius {
                for c in -1 * radius...radius {
                    let y = row + r
                    let x = col + c
                    var val:Float
                    if y >= 0 && y < imageHeight && x >= 0 && x < imageWidth {
                        val = channel[y,x]
                    } else {
                        val = 0.0
                    }
                    imgMatrix[row * imageWidth + col, (r + radius) * filterLen + (c + radius)] = val
                }
            }
            
//            for r in start_y...end_y {
//                for c in start_x...end_x {
//                    var val:Float
//                    if r >= 0 && r < imageHeight && c >= 0 && c < imageWidth {
//                        val = channel[r,c]
//                    } else {
//                        val = 0.0
//                    }
//                    imgMatrix[row * imageWidth + col, (r + radius) * filterLen + (c + radius)] = val
//                }
//            }
        }
    }
    
    return imgMatrix
}

