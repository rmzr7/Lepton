//
//  LPKMeans.swift
//  Lepton
//
//  Created by Rameez Remsudeen  on 11/30/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import Foundation

struct Cluster {
    let centroid: LPPixel
    let size: Int
}

func kMeans(points:[LPPixel], k:Int, threshold:Float = 0.001) -> ([Cluster], [Int]) {
    let n = points.count
    assert(k <= n, "k cannot be larger than the total number of points")
    
//    creating k centroids
    var centroids = points.randomValues(k)
    
    var memberships = [Int](repeating: -1, count: n)
    var clusterSizes = [Int](repeating: 0, count: k)
    
    var squaresError:Float = 0
    var prevSquaresError:Float = 0
    
    
    repeat {
        prevSquaresError = squaresError
        squaresError = 0
        var newCentroidRed = [Int](repeating: 0,count:k)
        var newCentroidGreen = [Int](repeating: 0,count:k)
        var newCentroidBlue = [Int](repeating: 0,count:k)
        
        var newClusterSizes = [Int](repeating: 0, count: k)
        
        for i in 0..<n {
            let point = points[i]
            let clusterIndex = findNearestCluster(point, centroids: centroids, k: k)
            if memberships[i] != clusterIndex {
                squaresError += 1
                memberships[i] = clusterIndex
            }
            newClusterSizes[clusterIndex] += 1
            newCentroidRed[clusterIndex] = newCentroidRed[clusterIndex] + Int(point.red)
            newCentroidGreen[clusterIndex] = newCentroidGreen[clusterIndex] + Int(point.green)
            newCentroidBlue[clusterIndex] = newCentroidBlue[clusterIndex] + Int(point.blue)
        }
        
        for i in 0..<k {
            let size = newClusterSizes[i]
            if size > 0 {
                
                centroids[i].red = (Float(newCentroidRed[i]) / Float(size)).toUInt8()
                centroids[i].green = (Float(newCentroidGreen[i]) / Float(size)).toUInt8()
                centroids[i].blue = (Float(newCentroidBlue[i]) / Float(size)).toUInt8()

            }
        }
        
        clusterSizes = newClusterSizes
    } while abs(squaresError - prevSquaresError) > threshold
    
    let clusters = zip(centroids, clusterSizes).map { Cluster(centroid: $0, size: $1) }
    return (clusters, memberships)
}

private func findNearestCluster(_ point: LPPixel, centroids: [LPPixel], k: Int) -> Int {
    var minDistance = Float.infinity
    var clusterIndex = 0
    for i in 0..<k {
        let distance = colorDifference(color1: point, color2: centroids[i])
        if distance < minDistance {
            minDistance = distance
            clusterIndex = i
        }
    }
    return clusterIndex
}

private func randomNumberInRange(_ range: Range<Int>) -> Int {
    let interval = range.upperBound - range.lowerBound - 1
    let buckets = Int(RAND_MAX) / interval
    let limit = buckets * interval
    var r = 0
    repeat {
        r = Int(arc4random())
    } while r >= limit
    return range.lowerBound + (r / buckets)
}

private extension Array {
    func randomValues(_ num: Int) -> [Element] {
        
        var indices = [Int]()
        indices.reserveCapacity(num)
        let range: Range<Int> = 0..<self.count
        for _ in 0..<num {
            var random = 0
            repeat {
                random = randomNumberInRange(range)
            } while indices.contains(random)
            indices.append(random)
        }
        
        return indices.map { self[$0] }
    }
}
