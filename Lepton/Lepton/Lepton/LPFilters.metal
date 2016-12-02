///
//  LPFilters.metal
//  Lepton
//
//  Created by Rameez Remsudeen  on 11/29/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void gaussian_filter(texture2d<uint, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::read> mask [[texture(1)]],
                            texture2d<uint, access::write> outTexture [[texture(2)]],
                            uint2 gid [[thread_position_in_grid]] ) {
    //return;
    int width = mask.get_width();
    int radius = width/2;
    
//    insertDebugSignpost()
    float4 rgba(0,0,0,0);
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < width; j++) {
            uint2 maskIdx(i,j);
            uint2 imgIdx(gid.x + (i - radius), gid.y + (j - radius));
            uint4 color = inTexture.read(imgIdx).rgba;
            float4 fcolor = float4(float(color[0]), float(color[1]), float(color[2]), float(color[3]));
            float4 weight = mask.read(maskIdx).rrrr;
            rgba += weight * fcolor;
        }
    }
    
    outTexture.write(16777215, gid);
}
