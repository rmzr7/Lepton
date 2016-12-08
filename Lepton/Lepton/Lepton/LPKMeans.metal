//
//  LPKMeans.metal
//  Lepton
//
//  Created by Rameez Remsudeen  on 12/7/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

device float colorDifference(float4 color1, float4 color2) {
    float r1 = color1.r;
    float g1 = color1.g;
    float b1 = color1.b;
    
    float r2 = color2.r;
    float g2 = color2.g;
    float b2 = color2.b;
    
    return pow(r2-r1, 2) + pow(g2-g1, 2) + pow(b2-b1, 2);
}

kernel void findNearestCluster(texture2d<float, access::read> inTexture [[texture(0)]],
                               device uint* memberships [[buffer(1)]],
                               device float* red [[buffer(2)]],
                               device float* green [[buffer(3)]],
                               device float* blue [[buffer(4)]],
                               device int* centroids [[buffer(5)]],
                               device int* clusterSizes [[buffer(6)]],
                               uint k,
                               uint2 gid [[thread_position_in_grid]]) {
    
    float colorDiff = FLT_MAX;
    int nearestCentroid = -1;
    int imageWidth = inTexture.imageWidth;
    int imageHeight = inTexture.imageHeight;
    for (int i = 0; i < k; i++) {
        uint centroid = centroids[i];
        uint centroid_x = centroid / imageWidth;
        uint centroid_y = centroid % imageWidth;
        float4 pixelColor = inTexture.read(gid).rgba;
        float4 centroidColor = inTexture.read(centroid_x, centroid_y).rgba;
        float pointCentroidColorDiff = colorDifference(pixelColor, centroidColor);
        
        if (pointCentroidColorDiff < colorDiff) {
            colorDiff = pointCentroidColorDiff;
            nearestCentroid = centroid;
        }
    }
    
    int imgIdx = gid.x * imageWidth + gid.y
    if (memberships[imgIdx] != nearestCentroid) {
        memberships[imgIdx] = nearestCentroid;
        membershipChanged[imgIdx] = 1;
    }
    
}
