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

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var trackerNode: SCNNode!
    var mainContainer: SCNNode!
    var foundSurface = false
    var hasStarted = false
    var officePos = SCNVector3Make(0, 0, 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Scene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func randomPosition() -> SCNVector3 {
        let randX = (Float(arc4random_uniform(200)) / 100) - 1.0
        let randY = (Float(arc4random_uniform(200)) / 100) + 1.0
        
        return SCNVector3Make(randX, randY, -10.0)
    }
    
    @objc func addPlane() {
        let planeNode = sceneView.scene.rootNode.childNode(withName: "ship", recursively: false)?.copy() as! SCNNode
        planeNode.isHidden = false
        planeNode.position = randomPosition()
        
        sceneView.scene.rootNode.addChildNode(planeNode)
        
        let randSpeed = SCNVector3Make(0, 0, Float(arc4random_uniform(2) + 4))
        planeNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        planeNode.physicsBody?.isAffectedByGravity = false
        planeNode.physicsBody?.applyForce(randSpeed, asImpulse: true)
        
        let planeDissapearAction = SCNAction.sequence([SCNAction.wait(duration: 10), SCNAction.fadeOut(duration: 1), SCNAction.removeFromParentNode()])
        planeNode.runAction(planeDissapearAction)
        
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(addPlane), userInfo: nil, repeats: false)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard foundSurface else {
            return
        }
        trackerNode.removeFromParentNode()
        hasStarted = true
        
        mainContainer = sceneView.scene.rootNode.childNode(withName: "mainContainer", recursively: false)!
        mainContainer.isHidden = false
        mainContainer.position = officePos
        
//        addPlane()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard !hasStarted else { return }
        
        guard let hitTest = sceneView.hitTest(CGPoint(x: view.frame.midX, y: view.frame.midY), types: [.existingPlane, .featurePoint]).last else { return }
        let trans = SCNMatrix4(hitTest.worldTransform)
        officePos = SCNVector3Make(trans.m41, trans.m42, trans.m43)
        
        if !foundSurface {
            let trackerPlane = SCNPlane(width: 0.3, height: 0.3)
            trackerPlane.firstMaterial?.diffuse.contents = UIImage.init(named: "tron_grid.png")
            
            trackerNode = SCNNode.init(geometry: trackerPlane)
            trackerNode.eulerAngles.x = .pi * -0.5
            
            sceneView.scene.rootNode.addChildNode((trackerNode)!)
        }
        
        trackerNode.position = officePos
        foundSurface = true
        
    }
}
