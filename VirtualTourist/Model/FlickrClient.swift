//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Khalil Kum on 6/26/21.
//

import Foundation

class FlickrClient {
    static let apiKey = ProcessInfo.processInfo.environment["flickrApiKey"]
    static let keySecret = ""

    enum Endpoints {
        static let baseUri = "https://www.flickr.com/services/rest/?format=json&nojsoncallback=1&per_page=5&method=flickr.photos.search"
        static let radius = 5
        case getFlickrPhotos(Double, Double, Int, Int)

        var urlString: String {
            switch self {
            case .getFlickrPhotos(let lat, let lon, let perPage, let pageNum):
                return Endpoints.baseUri + "&api_key=\(FlickrClient.apiKey ?? "")" + "&lat=\(lat)" + "&lon=\(lon)" + "&per_page=\(perPage)" + "&page=\(pageNum)" + "&radius=\(Endpoints.radius)" + "&extras=url_m"
            }
        }

        var url: URL {
            return URL(string: urlString)!
        }
    }

    class func buildSearchURL(lat: Double, lon: Double, pageNum: Int, photosPerPage: Int) -> URL {
        let searchURL = Endpoints.getFlickrPhotos(lat, lon, photosPerPage, pageNum).url
        
        return searchURL
    }
}

extension FlickrClient {
    class func searchFlickerPhotos(latitude: Double, longitude: Double, pageNum: Int = 0, photosPerPage: Int = 30, completionHandler: @escaping (FlickrPhotosData?, Error?) -> Void) {
        let url = buildSearchURL(lat: latitude, lon: longitude, pageNum: pageNum, photosPerPage: photosPerPage)
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                
                return
            }
            
            let decoder = JSONDecoder()

            do {
                let responseObject = try decoder.decode(FlickrSearchPhotosResponse.self, from: data)
                
                DispatchQueue.main.async {
                    completionHandler(responseObject.photos, nil)
                }
            } catch {
                do {
                    let errorResponseObject = try decoder.decode(FlickrErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(nil, errorResponseObject)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completionHandler(nil, error)
                    }
                }
            }
        }
        
        task.resume()
    }
    
    class func downloadPhoto(_ imageURL: URL, completion: @escaping (Data?, Error?) -> Void) {
         
         let request = URLRequest(url: imageURL)
         let task = URLSession.shared.dataTask(with: request) { data, response, error in
             DispatchQueue.main.async {
                if let data = data {
                    completion(data, nil)
                } else {
                    completion(nil, error)
                }
             }
         }
         task.resume()
    }
}
