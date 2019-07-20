//
//  polynomial.swift
//  polylib
//
//  Created by Laurent Cerveau on 01/23/2017.
//  Copyright © 2017 MMyneta. All rights reserved.
//

import CoreFoundation
import CoreGraphics
import CoreText
import ImageIO

#if os(iOS)
    import UIKit
#endif


prefix operator ∂
prefix operator ∫

enum PolyDrawOption:Int {
    case foreColor = 1
    case backColor
    case withScaleAxis
    case drawGrid
    case exportFormat
}

//Internal only
enum AxisPosition:Int, CustomStringConvertible {
    case none = 0
    case lower = 1
    case middle
    case upper
    
    var description: String {
        switch self {
        case .none:
            return "none"
        case .lower:
            return "lower"
        case .middle:
            return "middle"
        case .upper:
            return "upper"
        }
    }
    
}


struct polynomial:CustomStringConvertible {
    var coefficients:[Float]
    
    //computed properties. for nil polynomial, -1 is the common value
    var degree:Int {
        return  (coefficients.count - 1)
    }
    
    //At init we need to check if we are passed array with useless values (trailing 0)
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
        let titleHeight:Float = 30.0
        var outPathURL:URL
        print("++ DRAW++")
        print(width)
        print(height)
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
            pixelResolution = UIScreen.main.scale
        #endif
        print(pixelResolution)
        
            //Compute an elegant title string with superscript. We replace all power (^) with superscripts
        var titleString:String = ("P(X) = " + self.description + " on [" + String(interval.lowerBound) + ", " + String(interval.upperBound) + "]")
        
        let mappingSuperScript = [ "\u{0030}":"\u{2070}", "\u{0031}":"\u{00B9}", "\u{0032}":"\u{00B2}",
                                   "\u{0033}":"\u{00B3}", "\u{0034}":"\u{2074}", "\u{0035}":"\u{2075}",
                                   "\u{0036}":"\u{2076}", "\u{0037}":"\u{2077}", "\u{0038}":"\u{2078}", "\u{0039}":"\u{2079}"]
        
        let titleArray = titleString.split(whereSeparator: { $0 == "^" }).enumerated().map( {
            (index, tmpCharSub) -> String in
            
            var tmpSub = String(tmpCharSub)
            for (jdx, aSubChar) in tmpSub.enumerated() {
                if let replaceChar = mappingSuperScript[String(aSubChar)] {
                    let oneCharRange = tmpSub.index(tmpSub.startIndex, offsetBy: jdx)..<tmpSub.index(tmpSub.startIndex, offsetBy: jdx+1)                    
                    tmpSub.replaceSubrange(oneCharRange, with: replaceChar)
                } else {
                    break;
                }
            }
            return tmpSub
        })
        titleString = titleArray.joined()
        print(titleString)
            //Compute out path name and URL
        let tmpFormatter:DateFormatter = DateFormatter()
        tmpFormatter.dateFormat = "yyyy-MM-dd-HH'H'mm'm'ss"
        let dateComponent:String = tmpFormatter.string(from: Date())
        let extensionComponent = (pixelResolution > 1.0) ? "@\(Int(pixelResolution))x.jpg" :".jpg"
        let outName:String = titleString + " - " + dateComponent+extensionComponent
        
        if folderPath.hasPrefix(".") {
            outPathURL = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent(outName)
        } else {
            outPathURL = URL(fileURLWithPath: NSString(string:folderPath).expandingTildeInPath).appendingPathComponent(outName)
        }
        
            //Get X Parameters. We have pointX = scalePointX * valueX + zeroPointX
        let minX = interval.lowerBound
        let maxX = interval.upperBound
        let minPointX = borderMargin
        let maxPointX = width - borderMargin
        let deltaX = maxX - minX
        let deltaPointX = maxPointX - minPointX

            //Grid scale is picked according to what is to be displayed
        var gridX = 100.0
        if deltaX < 10.0 { gridX = 1.0 }
        else if deltaX < 40.0 { gridX = 5.0 }
        else if deltaX < 120.0 { gridX = 10.0 }
        else if deltaX < 200.0 { gridX = 20.0 }
        else if deltaX < 350.0 { gridX = 50.0 }
        
        let scaleToPointX:Float =  deltaPointX / deltaX
        let zeroPointX:Float = borderMargin - scaleToPointX * minX
        
            //Compute all Y: the interval is created using one visual point resolution
        let xValues:[Float] = stride(from:interval.lowerBound, through:interval.upperBound, by:1.0/scaleToPointX).map({return $0})
        let yValues = self.eval(x: xValues)
       
