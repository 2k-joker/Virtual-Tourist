//
//  Pin.swift
//  VirtualTourist
//
//  Created by Khalil Kum on 7/4/21.
//

import Foundation
import CoreData

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
    }
}
