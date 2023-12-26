//
//  IfcNode.swift
//  GLTFViewer
//
//  Created by Jesse Armand on 22/12/23.
//

import ObjectiveC
import SceneKit

extension SCNNode {
    private enum AssociatedKeys {
        static var ifcID = "IfcId"
        static var ifcTag = "IfcTag"
        static var ifcAssetType = "IfcAssetType"
        static var ifcElevation = "IfcElevation"
    }

    class func nodeFromIfcId(_ ifcID: String, ifcTag: String = "", ifcAssetType: IfcAssetType, ifcElevation: Float = 0.0) -> SCNNode {
        let node = SCNNode()
        node.ifcID = ifcID
        node.ifcTag = ifcTag
        node.ifcAssetType = ifcAssetType
        node.ifcElevation = ifcElevation
        return node
    }

    var ifcID: String {
        get {
            withUnsafePointer(to: AssociatedKeys.ifcID) {
                objc_getAssociatedObject(self, $0)
            } as? String ?? ""
        }
        set {
            withUnsafePointer(to: AssociatedKeys.ifcID) {
                objc_setAssociatedObject(self, $0, newValue as NSString, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    var ifcTag: String {
        get {
            withUnsafePointer(to: AssociatedKeys.ifcTag) {
                objc_getAssociatedObject(self, $0)
            } as? String ?? ""
        }
        set {
            withUnsafePointer(to: AssociatedKeys.ifcTag) {
                objc_setAssociatedObject(self, $0, newValue as NSString, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    var ifcAssetType: IfcAssetType {
        get {
            let rawValue = withUnsafePointer(to: AssociatedKeys.ifcAssetType) {
                objc_getAssociatedObject(self, $0)
            } as? UInt16 ?? 0
            return IfcAssetType(rawValue: rawValue) ?? .none
        }
        set {
            withUnsafePointer(to: AssociatedKeys.ifcAssetType) {
                objc_setAssociatedObject(self, $0, newValue.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    var ifcElevation: Float? {
        get {
            withUnsafePointer(to: AssociatedKeys.ifcElevation) {
                objc_getAssociatedObject(self, $0)
            } as? Float
        }
        set {
            withUnsafePointer(to: AssociatedKeys.ifcElevation) {
                objc_setAssociatedObject(self, $0, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    var isIfcNode: Bool {
        (ifcID.isEmpty == false) && (ifcTag.isEmpty == false)
    }

    func copyIfcInfo(from node: SCNNode) {
        ifcID = node.ifcID
        ifcTag = node.ifcTag
        ifcAssetType = node.ifcAssetType
        ifcElevation = node.ifcElevation
    }
}
