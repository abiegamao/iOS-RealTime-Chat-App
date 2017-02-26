//
//  ChatMessageCell.swift
//  GameOfChats
//
//  Created by Abz Maxey on 24/01/2017.
//  Copyright © 2017 Abz Maxey. All rights reserved.
//

import UIKit

class ChatMessageCell: UICollectionViewCell {
    
    var chatLogController : ChatLogController?
    
    let textView : UITextView = {
        let tv = UITextView()
        tv.text = "Sample Text"
        tv.font = UIFont.systemFont(ofSize: 16) //12 - causing the bigspace
        tv.translatesAutoresizingMaskIntoConstraints =  false
        tv.backgroundColor = UIColor.clear
        tv.textColor = UIColor.white
        tv.isEditable = false
       // tv.backgroundColor = UIColor.yellow
        return tv
    }()
    
    static var blueColor: UIColor = UIColor(r: 0, g: 137, b: 249)
    
    let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = blueColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
    
        return view
    }()
    
    let profileImageView: UIImageView = {
     
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var messageImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.clear
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))
        return imageView
    
    }()
    func handleZoomTap(tapGesture: UITapGestureRecognizer) {
        print("image tapped")
        if let imageView = tapGesture.view as? UIImageView{
            chatLogController?.performZoomIn(startingImageView: imageView) 
        }
        
    }
    var bubbleWidthAnchor : NSLayoutConstraint?
    var bubbleRightAnchor : NSLayoutConstraint?
    var bubbleLeftAnchor : NSLayoutConstraint?
    var imageViewRightAnchor : NSLayoutConstraint?
    var imageViewLeftAnchor : NSLayoutConstraint?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white

        addSubview(bubbleView)
        addSubview(textView)
        addSubview(profileImageView)
        bubbleView.addSubview(messageImageView)
        
        //msgimageview const
        messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        messageImageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
        messageImageView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
        
        
        
        //textview constraints
        //textView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        textView.leftAnchor.constraint(equalTo: self.bubbleView.leftAnchor, constant: 8).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        //textView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        textView.rightAnchor.constraint(equalTo: self.bubbleView.rightAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        //profileImageView constraints
        // GREY - their messages
        imageViewLeftAnchor = profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8)
        //imageViewLeftAnchor?.isActive = true
        // BlUE - my messages
        imageViewRightAnchor = profileImageView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 5)
        imageViewRightAnchor?.isActive = true
        
        
        //x,y,w,h cons
        profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true

        
        //bubbleView constraints
        bubbleRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubbleRightAnchor?.isActive = true
        
        bubbleLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: self.profileImageView.rightAnchor, constant: 8)
       // bubbleLeftAnchor?.isActive = true
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        self.bubbleWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
