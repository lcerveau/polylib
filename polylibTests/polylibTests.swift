//
//  polylibTests.swift
//  polylibTests
//
//  Created by Laurent Cerveau on 01/23/2017.
//  Copyright © 2017 MMyneta. All rights reserved.
//

import XCTest
import AppKit
@testable import polylib

class polylibTests: XCTestCase {
        
    func test0CreationDescription() {
        //null polynomial
        var pol = polynomial(coefficients: [])
        XCTAssertEqual(-1, pol.degree)
        XCTAssertEqual("", pol.description)
        
        //null polynomial again, but with one trailing zeros
        pol = polynomial(coefficients: [0.0])
        XCTAssertEqual(-1, pol.degree)
        XCTAssertEqual("", pol.description)
        
        //null polynomial in a even more complexe way,  with more trailing zeros
        pol = polynomial(coefficients: [0.0, 0.0, 0.0])
        XCTAssertEqual(-1, pol.degree)
        XCTAssertEqual("", pol.description)
        
        //Constant unity polynomial
        pol = polynomial(coefficients: [1.0])
        XCTAssertEqual(0, pol.degree)
        XCTAssertEqual("1.0", pol.description)
        
        //Constant unity polynomial with trailing zeros
        pol = polynomial(coefficients: [1.0, 0.0, 0.0])
        XCTAssertEqual(0, pol.degree)
        XCTAssertEqual("1.0", pol.description)
        
        //Identity polynomial
        pol = polynomial(coefficients: [0.0, 1.0])
        XCTAssertEqual(1, pol.degree)
        XCTAssertEqual("X", pol.description)
        
        //Minus Identity polynomial
        pol = polynomial(coefficients: [0.0, -1.0])
        XCTAssertEqual(1, pol.degree)
        XCTAssertEqual("-X", pol.description)
        
        //Arbitrary polynomial
        pol = polynomial(coefficients: [1.0, 1.0, 2.0, 0.0, 2.0])
        XCTAssertEqual(4, pol.degree)
        XCTAssertEqual("1.0+X+2.0X^2+2.0X^4", pol.description)
       
        //Arbitrary polynomial with negative coeeficients
        pol = polynomial(coefficients: [1.0, -1.0, 2.0, 0.0, -2.0])
        XCTAssertEqual(4, pol.degree)
        XCTAssertEqual("1.0-X+2.0X^2-2.0X^4", pol.description)
        
        //Arbitrary polynomial with trailing zeros
        pol = polynomial(coefficients: [1.0, 1.0, 2.0, 0.0, 2.0, 0.0, 0.0])
        XCTAssertEqual(4, pol.degree)
        XCTAssertEqual("1.0+X+2.0X^2+2.0X^4", pol.description)
        
        //Another arbitrary polynomial
        pol = polynomial(coefficients: [-1.0, -2.0, 0.0, 1.0])
        XCTAssertEqual(3, pol.degree)
        XCTAssertEqual("-1.0-2.0X+X^3", pol.description)
        
        let pol1 = polynomial(coefficients: [-1.0, -2.0, 0.0, 1.0])
        XCTAssertEqual(true, pol == pol1)

    }
    
    
    func test1LinearManipulation() {
        
        
        //start with a polynomial
        let pol0 = polynomial(coefficients: [1.0, 1.0, 2.0, 0.0, 2.0])
        XCTAssertEqual(4, pol0.degree)
        XCTAssertEqual("1.0+X+2.0X^2+2.0X^4", pol0.description)
        
        //left constant multiplication
        let pol1 = 3*pol0
        XCTAssertEqual(4, pol1.degree)
        XCTAssertEqual("3.0+3.0X+6.0X^2+6.0X^4", pol1.description)
        
        //right constant multiplication
        let pol2 = pol0*3
        XCTAssertEqual(4, pol2.degree)
        XCTAssertEqual("3.0+3.0X+6.0X^2+6.0X^4", pol2.description)
        
        //0 multiplication
        let pol3 = 0*pol0
        XCTAssertEqual(-1, pol3.degree)
        XCTAssertEqual("", pol3.description)
        
        //addition: same degree
        let pol4 = pol0+pol2
        XCTAssertEqual(4, pol4.degree)
        XCTAssertEqual("4.0+4.0X+8.0X^2+8.0X^4", pol4.description)
        
        //addition: different degree
        let pol6 = polynomial(coefficients: [1.0, 0.0, 0.0, 0.0, 0.0, 1.0])
        let pol7 = pol0+pol6
        XCTAssertEqual(5, pol7.degree)
        XCTAssertEqual("2.0+X+2.0X^2+2.0X^4+X^5", pol7.description)
        
        //addition: use negative value to get inferior degree
        let pol8 = polynomial(coefficients: [1.0, 0.0, 0.0, 1.0, -2.0])
        let pol9 = pol0+pol8
        XCTAssertEqual(3, pol9.degree)
        XCTAssertEqual("2.0+X+2.0X^2+X^3", pol9.description)
        
        //addition: substract a polynomial to itself
        let pol11 = pol0-pol0
        XCTAssertEqual(-1, pol11.degree)
        XCTAssertEqual("", pol11.description)
        
    }

