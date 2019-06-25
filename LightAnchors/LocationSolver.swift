//
//  LocationSolver.swift
//  LASwift
//
//  Created by Nick Wilkerson on 6/13/19.
//

import UIKit
import Accelerate
import ARKit
import LASwift

struct AnchorPoint {
    var location3d: SCNVector3
    var location2d: CGPoint
}

class LocationSolver: NSObject {
    
    func solveForLocation(intrinsics: simd_float3x3, cameraTransform: simd_float4x4, anchorPoints:[AnchorPoint], callback: @escaping ((simd_float4x4, Bool)->()))  {
        DispatchQueue.global(qos: .default).async {
            
            let correctedIntrinsics = self.convert(matrix: intrinsics)
            let worldTransform = cameraTransform.inverse
            
            NSLog("correctedIntrinsics")
            self.printMatrix(correctedIntrinsics)
            NSLog("worldTransform")
            self.printMatrix(worldTransform)
            
            
            let numPoints = anchorPoints.count
            
            //var fixedCoords = Array(repeating: Array(repeating: 1, count: anchorPoints.count), count: 4)
            var fixedCoords = [simd_float4]()
            for i in 0..<numPoints {
                let point = anchorPoints[i]
                let spoint = simd_float4(x: point.location3d.x, y: point.location3d.y, z: point.location3d.z, w: 1.0)
                fixedCoords.append( worldTransform * spoint )
            }
            NSLog("fixedCoords")
            self.printMatrix(fixedCoords)
            
            let k11 = correctedIntrinsics[0][0]
            let k12 = correctedIntrinsics[1][0]
            let k13 = correctedIntrinsics[2][0]
            let k21 = correctedIntrinsics[0][1]
            let k22 = correctedIntrinsics[1][1]
            let k23 = correctedIntrinsics[2][1]
            let k31 = correctedIntrinsics[0][2]
            let k32 = correctedIntrinsics[1][2]
            let k33 = correctedIntrinsics[2][2]
            
            let matrixA = Matrix(numPoints*2, 5)
            var vectorB = Vector(repeating: 0.0, count: numPoints * 2)
            for i in 0..<numPoints {
                let u = Float(anchorPoints[i].location2d.x)
                let v = Float(anchorPoints[i].location2d.y)
                let x = fixedCoords[i][0]
                let y = fixedCoords[i][1]
                let z = fixedCoords[i][2]
                NSLog("u: \(u) v: \(v) x: \(x) y: \(y) z: \(z)")
                let first1 = (u*k31-k11)*x
                let second1 = (u*k33-k13)*z
                NSLog("first1: \(first1) second1: \(second1)")
             
                matrixA[i*2,0] = Double(first1+second1)
                let first2 = (u*k31-k11)*z
                let second2 = (u*k33-k13)*x
                NSLog("first2: \(first2) second2: \(second2)")
                matrixA[i*2,1] = Double(first2-second2)
                matrixA[i*2,2] = Double(u*k31-k11)
                matrixA[i*2,3] = Double(u*k32-k12)
                matrixA[i*2,4] = Double(u*k33-k13)
         
                let first3 = (v*k31-k21)*x
                let second3 = (v*k33-k23)*z
                matrixA[i*2+1,0] = Double(first3+second3)
                let first4 = (v*k31-k21)*z
                let second4 = (v*k33-k23)*x
                matrixA[i*2+1,1] = Double(first4-second4)
                matrixA[i*2+1,2] = Double(v*k31-k21)
                matrixA[i*2+1,3] = Double(v*k32-k22)
                matrixA[i*2+1,4] = Double(v*k33-k23)

                
                vectorB[i*2] = Double(k12-u*k32)*Double(y)
                vectorB[i*2+1] = Double(k22-v*k32)*Double(y)
            }

            NSLog("matrixA")
            self.printMatrix(matrixA)
            NSLog("vectorB")
            self.printMatrix(Matrix(vectorB))
            
            let matrixC: Matrix = Matrix([[1.0, 0.0, 0.0, 0.0, 0.0],
                                          [0.0, 1.0, 0.0, 0.0, 0.0]])
            
            let vectorD: Vector = [0.0, 0.0]
            
            let (xStar, success) = self.solveQP(matrixA: matrixA, vectorB: vectorB, matrixC: matrixC, vectorD: vectorD, a: 1.0)
            var newTransform = simd_float4x4()
            newTransform[0][0] = Float(xStar[0])
            newTransform[2][0] = Float(xStar[1])
            newTransform[3][0] = Float(xStar[2])
            newTransform[1][1] = Float(1)
            newTransform[3][1] = Float(xStar[3])
            newTransform[0][2] = Float(-xStar[1])
            newTransform[2][2] = Float(xStar[0])
            newTransform[3][2] = Float(xStar[4])
            newTransform[3][3] = Float(1)
            NSLog("newTransform")
            self.printMatrix(newTransform)
            let rTransform = cameraTransform * newTransform * worldTransform
            
            print(xStar)
            
            DispatchQueue.main.async {
                callback(rTransform, success)
            }
        }
    }
    
    
    func solveQP(matrixA: Matrix, vectorB: Vector, matrixC: Matrix, vectorD: Vector, a: Double) -> (Vector, Bool) {
        
        let (matrixU, matrixV, _, alpha, gamma, success) = gsvd(matrixA, matrixC)
        if success == false || alpha.count != 2 {
            return (Vector(), false)
        }
        
        let mu = alpha .* alpha ./ (gamma .* gamma)
        let c = (matrixU′ * Matrix(vectorB)).flat
        let e = (matrixV′ * Matrix(vectorD)).flat
        let startOfC = Vector(c[0...1])
        let startOfE = Vector(e[0...1])
        let restOfE = Vector(e[2..<e.count])

        let diff = gamma .* startOfC - alpha .* startOfE
        var f = alpha .* alpha .* diff .* diff
        
        f.append(sum(restOfE .* restOfE) - a * a)
        
        let gammaZero2 = gamma[0] * gamma[0]
        let gammaZero4 = gammaZero2 * gammaZero2
        let gammaOne2 = gamma[1] * gamma[1]
        let gammaOne4 = gammaOne2 * gammaOne2
        let alphaZero2 = alpha[0] * alpha[0]
        let alphaZero4 = alphaZero2 * alphaZero2
        let alphaOne2 = alpha[1] * alpha[1]
        let alphaOne4 = alphaOne2 * alphaOne2
        var poly: [Double] = [f[2]*gammaZero4*gammaOne4,
                              2*f[2]*gammaZero4*gammaOne2*alphaOne2+2*f[2]*gammaZero2*gammaOne4*alphaZero2,
                              f[2]*gammaZero4*alphaOne4+4*f[2]*gammaZero2*gammaOne2*alphaZero2*alphaOne2+f[2]*gammaOne4*alphaZero4+f[0]*gammaOne4+f[1]*gammaZero4,
                              2*f[2]*gammaZero2*alphaZero2*alphaOne4+2*f[2]*gammaOne2*alphaZero4*alphaOne2+2*f[0]*gammaOne2*alphaOne2+2*f[1]*gammaZero2*alphaZero2,
                              f[2]*alphaZero4*alphaOne4+f[0]*alphaOne4+f[1]*alphaZero4]
        var roots = Array(repeating: 0.0, count: 4)
        solve_real_poly(4, &poly, &roots)
        
        let lambdaStar = max(roots)
        let muStar = min(mu)
        if lambdaStar <= -muStar + 1e-15 {
            return (Vector(), false)
        }
        let invMat = inv((matrixA′ * matrixA) + lambdaStar .* (matrixC′ * matrixC))
        let rhsMat = (matrixA′ * Matrix(vectorB) + lambdaStar .* matrixC′ * Matrix(vectorD))
        let xStar = invMat * rhsMat
        
        return (xStar.flat, true)
    }
    
    
    /// Perform a generalized singular value decomposition of 2 given matrices.
    ///
    /// - Parameters:
    ///    - A: first matrix
    ///    - B: second matrix
    /// - Returns: matrices U, V, and Q, plus vectors alpha and beta
    public func gsvd(_ A: Matrix, _ B: Matrix) -> (U: Matrix, V: Matrix, Q: Matrix, alpha: Vector, beta: Vector, success: Bool) {
        /* LAPACK is using column-major order */
        let _A = toCols(A, .Row)
        let _B = toCols(B, .Row)
        
        var jobu:Int8 = Int8(Array("U".utf8).first!)
        var jobv:Int8 = Int8(Array("V".utf8).first!)
        var jobq:Int8 = Int8(Array("Q".utf8).first!)
        
        var M = __CLPK_integer(A.rows)
        var N = __CLPK_integer(A.cols)
        var P = __CLPK_integer(B.rows)
        
        var LDA = M
        var LDB = P
        var LDU = M
        var LDV = P
        var LDQ = N
        
        let lWork = max(max(Int(3*N),Int(M)),Int(P))+Int(N)
        var iWork = [__CLPK_integer](repeating: 0, count: Int(N))
        var work = Vector(repeating: 0.0, count: Int(lWork))
        var error = __CLPK_integer(0)
        
        var k = __CLPK_integer()
        var l = __CLPK_integer()
        
        let U = Matrix(Int(LDU), Int(M))
        let V = Matrix(Int(LDV), Int(P))
        let Q = Matrix(Int(LDQ), Int(N))
        var alpha = Vector(repeating: 0.0, count: Int(N))
        var beta = Vector(repeating: 0.0, count: Int(N))
        
        dggsvd_(&jobu, &jobv, &jobq, &M, &N, &P, &k, &l, &_A.flat, &LDA, &_B.flat, &LDB, &alpha, &beta, &U.flat, &LDU, &V.flat, &LDV, &Q.flat, &LDQ, &work, &iWork, &error)
        
        //precondition(error == 0, "Failed to compute SVD")
        if error != 0 {
            return (toRows(U, .Column), toRows(V, .Column), toRows(Q, .Column), Vector(alpha[Int(k)...Int(k+l)-1]), Vector(beta[Int(k)...Int(k+l)-1]), false)
        } else {
            return (toRows(U, .Column), toRows(V, .Column), toRows(Q, .Column), Vector(alpha[Int(k)...Int(k+l)-1]), Vector(beta[Int(k)...Int(k+l)-1]), true)
        }
    }
    
    
    func convert(matrix: simd_float3x3) -> simd_float3x3 {
        var matrix = matrix
        matrix.columns.1.x = -matrix.columns.1.x
        matrix.columns.1.y = -matrix.columns.1.y
        matrix.columns.1.z = -matrix.columns.1.z
        matrix.columns.2.x = -matrix.columns.2.x
        matrix.columns.2.y = -matrix.columns.2.y
        matrix.columns.2.z = -matrix.columns.2.z
        return matrix
    }
    
    func printMatrix(_ m: simd_float4x4) {
        for i in 0..<4 {
            print(String(m.columns.0[i]) + "\t\t" + String(m.columns.1[i]) + "\t\t" + String(m.columns.2[i]) + "\t\t" + String(m.columns.3[i]))
        }
    }
    

    

    
    
    func printMatrix(_ m: simd_float3x3) {
        for i in 0..<3 {
            print(String(m.columns.0[i]) + "\t\t" + String(m.columns.1[i]) + "\t\t" + String(m.columns.2[i]))
        }
    }
    
    func printMatrix(_ m: [simd_float4]) {
        for r in m {
            print(String(r[0]) + "\t\t" + String(r[1]) + "\t\t" + String(r[2]) + "\t\t" + String(r[3]))
        }
    }
    
    func printMatrix(_ m: Matrix) {
        for r in 0..<m.rows {
            for c in 0..<m.cols {
                print(String(m[r,c]) + "\t\t", terminator: "")
            }
            print()
        }
    }
    
    
}


