//
//  MyGLView.swift
//  GLKitDemo
//
//  Created by techcul_iOS on 2018/5/22.
//  Copyright © 2018年 techcul. All rights reserved.
//

import UIKit
import GLKit

class MyGLView: UIView {
    
    
    let Vertices = [
        Vertex(Position: (1, -1, 0) , Color: (1, 0, 0, 1)),
        Vertex(Position: (1, 1, 0)  , Color: (0, 1, 0, 1)),
        Vertex(Position: (-1, 1, 0) , Color: (0, 0, 1, 1)),
        Vertex(Position: (-1, -1, 0), Color: (0, 0, 0, 1))
    ]
    
    let Indices: [GLubyte] = [
        0, 1, 2,
        2, 3, 0
    ]
    
    var eaglLayer : CAEAGLLayer!
    var context : EAGLContext!
    var colorRenderBuffer : GLuint = GLuint()
    
    var positionSlot: GLuint = GLuint()
    var colorSlot: GLuint = GLuint()
    
    var programHandle: GLuint = GLuint()
    var vao = GLuint()
    
    var modelViewMatrixUniform: GLuint = GLuint()
    var projectionMatrixUniform: GLuint = GLuint()
    var modelViewMatrix: GLKMatrix4 = GLKMatrix4()
    var projectionMatrix: GLKMatrix4 = GLKMatrix4()
    
    var position = GLKVector3.init(v: (0.0, 0.0, 0.0))
    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    var scale: Float = 1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Set layer to opaque
        self.eaglLayer = self.layer as! CAEAGLLayer
        self.eaglLayer.isOpaque = true
        
        self.setupContext()
        self.setupRenderBuffer()
        self.setupFrameBuffer()
        
