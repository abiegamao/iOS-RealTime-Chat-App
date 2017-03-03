//
//  Message.swift
//  GameOfChats
//
//  Created by Abz Maxey on 22/01/2017.
//  Copyright © 2017 Abz Maxey. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject{
    var fromID: String?
    var text: String?
    var toID: String?
    var timeStamp: NSNumber?
    var imageUrl: String?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    var videoUrl: String?
    
    func chatPartnerId() -> String? {
        //whos gonna show up in the messages
        // if logged in user is sender, show the other parties picture
        return fromID == FIRAuth.auth()?.currentUser?.uid ? toID : fromID
    }
    
    init(dictionary: [String:AnyObject]) {
        super.init()
        fromID = dictionary["fromID"] as? String
        toID = dictionary["toID"] as? String
        text = dictionary["text"] as? String
        timeStamp = dictionary["timeStamp"] as? NSNumber
        imageUrl = dictionary["imageUrl"] as? String
        imageWidth = dictionary["imageWidth"] as? NSNumber
        imageHeight = dictionary["imageHeight"] as? NSNumber
        videoUrl = dictionary["videoUrl"] as? String
    }

}
