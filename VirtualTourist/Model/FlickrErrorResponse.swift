//
//  FlickrErrorResponse.swift
//  VirtualTourist
//
//  Created by Khalil Kum on 6/27/21.
//

import Foundation

struct FlickrErrorResponse: Decodable {
    let status: String
    let code: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case status = "stat"
        case code
        case message
    }
}

extension FlickrErrorResponse: LocalizedError {
    var errorDescription: String? {
        var description: String {
            if code == FlickrErrorCodes.InvalidLatLon.rawValue {
                return CustomErrorMessages.invalidLocation.message
            } else {
                return CustomErrorMessages.searchError.message
            }
        }
        
        return description
    }
}

enum FlickrErrorCodes: Int {
    case InvalidLatLon = 999
}

enum CustomErrorMessages: String {
    case invalidLocation
    case invalidPhotoResource
    case searchError
    case emptyPhotosObject
    
    var message: String {
        switch self {
        case .invalidLocation:
            return "Location is invalid."
        case .invalidPhotoResource:
            return "Failed to download photo because the resource is unavailable."
        case .searchError:
            return "Failed to look up this location.\nPlease check your connection and try again."
        case .emptyPhotosObject:
            return "No new photos found."
        }
    }
}
