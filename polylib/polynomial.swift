//
//  polynomial.swift
//  polylib
//
//  Created by Laurent Cerveau on 01/23/2017.
//  Copyright © 2017 MMyneta. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreGraphics
import ImageIO


prefix operator ∂
prefix operator ∫

enum PolyDrawOption:Int {
    case foreColor = 1
    case backColor
    case withScaleAxis
    case drawGrid
    case exportFormat
}

struct polynomial:CustomStringConvertible {
    var coefficients:[Float]
    
    //computed properties. for nil polynomial, -1 is an acceptable value
    var degree:Int {
        return  (coefficients.count - 1)
    }
    
    //At init we need to check if we are passed array with useless values
    //(trailing 0)
    init(coefficients:[Float]) {
        
            //we remove all trailings 0
        let trailing0:(Bool, Int) = coefficients.reversed().reduce((true ,0)) {
            (result, value) in
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
            sCoeff in
            return (sCoeff != "");
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
        let tmpPol = -1.0 * right
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
    func draw(interval:Range<Float>, width:Float, height:Float, folderPath:String = ".", options:[PolyDrawOption:Any]? = nil) -> String {
        let borderMargin:Float = 10.0
        let curvePadding:Float = 5.0
        var outPathURL:URL
        
            //check values
        guard width > 0.0 else { return "" }
        guard height > 0.0 else { return "" }
        
        //Get display resolution
        var pixelResolution:Float = 1.0
        #if os(macOS)
            let mainDisplayID:CGDirectDisplayID = CGMainDisplayID()
            if let mainDisplayMode:CGDisplayMode = CGDisplayCopyDisplayMode(mainDisplayID) {
                pixelResolution = Float(mainDisplayMode.pixelWidth) / Float(mainDisplayMode.width)
            }
        #elseif os(iOS)
            pixelResolution = 2.0
        #endif
        
        //Compute out name
        let tmpFormatter:DateFormatter = DateFormatter()
        tmpFormatter.dateFormat = "yyyy-MM-dd-HH'H'mm'm'ss"
        
        let dateComponent:String = tmpFormatter.string(from: Date())
        let extensionComponent = (pixelResolution > 1.0) ? "@\(Int(pixelResolution))x.jpg" :".jpg"
        let outName:String = "pol("+self.description+")-"+dateComponent+extensionComponent

        //find if absolute or relative path
        if folderPath.hasPrefix(".") {
            outPathURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent(outName)
        } else {
            print(NSString(string:folderPath).expandingTildeInPath)
            outPathURL = URL(fileURLWithPath: NSString(string:folderPath).expandingTildeInPath).appendingPathComponent(outName)
        }
        
        
        
        var pointPerXUnit:Float = (interval.upperBound - interval.lowerBound) / width
        if pointPerXUnit < 1 {
            pointPerXUnit = 1
        } else {
            pointPerXUnit = round(pointPerXUnit)
        }
        
        //}
        
        
        //compute scale for resolution
        
            //draw
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let bitmapContext = CGContext(data: nil, width: Int(width*pixelResolution), height: Int(height*pixelResolution), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return ""}
        bitmapContext.scaleBy(x: CGFloat(pixelResolution), y: CGFloat(pixelResolution))
        
        
            //Axis : main lines then arrows
        bitmapContext.setStrokeColor(red: 0.0, green: 0, blue: 0, alpha: 1.0)
        bitmapContext.setFillColor(red: 0.0, green: 0, blue: 0, alpha: 1.0)
        bitmapContext.setLineWidth(1.0)
        
        let startX:CGFloat = floor(CGFloat(borderMargin))
        let midX:CGFloat = floor(CGFloat(width/2.0))
        let endX:CGFloat = floor(CGFloat(width - borderMargin))
        let startY:CGFloat = floor(CGFloat(borderMargin))
        let midY:CGFloat = floor(CGFloat(height/2.0))
        let endY:CGFloat = floor(CGFloat(height - borderMargin))
        
        bitmapContext.beginPath()
        bitmapContext.move(to: CGPoint(x: startX, y: midY))
        bitmapContext.addLine(to:CGPoint(x: endX, y: midY))
        bitmapContext.move(to: CGPoint(x: midX, y: startY))
        bitmapContext.addLine(to:CGPoint(x: midX, y: endY))
        bitmapContext.strokePath()
        
        bitmapContext.beginPath()
        bitmapContext.move(to: CGPoint(x:endX - 7.0 , y: midY + 4.0))
        bitmapContext.addLine(to: CGPoint(x:endX - 7.0, y: midY - 4.0))
        bitmapContext.addLine(to: CGPoint(x:endX , y: midY))
        bitmapContext.addLine(to: CGPoint(x:endX - 7.0, y: midY + 4.0))
        bitmapContext.fillPath()
        
        bitmapContext.beginPath()
        bitmapContext.move(to: CGPoint(x:midX - 4.0 , y: endY - 7.0))
        bitmapContext.addLine(to: CGPoint(x:midX + 4.0, y: endY - 7.0))
        bitmapContext.addLine(to: CGPoint(x:midX , y: endY))
        bitmapContext.addLine(to: CGPoint(x:midX - 4.0, y: endY - 7.0))
        bitmapContext.fillPath()
        
            //Grid
        let intervalWidth:Float = interval.upperBound - interval.lowerBound
        var gridStep:CGFloat = 100.0
        if intervalWidth < 40.0 {
            gridStep = 5.0
        } else if intervalWidth < 120.0 {
            gridStep = 10.0
        } else if intervalWidth < 200.0 {
            gridStep = 20.0
        } else if intervalWidth < 350.0 {
            gridStep = 50.0
        }
        print(gridStep)
        
        bitmapContext.setLineDash(phase: 0.0, lengths: [2.0, 4.0])
        bitmapContext.beginPath()
        var curP = midX
        var curN = midX
        while (true) {
            curP += gridStep
            curN -= gridStep
            guard (curP < endX) else { break }
            bitmapContext.move(to: CGPoint(x: curP, y: startY))
            bitmapContext.addLine(to: CGPoint(x: curP, y: endY))
            bitmapContext.move(to: CGPoint(x: curN, y: startY))
            bitmapContext.addLine(to: CGPoint(x: curN, y: endY) )
        }
        
        curP = midY
        curN = midY
        while (true) {
            curP += gridStep
            curN -= gridStep
            guard (curP < endY) else { break }
            bitmapContext.move(to: CGPoint(x: startX, y: curP))
            bitmapContext.addLine(to: CGPoint(x: endX, y: curP))
            bitmapContext.move(to: CGPoint(x: startX, y: curN))
            bitmapContext.addLine(to: CGPoint(x: endX, y: curN) )
        }
        bitmapContext.strokePath()
        //bitmapContext.beginPath()
        
        
            //Export to JPG
        if let contextImage:CGImage = bitmapContext.makeImage(),
            let imageDestination = CGImageDestinationCreateWithURL(outPathURL as CFURL, "public.jpeg" as CFString ,1, nil) {
            CGImageDestinationAddImage(imageDestination, contextImage, nil)
            let writeSuccess = CGImageDestinationFinalize(imageDestination)
            if false == writeSuccess {
                print("[Error] Error writing image file")
            }
        }
        

        return outPathURL.path;
    }
    

    func zeros() -> [Float] {
        switch self.coefficients.count {
        case 0:
            return []
        case 1:
            return 0 == (self.coefficients[0]) ? [Float.greatestFiniteMagnitude] : []
        case 2:
           return [-self.coefficients[0] / self.coefficients[1]]
        case 3:
            let a = self.coefficients[2]
            let b = self.coefficients[1]
            let c = self.coefficients[0]
            let delta:Float = b * b - 4 * a * c
            if delta < 0 {
                return []
            } else if delta ==  0 {
                return [(-b)/(2*a)]
            } else {
                return [(-b - sqrt(delta))/(2*a), (-b + sqrt(delta))/(2*self.coefficients[0])]
            }
        case 4:
            let a = self.coefficients[3]
            let b = self.coefficients[2]
            let c = self.coefficients[1]
            let d = self.coefficients[0]
            let p = -b*b/(3*a*a)+c/a
            let q = b*(2*b*b/a*a)/(27*a - 9*c/a)+d/a
            return []
        default:
            return []
        }
        
        
    }
    
    //derivative
    static prefix func ∂ (left: polynomial) -> polynomial {        
        var resultCoefficients:[Float] = [Float](repeating: 0, count: left.coefficients.count-1)
        
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
            resultCoefficients[index+1] = coeff/Float(index+1)
        }
        return polynomial(coefficients:resultCoefficients)
    }
    
    
    //print on a file
    
    
    //symbolic integral
    
    //sum over interval
    
    //find zeros
    
}

