///
//  LPFilters.metal
//  Lepton
//
//  Created by Rameez Remsudeen  on 11/29/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void gaussian_filter(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::read> mask [[texture(1)]],
                            texture2d<float, access::write> outTexture [[texture(2)]],
                            uint2 gid [[thread_position_in_grid]] ) {
    //return;
    int width = mask.get_width();
    int radius = width/2;
    
    float4 rgba(0,0,0,0);
    for (int j = 0; j < width; j++) {
        for (int i = 0; i < width; i++) {
            uint2 maskIdx(i,j);
            uint2 imgIdx(gid.x + (i - radius), gid.y + (j - radius));
            float4 color = inTexture.read(imgIdx).rgba;
            float4 weight = mask.read(maskIdx).rrrr;
            rgba += color * weight;
        }
    }
    rgba.a = 1;
    outTexture.write(rgba, gid);
}
