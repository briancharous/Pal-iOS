//
//  PalConnection.swift
//  Pal-iOS
//
//  Created by Brian Charous on 2/5/15.
//  Copyright (c) 2015 The Best Comps Team. All rights reserved.
//

import Foundation

class PalConnection: NSObject {
    
    let kBaseUrl = "http://localhost:5000/api/pal"
   
    func queryPal(query: String) -> NSDictionary? {
        let requestUrl = NSURL(string: kBaseUrl)
        var request = NSMutableURLRequest(URL: requestUrl!)
        request.HTTPMethod = "POST"
        let params = "query=\(query.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)&client=iOS"
        println(params)
        request.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding)
        var response : NSURLResponse?
        var error : NSError?
        let result = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
        if let _error = error {
            println("\(_error.localizedDescription)")
            return nil
        }
        else {
            var jsonError : NSError?
            let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(result!, options: nil, error: &jsonError)
            if let _jsonError = jsonError {
                println("\(_jsonError.localizedDescription)")
                return nil
            }
            if let jsonDict : NSDictionary = json as? NSDictionary {
                return jsonDict
            }
        }
        return nil
    }
}
