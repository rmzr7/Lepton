//
//  LPColorUtils.swift
//  Lepton
//
//  Created by Rameez Remsudeen  on 11/30/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Foundation

func colorDifference(color1:LPPixel, color2:LPPixel) -> Float {
    let (r1,g1,b1) = color1.rgb()
    let (r2,g2,b2) = color2.rgb()
    
    return pow(Float(r2) - Float(r1), 2) + pow(Float(g2) - Float(g1), 2) + pow(Float(b2) - Float(b1), 2)
}