            //Get Y parameters. We have pointY = scalePointY * valueY + zeroPointY
        guard let minY = yValues.min() else { return "" }
        guard let maxY = yValues.max() else { return "" }
        let minPointY = borderMargin
        let maxPointY = height - borderMargin - titleHeight
        //let deltaY = maxY - minY
        let deltaY = ceil(maxY - minY)
        let deltaPointY = maxPointY - minPointY
        
            //Y axis scale
        var gridY = 100.0
        if deltaY < 10.0 { gridY = 1.0 }
        else if deltaY < 40.0 { gridY = 5.0 }
        else if deltaY < 120.0 { gridY = 10.0 }
        else if deltaY < 200.0 { gridY = 20.0 }
        else if deltaY < 350.0 { gridY = 50.0 }

            //Difference with X is that we can have a constant value. In such case we decide arbitrary to have 2 grids in view
        //let scaleToPointY:Float =  (maxY == minY) ? ( Float(deltaPointY) / Float(2 * gridY) ) : ( deltaPointY / (maxY - minY) )
        
        let scaleToPointY:Float =  (maxY == minY) ? ( Float(deltaPointY) / Float(2 * gridY) ) : ( deltaPointY / deltaY )
        let zeroPointY:Float = (maxY == minY) ? borderMargin : borderMargin - scaleToPointY * minY

        
            //Create bitmap context
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let bitmapContext = CGContext(data: nil, width: Int(width*pixelResolution), height: Int(height*pixelResolution), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return ""}
        bitmapContext.scaleBy(x: CGFloat(pixelResolution), y: CGFloat(pixelResolution))
        
