//
//  IfcNode.swift
//  GLTFViewer
//
//  Created by Jesse Armand on 22/12/23.
//

import SceneKit

class IfcNode: SCNNode {
    var ifcID: String
    var ifcTag: String
    var ifcAssetType: IfcAssetType
    var ifcElevation: Float

    init(ifcID: String, ifcTag: String = "", ifcAssetType: IfcAssetType, ifcElevation: Float = 0.0) {
        self.ifcID = ifcID
        self.ifcTag = ifcTag
        self.ifcAssetType = ifcAssetType
        self.ifcElevation = ifcElevation

        super.init()
    }

    required init?(coder: NSCoder) {
        self.ifcID = ""
        self.ifcTag = ""
        self.ifcAssetType = .none
        self.ifcElevation = 0.0

        super.init(coder: coder)
    }
}
