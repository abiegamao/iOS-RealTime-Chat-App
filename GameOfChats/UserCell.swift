//
//  UserCell.swift
//  GameOfChats
//
//  Created by Abz Maxey on 22/01/2017.
//  Copyright © 2017 Abz Maxey. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell {
    let dateFormatter : DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "hh:mm:ss a"
        return df
    }()
    
    var message: Message? {
        didSet{
            setUpNameAndProfileImage()
            self.detailTextLabel?.text = message?.text
            if let seconds = message?.timeStamp?.doubleValue{
                let timeStampDate = Date(timeIntervalSince1970: seconds)

                self.timeLabel.text = dateFormatter.string(from: timeStampDate)// YYYY-MM-DD HH:MM:SS
            }
        }
    }
    
    func setUpNameAndProfileImage() {
        self.profileImageView.image = nil

        if let id = message?.chatPartnerId() {
            let ref = FIRDatabase.database().reference().child("users").child(id)
            
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject]{
                    self.textLabel?.text = dictionary["name"] as? String
                    
                    if let profileImageUrl = dictionary["profileImageUrl"] as? String {
                        self.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
                    }
                    
                }
            }, withCancel: nil)
        }
    }
    
    let profileImageView : UIImageView  = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "abz_logo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let timeLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        addSubview(profileImageView)
        addSubview(timeLabel)
        
        // ios 10 constraint anchors
        // x,y,w,h
        self.profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        self.profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        self.profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        self.timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 15).isActive = true
        self.timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        self.timeLabel.heightAnchor.constraint(equalTo: (self.textLabel?.heightAnchor)!).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.frame = CGRect(x: 64, y: ( textLabel?.frame.origin.y)! - 2, width: (textLabel?.frame.width)!, height: (textLabel?.frame.height)!)
        detailTextLabel?.frame = CGRect(x: 64, y: ( detailTextLabel?.frame.origin.y)! + 2, width: (detailTextLabel?.frame.width)!, height: (detailTextLabel?.frame.height)!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
