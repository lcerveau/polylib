//
//  polynomial.swift
//  polylib
//
//  Created by Laurent Cerveau on 01/23/2017.
//  Copyright © 2017 MMyneta. All rights reserved.
//

import Foundation
import CoreGraphics
import ImageIO

prefix operator ∂
prefix operator ∫


struct polynomial:CustomStringConvertible {
    var coefficients:[Float]
    
    //computed properties. for nil polynomial, -1 is an acceptable value
    var degree:Int {
        return  (coefficients.count - 1)
    }
    
    //At init we need to check if we are passed array with useless values (trailing 0)
    init(coefficients:[Float]) {
        
            //we remove all trailings 0
        let trailing0:(Bool, Int) = coefficients.reversed().reduce((true ,0)) { (result, value) in
            guard result.0 == true else { return (false, result.1) }
            return (0.0 == value) ? (true, result.1+1) : (false, result.1)
        }
            //and instantiate with the result of this removal
        if 0 == trailing0.1 {
            self.coefficients = coefficients
        } else if coefficients.count == trailing0.1 {
            self.coefficients = []
        } else {
            self.coefficients = Array(coefficients[(0...(coefficients.count-1-trailing0.1))])
        }
    }
    
    //Print it like in school books
    var description:String {
        
        var firstNonZeroIndex:Int = -1;
        
        let stringCoeffs = coefficients.enumerated().map({ (index, coeff) in
            
            if coeff < 0 {
                if -1 == firstNonZeroIndex { firstNonZeroIndex = index }
                switch index {
                    case 0:
                        return "\(coeff)"
                    case 1:
                        return ((-1.0 == coeff) ? "-X" : "\(coeff)X")
                    default:
                        return ((-1.0 == coeff) ? "-X^\(index)" : "\(coeff)X^\(index)")
                }
            } else if 0 == coeff {
                return ""
            } else {
                if -1 == firstNonZeroIndex { firstNonZeroIndex = index }
                switch index {
                    case 0:
                        return "\(coeff)"
                    case 1:
                        return ((1 == coeff) ?
                                    ((firstNonZeroIndex == index) ? "X" :"+X") :
                                    ((firstNonZeroIndex == index) ? "\(coeff)X" :"+\(coeff)X"))
                    default:
                        return ((1 == coeff) ?
                                    ((firstNonZeroIndex == index) ? "X^\(index)" : "+X^\(index)") :
                                    ((firstNonZeroIndex == index) ? "\(coeff)X^\(index)" : "+\(coeff)X^\(index)") )
                }
            }                        
        }).filter( {
            sCoeff in return (sCoeff != "");
        })
        
        return stringCoeffs.joined(separator: "")
    }
    
    //Addition of polynomials
    static func +(left:polynomial, right: polynomial) -> polynomial {
        let (maxpol, minpol) =  (right.degree > left.degree) ? (right, left) : (left, right)        
        
        let sumCoeffs = maxpol.coefficients.enumerated().map() {
            (index, coeff) in
            return  (index < minpol.coefficients.count) ? coeff+minpol.coefficients[index] : coeff
        }
        return polynomial(coefficients: sumCoeffs)
    }
    
    //Equality test : coefficients are the same
    static func ==(left: polynomial, right:polynomial) -> Bool {
        return left.coefficients == right.coefficients
    }
    
    //Substraction of polynomials
    static func -(left:polynomial, right: polynomial) -> polynomial {
        let tmpPol = -1 * right
        return (left+tmpPol)
    }    
    
    //Multiply by a constant
    static func *(left: Float, right:polynomial) -> polynomial {
        return polynomial(coefficients: right.coefficients.map(){ left * $0 })
    }
    
    //Multiply by a constant : associativity
    static func *(left: polynomial, right:Float) -> polynomial {
        return polynomial(coefficients: left.coefficients.map(){ right * $0 })
    }
    
