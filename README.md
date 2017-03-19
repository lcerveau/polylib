Insert image for Polylib

#POLYLIB v1.0

Polylib is a Swift library dedicated to the manipulation of polynomials (https://en.wikipedia.org/wiki/Polynomial). It came from looking at all functionnaly oriented Swift methods for collections and thinking that they could be apply to the manipulation of mathematical entities.

##DESIGN CONSIDERATIONS
There could be a few choice in order to describe a polynomial. Either create a structure/class that would represent such concept, either use the fact that function are first class citizen in Swift use them directly. 
In the first version of the library the first approach has been adopted : a polynomial is an object holding a suite of real coefficients


##FEATURES
The following features have been integrated into Polylib version 1.0

### Basic Operations
Basic operators have been defined for Polynomials : addition (and substraction), multiplication by a real number, polynomial multiplications, polynomial division (not by growing power)

### Evaluation
The *eval* method allows to compute the value of the polynomial for a given X numbers. It uses the Horner method for efficiency. When multiple values have to be computed they can be passed at once in an array.

### Drawing
For a given polynomial, it is possible to generate a drawing (image file) of the polynomial function computed on a range

### Zeros
Such methods will return zeros for a given polynomial. Depending on the polynomial degree, various method will be used. Degree 1 is using basic equation solving, degree 2 is using computation of discriminant, degree 3 is using Cardan's method, degree 4 Ferrari's method. Above degree 4 numerical computation using recursive method is used

### Derivation, Sum
Operators defining derivations and sum have been added to Polylib. In addition it is possible to compute the sum of a Polynomial on a given intercal

##INSTALL
### Setting up with CocoaPods

### Setting up with Carthage

### Setting up with Swift Package Manager

##USAGE

### Initialization

### Operations 

### Evaluation

### Zeros

### Drawing


##LICENSE
Polylib is distributed under a MIT license model.

Laurent Cerveau - MMyneta 2017