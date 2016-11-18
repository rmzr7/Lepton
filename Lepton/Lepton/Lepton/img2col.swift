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
    var blueMat = Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
    for y in 0..<height {
        for x in 0..<width {
            let idx = y*width + x
            let pixel = imageRGBA.pixels[idx]
            redMatrix[y,x] = Float(pixel.red)
            greenMatrix[y,x] = Float(pixel.green)
            blueMat[y,x] = Float(pixel.blue)
        }
    }
    
    return (redMatrix, greenMatrix, blueMat)
}

public func img2col(channel:[[UInt32]], filterLen:Int) -> ([[UInt32]]) {
    var imgMatrix = [[UInt32]]()
    let imageHeight = channel.count
    let imageWidth = channel[0].count
    let radius = filterLen / 2
    for row in 0..<imageHeight {
        for col in 0..<imageWidth {
            var conv = [UInt32]()
            let start_x = col - radius
            let end_x = col + radius
            let start_y = row - radius
            let end_y = row + radius
            for r in start_y...end_y {
                for c in start_x...end_x {
                    if r >= 0 && r < imageHeight && c >= 0 && c < imageWidth {
                        conv.append(channel[r][c])
                    } else {
                        conv.append(0)
                    }
                }
            }
            imgMatrix.append(conv)
        }
    }
    
    return imgMatrix
}

public func convolve(imgcol:[[UInt32]], filter:[[Double]]) -> ([[UInt32]]) {
    
}