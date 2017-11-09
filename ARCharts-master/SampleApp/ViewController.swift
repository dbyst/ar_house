//
//  ViewController.swift
//  ARCharts
//
//  Created by Bobo on 7/5/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

import ARKit
import SceneKit
import UIKit


class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var chartButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    
    var currentNode: SCNNode? {
        didSet {
            chartButton.setTitle(currentNode == nil ? "Add" : "Remove", for: .normal)
        }
    }
    
    var session: ARSession {
        return sceneView.session
    }
    
    var screenCenter: CGPoint?
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.showsStatistics = false
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = false
        sceneView.contentScaleFactor = 1.0
        sceneView.preferredFramesPerSecond = 60
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
        
        chartButton.layer.cornerRadius = 5.0
        chartButton.clipsToBounds = true
        
        setupFocusSquare()
        setupRotationGesture()
        setupHighlightGesture()
        
        addLightSource(ofType: .omni)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.configuration?.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        sceneView.delegate = self
        
        screenCenter = self.sceneView.bounds.mid
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK - Setups
    
    var focusSquare = FocusSquare()
    
    func setupFocusSquare() {
        focusSquare.isHidden = true
        focusSquare.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(focusSquare)
    }
    
    func addObject(at position: SCNVector3) {
        if currentNode != nil {
            currentNode?.removeFromParentNode()
            currentNode = nil
        }
        
        let officeNode = createOfficeNode()
        officeNode.position = position
        currentNode = officeNode
        
        sceneView.scene.rootNode.addChildNode(officeNode)
    }
    
    func createOfficeNode() -> SCNNode {
        let scene = SCNScene(named: "art.scnassets/Scene.scn")!
        let office = scene.rootNode.childNode(withName: "mainContainer", recursively: false)!
        
        return office
    }
    
    func createNewBubbleParentNode() -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(sphereNode)
//        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    func createSphereNodeWithRadius(_ radius: CGFloat, position: SCNVector3) -> SCNNode {
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.red
        sphereMaterial.specular.contents = UIColor.red
        
        let sphereGeometry = SCNSphere(radius: radius)
        sphereGeometry.materials = [sphereMaterial]
        
        let sphereNode = createEmptyNodeWithPosition(position)
        sphereNode.geometry = sphereGeometry
        
        return sphereNode
    }

    func createEmptyNodeWithPosition(_ position: SCNVector3) -> SCNNode {
        let node = SCNNode()
        node.position = position
        
        return node
    }
    
    private func addLightSource(ofType type: SCNLight.LightType, at position: SCNVector3? = nil) {
        let light = SCNLight()
        light.color = UIColor.white
        light.type = type
        light.intensity = 1500 // Default SCNLight intensity is 1000
        
        let lightNode = SCNNode()
        lightNode.light = light
        if let lightPosition = position {
            // Fix the light source in one location
            lightNode.position = lightPosition
            self.sceneView.scene.rootNode.addChildNode(lightNode)
        } else {
            // Make the light source follow the camera position
            self.sceneView.pointOfView?.addChildNode(lightNode)
        }
    }
    
    private func setupRotationGesture() {
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        self.view.addGestureRecognizer(rotationGestureRecognizer)
    }
    
    private func setupHighlightGesture() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // TODO: Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // TODO: Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // TODO: Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    // MARK: - Actions
    
    @IBAction func handleTapChartButton(_ sender: UIButton) {
        guard let lastPosition = focusSquare.lastPosition else {
            return
        }
        
        if self.currentNode != nil {
            self.currentNode?.removeFromParentNode()
            self.currentNode = nil
        } else {
            addObject(at: lastPosition)
        }
    }
    
    private var startingRotation: Float = 0.0
    
    @objc func handleRotation(rotationGestureRecognizer: UIRotationGestureRecognizer) {
        guard let currentNode = currentNode,
            let pointOfView = sceneView.pointOfView,
            sceneView.isNode(currentNode, insideFrustumOf: pointOfView) == true else {
            return
        }
        
        if rotationGestureRecognizer.state == .began {
            startingRotation = currentNode.eulerAngles.y
        } else if rotationGestureRecognizer.state == .changed {
            self.currentNode?.eulerAngles.y = startingRotation - Float(rotationGestureRecognizer.rotation)
        }
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UITapGestureRecognizer) {
        let longPressLocation = gestureRecognizer.location(in: self.view)
        let selectedNode = self.sceneView.hitTest(longPressLocation, options: nil).first?.node
        
        if selectedNode == currentNode {
            print("HIT")
        }
    }
    
    @objc func handleTapToUnhighlight(_ gestureRecognizer: UITapGestureRecognizer) {
//        barChart?.unhighlight()
//        self.view.removeGestureRecognizer(gestureRecognizer)
    }
    
    // MARK: - Helper Functions
    
    func updateFocusSquare() {
        guard let screenCenter = screenCenter else {
            return
        }
        
        if currentNode != nil {
            focusSquare.isHidden = true
            focusSquare.hide()
        } else {
            focusSquare.isHidden = false
            focusSquare.unhide()
        }
        
        let (worldPos, planeAnchor, _) = worldPositionFromScreenPosition(screenCenter, objectPos: focusSquare.position)
        if let worldPos = worldPos {
            focusSquare.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
        }
    }
    
    var dragOnInfinitePlanesEnabled = false
    
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}
