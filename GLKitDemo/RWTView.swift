//
//  MyGLView.swift
//  GLKitDemo
//
//  Created by techcul_iOS on 2018/5/22.
//  Copyright © 2018年 techcul. All rights reserved.
//

import UIKit
import GLKit

class RWTView: UIView {
    let Vertices = [
        RWTVertex( 0, 0, 0),
        RWTVertex( -1, -1, 0),
        RWTVertex( 1, -1, 0)
        
    ]
    
    var eaglLayer : CAEAGLLayer!
    var context : EAGLContext!
    var colorRenderBuffer : GLuint = GLuint()
    
    var positionSlot: GLuint = GLuint()
    var colorSlot: GLuint = GLuint()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Set layer to opaque
        self.eaglLayer = self.layer as! CAEAGLLayer
        self.eaglLayer.isOpaque = true
        
        self.setupContext()
        self.setupRenderBuffer()
        self.setupFrameBuffer()
        
        self.compileShaders()
        self.setupVBOs()
        
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
        let vertexShader = self.compileShader(shaderName: "RWTSimpleVertex", withType: GLenum(GL_VERTEX_SHADER))
        let fragmentShader = self.compileShader(shaderName: "RWTSimpleFragment", withType: GLenum(GL_FRAGMENT_SHADER))
        
        let programHandle = glCreateProgram()
        glAttachShader(programHandle, vertexShader)
        glAttachShader(programHandle, fragmentShader)
        glLinkProgram(programHandle)
        
        var linkSuccess = GLint()
        glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &linkSuccess)
        if linkSuccess == GL_FALSE{
            var message = [GLchar](repeating: 0, count: 256)
            glGetShaderInfoLog(programHandle, GLsizei(message.count), nil, &message)
            fatalError("compile failed: \(String(cString: message))")
        }
        
        glUseProgram(programHandle)
        
        self.positionSlot = GLuint(glGetAttribLocation(programHandle, "Position"))
        glEnableVertexAttribArray(self.positionSlot)
    }
    
    func setupVBOs() {
        print("setupVBOs")
        var vertexBuffer = GLuint()
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), Vertices.count * MemoryLayout.size(ofValue: Vertices[0]), Vertices, GLenum(GL_STATIC_DRAW))
    }
    
    func render() {
        print("render")
        //Clear the screen
        glClearColor(0.0, 104.0/255.0, 55.0/255.0, 1.0)
        glClear(GLbitfield.init(bitPattern: GL_COLOR_BUFFER_BIT))
        
        glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
        //
        glVertexAttribPointer(self.positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<RWTVertex>.size), nil)
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(Vertices.count))
        
        self.context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
