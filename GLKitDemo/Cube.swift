//
//  Cube.swift
//  GLKitDemo
//
//  Created by techcul_iOS on 2018/5/25.
//  Copyright © 2018年 techcul. All rights reserved.
//

import Foundation
import GLKit

class Cube: UIView {
    let cubePositions : [RWTVertex] = [
        RWTVertex(1, 0, -5),
        RWTVertex(2, 4, -9),
        RWTVertex(-3, 5, -12),
        RWTVertex(-4, -6, -15),
        RWTVertex(1, -5, -10),
    ]
    // ObjC sizeof(Vertices) == Swift MemoryLayout<Vertex>.size * Vertices.count
    let vertexList : [TextureVertex] = [
        
        // Front
        TextureVertex( 1, -1, 1,  1, 1, 1, 1,  1, 0), // 0
        TextureVertex( 1,  1, 1,  1, 1, 1, 1,  1, 1), // 1
        TextureVertex( -1,  1, 1,  1, 1, 1, 1,  0, 1), // 2
        TextureVertex(-1, -1, 1,  1, 1, 1, 1,  0, 0), // 3
        
        // Back
        TextureVertex(-1, -1, -1, 1, 1, 1, 1,  1, 0), // 4
        TextureVertex(-1,  1, -1, 1, 1, 1, 1,  1, 1), // 5
        TextureVertex( 1,  1, -1, 1, 1, 1, 1,  0, 1), // 6
        TextureVertex( 1, -1, -1, 1, 1, 1, 1,  0, 0), // 7
        
        // Left
        TextureVertex(-1, -1,  1, 1, 1, 1, 1,  1, 0), // 8
        TextureVertex(-1,  1,  1, 1, 1, 1, 1,  1, 1), // 9
        TextureVertex(-1,  1, -1, 1, 1, 1, 1,  0, 1), // 10
        TextureVertex(-1, -1, -1, 1, 1, 1, 1,  0, 0), // 11
        
        // Right
        TextureVertex( 1, -1, -1, 1, 1, 1, 1,  1, 0), // 12
        TextureVertex( 1,  1, -1, 1, 1, 1, 1,  1, 1), // 13
        TextureVertex( 1,  1,  1, 1, 1, 1, 1,  0, 1), // 14
        TextureVertex( 1, -1,  1, 1, 1, 1, 1,  0, 0), // 15
        
        // Top
        TextureVertex( 1,  1,  1, 1, 1, 1, 1,  1, 0), // 16
        TextureVertex( 1,  1, -1, 1, 1, 1, 1,  1, 1), // 17
        TextureVertex(-1,  1, -1, 1, 1, 1, 1,  0, 1), // 18
        TextureVertex(-1,  1,  1, 1, 1, 1, 1,  0, 0), // 19
        
        // Bottom
        TextureVertex( 1, -1, -1, 1, 1, 1, 1,  1, 0), // 20
        TextureVertex( 1, -1,  1, 1, 1, 1, 1,  1, 1), // 21
        TextureVertex(-1, -1,  1, 1, 1, 1, 1,  0, 1), // 22
        TextureVertex(-1, -1, -1, 1, 1, 1, 1,  0, 0), // 23
        
    ]
    
