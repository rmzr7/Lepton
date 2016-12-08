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

func C(_ a: Float, b: Float) -> Float {
    return sqrt(pow(a, 2) + pow(b, 2))
}

// From http://www.brucelindbloom.com/index.html?Eqn_DeltaE_CIE94.html
func colorDifference2(color1:LPPixel, color2:LPPixel) -> Float {
    let kL:Float = 1
    let kC:Float = 1
    let kH:Float = 1
    let K1:Float = 0.045
    let K2:Float = 0.015
    
    let (r1,g1,b1) = color1.rgb()
    let (r2,g2,b2) = color2.rgb()
    let ΔL = r1 - r2
    
    let (C1, C2) = (C(g1, b: b1), C(g2, b: b2))
    let ΔC = C1 - C2
    
    let ΔH = sqrt(pow(g1 - g2, 2) + pow(b1 - b2, 2) - pow(ΔC, 2))
    
    let Sl: Float = 1
    let Sc = 1 + K1 * C1
    let Sh = 1 + K2 * C1
    
    return pow(ΔL / (kL * Sl), 2) + pow(ΔC / (kC * Sc), 2) + pow(ΔH / (kH * Sh), 2)
}

func randomNumberInRange(_ range: Range<Int>) -> Int {
    let interval = range.upperBound - range.lowerBound - 1
    let buckets = Int(RAND_MAX) / interval
    let limit = buckets * interval
    var r = 0
    repeat {
        r = Int(arc4random())
    } while r >= limit
    return range.lowerBound + (r / buckets)
}
