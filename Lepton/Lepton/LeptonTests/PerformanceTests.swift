//
//  PerformanceTests.swift
//  Lepton
//
//  Created by Rameez Remsudeen  on 11/26/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import XCTest
import UIKit
@testable import Lepton


class PerformanceTests: XCTestCase {
    
    var lepton = LPImageFilter()
    var kmeans = LPImageSegment()
    var gaussian:LPMask!
    var bundle:Bundle!
    var image:UIImage!
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        bundle = Bundle(for: type(of: self))
//        image = 
        image = UIImage(named: "500x500.png", in: bundle, compatibleWith: nil)
        gaussian = lepton.GaussianFilterGenerator(2)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBlurPerformance() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            self.lepton.blurImage(self.image, mask: self.gaussian)
        }
    }
    
    func testSIMDBlurPerformance() {
        self.measure {
            self.lepton.acceleratedBlurImageCPU(self.image, mask: self.gaussian)
        }
    }
    
    func testGPUBlurPerformance() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            self.lepton.acceleratedImageBlurGPU(self.image, mask: self.gaussian)
        }
    }
    
    func testKMeansPerformance() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            self.kmeans.kmeansSegment(self.image, k:8, threshold:0.001)
        }
    }
    
    func testGPUKMeansPerformance() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            self.kmeans.KMeansGPU(self.image, k:8, threshold:0.001)
        }
    }
    
}
