//
//  polylibTests.swift
//  polylibTests
//
//  Created by Laurent Cerveau on 01/23/2017.
//  Copyright © 2017 MMyneta. All rights reserved.
//

import XCTest
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

    func test2Evaluation() {
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
    }
    
    func test3ProductAndDivide() {
        //polynomial multiplication
        var pol0 = polynomial(coefficients: [1.0])
        var pol1 = polynomial(coefficients: [2.0, 0.0, 1.0, 1.0])
        var mpol = pol0*pol1
        XCTAssertEqual(true, mpol == pol1)
        
        pol0 = polynomial(coefficients: [1.0, 1.0, 2.0, 0.0, 2.0])
        pol1 = polynomial(coefficients: [2.0, 0.0, 1.0, 1.0])
        mpol = pol0*pol1
        print(mpol)
        print("coucou")
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func test4DerivationAndSum() {
        let pol1 = polynomial(coefficients: [1.0, 1.0, 2.0, 0.0, 2.0])
        print(∂pol1)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func test5Legendre() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func test5Cheybishech() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
