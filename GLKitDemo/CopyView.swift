//
//  CopyView.swift
//  GLKitDemo
//
//  Created by techcul_iOS on 2018/5/25.
//  Copyright © 2018年 techcul. All rights reserved.
//

import Foundation
import GLKit

class CopyView: UIView {
    
    var eaglLayer : CAEAGLLayer!
    var context : EAGLContext!
    
    var colorRenderBuffer : GLuint = GLuint()
    var depthBuffer : GLuint = GLuint()
    var frameBuffer : GLuint = GLuint()
    
    var positionSlot: GLuint = GLuint()
    var colorSlot: GLuint = GLuint()
    var textureSlot: GLuint = GLuint()
    
    var programHandle: GLuint = GLuint()
    var vao = GLuint()
    
    var modelViewMatrixUniform: GLuint = GLuint()
    var projectionMatrixUniform: GLuint = GLuint()
    var textureUniform1: GLuint = GLuint()
    var textureUniform2: GLuint = GLuint()
    var modelViewMatrix: GLKMatrix4 = GLKMatrix4()
    var projectionMatrix: GLKMatrix4 = GLKMatrix4()
    
    var position = GLKVector3.init(v: (0.0, 0.0, 0.0))
    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    var scale: Float = 1
    
    var texture1: GLuint = GLuint()
    var texture2: GLuint = GLuint()
    
    var textureID: GLuint?
    
    //    var panGesture: UIPanGestureRecognizer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //        self.panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureAction(gesture:)))
        //        self.addGestureRecognizer(panGesture)
        
        // Set layer to opaque
        self.eaglLayer = self.layer as! CAEAGLLayer
        self.eaglLayer.isOpaque = true
        
        self.setupContext()
        
        GLUtil.setupDepthBuffer(depthBuffer: &self.depthBuffer, self.frame.size)
        GLUtil.setupRenderBuffer(renderBuffer: &self.colorRenderBuffer, self.context, self.eaglLayer)
        GLUtil.setupFrameBuffer(framebuffer: &self.frameBuffer, renderBuffer: self.colorRenderBuffer, depthBuffer: self.depthBuffer)
        
        self.loadProgram()
        
        self.setupVAOs()
        self.setupEBOs()
        self.setupVBOs()
        self.setupLocations()
        self.render()
        
    }
    override class var layerClass : AnyClass {
        return CAEAGLLayer.self
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
    
    func loadProgram() {
        if let program = GLUtil.getProgramHandleWith(vertexShaderName: "TexVertex.glsl", fragmentShaderName: "TexFragment.glsl"){
            self.programHandle = program
            glUseProgram(programHandle)
            
            if let texture1 = GLUtil.getTextureImage(imageName: "w.jpg"){
                self.texture1 = texture1
            }
            if let texture2 = GLUtil.getTextureImage(imageName: "t.jpg"){
                self.texture2 = texture2
            }
        }
    }
    
    func setupVAOs(){
        glGenVertexArraysOES(1, &vao)
        glBindVertexArrayOES(vao)
        
    }
    func setupVBOs() {
        var vertexBuffer = GLuint()
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
//        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<TextureVertex>.size * vertexList.count, vertexList, GLenum(GL_STATIC_DRAW))
        
    }
    func setupEBOs() {
        var indexBuffer = GLuint()
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
//        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), MemoryLayout<GLubyte>.size * indexList.count, indexList, GLenum(GL_STATIC_DRAW))
    }
    func setupLocations() {
        
        self.modelViewMatrixUniform = GLuint(glGetUniformLocation(programHandle, "u_ModelViewMatrix"))
        self.projectionMatrixUniform = GLuint(glGetUniformLocation(programHandle, "u_ProjectionMatrix"))
        self.textureUniform1 = GLuint(glGetUniformLocation(programHandle, "u_Texture1"))
        self.textureUniform2 = GLuint(glGetUniformLocation(programHandle, "u_Texture2"))
        
        self.positionSlot = GLuint(glGetAttribLocation(programHandle, "a_Position"))
        glEnableVertexAttribArray(self.positionSlot)
        self.colorSlot = GLuint(glGetAttribLocation(programHandle, "a_Color"))
        glEnableVertexAttribArray(self.colorSlot)
        self.textureSlot = GLuint(glGetAttribLocation(programHandle, "a_TexCoord"))
        
        glEnableVertexAttribArray(self.textureSlot)
        
        glVertexAttribPointer(self.positionSlot, 3,
                              GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<TextureVertex>.size),
                              GLUtil.BUFFER_OFFSET(0))
        glVertexAttribPointer(self.colorSlot, 4,
                              GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<TextureVertex>.size),
                              GLUtil.BUFFER_OFFSET(MemoryLayout<GLfloat>.size * 3))
        glVertexAttribPointer(self.textureSlot, 2,
                              GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<TextureVertex>.size),
                              GLUtil.BUFFER_OFFSET((3+4) * MemoryLayout<GLfloat>.size))
        
        glBindVertexArrayOES(0)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
        
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
        //        print("render")
        //Clear the screen
        glClearColor(0.0, 104.0/255.0, 55.0/255.0, 1.0)
        glClear(GLbitfield.init(bitPattern: GL_COLOR_BUFFER_BIT))
        glClear(GLbitfield.init(bitPattern: GL_DEPTH_BUFFER_BIT))
        glEnable(GLenum(GL_DEPTH_TEST))
        //glEnable(GLenum(GL_CULL_FACE))
        
        glBindVertexArrayOES(vao)
        
        if self.textureID != nil {
            
            
            glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
            
            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(GLenum(GL_TEXTURE_2D), self.textureID!)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLint(GL_REPEAT))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLint(GL_REPEAT))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_NEAREST))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_NEAREST))

            glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER),
                                   GLenum(GL_COLOR_ATTACHMENT0),
                                   GLenum(GL_TEXTURE_2D),
                                   self.textureID!,
                                   GLint(0))
            
            
//            glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, 4)
            
        }
        glBindVertexArrayOES(0)
        
        self.context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    func updateWIthDelta(dt: TimeInterval, textureid: GLuint) {
        if textureid != self.textureID{
            print(textureid)
            self.textureID = textureid
            self.render()
        }
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