            //Draw Title
        bitmapContext.saveGState()
        var alignment = CTTextAlignment.center
        let alignmentSetting = [CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout.size(ofValue:alignment), value: &alignment)]
        let titleStyle = CTParagraphStyleCreate(alignmentSetting, alignmentSetting.count)
        
        let titleFont:CTFont = CTFontCreateWithName("Arial" as CFString, 11.0, nil)
        let titleAttributes:[String:Any] = [kCTFontAttributeName as String:titleFont,
                                            kCTParagraphStyleAttributeName as String:titleStyle,
                                            kCTUnderlineStyleAttributeName as String: 0]
        

        if let titleAttributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0 ) {            
            CFAttributedStringReplaceString(titleAttributedString, CFRangeMake(0,0), titleString as CFString)
            CFAttributedStringSetAttributes(titleAttributedString, CFRangeMake(0, titleString.count), titleAttributes as CFDictionary?, true)
            let titleLine:CTLine = CTLineCreateWithAttributedString(titleAttributedString)
            let titleTypographicsBound = CTLineGetBoundsWithOptions(titleLine, CTLineBoundsOptions(rawValue: 0))
            bitmapContext.textPosition = CGPoint(x: CGFloat(width/2.0) - titleTypographicsBound.size.width/2.0, y:CGFloat(height - borderMargin - titleHeight*1/3.0))
            CTLineDraw(titleLine, bitmapContext)
        }
        bitmapContext.restoreGState()

        
            //Axis : main lines then arrows
        bitmapContext.setStrokeColor(red: 0.0, green: 0, blue: 0, alpha: 1.0)
        bitmapContext.setFillColor(red: 0.0, green: 0, blue: 0, alpha: 1.0)
        bitmapContext.setLineWidth(1.0)
        
        let startPointXAxis:CGFloat = floor(CGFloat(borderMargin))
        let endPointXAxis:CGFloat = floor(CGFloat(width - borderMargin))
        let startPointYAxis:CGFloat = floor(CGFloat(borderMargin))
        let endPointYAxis:CGFloat = floor(CGFloat(height - borderMargin - titleHeight))

        var crossPointXAxis:CGFloat = 0.0  //Here this is not clear that we are in representation
        var crossPointYAxis:CGFloat = 0.0
        
        
        //Get axis positions as enum: it depends of the other axis value!!
        let  axisPositionX:AxisPosition = (minY <= 0.0) ? ((maxY <= 0.0) ? .upper : .middle) : .lower
        let  axisPositionY:AxisPosition = (minX <= 0.0) ? ((maxX <= 0.0) ? .upper : .middle) : .lower

        
        switch axisPositionY {
        case .lower:
            crossPointXAxis = startPointXAxis
        case .middle:
            crossPointXAxis = CGFloat(zeroPointX)
        case .upper:
            crossPointXAxis = endPointXAxis
        default:
            crossPointXAxis = 0.0
        }
        
        switch axisPositionX {
        case .lower:
            crossPointYAxis = startPointYAxis
        case .middle:
            crossPointYAxis = CGFloat(zeroPointY)
        case .upper:
            crossPointYAxis = endPointYAxis
        default:
            crossPointYAxis = 0.0
        }
        Swift.print("AXIS X:" + axisPositionX.description + " Y:" + axisPositionY.description)
        
            //Draw X Axis
        bitmapContext.beginPath()
        bitmapContext.move(to: CGPoint(x: startPointXAxis, y: crossPointYAxis))
        bitmapContext.addLine(to:CGPoint(x: endPointXAxis, y: crossPointYAxis))
        bitmapContext.move(to: CGPoint(x: crossPointXAxis, y: startPointYAxis))
        bitmapContext.addLine(to:CGPoint(x: crossPointXAxis, y: endPointYAxis))
        bitmapContext.strokePath()
        
        bitmapContext.beginPath()
        bitmapContext.move(to: CGPoint(x:endPointXAxis - 7.0 , y: crossPointYAxis + 4.0))
        bitmapContext.addLine(to: CGPoint(x:endPointXAxis - 7.0, y: crossPointYAxis - 4.0))
        bitmapContext.addLine(to: CGPoint(x:endPointXAxis , y: crossPointYAxis))
        bitmapContext.addLine(to: CGPoint(x:endPointXAxis - 7.0, y: crossPointYAxis + 4.0))
        bitmapContext.fillPath()
        
        bitmapContext.beginPath()
        bitmapContext.move(to: CGPoint(x:crossPointXAxis - 4.0 , y: endPointYAxis - 7.0))
        bitmapContext.addLine(to: CGPoint(x:crossPointXAxis + 4.0, y: endPointYAxis - 7.0))
        bitmapContext.addLine(to: CGPoint(x:crossPointXAxis , y: endPointYAxis))
        bitmapContext.addLine(to: CGPoint(x:crossPointXAxis - 4.0, y: endPointYAxis - 7.0))
        bitmapContext.fillPath()
        
            //Grid X - including scale
        var curP:CGFloat = crossPointXAxis
        var curN:CGFloat = crossPointXAxis
        
        let axisStyle = CTParagraphStyleCreate(alignmentSetting, alignmentSetting.count)
        let axisFont:CTFont = CTFontCreateWithName("Monaco" as CFString, 9.0, nil)
        let axisAttributes:[String:Any] = [kCTFontAttributeName as String:axisFont,
                                            kCTParagraphStyleAttributeName as String:axisStyle]
        
        let p = (Float(curP) - Float(zeroPointX))/Float(scaleToPointX)
        print("p  + \(p)")
        if let attributedString = CFAttributedStringCreate(kCFAllocatorDefault, String(describing: p) as CFString, axisAttributes as CFDictionary) {
            let axisLine:CTLine = CTLineCreateWithAttributedString(attributedString)
            bitmapContext.textPosition = CGPoint(x: curP + 2.0 , y:crossPointYAxis+8)
            CTLineDraw(axisLine, bitmapContext)
        }
        
        
        while (true) {
            print("gridX+\(gridX)")
            curP += CGFloat(gridX) * CGFloat(scaleToPointX)
            curN -= CGFloat(gridX) * CGFloat(scaleToPointX)
            
            guard (curP <= endPointXAxis) else { break }
            bitmapContext.beginPath()
            bitmapContext.setLineDash(phase: 0.0, lengths: [2.0, 4.0])
            bitmapContext.move(to: CGPoint(x: curP, y: startPointYAxis))
            bitmapContext.addLine(to: CGPoint(x: curP, y: endPointYAxis))
            bitmapContext.move(to: CGPoint(x: curN, y: startPointYAxis))
            bitmapContext.addLine(to: CGPoint(x: curN, y: endPointYAxis) )
            bitmapContext.strokePath()
            bitmapContext.beginPath()
            bitmapContext.setLineDash(phase: 0.0, lengths: [])
            bitmapContext.move(to: CGPoint(x: curP, y: crossPointYAxis - 6))
            bitmapContext.addLine(to: CGPoint(x: curP, y: crossPointYAxis + 6))
            bitmapContext.move(to: CGPoint(x: curN, y: crossPointYAxis - 6))
            bitmapContext.addLine(to: CGPoint(x: curN, y: crossPointYAxis + 6))
            bitmapContext.strokePath()
            
            let p = (Float(curP) - Float(zeroPointX))/Float(scaleToPointX)
            print(p)
            if let attributeString = CFAttributedStringCreate(kCFAllocatorDefault, String(describing: p ) as CFString, axisAttributes as CFDictionary) {
                let axisLine:CTLine = CTLineCreateWithAttributedString(attributeString)
                let axisTypographicsBound = CTLineGetBoundsWithOptions(axisLine, CTLineBoundsOptions(rawValue: 0))
                bitmapContext.textPosition = CGPoint(x: curP - axisTypographicsBound.width/2, y:crossPointYAxis+8)
                CTLineDraw(axisLine, bitmapContext)
            }
            
            let n = (Float(curN) - Float(zeroPointX))/Float(scaleToPointX)
            if let attributeString = CFAttributedStringCreate(kCFAllocatorDefault, String(describing: n) as CFString, axisAttributes as CFDictionary) {
                let axisLine:CTLine = CTLineCreateWithAttributedString(attributeString)
                let axisTypographicsBound = CTLineGetBoundsWithOptions(axisLine, CTLineBoundsOptions(rawValue: 0))
                bitmapContext.textPosition = CGPoint(x: curN - axisTypographicsBound.width/2, y:crossPointYAxis+8)
                CTLineDraw(axisLine, bitmapContext)
            }
        }
        
        
        curP = crossPointYAxis
        curN = crossPointYAxis
        while (true) {
            print(gridY)
            curP += CGFloat(gridY) * CGFloat(scaleToPointY)
            curN -= CGFloat(gridY) * CGFloat(scaleToPointY)
            guard (curP <= endPointYAxis) else { break }
            bitmapContext.beginPath()
            bitmapContext.setLineDash(phase: 0.0, lengths: [2.0, 4.0])
            bitmapContext.move(to: CGPoint(x: startPointXAxis, y: curP))
            bitmapContext.addLine(to: CGPoint(x: endPointXAxis, y: curP))
            bitmapContext.move(to: CGPoint(x: startPointXAxis, y: curN))
            bitmapContext.addLine(to: CGPoint(x: endPointXAxis, y: curN) )
            bitmapContext.strokePath()
            bitmapContext.beginPath()
            bitmapContext.setLineDash(phase: 0.0, lengths: [])
            bitmapContext.move(to: CGPoint(x: crossPointXAxis - 6, y: curP))
            bitmapContext.addLine(to: CGPoint(x: crossPointXAxis + 6, y: curP))
            bitmapContext.move(to: CGPoint(x: crossPointXAxis - 6, y: curN))
            bitmapContext.addLine(to: CGPoint(x: crossPointXAxis + 6, y: curN) )
            bitmapContext.strokePath()
            
            let p = (Float(curP) - Float(zeroPointY))/Float(scaleToPointY)
            print("Value is \(p)")
            if let attributeString = CFAttributedStringCreate(kCFAllocatorDefault, String(describing: p) as CFString, axisAttributes as CFDictionary) {
                let axisLine:CTLine = CTLineCreateWithAttributedString(attributeString)
                let axisTypographicsBound = CTLineGetBoundsWithOptions(axisLine, CTLineBoundsOptions(rawValue: 0))
                bitmapContext.textPosition = CGPoint(x: crossPointXAxis+4, y:curP - axisTypographicsBound.height/3.0)
                CTLineDraw(axisLine, bitmapContext)
            }
            
            let n = (Float(curN) - Float(zeroPointY))/Float(scaleToPointY)
print(p)
            if let attributeString = CFAttributedStringCreate(kCFAllocatorDefault, String(describing: n) as CFString, axisAttributes as CFDictionary) {
                let axisLine:CTLine = CTLineCreateWithAttributedString(attributeString)
                //let axisTypographicsBound = CTLineGetBoundsWithOptions(axisLine, CTLineBoundsOptions(rawValue: 0))
                bitmapContext.textPosition = CGPoint(x: crossPointXAxis+4, y:curN)
                CTLineDraw(axisLine, bitmapContext)
            }
        }
        
        
            //The data themselves
        bitmapContext.setStrokeColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        bitmapContext.setLineDash(phase: 0, lengths: [])
        bitmapContext.beginPath()
        xValues.enumerated().forEach(){ (idx:Int, x: Float) in
            if 0 == idx {
                bitmapContext.move(to: CGPoint(x: CGFloat(x * scaleToPointX + zeroPointX), y: CGFloat(zeroPointY + scaleToPointY * yValues[idx])))
            } else {
                bitmapContext.addLine(to: CGPoint(x: CGFloat(x * scaleToPointX + zeroPointX), y: CGFloat(zeroPointY + scaleToPointY * yValues[idx])))
            }
        }
        bitmapContext.strokePath()
        
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
        case 4: //Cardan
            let a = self.coefficients[2]/self.coefficients[3]
            let b = self.coefficients[1]/self.coefficients[3]
            let c = self.coefficients[0]/self.coefficients[3]
    
            let p = b - a*a/3
            let q = (2*a*a - 9*b) * a/27 + c

            let delta:Float = 0
            if delta < 0 {
                //One real solution only (2 complex)
            } else if delta == 0 {
                //one multiple real solution
            } else {
                //3 real distinct solutions
            }
            return []
        case 5: //Ferrari
            let a = self.coefficients[4]
            let b = self.coefficients[3]
            let c = self.coefficients[2]
            let d = self.coefficients[1]
            let e = self.coefficients[0]
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

