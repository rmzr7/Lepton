//
//  img2col.swift
//  Lepton
//
//  Created by William Tong on 11/17/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Accelerate

/// Extracting RGB channels from RGBA representation
public func extractChannels(_ imageRGBA:RGBA)-> (redMatrix: [Float], greenMatrix: [Float], blueMatrix: [Float])
    //(redMatrix:Matrix<Float>, blueMatrix:Matrix<Float>, greenMatrix:Matrix<Float>)
{
    
    let width = imageRGBA.width
    let height = imageRGBA.height
        
    var redMatrix = [Float](repeating: 0.0, count: width*height)//Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
    var greenMatrix = [Float](repeating: 0.0, count: width*height)//Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
    var blueMatrix = [Float](repeating: 0.0, count: width*height)//Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
    
    for idx in 0..<height * width {
        let pixel = imageRGBA.pixels[idx]
        redMatrix[idx] = Float(pixel.red)
        greenMatrix[idx] = Float(pixel.green)
        blueMatrix[idx] = Float(pixel.blue)
    }
    
    /*for y in 0..<height {
        for x in 0..<width {
            let idx = y*width + x
            let pixel = imageRGBA.pixels[idx]
            redMatrix[idx] = Float(pixel.red)
            greenMatrix[idx] = Float(pixel.green)
            blueMatrix[idx] = Float(pixel.blue)
        }
    }*/
    
    return (redMatrix, greenMatrix, blueMatrix)
}

public func combineChannels(_ imageRGBA:RGBA, redValues:[UInt8], greenValues:[UInt8], blueValues:[UInt8]) -> RGBA {
    
    let width = imageRGBA.width
    let height = imageRGBA.height
    let pixels = imageRGBA.pixels
    
    for idx in 0..<height * width {
        var pixel = pixels[idx]
        pixel.red = redValues[idx]
        pixel.green = greenValues[idx]
        pixel.blue = blueValues[idx]
    }
    
    return imageRGBA
}

/*public func addPadding(_ channel:inout Matrix<Float>, filterRadius: Int) -> Matrix<Float> {
    let h = channel.rows
    let w = channel.columns
    let padding = 2 * filterRadius
    let paddedMatrixHeight = h + padding
    let paddedMatrixWidth = w + padding
    var paddedMatrix = Matrix<Float>(rows: paddedMatrixHeight, columns: paddedMatrixWidth, repeatedValue: 0)
    for row in 0..<h {
        vDSP_mmov(&channel[row, 0], &paddedMatrix[row + filterRadius, filterRadius], vDSP_Length(w), 1, vDSP_Length(w), vDSP_Length(paddedMatrixWidth))
    }
    return paddedMatrix
}*/

/*public func img2col(_ channel:Matrix<Float>, filterLen:Int) -> Matrix<Float> {
    
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
    
    // write parallel version by padding image matrix (using vDSP_mmov) then calling vDSP_imgfir
    
    // 
    
    return imgMatrix
}*/

/*public func filter2col(_ filter:Matrix<Float>) -> Matrix<Float> {
    let filterRows = filter.rows
    var filtMatrix = Matrix<Float>(rows: filterRows * filterRows, columns: 1, repeatedValue: 0)
    for row in 0..<filtMatrix.rows {
        let r = row / filterRows
        let c = row % filterRows
        filtMatrix[row, 0] = filter[r, c]
    }
    return filtMatrix
}*/

/*public func col2img(_ col:[Float], width:Int, height:Int) -> [Float] {
    var img = Matrix<Float>(rows: height, columns: width, repeatedValue: 0)
    for r in 0..<height {
        for c in 0..<width {
            img[r, c] = col[ r * height + c ]
        }
    }
    return img.grid
}*/