        self.compileShaders()
        self.setupVAOs()
        self.setupVBOs()
        self.render()
        
    }
    override class var layerClass : AnyClass {
        return CAEAGLLayer.self
    }
    func setupContext() {
        print("setupContext")
        // Create OpenGL context
        self.context = EAGLContext.init(api: EAGLRenderingAPI.openGLES2)
        if self.context == nil {
            print("failed to initalize OpenGLES 3.0 context")
            exit(1)
        }
        if EAGLContext.setCurrent(self.context) == false {
            print("failed to set current OpenGL context")
            exit(1)
        }
    }
    func setupRenderBuffer() {
        print("setupRenderBuffer")
        // Create a render buffer
        glGenRenderbuffers(1, &self.colorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.colorRenderBuffer)
        self.context.renderbufferStorage(Int(GL_RENDERBUFFER), from: self.eaglLayer)
    }
    func setupFrameBuffer() {
        print("setupFrameBuffer")
        //Create a frame buffer
        var framebuffer = GLuint()
        glGenFramebuffers(1, &framebuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), self.colorRenderBuffer)
    }

    func compileShader(shaderName: String, withType shaderType: GLenum) -> GLuint {
        
        if let shaderPath = Bundle.main.path(forResource: shaderName, ofType: "glsl"){
            do{
                let shaderString = try String.init(contentsOfFile: shaderPath, encoding: String.Encoding.utf8)
                
                
                let shaderHandle = glCreateShader(shaderType)
                var shaderStringUTF8 = NSString(string: shaderString).utf8String
                var shaderStringLength = GLint(shaderString.count)
                glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength)
                
                glCompileShader(shaderHandle)
                
                var compileSuccess = GLint()
                glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &compileSuccess)
                
                if compileSuccess == GL_FALSE{
                    var message = [GLchar](repeating: 0, count: 256)
                    glGetShaderInfoLog(shaderHandle, GLsizei(message.count), nil, &message)
                    fatalError("compile failed: \(String(cString: message))")
                }
                return shaderHandle
            }catch let error{
                fatalError(error.localizedDescription)
            }
        }else{
            fatalError("no such file \(shaderName)")
        }
    }
    
    func compileShaders() {
        print("compileShaders")
        let vertexShader = self.compileShader(shaderName: "SimpleVertex", withType: GLenum(GL_VERTEX_SHADER))
        let fragmentShader = self.compileShader(shaderName: "SimpleFragment", withType: GLenum(GL_FRAGMENT_SHADER))
        
        programHandle = glCreateProgram()
        glAttachShader(programHandle, vertexShader)
        glAttachShader(programHandle, fragmentShader)
        
//        glBindAttribLocation(programHandle, 0, "Position")
//        glBindAttribLocation(programHandle, 1, "SourceColor")
        
        glLinkProgram(programHandle)
        
        self.modelViewMatrix = GLKMatrix4Identity
        modelViewMatrixUniform = GLuint(glGetUniformLocation(programHandle, "u_ModelViewMatrix"))
        //        self.projectionMatrix = GLKMatrix4Identity
        self.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0), Float(self.bounds.width / self.bounds.height), 1, 150)
        projectionMatrixUniform = GLuint(glGetUniformLocation(programHandle, "u_ProjectionMatrix"))
        
        
        var linkSuccess = GLint()
        glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &linkSuccess)
        if linkSuccess == GL_FALSE{
            var message = [GLchar](repeating: 0, count: 256)
            glGetShaderInfoLog(programHandle, GLsizei(message.count), nil, &message)
            fatalError("compile failed: \(String(cString: message))")
        }
        
        glUseProgram(programHandle)
        
    }
    
    func setupVBOs() {
        print("setupVBOs")
        var vertexBuffer = GLuint()
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), Vertices.count * MemoryLayout.size(ofValue: Vertices[0]), Vertices, GLenum(GL_STATIC_DRAW))
        
        var indexBuffer = GLuint()
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), Indices.count * MemoryLayout.size(ofValue: Indices[0]), Indices, GLenum(GL_STATIC_DRAW))
        
        
        self.positionSlot = GLuint(glGetAttribLocation(programHandle, "Position"))
        self.colorSlot = GLuint(glGetAttribLocation(programHandle, "SourceColor"))
        glEnableVertexAttribArray(self.positionSlot)
        glEnableVertexAttribArray(self.colorSlot)
        
        glVertexAttribPointer(self.positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), nil)
        glVertexAttribPointer(self.colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), nil)
        
        glBindVertexArrayOES(0)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
    }
    func setupVAOs(){
        glGenVertexArraysOES(1, &vao)
        glBindVertexArrayOES(vao)
        
    }
    func modelMatrix() -> GLKMatrix4 {
        var modelMatrix = GLKMatrix4Identity
        modelMatrix = GLKMatrix4Translate(modelMatrix, position.x, position.y, position.z)
        modelMatrix = GLKMatrix4Rotate(modelMatrix, rotationX, 1, 0, 0)
        modelMatrix = GLKMatrix4Rotate(modelMatrix, rotationY, 0, 1, 0)
        modelMatrix = GLKMatrix4Rotate(modelMatrix, rotationZ, 0, 0, 1)
        modelMatrix = GLKMatrix4Scale(modelMatrix, scale, scale, scale)
        
        return modelMatrix
    }
    func render() {
        print("render")
        //Clear the screen
        glClearColor(0.0, 104.0/255.0, 55.0/255.0, 1.0)
        glClear(GLbitfield.init(bitPattern: GL_COLOR_BUFFER_BIT))
        
        let parentMatrix = GLKMatrix4MakeTranslation( 0, -1 , -5)
        let viewMatrix = GLKMatrix4Multiply(parentMatrix, self.modelMatrix())
        self.modelViewMatrix = viewMatrix // modelMatrix()
        
        let components1 = MemoryLayout.size(ofValue: self.modelViewMatrix.m)/MemoryLayout.size(ofValue: self.modelViewMatrix.m.0)
        withUnsafePointer(to: &self.modelViewMatrix.m) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: components1) {
                glUniformMatrix4fv(GLint(modelViewMatrixUniform), 1, GLboolean(GL_FALSE), $0)
            }
        }
        let components2 = MemoryLayout.size(ofValue: self.projectionMatrix.m)/MemoryLayout.size(ofValue: self.projectionMatrix.m.0)
        withUnsafePointer(to: &self.projectionMatrix.m) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: components2) {
                glUniformMatrix4fv(GLint(projectionMatrixUniform), 1, GLboolean(GL_FALSE), $0)
            }
        }
        
        glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
        
        glBindVertexArrayOES(vao)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(Indices.count/3 * 3), GLenum(GL_UNSIGNED_BYTE), nil)
        glBindVertexArrayOES(0)
        
//        glDisableVertexAttribArray(self.positionSlot)
//        glDisableVertexAttribArray(self.colorSlot)
        
        self.context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    func updateWIthDelta(dt: TimeInterval) {
        let secsPerMove = Float(2)
        let x = sinf(Float(CACurrentMediaTime()) * 2.0 * Float.pi / secsPerMove)
        self.position = GLKVector3.init(v: (x, self.position.y,  self.position.z))
        self.render()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
