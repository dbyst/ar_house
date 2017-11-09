//
//  ViewController.swift
//  ARKitSample
//
//  Created by Andriy Kupich on 11/6/17.
//  Copyright © 2017 Remit. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var trackerNode: SCNNode!
    var mainContainer: SCNNode!
    var foundSurface = false
    var hasStarted = false
    var officePos = SCNVector3Make(0, 0, 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        addGridImage()
    }
    
    func setupScene () {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Scene.scn")!
        sceneView.scene = scene
    }
    
    func addGridImage () {
        let trackerPlane = SCNPlane(width: 0.3, height: 0.3)
        trackerPlane.firstMaterial?.diffuse.contents = UIImage(named: "tron_grid.png")
        trackerNode = SCNNode.init(geometry: trackerPlane)
        trackerNode.eulerAngles.x = .pi * -0.5
        sceneView.scene.rootNode.addChildNode((trackerNode)!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard foundSurface else {
            return
        }
        trackerNode.removeFromParentNode()
        hasStarted = true
        
        mainContainer = sceneView.scene.rootNode.childNode(withName: "mainContainer", recursively: false)!
        mainContainer.isHidden = false
        mainContainer.position = SCNVector3Make(officePos.x + mainContainer.boundingBox.min.x/2, officePos.y, officePos.z)
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard !hasStarted else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            guard let hitTest = strongSelf.sceneView.hitTest(CGPoint(x: strongSelf.view.frame.midX, y: strongSelf.view.frame.midY), types: [.existingPlane, .featurePoint]).last else { return }
            let trans = SCNMatrix4(hitTest.worldTransform)
            strongSelf.officePos = SCNVector3Make(trans.m41, trans.m42, trans.m43)
            
            strongSelf.trackerNode.position = strongSelf.officePos
            strongSelf.foundSurface = true
        }
    }
}

