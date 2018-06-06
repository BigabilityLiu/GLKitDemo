//
//  ViewController.swift
//  GLKitDemo
//
//  Created by techcul_iOS on 2018/5/22.
//  Copyright © 2018年 techcul. All rights reserved.
//

import UIKit
import GLKit

class ViewController: GLKViewController, GLKViewControllerDelegate {
    
    var context: EAGLContext!
    var glView: MyGLView!
    var cubeView: Cube!
    var rocket: Rocket!
    var copyGLView: CopyView!
    
    @IBOutlet weak var myGLView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        
        self.context = EAGLContext.init(api: EAGLRenderingAPI.openGLES3)
        
        cubeView = Cube(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.width, height: self.view.frame.height/2)))
//        copyGLView = CopyView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.width, height: self.view.frame.height/2)))
        
        self.myGLView.addSubview(cubeView)
//        self.copyView.addSubview(copyGLView)

//        rocket = Rocket(frame: self.view.frame)
//        self.view = rocket
        
        
//        glView = MyGLView(frame: self.view.frame)
//        self.view.addSubview(glView)
        
//        let rwtView = RWTView(frame: self.view.frame)
//        self.view.addSubview(rwtView)
        
//        let glkView = self.view as! GLKView
//        glkView.context = self.context;
//        glClearColor(1.0, 0.0, 0.0, 1.0)
        
    }
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return UIInterfaceOrientationMask.landscape
//    }
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
    }
    
    func glkViewControllerUpdate(_ controller: GLKViewController) {
//        self.glView.updateWIthDelta(dt: self.timeSinceLastUpdate)
        self.imageView.image = self.cubeView.updateWIthDelta(dt: self.timeSinceLastUpdate)
//        self.copyGLView.updateWIthDelta(dt: self.timeSinceLastUpdate, textureid: textureID)
        
//        self.rocket.updateWIthDelta(dt: self.timeSinceLastUpdate)
    }
}

