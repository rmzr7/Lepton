//
//  LPKMeans.metal
//  Lepton
//
//  Created by Rameez Remsudeen  on 12/7/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct KMeansParams {
    int k;
};

device float colorDifference(float4 color1, float4 color2) {
    float r1 = color1.r;
    float g1 = color1.g;
    float b1 = color1.b;
    
    float r2 = color2.r;
    float g2 = color2.g;
    float b2 = color2.b;
    
    return pow(r2-r1, 2) + pow(g2-g1, 2) + pow(b2-b1, 2);
}



// TODO: check correctness of this kernel
kernel void findNearestCluster(texture2d<float, access::read> inTexture [[texture(0)]],
                               device int* memberships [[buffer(1)]],
                               device float* red [[buffer(2)]],
                               device float* green [[buffer(3)]],
                               device float* blue [[buffer(4)]],
                               device int* centroids [[buffer(5)]],
                               device int* clusterSizes [[buffer(6)]],
                               device int* membershipChanged [[buffer(7)]],
                               constant KMeansParams &k [[buffer(8)]]
                               constant
                               uint2 gid [[thread_position_in_grid]]) {
    
    float colorDiff = FLT_MAX;
    int nearestCentroid = -1;
    int imageWidth = inTexture.imageWidth;
    int imageHeight = inTexture.imageHeight;
    for (int i = 0; i < k; i++) {
        float4 centroidColor = centroids[i].rgba;
        float4 pixelColor = inTexture.read(gid).rgba;
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
    
    atomic_fetch_add_explicit(&clusterSizes[nearestCentroid], 1, memory_order_relaxed);
    atomic_fetch_add_explicit(&red[nearestCentroid], pixelColor.r, memory_order_relaxed);
    atomic_fetch_add_explicit(&green[nearestCentroid], pixelColor.g, memory_order_relaxed);
    atomic_fetch_add_explicit(&blue[nearestCentroid], pixelColor.b, memory_order_relaxed);

}

// NEW: this is the kernel for the last loop in kmeansSegment in LPImageSegment.swift
kernel void applyClusterColors(texture2d<float, access::read> inTexture [[texture(0)]],
                               device uint* centroids [[buffer(1)]],
                               device uint* memberships [[buffer(2)]],
                               texture2d<float, access::write> outTexture [[texture(3)]],
                               uint2 gid [[thread_position_in_grid]]) {
    
    int width = inTexture.imageWidth;
    int i = gid.x * width + gid.y;
    uint membership = memberships[i];
    uint centroid = centroids[membership];
    uint2 centroidImgIdx(centroid / width, centroid % width);
    float4 rgba = inTexture.read(centroidImgIdx).rgba;
    rgba.a = 1;
    outTexture.write(rgba, gid);
}


