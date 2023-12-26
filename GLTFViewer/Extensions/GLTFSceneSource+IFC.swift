//
//  GLTFSceneSource+IFC.swift
//  GLTFViewer
//
//  Created by Jesse Armand on 21/12/23.
//

import Foundation
import os
import GLTFKit2
import SceneKit

extension GLTFSCNSceneSource {
    func ifcHierarchyFromAsset(_ asset: GLTFAsset, assetType: IfcAssetType) throws -> IfcHierarchy {
        guard let defaultScene = asset.defaultScene else {
            throw IfcExtrasError.sceneError
        }

        let childParentRelation = try defaultScene.readIfcHierarchy(assetType: assetType)
        return childParentRelation
    }

    func ifcRootFromIFCHierarchy(_ ifcHierarchy: IfcHierarchy, assetType: IfcAssetType) -> SCNNode? {
        // Create a node as the model root and put the mesh under the model root node
        let ifcRoot = SCNNode()
        ifcRoot.name = assetType.description

        var ifcNodes = [String: SCNNode]()
        let scene = defaultScene

        scene?.rootNode.childNodes.forEach { node in
            if let name = node.name {
                ifcNodes[name] = node
            }
        }

        ifcHierarchy.forEach { key, value in
            if !(ifcNodes.contains { $0.key == key }) {
                let node = SCNNode.nodeFromIfcId(key, ifcTag: value.attribute.typeName, ifcAssetType: assetType)
                node.name = key
                ifcNodes[key] = node
            }

            value.childAttributes.forEach { attribute in
                if !(ifcNodes.contains { $0.key == attribute.id }) {
                    let node = SCNNode.nodeFromIfcId(attribute.id, ifcTag: attribute.typeName, ifcAssetType: assetType)
                    node.name = attribute.id
                    ifcNodes[attribute.id] = node
                }
            }
        }

        var currentNode = ["headNode"]
        var parentToChildMap = ifcHierarchy

        while !parentToChildMap.isEmpty {
            if let headNode = currentNode.first, let element = parentToChildMap[headNode] {
                element.childAttributes.forEach { attribute in
                    guard let childNode = ifcNodes[attribute.id] else {
                        return
                    }

                    guard let parentNode = ifcNodes[headNode] else {
                        return
                    }

                    if headNode == "headNode" {
                        ifcRoot.addChildNode(childNode)
                        ifcRoot.name = assetType.description
                    } else {
                        childNode.name = attribute.id
                        parentNode.name = headNode

                        let parentTransform = parentNode.worldTransform
                        let inverseParentTransform = SCNMatrix4Invert(parentTransform)

                        childNode.transform = SCNMatrix4Mult(childNode.worldTransform, inverseParentTransform)
                        parentNode.addChildNode(childNode)
                    }

                    currentNode.append(attribute.id)
                }
            } else {
                if let headNode = currentNode.first {
                    ifcNodes[headNode]?.name = headNode
                }
            }

            if let headNode = currentNode.first {
                parentToChildMap.removeValue(forKey: headNode)
            }
            currentNode.removeFirst()
        }

        return ifcRoot
    }

}
