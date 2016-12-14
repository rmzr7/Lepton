//
//  LPKMeans.metal
//  Lepton
//
//  Created by Rameez Remsudeen  on 12/7/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//


#include <metal_stdlib>
#include <metal_compute>
#include <metal_atomic>
#include <metal_math>

using namespace metal;

struct KMeansParams {
    int k;
    int numRegionsWidth;
    int numRegionsHeight;
};

struct debugBuff {
    int idx;
};

device uint powerDiff(uint c1, uint c2) {
    uint diff;
    if (c1 > c2)
        diff = c1 - c2;
    else
        diff = c2 - c1;
    return diff * diff;
}

device uint colorDifference(uint4 color1, uint4 color2) {
//    float r1 = color1.r;
//    float g1 = color1.g;
//    float b1 = color1.b;
//    
//    float r2 = color2.r;
//    float g2 = color2.g;
//    float b2 = color2.b;
    
    uint r1 = color1.r;
    uint g1 = color1.g;
    uint b1 = color1.b;
    
    uint r2 = color2.r;
    uint g2 = color2.g;
    uint b2 = color2.b;
    
    return powerDiff(r1,r2) + powerDiff(g1,g2) + powerDiff(b1,b2);
}

device uint4 intToUInt4(int centroid) {
    
//    float red = float(uint(centroid & 0xFF));
//    float green = float(uint((centroid >> 8) & 0xFF));
//    float blue = float(uint((centroid >> 16) & 0xFF));
    uint red = uint(centroid & 0xFF);
    uint green = uint((centroid >> 8) & 0xFF);
    uint blue = uint((centroid >> 16) & 0xFF);
//    if (red > 255)
//        red = 255;
//    if (green > 255)
//        green = 255;
//    if (blue > 255)
//        blue = 255;
    uint alpha = 255;
    
    return (red, green, blue, alpha);
    
}

// TODO: check correctness of this kernel
kernel void findNearestCluster(texture2d<uint, access::read> inTexture [[texture(0)]],
                               device int* memberships [[buffer(0)]],
                               device uint* red [[buffer(1)]],
                               device uint* green [[buffer(2)]],
                               device uint* blue [[buffer(3)]],
                               device uint* centroids [[buffer(4)]],
                               device uint* clusterSizes [[buffer(5)]],
                               device uint* membershipChanged [[buffer(6)]],
                               constant KMeansParams &params [[buffer(7)]],
                               device uint* debug [[buffer(8)]],
                               uint2 gid [[thread_position_in_grid]],
                               uint2 bid [[threadgroup_position_in_grid]]){
    
    uint colorDiff = 4294967295;
    int k = params.k;
    int numRegionsWidth = params.numRegionsWidth;
    int numRegionsHeight = params.numRegionsHeight;
    int clusterIndex = -1;
    uint4 pixelColor = inTexture.read(gid).rgba;
    for (int i = 0; i < k; i++) {
        int centroid = centroids[i];
        uint4 centroidColor = intToUInt4(centroid);
        uint pointCentroidColorDiff = colorDifference(pixelColor, centroidColor);

        if (pointCentroidColorDiff < colorDiff) {
            colorDiff = pointCentroidColorDiff;
            clusterIndex = i;
        }
    }
    
    threadgroup_barrier(mem_flags::mem_threadgroup);

    uint imageWidth = inTexture.get_width();
    uint imageHeight = inTexture.get_height();
    
    if (gid.x >= imageWidth|| gid.y >= imageHeight)
        return;
    
    int imgIdx = gid.y * imageWidth + gid.x;

    if (memberships[imgIdx] != clusterIndex) {
        membershipChanged[imgIdx] = 1;
        memberships[imgIdx] = clusterIndex;
    }
    
    int tIdx = bid.y * numRegionsWidth + bid.x;
    int bufIdx = clusterIndex * numRegionsWidth * numRegionsHeight + tIdx;
    
    //threadgroup_barrier(mem_flags::mem_threadgroup);
    
    threadgroup atomic_uint clusterSize;
    atomic_store_explicit(&clusterSize, (clusterSizes[bufIdx]), memory_order_relaxed);
    atomic_fetch_add_explicit(&clusterSize, 1, memory_order_relaxed);
    clusterSizes[bufIdx] = atomic_load_explicit(&clusterSize, memory_order_relaxed);
    
    //threadgroup_barrier(mem_flags::mem_threadgroup);
    
    threadgroup atomic_uint pixelR;
    atomic_store_explicit(&pixelR, red[bufIdx], memory_order_relaxed);
    //atomic_store_explicit(&pixelR, 1, memory_order_relaxed);
    atomic_fetch_add_explicit(&pixelR, pixelColor.r, memory_order_relaxed);
    red[bufIdx] = atomic_load_explicit(&pixelR, memory_order_relaxed);
    
    //threadgroup_barrier(mem_flags::mem_threadgroup);

    threadgroup atomic_uint pixelG;
    atomic_store_explicit(&pixelG, green[bufIdx], memory_order_relaxed);
    atomic_fetch_add_explicit(&pixelG, pixelColor.g, memory_order_relaxed);
    green[bufIdx] = atomic_load_explicit(&pixelG, memory_order_relaxed);
    
    //threadgroup_barrier(mem_flags::mem_threadgroup);

    threadgroup atomic_uint pixelB;
    atomic_store_explicit(&pixelB, blue[bufIdx], memory_order_relaxed);
    atomic_fetch_add_explicit(&pixelB, pixelColor.b, memory_order_relaxed);
    blue[bufIdx] = atomic_load_explicit(&pixelB, memory_order_relaxed);
    
    //threadgroup_barrier(mem_flags::mem_threadgroup);
}

kernel void applyClusterColors(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               device uint* centroids [[buffer(0)]],
                               device uint* memberships [[buffer(1)]],
                               uint2 gid [[thread_position_in_grid]]) {
    
    int imageWidth = inTexture.get_width();
    int imageHeight = inTexture.get_height();
    if (gid.x >= imageWidth || gid.y >= imageHeight)
        return;
    int index = gid.y * imageWidth + gid.x;
    int membership = memberships[index];
    uint centroid = centroids[membership];
    //uint4 rgba = intToUInt4(int(centroid));
    //rgba.g = 255;
    //rgba.a = 255;
    outTexture.write(centroid, gid);
}

