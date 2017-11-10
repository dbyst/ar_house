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
    
    @IBOutlet weak var showOfficeButton: UIButton! {
        didSet {
            showOfficeButton.layer.cornerRadius = 5.0
            showOfficeButton.clipsToBounds = true
        }
    }
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet var sceneView: ARSCNView!
    
    var currentNode: SCNNode? {
        didSet {
            showOfficeButton.isHidden = currentNode != nil
            resetButton.isHidden = currentNode == nil
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
        
        setupFocusSquare()
        setupRotationGesture()
        setupHighlightGesture()
        setupPinchGesture()
        
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
        
        let originalScale = officeNode.scale
        let newScale = SCNVector3Make(originalScale.x, 0, originalScale.z)
        officeNode.scale = newScale
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2
        officeNode.scale = originalScale
        
        SCNTransaction.commit()
    }
    
    func createOfficeNode() -> SCNNode {
        let scene = SCNScene(named: "art.scnassets/Scene.scn")!
        let office = scene.rootNode.childNode(withName: "mainContainer", recursively: false)!
        
        return office
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
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
        self.view.addGestureRecognizer(panRecognizer)
    }
    
    private func setupHighlightGesture() {
        let longPressRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    private func setupPinchGesture() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(gestureRecognize:)))
        self.view.addGestureRecognizer(pinchGesture)
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
        }
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
    
    private var startScale: Float = 1.0
    private var lastScale: Float = 1.0
    @objc func handlePinch(gestureRecognize: UIPinchGestureRecognizer) {
        if gestureRecognize.numberOfTouches == 2 {
            guard let currentNode = currentNode else {
                return
            }
            if (gestureRecognize.state == .began){
                startScale = Float(gestureRecognize.scale)
            } else if (gestureRecognize.state == .changed) {
                lastScale = Float(gestureRecognize.scale)
                let zoom = (lastScale - startScale) * 0.1
                let scale = currentNode.scale
                if scale.x < 0.02 && zoom < 0 { return }
                let newScale = SCNVector3Make(scale.x + zoom, scale.y + zoom, scale.z + zoom)
                currentNode.scale = newScale
                startScale = lastScale
            }
        }
    }
    
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        
        guard let currentNode = currentNode,
            let pointOfView = sceneView.pointOfView,
            sceneView.isNode(currentNode, insideFrustumOf: pointOfView) == true,
            pan.numberOfTouches == 1
            else {
                return
        }
        
        if pan.state == .began {
            startingRotation = currentNode.eulerAngles.y
        } else if pan.state == .changed {
            let translation = pan.translation(in: view).x / 200
            self.currentNode?.eulerAngles.y = startingRotation + Float(translation)
        }
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UITapGestureRecognizer) {
        let longPressLocation = gestureRecognizer.location(in: self.view)
        
        
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.categoryBitMask] = 2
        let selectedNode = self.sceneView.hitTest(longPressLocation, options: hitTestOptions).first?.node
        if (selectedNode?.name == "iOSRoom") {
            performSegue(withIdentifier: "presentList", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationContoller = segue.destination as? UINavigationController,
            let listVC = navigationContoller.viewControllers.first {
            listVC.title = "iOS Room"
        }
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
