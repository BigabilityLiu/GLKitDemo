//
//  Extension.swift
//  GLKitDemo
//
//  Created by techcul_iOS on 2018/5/24.
//  Copyright © 2018年 techcul. All rights reserved.
//

import Foundation
import GLKit


enum VertexAttributes : GLuint {
    case position = 0
    case color = 1
    case texCoord = 2
}
struct RWTVertex {
    var x : GLfloat = 0.0
    var y : GLfloat = 0.0
    var z : GLfloat = 0.0
    
    init(_ x : GLfloat, _ y : GLfloat, _ z : GLfloat) {
        self.x = x
        self.y = y
        self.z = z
    }
}

struct Vertex {
    let Position: (GLfloat, GLfloat, GLfloat)
    let Color: (GLfloat, GLfloat, GLfloat, GLfloat)
}

struct TextureVertex {
    var x : GLfloat = 0.0
    var y : GLfloat = 0.0
    var z : GLfloat = 0.0
    
    var r : GLfloat = 0.0
    var g : GLfloat = 0.0
    var b : GLfloat = 0.0
    var a : GLfloat = 1.0
    
    var u : GLfloat = 0.0
    var v : GLfloat = 0.0
    
    
    init(_ x : GLfloat, _ y : GLfloat, _ z : GLfloat, _ r : GLfloat = 0.0, _ g : GLfloat = 0.0, _ b : GLfloat = 0.0, _ a : GLfloat = 1.0, _ u : GLfloat = 0.0, _ v : GLfloat = 0.0) {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = r
        self.g = g
        self.b = b
        self.a = a
        
        self.u = u
        self.v = v
    }
}
//helper extensions to pass arguments to GL land
extension Array {
    func size () -> Int {
        return self.count * MemoryLayout.size(ofValue: self[0])
    }
}

extension Int32 {
    func __conversion() -> GLenum {
        return GLuint(self)
    }
    
    func __conversion() -> GLboolean {
        return GLboolean(UInt8(self))
    }
}

extension Int {
    func __conversion() -> Int32 {
        return Int32(self)
    }
    
    func __conversion() -> GLubyte {
        return GLubyte(self)
    }
    
}
extension GLKMatrix2 {
    var array: [Float] {
        return (0..<4).map { i in
            self[i]
        }
    }
}


extension GLKMatrix3 {
    var array: [Float] {
        return (0..<9).map { i in
            self[i]
        }
    }
}

extension GLKMatrix4 {
    var array: [Float] {
        return (0..<16).map { i in
            self[i]
        }
    }
}
