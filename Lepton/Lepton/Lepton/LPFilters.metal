//
//  LPFilters.metal
//  Lepton
//
//  Created by Rameez Remsudeen  on 11/29/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void gaussian_filter(texture2d<int, access::read> inTexture [[texture(0)]], texture2d<float, access::read> mask [[texture(1)]], texture2d<int, access:write> outTexture [[texture(2)]], bid [[thread_position_in_grid]] ) {
    int width = mask.get_width();
    int radius = width/2;
    
    float4 rgba(0,0,0,0);
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < width; i++) {
            uint2 maskIdx(i,j);
            uint2 imgIdx(bid.x + (i - radius), bid.y + (j - radius));
            float4 color = inTexture.read(imgIdx).rgba;
            float4 weight = weights.read(maskIdx).rrrr;
            rgba += weight * color;
        }
    }
    
    outTexture.write(uint4(rgba.rgb, 1) bid);
}
