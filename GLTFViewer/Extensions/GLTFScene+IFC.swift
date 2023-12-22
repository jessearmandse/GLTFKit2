//
//  GLTFScene+IFC.swift
//  GLTFViewer
//
//  Created by Jesse Armand on 13/12/23.
//

import Foundation
import os
import GLTFKit2

let logger = Logger(subsystem: "com.metalbyexample.gltfkit2", category: "GLTFScene+IFC")

enum IfcAssetType: UInt16, CustomStringConvertible {
    case architectural
    case structural
    case mep
    case scan
    case none
    
    var description: String {
        switch self {
        case .architectural:
            return "Architectural"
        case .structural:
            return "Structural"
        case .mep:
            return "MEP"
        case .scan:
            return "3D Scan"
        case .none:
            return ""
        }
    }
    
}

enum IfcExtrasError: Swift.Error, CustomDebugStringConvertible {
    case missingExtrasError
    case sceneError
    case assetTypeError(type: IfcAssetType)
    case decompositionError
    case projectError
    case siteError
    case buildingError
    case buildingStoreyError
    case attributesError(element: String)
    case hierarchyConsistencyError

    var debugDescription: String {
        switch self {
        case .missingExtrasError:
            "No extras is found under GLTFScene"
        case .sceneError:
            "No scene available for root node hierarchy"
        case .assetTypeError(let type):
            "No asset type \(type) is found in the IFC hierarchy"
        case .decompositionError:
            "Expected decomposition is empty"
        case .projectError:
            "Expected IfcProject is empty"
        case .siteError:
            "Expected IfcSite is empty"
        case .buildingError:
            "Expected IfcBuilding is empty"
        case .buildingStoreyError:
            "Expected IfcBuildingStorey is empty"
        case .attributesError(let element):
            "No attributes found on IFC element \(element)"
        case .hierarchyConsistencyError:
            "IFC hierarchy consistency error"
        }
    }
}

typealias IfcBuildingStorey = [String: Any]
typealias IfcHierarchy = [String: IfcElement]

enum IfcObjectTypeName: String {
    case IfcProject
    case IfcSite
    case IfcBuilding
    case IfcBuildingStorey
}

extension GLTFScene {
    func readAssetType(_ assetType: IfcAssetType, extras: [String: Any]) -> [String: Any]? {
        let ifcKey = "ifc\(assetType.rawValue)"
        return extras[ifcKey] as? [String: Any]
    }
    
    func readDecomposition(ifcAsset: [String: Any]) -> [String: Any]? {
        ifcAsset["decomposition"] as? [String: Any]
    }
    
    func readIfcProject(decomposition: [String: Any]) -> [String: Any]? {
        decomposition["IfcProject"] as? [String: Any]
    }
    
    func readIfcSite(ifcProject: [String: Any]) -> [String: Any]? {
        ifcProject[IfcObjectTypeName.IfcSite.rawValue] as? [String: Any]
    }
    
    func readIfcBuilding(ifcSite: [String: Any]) -> [String: Any]? {
        ifcSite[IfcObjectTypeName.IfcBuilding.rawValue] as? [String: Any]
    }
    
    func readBuildingStoreys(ifcBuilding: [String: Any]) -> [IfcBuildingStorey] {
        ifcBuilding[IfcObjectTypeName.IfcBuildingStorey.rawValue] as? [IfcBuildingStorey] ?? []
    }
    
    func readIfcBuildingStorey(_ storey: IfcBuildingStorey, parentObjectType: String, parentId: String) throws {
        guard let attribute = try readIfcAttribute(from: storey, parentObjectType: parentObjectType, parentId: parentId) else {
            throw IfcExtrasError.attributesError(element: parentObjectType)
        }
    }
    
    func readIfcAttribute(from node: [String: Any], parentObjectType: String, parentId: String) throws -> IfcAttribute? {
        guard let attributes = node[IfcAttribute.attributesKey] as? [String: Any] else {
            return nil
        }

        guard let attributeId = attributes[IfcAttribute.idKey] as? String else {
            return nil
        }
        
        if parentId.isEmpty, parentId != "headNode" {
            logger.error("Child element should have a parent id")
            throw IfcExtrasError.hierarchyConsistencyError
        }

        let name = attributes[IfcAttribute.nameKey] as? String ?? ""
        return IfcAttribute(id: attributeId, name: name, typeName: parentObjectType, elevation: 0.0, parentId: parentId)
    }

