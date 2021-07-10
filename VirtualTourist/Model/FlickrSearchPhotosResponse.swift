//
//  FlickrPhotosData.swift
//  VirtualTourist
//
//  Created by Khalil Kum on 6/26/21.
//

import Foundation

struct FlickrSearchPhotosResponse: Decodable {
    let photos: FlickrPhotosData
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case photos
        case status = "stat"
    }
}

struct FlickrPhotosData: Decodable {
    let pageNumber: Int
    let numberOfPages: Int
    let photosPerPage: Int
    let totalNumberOfPhotos: Int
    let photos: [PhotoData]
    
    enum CodingKeys: String, CodingKey {
        case pageNumber = "page"
        case numberOfPages = "pages"
        case photosPerPage = "perpage"
        case totalNumberOfPhotos = "total"
        case photos = "photo"
    }
}

struct PhotoData: Decodable {
    let id: String
    let title: String
    let mediumSizeURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case mediumSizeURL = "url_m"
    }
}
