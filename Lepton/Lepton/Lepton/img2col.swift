//
//  img2col.swift
//  Lepton
//
//  Created by William Tong on 11/17/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Accelerate

/// Extracting RGB channels from RGBA representation
public func extractChannels(_ imageRGBA:RGBA)-> (redMatrix:Matrix<Float>, blueMatrix:Matrix<Float>, greenMatrix:Matrix<Float>) {
    
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

public func combineChannels(_ imageRGBA:RGBA, redValues:[UInt8], greenValues:[UInt8], blueValues:[UInt8]) -> RGBA {
    
    let width = imageRGBA.width
    let height = imageRGBA.height
    let pixels = imageRGBA.pixels
    
    for y in 0..<height {
        for x in 0..<width {
            let idx = y*width + x
            var pixel = pixels[idx]
            pixel.red = redValues[idx]
            pixel.green = greenValues[idx]
            pixel.blue = blueValues[idx]
        }
    }
    
    return imageRGBA
}


public func img2col(_ channel:Matrix<Float>, filterLen:Int) -> Matrix<Float> {
    
    let imageHeight = channel.rows
    let imageWidth = channel.columns
    var imgMatrix = Matrix<Float>(rows: imageHeight * imageWidth, columns: filterLen * filterLen, repeatedValue: 0)
    let radius = filterLen / 2
    for row in 0..<imageHeight {
        for col in 0..<imageWidth {
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
        }
    }
    
    return imgMatrix
}

public func filter2col(_ filter:Matrix<Float>) -> Matrix<Float> {
    let filterRows = filter.rows
    var filtMatrix = Matrix<Float>(rows: filterRows * filterRows, columns: 1, repeatedValue: 0)
    for row in 0..<filtMatrix.rows {
        let r = row / filterRows
        let c = row % filterRows
        filtMatrix[row, 0] = filter[r, c]
    }
    return filtMatrix
}

public func col2img(_ col:[Float], width:Int, height:Int) -> [Float] {
    var img = Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
    for r in 0..<height {
        for c in 0..<width {
            img[r, c] = col[ r * height + c ]
        }
    }
    return img.grid
}



