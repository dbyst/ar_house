//
//  OfficeModel.swift
//  ARKitSample
//
//  Created by Vitalii Obertynskyi on 11/9/17.
//  Copyright © 2017 Remit. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class OfficeModel: SCNScene {
    
    var office: SCNNode!
    var door: SCNNode!
    
    override init() {
        super.init()
        
    }
    
    func loadModel() {
        guard let model = SCNScene(named: "office.dae", inDirectory: "art.scnassets/office") else {
            return
        }
    }
}
