 //
//  ChatLogController.swift
//  GameOfChats
//
//  Created by Abz Maxey on 20/01/2017.
//  Copyright © 2017 Abz Maxey. All rights reserved.
//
 
import UIKit
import Firebase
import MobileCoreServices
import AVFoundation


class ChatLogController: UICollectionViewController, UITextFieldDelegate,
UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    let cellID = "cellId"
    var user: User?{
        didSet{
         navigationItem.title = user?.name
        observeMessages(user: user)
        }
        
        
    } // dapat ma optional
    
    var messages = [Message]()
    
    func observeMessages(user: User?) {
        //ep 16 - optimize
        guard let uid = FIRAuth.auth()?.currentUser?.uid
                , let toID = user?.id // switch, get from id / to id
                else{
                    return
                }
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toID)
        
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
           let messageId = snapshot.key
           let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String: AnyObject] else{
                    return
                }

                
                self.messages.append(Message(dictionary:dictionary))
                DispatchQueue.main.async(execute: {
                    self.collectionView?.reloadData()
                     if self.messages.count > 0 {
                        self.collectionView?.scrollToBottom()
                    }

                })

                
                
            }, withCancel: nil)
        }, withCancel: nil)
        
        
        
        
    } 
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //navigationItem.title  = user?.name // "Chat Log Controller"
        // PADDING
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //scrollbar same with padding - ish
/*
        collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        */
        
        collectionView?.alwaysBounceVertical = true // draggable vertically
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellID)
        
        //ep15
        collectionView?.keyboardDismissMode = .interactive
/*
        setUpInputComponents()*/
        
        setUpKeyboardObservers()


    }
    
    
    
    //FOR KEYBOARD
