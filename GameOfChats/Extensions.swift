//
//  Extensions.swift
//  GameOfChats
//
//  Created by Abz Maxey on 20/01/2017.
//  Copyright © 2017 Abz Maxey. All rights reserved.
//

//import Foundation
import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()


extension UIImageView {
    func loadImageUsingCacheWithUrlString(urlString: String) {
        //prevent flashing
        
        self.image = nil
        
        //if image already in cache, load this
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject ) as? UIImage{
            self.image = cachedImage
            return
        }
        
        
        // if new image is being downloaded
        let url = NSURL(string: urlString)
        let request = URLRequest(url: url as! URL)
        URLSession.shared.dataTask(with: request,
           completionHandler: {
            (data, response, error) in
            if error != nil {
                
                print(error ?? "")
                return
             }
            
            //REQUIRED For images to load
            DispatchQueue.main.async(execute: {
                if let downloadedImage = UIImage(data: data!){
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    self.image = downloadedImage
                }
               
     
            })
            
        }).resume()

    }

}
