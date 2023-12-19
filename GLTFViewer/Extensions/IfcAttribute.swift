//
//  IfcAttribute.swift
//  GLTFViewer
//
//  Created by Jesse Armand on 13/12/23.
//

import Foundation

struct IfcAttribute {
    let id: String
    let name: String
    let typeName: String
    let elevation: Float
    let parentId: String

    static var attributesKey: String {
        "_attributes"
    }

    static var idKey: String {
        "id"
    }

    static var nameKey: String {
        "Name"
    }
}

extension IfcAttribute: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        id: \(id)
        name: \(name)
        IfcObjectType: \(typeName)
        IfcElevation: \(elevation)
        parentId: \(parentId)
        """
    }

}