/*
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white

        
        containerView.addSubview(self.inputTextField)
        //x,y,w,h
        self.inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        

        return containerView
    }()*/

    func handleUploadTap() {
        print("We tapped upload")
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        //When Video is selected
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL{
            print("Here's the link of the url \(videoUrl)")
            handleVideoSelected(url: videoUrl)
        }else{
            handleImageSelected(info: info)
        }
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelected(url: URL){
        let fileName = UUID().uuidString + ".mov" // generate new file name
        let uploadTask = FIRStorage.storage().reference().child("message_videos").child(fileName).putFile(url, metadata: nil, completion: { (metadata, error) in
            
            if error != nil{
                print("Error uploading data", error!)
                return
            }
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString{
               // print(storageUrl)
                if let thumbnailImage = self.thumbnailImageForFileUrl(url: url){
                    // missing: image URL
                    self.uploadToFirebaseStorage(image: thumbnailImage, completion: { (imageUrl) in
                        let properties = ["imageUrl": imageUrl as AnyObject, "imageWidth": thumbnailImage.size.width as AnyObject, "imageHeight": thumbnailImage.size.height as AnyObject, "videoUrl": videoUrl as AnyObject ]
                        self.sendMessageWithProperties(properties: properties)
                    })

                }

            }
        })
        // Progress
        uploadTask.observe(.progress) { (snapshot) in
            if let computedUnitCount = snapshot.progress?.completedUnitCount{
                self.navigationItem.title = String(computedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    // --- For Videos
    func sendMessageWithVideoUrl(imageUrl: String, image: UIImage) {
       // let thumbnailImage = self.thumbnailImageForFileUrl(url: imageUrl)


        
    }
    
    func thumbnailImageForFileUrl(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60) , actualTime: nil)
            return UIImage(cgImage: cgImage)
        }catch let err{
            print(err)
        }
        
        
        return nil
    }
    
    
    private func handleImageSelected(info: [String: Any]){
        // We selected an image        
        var selectedImageFromPicker: UIImage?
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        print(selectedImageFromPicker?.size ?? "")
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorage(image: selectedImage, completion: { (url) in
                self.sendMessageWithImageUrl(imageUrl: url, image: selectedImage)
            })
            
        }
    }
    
    
    
    func uploadToFirebaseStorage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
        print("Upload to firebase")

        let imageName = UUID().uuidString
        let ref = FIRStorage.storage().reference().child("message_images").child("\(imageName).jpg")
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2){
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                if error   != nil{
                    print("Error uploading: \(error)")
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString{
                    completion(imageUrl)
                }
               // print(metadata?.downloadURL()?.absoluteString as Any)
            })
        }
        

    }
    
    // --- For Text
    func handleSend(){
         let properties = ["text":inputContainerView.inputTextField.text! as AnyObject]
         self.sendMessageWithProperties(properties: properties)
    }
    
    
    // --- For Images
    func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        let properties = ["imageUrl": imageUrl as AnyObject, "imageWidth": image.size.width as AnyObject, "imageHeight": image.size.height as AnyObject]
        self.sendMessageWithProperties(properties: properties)
    }
    

    func sendMessageWithProperties(properties: [String: AnyObject]) {
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toID = user!.id!
        let fromID = FIRAuth.auth()!.currentUser!.uid
        // modift for image url
        let timeStamp: NSNumber = NSNumber(value: Int(Date().timeIntervalSince1970))
        // basic properties
        var values : [String: AnyObject] = ["toID" : toID as AnyObject, "fromID": fromID as AnyObject, "timeStamp": timeStamp]
        
        // append - additional properties ep 18 [text/image/video]
        // $0: key - $1: value
        properties.forEach({values[$0] = $1})

        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error?.localizedDescription ?? "")
                return
            }
            
            self.inputContainerView.inputTextField.text = nil
            
            //ep 16 fix - optimize chat log
            //success update // SENT-MESSAGES
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromID).child(toID)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            // RECEIVED MESSAGES
            let receipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toID).child(fromID)
            receipientUserMessagesRef.updateChildValues([messageId: 1])
            
        }

        
    }
    


    lazy var inputContainerView: ChatInputContainerView = { // lazy var to access self
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
    }()
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
           
        }
    }
    
    override var canBecomeFirstResponder : Bool { // crucial for interactive keyboard and components to show
        return true
    }
    
    // KEYBOARD METHODS
    func setUpKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
       /*
 NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)*/

    }
    func handleKeyboardDidShow() {
        // avoid crashing
        if self.messages.count > 0 {
            //let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
            self.collectionView?.scrollToBottom() //fix for crashing!
        }
    }
    
    func handleKeyboardWillShow(notification: Notification){
        let keyboardFrame = ((notification as
            NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as
            AnyObject).cgRectValue
        
        let keyboardDuration = ((notification as NSNotification).userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        //print(keyboardFrame?.height)
        //keyboard show bug fix
        containerViewBottomLayout?.constant = -(keyboardFrame!.height)
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    func handleKeyboardWillHide(notification: Notification) {
        // so container goes with the keyboard
        let keyboardDuration = ((notification as NSNotification).userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        containerViewBottomLayout?.constant = 0
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    // Method call when rotated
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout() // the fix to blend with my constraints
    }
    
    
    var containerViewBottomLayout : NSLayoutConstraint?
 
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! ChatMessageCell
        
        //chatlogreference ep19
        cell.chatLogController = self
        
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        cell.message = message
        
        setUpCell(message: message, cell: cell)
        
        // Modify BubbleView's width
        if let messageText = message.text { // Text
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: messageText).width + 30 //tricky
            cell.textView.isHidden = false
        }else if message.imageUrl != nil{   // Image
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        // Play button only appears on videos
        cell.playButton.isHidden = message.videoUrl == nil

        return cell
    }
    
    func setUpCell(message: Message, cell: ChatMessageCell) {
        if let profileImageUrl = self.user?.profileImageUrl{ // user is partner
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }

        // Chat bubble View Coloring
        if message.fromID == FIRAuth.auth()?.currentUser?.uid {
            //grey - incoming message
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            // flip
            cell.bubbleRightAnchor?.isActive = true
            cell.bubbleLeftAnchor?.isActive = false
            cell.profileImageView.isHidden = true
        }else{
            //blue - outgoing message
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.bubbleRightAnchor?.isActive = false
            cell.bubbleLeftAnchor?.isActive = true // partner message move to left
            
            cell.imageViewRightAnchor?.isActive = false
            cell.imageViewLeftAnchor?.isActive = true // partner image move to left
            cell.profileImageView.isHidden = false
            
        }
        
        // ep 17 - last part of this method so bubbleblue color goes away
        if let messageImageUrl = message.imageUrl {
            cell.bubbleView.backgroundColor = UIColor.clear
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
        }else{
            cell.messageImageView.isHidden = true
            
        }
        
    }
    
    func estimateFrameForText(text: String) -> CGRect { // for text block
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin);
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height:CGFloat = 80
        
        
        let message = messages[indexPath.item]
        // get estimated text somehow
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 15
        }else if let imageWidth = message.imageWidth?.floatValue,
                let imageHeight = message.imageHeight?.floatValue {
            
            // h1/w1 = h2/w2
            // w1 = 200
            // h1/200 = h2/w2
            // h1 = h2/w2 * 200
            // minimized size
            height = CGFloat(imageHeight/imageWidth * 200)
        }
        // transition rotate fix frame.width to this
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    

    
    func indexPathIsValid(indexPath: IndexPath) -> Bool {
        if indexPath.section >= (collectionView?.numberOfSections)!  {
            return false
        }
        if indexPath.row >= (collectionView?.numberOfItems(inSection: 0))! {
            return false
        }
        return true
    }
    

    func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        print("Zoom out")
        if let zoomOutImageView = tapGesture.view{
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            //much better animation
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: { 
                zoomOutImageView.frame = self.startingFrame!
                self.blackBGView?.alpha = 0
                self.inputContainerView.alpha = 1 // comes back

            }, completion: { (bool) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
        }
    }
    
    var startingFrame : CGRect?
    var blackBGView: UIView?
    var startingImageView: UIImageView?
    
    func performZoomIn(startingImageView: UIImageView) {
        print("Zoom")
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
            print(self.startingFrame!)
            let zoomingImageView = UIImageView(frame: self.startingFrame!)
            zoomingImageView.backgroundColor = UIColor.black
            zoomingImageView.image = startingImageView.image
            zoomingImageView.isUserInteractionEnabled = true
            zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
                
            if let keyWindow = UIApplication.shared.keyWindow{
                blackBGView = UIView(frame: keyWindow.frame)
                blackBGView?.backgroundColor = UIColor.black
                blackBGView?.alpha = 0
                keyWindow.addSubview(blackBGView!) // before so behind
                
                keyWindow.addSubview(zoomingImageView)
                //math to get height when the keywindow frame width is the default width
                let defaultWidth = keyWindow.frame.width
                let frame = startingImageView.frame
                //h1/w1 = h2/w2
                let height = frame.height / frame.width * defaultWidth
                
                // animation
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    zoomingImageView.frame = CGRect(x: 0, y: 0, width: defaultWidth, height: height )
                    //keyWindow.frame.midY - startingFrame.height / 2
                    //easy center

                    self.blackBGView?.alpha = 1
                    self.inputContainerView.alpha = 0 // hide text area
                    zoomingImageView.center = keyWindow.center

                }, completion: nil)
            // zoomingImageView.isHidden = true
            }
        }
        //end
    

}
 
// fix for crashing in scrolling!!
extension UICollectionView {
    func scrollToBottom() {
        if self.numberOfSections > 1 {
            let lastSection = numberOfSections - 1
            self.scrollToItem(at: IndexPath(row: self.numberOfItems(inSection: lastSection - 1), section: lastSection), at: .bottom, animated: true)
        } // we need this coz sometimes this doesnt load // net connection// abrupt change of vcs
        else if numberOfItems(inSection: 0) > 0 && self.numberOfSections == 1 {
            
            self.scrollToItem(at: IndexPath(row: numberOfItems(inSection: 0)-1, section: 0), at: .bottom, animated: true)
            
        }
    }
}
