//
//  GLUtil.swift
//  GLKitDemo
//
//  Created by techcul_iOS on 2018/5/29.
//  Copyright © 2018年 techcul. All rights reserved.
//


import UIKit
import GLKit

class GLUtil: NSObject {

    
    static func compileShader(shaderName: String, withType shaderType: GLenum) -> GLuint? {
        
        if let shaderPath = Bundle.main.path(forResource: shaderName, ofType: nil){
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
                    print("compile failed: \(String(cString: message))")
                }
                return shaderHandle
            }catch let error{
                print(error.localizedDescription)
                return nil
            }
        }else{
            print("no such file \(shaderName)")
            return nil
        }
    }
    static func setupDepthBuffer(depthBuffer: inout GLuint,_ size: CGSize) {
        glGenRenderbuffers(1, &depthBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), depthBuffer)
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), GLsizei(size.width), GLsizei(size.height))
    }
    static func setupRenderBuffer(renderBuffer: inout GLuint,_ context: EAGLContext,_ eaglLayer: CAEAGLLayer) {
        glGenRenderbuffers(1, &renderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
        context.renderbufferStorage(Int(GL_RENDERBUFFER), from: eaglLayer)
    }
    static func setupFrameBuffer(framebuffer: inout GLuint, renderBuffer : GLuint?, depthBuffer: GLuint?) {
        var framebuffer = GLuint()
        glGenFramebuffers(1, &framebuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        if let renderBuffer = renderBuffer{
            glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), renderBuffer)
        }
        if let depthBuffer = depthBuffer{
            glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), depthBuffer)
        }
        
        if glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) == GL_FRAMEBUFFER_COMPLETE{
            print("glCheckFramebuffer success")
        }else{
            print("glCheckFramebuffer failed")
        }
//        glDeleteFramebuffers(1, &framebuffer)
    }
    static func getProgramHandleWith(vertexShaderName: String, fragmentShaderName: String) -> GLuint?{
        if let vertexShader = self.compileShader(shaderName: vertexShaderName, withType: GLenum(GL_VERTEX_SHADER)),
            let fragmentShader = self.compileShader(shaderName: fragmentShaderName, withType: GLenum(GL_FRAGMENT_SHADER)){
            
            let programHandle = glCreateProgram()
            glAttachShader(programHandle, vertexShader)
            glAttachShader(programHandle, fragmentShader)
            
            //        glBindAttribLocation(programHandle, 0, "Position")
            //        glBindAttribLocation(programHandle, 1, "SourceColor")
            glLinkProgram(programHandle)
            
            
            var linkSuccess = GLint()
            glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &linkSuccess)
            if linkSuccess == GL_FALSE{
                var message = [GLchar](repeating: 0, count: 256)
                glGetProgramInfoLog(programHandle, GLsizei(message.count), nil, &message)
                print("compile failed: \(String(cString: message))")
//                var infoLength : GLsizei = 0
//                let bufferLength : GLsizei = 1024
//                glGetProgramiv(programHandle, GLenum(GL_INFO_LOG_LENGTH), &infoLength)
//
//                let info : [GLchar] = Array(repeating: GLchar(0), count: Int(bufferLength))
//                var actualLength : GLsizei = 0
//
//                glGetProgramInfoLog(programHandle, bufferLength, &actualLength, UnsafeMutablePointer(mutating: info))
//                NSLog(String(validatingUTF8: info)!)
                glDeleteProgram(programHandle)
                return nil
            }
            glDeleteShader(vertexShader)
            glDeleteShader(fragmentShader)
            return programHandle
        }else{
            return nil
        }
    }
    static func getTextureImage(image: UIImage) -> GLuint? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        let width = cgImage.width
        let height = cgImage.height
        let data = UnsafeMutablePointer<GLubyte>.allocate(capacity: width * height * 4)
        let spriteContext = CGContext.init(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: cgImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.last.rawValue)
        
        spriteContext?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var texture = GLuint()
        glGenTextures(1, &texture)
        glBindTexture(GLenum(GL_TEXTURE_2D), texture)
        //设置纹理循环模式
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLint(GL_REPEAT))
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLint(GL_REPEAT))
        //设置纹理过滤模式
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_LINEAR))
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_LINEAR))
        
        glTexImage2D(GLenum(GL_TEXTURE_2D),0, GLint(GL_RGBA), GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), data)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        data.deallocate()
        
        return texture
        
    }
    static func getTextureImage(imageName: String) -> GLuint? {
        let path = Bundle.main.path(forResource: imageName, ofType: nil)!
        let option = [GLKTextureLoaderOriginBottomLeft: true]
        do {
            let info = try GLKTextureLoader.texture(withContentsOfFile: path, options: option as [String : NSNumber]?)
            return info.name
        } catch let error{
            print("getTextureImage error: \(error)")
            return nil
        }
    }
    static func BUFFER_OFFSET(_ n: Int) -> UnsafeRawPointer? {
        return UnsafeRawPointer(bitPattern: n)
    }
}