    func test2EvaluationAndDraw() {
        //constant polynomial
        var pol = polynomial(coefficients: [2])
        XCTAssertEqual(2, pol.eval(x: 3))
        
        //identity polynomial
        pol = polynomial(coefficients: [0, 1.0])
        XCTAssertEqual(3, pol.eval(x: 3))
        XCTAssertEqual(-1.0, pol.eval(x: -1.0))
        XCTAssertEqual(0, pol.eval(x: 0))
        
        //arbitrary polynomial
        pol = polynomial(coefficients: [3, 4.0, -1.0, 2.0])
        XCTAssertEqual(3, pol.eval(x: 0))
        XCTAssertEqual(8.0, pol.eval(x: 1.0))
        XCTAssertEqual(-4.0, pol.eval(x: -1.0))
        XCTAssertEqual(60.0, pol.eval(x: 3.0))
        XCTAssertEqual([-4.0, 3.0, 60.0], pol.eval(x: [-1.0, 0.0, 3.0]))
        
        //Draw: first some unacceptable inputs, then simple ones for visual check
        pol = polynomial(coefficients: [2])
        let drawInterval = Float(-10.0)..<Float(10.0)
        var fileURLString = pol.draw(interval:drawInterval, width: -1.0, height: 320.0)
        XCTAssertEqual(fileURLString, "")
        fileURLString = pol.draw(interval:drawInterval, width: 480.0, height: 0.0)
        XCTAssertEqual(fileURLString, "")
        
        fileURLString = pol.draw(interval:drawInterval, width: 800.0, height: 600.0, folderPath: "/Users/lcerveau/Desktop", options: nil)
        print(fileURLString)
        
        pol = polynomial(coefficients: [0, 1])
        fileURLString = pol.draw(interval:drawInterval, width: 800.0, height: 600.0, folderPath: "/Users/lcerveau/Desktop", options: nil)
        print(fileURLString)
        
        pol = polynomial(coefficients: [0, 0, 1])
        fileURLString = pol.draw(interval:drawInterval, width: 800.0, height: 600.0, folderPath: "/Users/lcerveau/Desktop", options: nil)
        print(fileURLString)
        
        pol = polynomial(coefficients: [1, 0, -1, 2])
        fileURLString = pol.draw(interval:Float(-1.0)..<Float(1.0), width: 800.0, height: 600.0, folderPath: "/Users/lcerveau/Desktop", options: nil)
        print(fileURLString)
        
        
        pol = polynomial(coefficients: [1, 0, 0, 2, 0, 0, 0, 0, 0, 0, -2, 4])
        fileURLString = pol.draw(interval:Float(-1.0)..<Float(1.0), width: 800.0, height: 600.0, folderPath: "/Users/lcerveau/Desktop", options: nil)
        print(fileURLString)
        
    }
    
    func test3ProductAndDivide() {
        //polynomial multiplication
        var pol0 = polynomial(coefficients: [1.0])
        var pol1 = polynomial(coefficients: [2.0, 0.0, 1.0, 1.0])
        var mpol = pol0*pol1
        XCTAssertEqual(true, mpol == pol1)
        
        pol0 = polynomial(coefficients: [0.0, 2.0])
        mpol = pol0*pol1
        XCTAssertEqual(pol1.degree+1, mpol.degree)
        XCTAssertEqual("4.0X+2.0X^3+2.0X^4", mpol.description)
    
        pol0 = polynomial(coefficients: [1.0, 1.0, 2.0, 0.0, 1.0])
        pol1 = polynomial(coefficients: [2.0, 0.0, 1.0, 1.0])
        mpol = pol0*pol1
        XCTAssertEqual(7, mpol.degree)
        XCTAssertEqual("2.0+2.0X+5.0X^2+2.0X^3+5.0X^4+2.0X^5+X^6+X^7", mpol.description)
        
        pol0 = polynomial(coefficients: [2.0, 5.0, 2.0])
        pol1 = polynomial(coefficients: [1.0, 2.0, 2.0])
        var dpol = pol0 % pol1
        XCTAssertEqual("1.0", dpol.description)
        
        pol0 = polynomial(coefficients: [2.0, 5.0, 2.0])
        pol1 = polynomial(coefficients: [1.0, 2.0, 2.0, 7.0])
        dpol = pol0 % pol1
        XCTAssertEqual("", dpol.description)
        
        pol0 = polynomial(coefficients: [2.0, 5.0, 2.0, 1.0, 4.0])
        pol1 = polynomial(coefficients: [1.0, 2.0, 2.0])
        dpol = pol0 % pol1
        XCTAssertEqual("1.5-1.5X+2.0X^2", dpol.description)
        
    }
    
    func test4DerivationAndSum() {
            //constant polynomial gives 0 polynom
        var pol = polynomial(coefficients: [1.0])
        var dpol = ∂pol
        XCTAssertEqual(dpol.degree , -1)
        XCTAssertEqual("", dpol.description)

            //identity polynomial gives 1
        pol = polynomial(coefficients: [0.0, 1.0])
        dpol = ∂pol
        XCTAssertEqual(dpol.degree , 0)
        XCTAssertEqual("1.0", dpol.description)
        
            //arbitrary polynomial
        pol = polynomial(coefficients: [1.0, 1.0, 2.0, 0.0, 2.0])
        dpol = ∂pol
        XCTAssertEqual(dpol.degree , (pol.degree - 1))
        XCTAssertEqual("1.0+4.0X+8.0X^3", dpol.description)
        
            //integral computation simple one
        pol = polynomial(coefficients: [1.0])
        var spol = ∫pol
        XCTAssertEqual(spol.degree , 1)
        XCTAssertEqual(spol.description , "X")
        
            //integral computation simple one
        pol = polynomial(coefficients: [1.0, 1.0, 3.0, 0.0, 2.0])
        spol = ∫pol
        XCTAssertEqual(spol.degree , 5)
        XCTAssertEqual(spol.description , "X+0.5X^2+X^3+0.4X^5")
        
    }
    
    func test5Legendre() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func test5Cheybishev() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
