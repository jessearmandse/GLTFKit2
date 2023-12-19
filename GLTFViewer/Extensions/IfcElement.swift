//
//  IfcElement.swift
//  GLTFViewer
//
//  Created by Jesse Armand on 22/12/23.
//

import Foundation

struct IfcElement {
    let attribute: IfcAttribute
    let childAttributes: [IfcAttribute]
}

extension IfcElement {
    func addChildAttribute(_ attribute: IfcAttribute) -> IfcElement {
        IfcElement(attribute: attribute, childAttributes: childAttributes + [attribute])
    }
}
