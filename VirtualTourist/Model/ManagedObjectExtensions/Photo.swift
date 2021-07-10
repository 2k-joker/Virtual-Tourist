//
//  Photo.swift
//  VirtualTourist
//
//  Created by Khalil Kum on 7/4/21.
//

import Foundation
import CoreData

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
    }
}