    //Multiplication of 2 polynomials
    static func *(left: polynomial, right:polynomial) -> polynomial {
        var resultCoefficients = [Float](repeating: 0, count: left.degree+right.degree+1 )
        left.coefficients.enumerated().forEach({ (idx: Int, lelem: Float) in
            right.coefficients.enumerated().forEach({ (jdx: Int, relem: Float) in
                resultCoefficients[idx+jdx] = resultCoefficients[idx+jdx]+lelem*relem
            })
        })        
        return polynomial(coefficients: resultCoefficients)
    }
    
    
    //Division of 2 polynomials
    static func % (left: polynomial, right:polynomial) -> (polynomial) {
        var resultCoefficients:[Float] = (left.degree < right.degree)  ? [Float]() : [Float](repeating: 0, count: left.degree-right.degree+1 )
                
        _ = left.coefficients.reversed().enumerated().reduce(left.coefficients) { (result, value) in
            var tmpResult:[Float] = result
            let ldegree:Int = result.count - value.0 - 1
            let rdegree:Int = right.coefficients.count - 1
            
            if ldegree >= rdegree {
                resultCoefficients[ldegree-rdegree] =  tmpResult[ldegree]/right.coefficients[right.coefficients.count-1]
                right.coefficients.reversed().enumerated().forEach() { (idx:Int, coeff: Float) in
                    tmpResult[ldegree-idx] = result[ldegree-idx] - resultCoefficients[ldegree-rdegree]*coeff
                }
            }
            return tmpResult
        }
        
        
        return (polynomial(coefficients: resultCoefficients))
    }
    
    //Evaluation of data:
    func eval(x:Float) -> Float {
        let result:Float = coefficients.reversed().reduce(0) { (result, value) in
            return result*x+value
        }
        return result;
    }
    
    //Evaluation of multidata:
    func eval(x:[Float]) -> [Float] {
        let result = x.map() { x0 in
            coefficients.reversed().reduce(0) { (result, value) in
                return result*x0+value
            }
        }
        return result;
    }
    
    //Will draw the polynomial for a given range
    func draw(interval:Range<Float>, width:Float, height:Float) -> String {
        
        return "/";
    }
    

    func zeros() -> [Float] {
        switch self.coefficients.count {
        case 0:
            return []
        case 1:
            return 0 == (self.coefficients[0]) ? [Float.greatestFiniteMagnitude] : []
        case 2:
           return [-self.coefficients[0]/self.coefficients[1]]
        case 3:
            let delta:Float = self.coefficients[1] * self.coefficients[1] - 4 * self.coefficients[0] * self.coefficients[0]
            if delta < 0 {
                return []
            } else if delta ==  0 {
                return [(-self.coefficients[1])/(2*self.coefficients[0])]
            } else {
                return [(-self.coefficients[1] - sqrt(delta))/(2*self.coefficients[0]), (-self.coefficients[1] + sqrt(delta))/(2*self.coefficients[0])]
            }
        case 4:
            let p = 0
            let q = 0
            return []
        default:
            return []
        }
        
        
    }
    
    //derivative
    static prefix func ∂ (left: polynomial) -> polynomial {
        var resultCoefficients = [Float](repeating: 0, count: left.coefficients.count-1)
        left.coefficients.enumerated().forEach {
            (index: Int, coeff: Float) in
            if index > 0 {
                resultCoefficients[index-1] = Float(index)*coeff
            }
        }
        return polynomial(coefficients:resultCoefficients)
    }
    
    //sum
    static prefix func ∫ (left: polynomial) -> polynomial {
        var resultCoefficients = [Float](repeating: 0, count: left.coefficients.count+1)
        left.coefficients.enumerated().forEach {
            (index: Int, coeff: Float) in
            resultCoefficients[index+1] = coeff/Float(index)
        }
        return polynomial(coefficients:resultCoefficients)
    }
    
    
    //print on a file
    
    
    //symbolic integral
    
    //sum over interval
    
    //find zeros
    
}