    func establishParentChildRelation(to node: [String: Any], parentAttribute: IfcAttribute, withRelation relation: IfcHierarchy) throws -> IfcHierarchy {
        var childParentRelation = relation
        if let attribute = try readIfcAttribute(from: node, parentObjectType: parentAttribute.typeName, parentId: parentAttribute.id) {
            let parentId = parentAttribute.id
            if let element = childParentRelation[parentId] {
                let newElement = element.addChildAttribute(attribute)
                childParentRelation[parentId] = newElement
            } else {
                let newElement = IfcElement(attribute: parentAttribute, childAttributes: [attribute])
                childParentRelation[parentId] = newElement
            }

            childParentRelation = try enumerateNode(node, parent: attribute, establishParentChildRelation: childParentRelation)
        }
        return childParentRelation
    }

    func enumerateNode(
        _ node: [String: Any],
        parent: IfcAttribute,
        establishParentChildRelation relation: IfcHierarchy) throws -> IfcHierarchy {

        var childParentRelation = relation
        var parentAttribute = parent

        try node.forEach { key, value in
            logger.debug("Current node: \(key)")
            if key == IfcAttribute.attributesKey {
                if let ifcAttribute = try readIfcAttribute(from: node, parentObjectType: parent.typeName, parentId: parent.id) {
                    logger.debug("parent: \(parent.debugDescription)")
                    logger.debug("\(ifcAttribute.debugDescription)")

                    parentAttribute = parent
                }
            } else {
                if parentAttribute.id.isEmpty, parentAttribute.id != "headNode" {
                    logger.error("Child element should have a parent id")
                    throw IfcExtrasError.hierarchyConsistencyError
                }

                if let childNode = value as? [String: Any] {
                    childParentRelation = try establishParentChildRelation(
                        to: childNode,
                        parentAttribute: parentAttribute,
                        withRelation: childParentRelation
                    )

                } else if let childNodes = value as? [[String: Any]] {
                    try childNodes.forEach { node in
                        childParentRelation = try establishParentChildRelation(
                            to: node,
                            parentAttribute: parentAttribute,
                            withRelation: childParentRelation
                        )
                    }

                }
            }
        }

        return childParentRelation
    }

    func readIfcHierarchy(assetType: IfcAssetType) throws -> IfcHierarchy {
        var childParentRelation: IfcHierarchy = [:]

        guard let ifcExtras = extras as? [String: Any] else {
            throw IfcExtrasError.missingExtrasError
        }
        
        guard let ifcAsset = readAssetType(assetType, extras: ifcExtras) else {
            throw IfcExtrasError.assetTypeError(type: assetType)
        }
        
        guard let decomposition = readDecomposition(ifcAsset: ifcAsset) else {
            throw IfcExtrasError.decompositionError
        }
        
        guard let ifcProject = readIfcProject(decomposition: decomposition) else {
            throw IfcExtrasError.projectError
        }

        let headAttribute = IfcAttribute(id: "headNode", name: "", typeName: IfcObjectTypeName.IfcProject.rawValue, elevation: 0.0, parentId: "")
        guard let attribute: IfcAttribute = try readIfcAttribute(from: ifcProject, parentObjectType: headAttribute.typeName, parentId: headAttribute.id) else {
            throw IfcExtrasError.attributesError(element: headAttribute.typeName)
        }

        guard let ifcSite = readIfcSite(ifcProject: ifcProject) else {
            throw IfcExtrasError.siteError
        }

        guard let attribute = try readIfcAttribute(from: ifcSite, parentObjectType: IfcObjectTypeName.IfcSite.rawValue, parentId: attribute.id) else {
            throw IfcExtrasError.attributesError(element: IfcObjectTypeName.IfcSite.rawValue)
        }
        
        guard let ifcBuilding = readIfcBuilding(ifcSite: ifcSite) else {
            throw IfcExtrasError.buildingError
        }

        guard let attribute = try readIfcAttribute(from: ifcBuilding, parentObjectType: IfcObjectTypeName.IfcBuilding.rawValue, parentId: attribute.id) else {
            throw IfcExtrasError.attributesError(element: IfcObjectTypeName.IfcBuilding.rawValue)
        }
        
        let stories = readBuildingStoreys(ifcBuilding: ifcBuilding)
        try stories.forEach { storey in
            try readIfcBuildingStorey(storey, parentObjectType: IfcObjectTypeName.IfcBuildingStorey.rawValue, parentId: attribute.id)
        }

        childParentRelation = try enumerateNode(
            ifcProject,
            parent: headAttribute,
            establishParentChildRelation: childParentRelation
        )

        return childParentRelation
    }
}
