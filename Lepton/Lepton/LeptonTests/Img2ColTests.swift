//
//  Img2ColTests.swift
//  Lepton
//
//  Created by William Tong on 11/17/16.
//  Copyright © 2016 Rameez Remsudeen. All rights reserved.
//

import XCTest
@testable import Lepton

class Img2ColTests: XCTestCase {

    let pixels:[[UInt32]] =
    [
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 10, 11, 12],
        [13, 14, 15, 16]
    ]
    let filter:[[Double]] =
    [
        [0.2, 0.8, 0.4],
        [0.0, 1.0, 0.1],
        [0.4, 0.5, 0.0]
    ]
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test1() {
        let (imgMat, filtMat) = img2col(pixels, filter: filter)
        /* 
        imgMat =
            [
                [0, 0, 0, 0, 1, 2, 0, 5, 6],
                [0, 0, 0, 1, 2, 3, 5, 6, 7],
                [0, 0, 0, 2, 3, 4, 6, 7, 8],
                [0, 0, 0, 3, 4, 0, 7, 8, 0],
                [0, 1, 2, 0, 5, 6, 0, 9, 10],
                [1, 2, 3, 5, 6, 7, 9, 10, 11],
                [2, 3, 4, 6, 7, 8, 10, 11, 12],
                [3, 4, 0, 7, 8, 0, 11, 12, 0],
                [0, 5, 6, 0, 9, 10, 0, 13, 14],
                [5, 6, 7, 9, 10, 11, 13, 14, 15],
                [6, 7, 8, 10, 11, 12, 14, 15, 16],
                [7, 8, 0, 11, 12, 0, 15, 16, 0],
                [0, 9, 10, 0, 13, 14, 0, 0, 0],
                [9, 10, 11, 13, 14, 15, 0, 0, 0],
                [10, 11, 12, 14, 15, 16, 0, 0, 0],
                [11, 12, 0, 15, 16, 0, 0, 0, 0]
            ]
        
        */
        XCTAssert(imgMat.count == 16)
        XCTAssert(imgMat[0].count == 9)
        XCTAssert(imgMat[0][8] == 6)
        XCTAssert(imgMat[3][2] == 0)
        XCTAssert(imgMat[4][7] == 9)
        XCTAssert(imgMat[5][3] == 5)
        XCTAssert(imgMat[10][6] == 14)
        
        XCTAssert(filtMat.count == 9)
        XCTAssert(filtMat[0].count == 16)
        XCTAssert(filtMat[0][0] == 0.2)
        XCTAssert(filtMat[0][4] == 0.2)
        XCTAssert(filtMat[4][1] == 1.0)
        XCTAssert(filtMat[4][13] == 1.0)
        XCTAssert(filtMat[8][15] == 0.0)
    }

}
