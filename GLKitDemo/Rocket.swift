//
//  Cube.swift
//  GLKitDemo
//
//  Created by techcul_iOS on 2018/5/25.
//  Copyright © 2018年 techcul. All rights reserved.
//

import Foundation
import GLKit

class Rocket: UIView {
    
    
    let Vertices = [
        Vertex(Position: (0, 1, 0)  , Color: (1, 1, 1, 0)),//0
        Vertex(Position: (1, -1, 1) , Color: (1, 0, 0, 0)),//1
        Vertex(Position: (1, -1, -1), Color: (0, 1, 0, 0)),//2
        Vertex(Position: (-1, -1, -1) , Color: (0, 0, 1, 0)),//3
        Vertex(Position: (-1, -1, 1), Color: (1, 1, 1, 0))//4
    ]
    
    let Indices: [GLubyte] = [
        // Front
        0, 1, 4,
        // Back
        0, 2, 3,
        // Left
        0, 3, 4,
        // Right
        0, 1, 2,
        // Bottom
        1, 2, 3,
        3, 4, 1
        
    ]
    var eaglLayer : CAEAGLLayer!
    var context : EAGLContext!
    
    var renderBuffer : GLuint = GLuint()
    var depthBuffer : GLuint = GLuint()
    
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
    
    var panGes: UIPanGestureRecognizer!
    var pinGes: UIPinchGestureRecognizer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupGestures()
        
        // Set layer to opaque
        self.eaglLayer = self.layer as! CAEAGLLayer
        self.eaglLayer.isOpaque = true
        
        self.setupContext()
        self.setupDepthBuffer()
        self.setupRenderBuffer()
        self.setupFrameBuffer()
        
        self.compileShaders()
        self.setupVAOs()
        self.setupVBOs()
        self.setupLocations()
        self.render()
        
    }
    override class var layerClass : AnyClass {
        return CAEAGLLayer.self
    }
    func setupGestures() {
        self.panGes = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureAction(gesture:)))
        self.addGestureRecognizer(panGes)
        
        self.pinGes = UIPinchGestureRecognizer.init(target: self, action: #selector(pinGestureAction(gesture:)))
        self.addGestureRecognizer(pinGes)
    }
    @objc func panGestureAction(gesture: UIPanGestureRecognizer) {
        let translation = gesture.velocity(in: self)
        self.rotationY += Float(translation.x/10000)
        self.rotationX += Float(-translation.y/10000)
        self.render()
    }
    @objc func pinGestureAction(gesture: UIPinchGestureRecognizer) {
        self.scale += Float(gesture.velocity/100)
        self.render()
    }
    func setupContext() {
        print("setupContext")
        // Create OpenGL context
        self.context = EAGLContext.init(api: EAGLRenderingAPI.openGLES3)
        
        if self.context == nil {
            print("failed to initalize OpenGLES 3.0 context")
            exit(1)
        }
        if EAGLContext.setCurrent(self.context) == false {
            print("failed to set current OpenGL context")
            exit(1)
        }
    }
    func setupDepthBuffer() {
        print("setupDepthBuffer")
        glGenRenderbuffers(1, &self.depthBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.depthBuffer)
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), GLsizei(self.frame.size.width), GLsizei(self.frame.size.height))
    }
    func setupRenderBuffer() {
        print("setupRenderBuffer")
        // Create a render buffer
        glGenRenderbuffers(1, &self.renderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.renderBuffer)
        
        self.context.renderbufferStorage(Int(GL_RENDERBUFFER), from: self.eaglLayer)
    }
    func setupFrameBuffer() {
        print("setupFrameBuffer")
        //Create a frame buffer
        var framebuffer = GLuint()
        glGenFramebuffers(1, &framebuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), self.renderBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), self.depthBuffer)
    }
    
    
    func compileShaders() {
        print("compileShaders")
        if let vertexShader = GLUtil.compileShader(shaderName: "SimpleVertex", withType: GLenum(GL_VERTEX_SHADER)),
            let fragmentShader = GLUtil.compileShader(shaderName: "SimpleFragment", withType: GLenum(GL_FRAGMENT_SHADER)){
            programHandle = glCreateProgram()
            glAttachShader(programHandle, vertexShader)
            glAttachShader(programHandle, fragmentShader)
            
            //        glBindAttribLocation(programHandle, 0, "Position")
            //        glBindAttribLocation(programHandle, 1, "SourceColor")
            
            glLinkProgram(programHandle)
            
            var linkSuccess = GLint()
            glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &linkSuccess)
            if linkSuccess == GL_FALSE{
                var message = [GLchar](repeating: 0, count: 256)
                glGetShaderInfoLog(programHandle, GLsizei(message.count), nil, &message)
                fatalError("compile failed: \(String(cString: message))")
            }
            
            glUseProgram(programHandle)
        }
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
    func setupLocations() {
        
        self.positionSlot = GLuint(glGetAttribLocation(programHandle, "Position"))
        self.colorSlot = GLuint(glGetAttribLocation(programHandle, "SourceColor"))
        
        self.modelViewMatrixUniform = GLuint(glGetUniformLocation(programHandle, "u_ModelViewMatrix"))
        self.projectionMatrixUniform = GLuint(glGetUniformLocation(programHandle, "u_ProjectionMatrix"))
        glEnableVertexAttribArray(self.positionSlot)
        glEnableVertexAttribArray(self.colorSlot)
        
        glVertexAttribPointer(self.positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), nil)
        let number = MemoryLayout<Vertex>.size
        let numberPointer = UnsafeRawPointer.init(bitPattern: number)
        glVertexAttribPointer(self.colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), numberPointer!)
        
        glBindVertexArrayOES(0)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
    }
    func render() {
//        print("render")
        //Clear the screen
        glClearColor(0.0, 104.0/255.0, 55.0/255.0, 1.0)
        glClear(GLbitfield.init(bitPattern: GL_COLOR_BUFFER_BIT))
        glClear(GLbitfield.init(bitPattern: GL_DEPTH_BUFFER_BIT))
        glEnable(GLenum(GL_DEPTH_TEST))
//        glEnable(GLenum(GL_CULL_FACE))
        
        let parentMatrix = GLKMatrix4MakeTranslation( 0, -1, -5)
        self.modelViewMatrix = GLKMatrix4Multiply(parentMatrix, self.modelMatrix())
        self.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0), Float(self.bounds.width / self.bounds.height), 1, 150)
        
        glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
        
        //glUniformMatrix4fv(GLint(modelViewMatrixUniform), 1, GLboolean(GL_FALSE), GLfloat(self.modelViewMatrix.m))
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
        
        glBindVertexArrayOES(vao)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(Indices.count), GLenum(GL_UNSIGNED_BYTE), nil)
        glBindVertexArrayOES(0)
        
        //glDisableVertexAttribArray(self.positionSlot)
        //glDisableVertexAttribArray(self.colorSlot)
        
        self.context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    func updateWIthDelta(dt: TimeInterval) {
        //self.rotationZ += Float.pi/2 * Float(dt)
//        self.rotationY += Float.pi * Float(dt)
        //self.rotationX += Float.pi * Float(dt)
//        self.position.y += 0.01
//        self.render()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
