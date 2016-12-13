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
};

struct debugBuff {
    int idx;
};

device float powerDiff(float r1, float r2) {
    return (r1-r2)*(r1-r2);
//    return 4;
}

device float colorDifference(float4 color1, float4 color2) {
    float r1 = color1.r;
    float g1 = color1.g;
    float b1 = color1.b;
    
    float r2 = color2.r;
    float g2 = color2.g;
    float b2 = color2.b;
    
//    float p2 = pow(r2-r1, 2);
    return powerDiff(r1,r2) + powerDiff(g1,g2) + powerDiff(b1,b2)
                                                           ;
//                                                           return 4;
}

device float4 intToFloat4(int centroid) {
    
    float red = float(uint(centroid & 0xFF));
    float green = float(uint((centroid >> 8) & 0xFF));
    float blue = float(uint((centroid >> 16) & 0xFF));
    float alpha = 1;
    
    return (red, green, blue, alpha);
    
}

// TODO: check correctness of this kernel
kernel void findNearestCluster(texture2d<float, access::read> inTexture [[texture(0)]],
                               device int* memberships [[buffer(0)]],
                               device float* red [[buffer(1)]],
                               device float* green [[buffer(2)]],
                               device float* blue [[buffer(3)]],
                               device uint* centroids [[buffer(4)]],
                               device uint* clusterSizes [[buffer(5)]],
                               device uint* membershipChanged [[buffer(6)]],
                               constant KMeansParams &params [[buffer(7)]],
                               device uint* debug [[buffer(8)]],
                               uint2 gid [[thread_position_in_grid]],
                               uint2 bid [[threadgroup_position_in_grid]],
                               uint2 num_groups [[threadgroups_per_grid]]){
    
    int imageWidth = inTexture.get_width();
    int imageHeight = inTexture.get_height();
    
    if (gid.x >= imageWidth|| gid.y >= imageHeight)
        return;
    
    float colorDiff = MAXFLOAT;
    int nearestCentroid = 0;
    int size = 0;
    int k = params.k;
    int currentCentroid = 0;
    float4 pixelColor = inTexture.read(gid).rgba;
    for (int i = 0; i < k; i++) {
        int centroid = centroids[i];
        float4 centroidColor = intToFloat4(centroid);
        float pointCentroidColorDiff = colorDifference(pixelColor, centroidColor);

        if (pointCentroidColorDiff < colorDiff) {
            colorDiff = pointCentroidColorDiff;
            size = clusterSizes[i];
            nearestCentroid = centroids[i];
            currentCentroid = i;
        }
    }

    int imgIdx = gid.y * imageWidth + gid.x;

    if (memberships[imgIdx] != nearestCentroid) {
        membershipChanged[imgIdx] = 1;
    }
    
    int tIdx = bid.y * num_groups.x + bid.x;
    int bufIdx = currentCentroid * num_groups.x * num_groups.y + tIdx;
    
    threadgroup atomic_int clusterSize;
    atomic_store_explicit(&clusterSize, (clusterSizes[bufIdx]), memory_order_relaxed);
    atomic_fetch_add_explicit(&clusterSize, 1, memory_order_relaxed);
    clusterSizes[bufIdx] = atomic_load_explicit(&clusterSize, memory_order_relaxed);
    
    threadgroup atomic_int pixelR;
    atomic_store_explicit(&pixelR, int((red[bufIdx])), memory_order_relaxed);
    atomic_store_explicit(&pixelR, 1, memory_order_relaxed);
    atomic_fetch_add_explicit(&pixelR, 1, memory_order_relaxed);
    red[bufIdx] = float(atomic_load_explicit(&pixelR, memory_order_relaxed));

    threadgroup atomic_int pixelG;
    atomic_store_explicit(&pixelG, (green[bufIdx]), memory_order_relaxed);
    atomic_fetch_add_explicit(&pixelG, 1, memory_order_relaxed);
    green[bufIdx] = atomic_load_explicit(&pixelG, memory_order_relaxed);

    threadgroup atomic_int pixelB;
    atomic_store_explicit(&pixelB, (blue[bufIdx]), memory_order_relaxed);
    atomic_fetch_add_explicit(&pixelB, 1, memory_order_relaxed);
    blue[bufIdx] = atomic_load_explicit(&pixelB, memory_order_relaxed);
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
        float4 rgba = intToFloat4(int(centroid));
        outTexture.write(rgba, gid);
}