    let indexList : [GLubyte] = [
        
        // Front
        0, 1, 2,
        2, 3, 0,
        
        // Back
        4, 5, 6,
        6, 7, 4,
        
        // Left
        8, 9, 10,
        10, 11, 8,
        
        // Right
        12, 13, 14,
        14, 15, 12,
        
        // Top
        16, 17, 18,
        18, 19, 16,
        
        // Bottom
        20, 21, 22,
        22, 23, 20
    ]
    
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
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<TextureVertex>.size * vertexList.count, vertexList, GLenum(GL_STATIC_DRAW))
        
    }
    func setupEBOs() {
        var indexBuffer = GLuint()
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), MemoryLayout<GLubyte>.size * indexList.count, indexList, GLenum(GL_STATIC_DRAW))
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
        
        for position in cubePositions {
            
            let parentMatrix = GLKMatrix4MakeTranslation(position.x, position.y , position.z)
            let viewMatrix = GLKMatrix4Multiply(parentMatrix,self.modelMatrix())
            self.modelViewMatrix =  GLKMatrix4Rotate(viewMatrix, GLKMathDegreesToRadians(10), 1, 0, 0)
            let lookatMatrix = GLKMatrix4MakeLookAt(camX, 0, camZ,
                                                    0, 0, 0,
                                                    0, 1, 0)
            self.modelViewMatrix = GLKMatrix4Multiply(lookatMatrix, self.modelViewMatrix)
            self.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85), Float(self.bounds.width / self.bounds.height), 1, 100)
            glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
            
            glUniformMatrix4fv(GLint(self.modelViewMatrixUniform), 1, GLboolean(GL_FALSE), self.modelViewMatrix.array)
            glUniformMatrix4fv(GLint(self.projectionMatrixUniform), 1, GLboolean(GL_FALSE), self.projectionMatrix.array)
            //        let components1 = MemoryLayout.size(ofValue: self.modelViewMatrix.m)/MemoryLayout.size(ofValue: self.modelViewMatrix.m.0)
            //        withUnsafePointer(to: &self.modelViewMatrix.m) {
            //            $0.withMemoryRebound(to: GLfloat.self, capacity: components1) {
            //                glUniformMatrix4fv(GLint(modelViewMatrixUniform), 1, GLboolean(GL_FALSE), $0)
            //            }
            //        }
            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(GLenum(GL_TEXTURE_2D), self.texture1)
            glUniform1i(GLint(self.textureUniform1), 0)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLint(GL_REPEAT))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLint(GL_REPEAT))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_NEAREST))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_NEAREST))
            
            glActiveTexture(GLenum(GL_TEXTURE1))
            glBindTexture(GLenum(GL_TEXTURE_2D), self.texture2)
            glUniform1i(GLint(self.textureUniform2), 1)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLint(GL_REPEAT))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLint(GL_REPEAT))
            
            glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indexList.count), GLenum(GL_UNSIGNED_BYTE), nil)
            
            //        glDisableVertexAttribArray(self.positionSlot)
            //        glDisableVertexAttribArray(self.colorSlot)
        }
        glBindVertexArrayOES(0)
        
        
        self.context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    var r: Float = 10
    var camX: Float = 0
    var camZ: Float = 3
    func updateWIthDelta(dt: TimeInterval) -> UIImage?{
//        self.rotationZ += Float.pi/2 * Float(dt)
//        self.rotationY += Float.pi/4 * Float(dt)
//        self.rotationX += Float.pi/8 * Float(dt)
        r += 1
        camX = sin(Float(r)/100) * 20.0 // 左右动
        camZ = cos(Float(r)/100) * 20.0 //前后动
        self.render()
        if let image = self.getImage(){
            print("not nil")
            return image
        }else {
            print("nil")
            return nil
        }
//        return self.getImage()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func getImage() -> UIImage?{
        let width: GLsizei = GLsizei(self.frame.width)
        let height: GLsizei = GLsizei(self.frame.height)
        let byteLength = Int(width * height)
        var bytes = [UInt32](repeating: 0, count: byteLength)
//        var b8 = [UInt8](repeating: 0, count: Int(byteLength))
        var anUIImage: UIImage! = nil
//        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
        
        glReadBuffer(GLenum(GL_COLOR_ATTACHMENT0))
        let t1 = Date()
        glReadPixels(0, 0, width, height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &bytes)
        /*
        // begin
        var textureCache: CVOpenGLESTextureCache?
        var renderTarget: CVPixelBuffer?
        var renderTexture: CVOpenGLESTexture?
        //        kCFTypeDictionaryKeyCallBacks
        var keyCallback = CFDictionaryKeyCallBacks()
        var valueCallback = CFDictionaryValueCallBacks()
        CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                     nil,
                                     CVEAGLContext(api: EAGLRenderingAPI.openGLES2)!,
                                     nil,
                                     &textureCache)
        var empty = CFDictionaryCreate(kCFAllocatorDefault, nil, nil, 0, &keyCallback, &valueCallback)
        var attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &keyCallback, &valueCallback)
        var pKey = kCVPixelBufferIOSurfacePropertiesKey
        CFDictionarySetValue(attrs, &pKey , &empty)
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(width),
                            Int(height),
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &renderTarget)
        CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                     textureCache!,
                                                     renderTarget!,
                                                     nil,
                                                     GLenum(GL_TEXTURE_2D),
                                                     GLint(GL_RGBA),
                                                     width,
                                                     height,
                                                     GLenum(GL_BGRA),
                                                     GLenum(GL_UNSIGNED_BYTE),
                                                     0,
                                                     &renderTexture)
        glBindTexture(CVOpenGLESTextureGetTarget(renderTexture!),CVOpenGLESTextureGetName(renderTexture!))
        glTexParameterf(GLenum(GL_TEXTURE_2D),
                        GLenum(GL_TEXTURE_WRAP_S),
                        GLfloat(GL_CLAMP_TO_EDGE))
        glTexParameterf(GLenum(GL_TEXTURE_2D),
                        GLenum(GL_TEXTURE_WRAP_T),
                        GLfloat(GL_CLAMP_TO_EDGE))
        
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER),
                               GLenum(GL_COLOR_ATTACHMENT0),
                               GLenum(GL_TEXTURE_2D),
                               CVOpenGLESTextureGetName(renderTexture!),
                               GLint(0))
        
        CVPixelBufferLockBaseAddress(renderTarget!, CVPixelBufferLockFlags(rawValue: 0))
        var rawBytesForimage = CVPixelBufferGetBaseAddress(renderTarget!)
        //end
 */
        let gl_error = glGetError()
        if gl_error == 0 {
            anUIImage = getUIImagefromRGBABuffer(src_buffer: &bytes, width: Int(width), height: Int(height))
//            anUIImage = getUIImagefromRGBABuffer(src_buffer: rawBytesForimage!, width: Int(width), height: Int(height))
        } else {
            print("getFramebuffer3Images 1 glerror GL_COLOR_ATTACHMENT0:", gl_error)
        }
//        CVPixelBufferUnlockBaseAddress(renderTarget!, CVPixelBufferLockFlags(rawValue: 0))
        let str = String.init(format: "getFramebuffer:t1 %.5f",
                              DateInterval.init(start: t1, end: Date()).duration)
        print(str)
        return anUIImage
    }
    public func getUIImagefromRGBABuffer(src_buffer: UnsafeMutableRawPointer, width: Int, height: Int) -> UIImage {
        var colorSpace: CGColorSpace?
        var alphaInfo: CGImageAlphaInfo!
        var bmcontext: CGContext?
        colorSpace = CGColorSpaceCreateDeviceRGB()
        alphaInfo = .noneSkipLast
        
        bmcontext = CGContext(data: src_buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace!, bitmapInfo: alphaInfo.rawValue)!
        let rgbImage: CGImage? = bmcontext!.makeImage()
        if rgbImage == nil {
            fatalError("getUIImagefromRGBABuffer rgbImage == nil error ")
        }
        let anUIImage = UIImage(cgImage: rgbImage!)
        return anUIImage
    }
}
