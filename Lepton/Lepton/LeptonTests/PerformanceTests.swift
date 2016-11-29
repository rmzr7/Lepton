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
    var gaussian:LPMask!
    var bundle:Bundle!
    var image:UIImage!
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        bundle = Bundle(for: type(of: self))
//        image = 
        image = UIImage(named: "seaSideTest.jpg", in: bundle, compatibleWith: nil)
        gaussian = lepton.makeGaussianFilter(10)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCPUPerformance() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            var blurImage = self.lepton.blurImage(self.image, mask: self.gaussian)
        }
    }
    
    func testCPUSIMDPerformance() {
        self.measure {
            var blurImage = self.lepton.acceleratedBlurImageCPU(self.image, mask: self.gaussian)
        }
    }
    
}
