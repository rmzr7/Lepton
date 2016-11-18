//
//  img2col.swift
//  Lepton
//
//  Created by William Tong on 11/17/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Accelerate


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