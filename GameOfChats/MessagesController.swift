//
//  ViewController.swift
//  GameOfChats
//
//  Created by Abz Maxey on 16/01/2017.
//  Copyright © 2017 Abz Maxey. All rights reserved.
//

import UIKit
import Firebase

class MessagesViewController: UITableViewController {
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    let cellID = "MessagesCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "new_message_icon"), style: .plain, target: self, action: #selector(handleNewMessage))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        checkIfUserIsLoggedIn()
        tableView.register(UserCell.self, forCellReuseIdentifier: cellID)
       //Enable delete
       tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    // Actions for delete in every row
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        print(indexPath.row)
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return //if error
        }
        let message = messages[indexPath.row]
        if let chatPartnerId = message.chatPartnerId(){
            // Storage - user-message - current user's node - chat partner's node - delete
            FIRDatabase.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (err, ref) in
                if err != nil{
                    print("Unable to delete", err!)
                    return
                }
                
                self.messagesDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadOfTable() //reload data
                //self.messages.remove(at: indexPath.row)
                //self.tableView.deleteRows(at: [indexPath], with: .automatic)
            })
        }
    }

    func observeUserMessages() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else{
            return
        }
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid)
        
        ref.observe(.childAdded, with: { (snapshot) in
           //print(snapshot)
            
          let userId = snapshot.key // got from there ^^ messages exclusive to current user
            
          // 16
          ref.child(userId).observe(.childAdded, with: { (snapshot) in
            print(snapshot)
            let messageId = snapshot.key
            self.fetchMessageWith(messageId: messageId)
          }, withCancel: nil)
        }, withCancel: nil)
        
        // When a message thread is deleted outside the app
        ref.observe(.childRemoved, with: { (snapshot) in
            print(snapshot.key)
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
        }, withCancel: nil)
    }
    
    private func fetchMessageWith(messageId: String){
        //copy paste previous. get from messages table
        let messageReference = FIRDatabase.database().reference().child("messages").child(messageId)
        messageReference.observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            
            //copy paste old observer, since we use the same logic but now its exclusive to theirs ( sent items )
            if let dictionary = snapshot.value as? [String: AnyObject]{
                let message = Message(dictionary:dictionary)
                //message.setValuesForKeys(dictionary)
                // BUG FIX toID = chatPartner ID , one log per chat
                if let chatPartnerID = message.chatPartnerId(){
                    self.messagesDictionary[chatPartnerID] = message
                }
                // ep 13 sort moved, so once only
            }
            self.attemptReloadOfTable()
        }, withCancel: nil)
    }
    
    private func attemptReloadOfTable() {
        // save computation
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (msg1, msg2) -> Bool in
            return (msg1.timeStamp?.intValue)! > (msg2.timeStamp?.intValue)!
        })
        
        // BUG FIX - multiple reloadTable, flickering of imageViews in chatlog
        self.timer?.invalidate()
        //print("Invalidate")
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    var timer: Timer?
    
    func handleReloadTable(){
        //this will crash because of background thread, so lets call this on dispatch_async main thread
        DispatchQueue.main.async(execute: {
           // print("reload")
            self.tableView.reloadData()
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "MessagesCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! UserCell // so that we can use its properties!
        
        let message = self.messages[indexPath.row]
        cell.message = message
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[indexPath.row]
        //print(message.toID,message.fromID, message.text)
        
        guard let chatPartnerId = message.chatPartnerId() else{
            return
        }
        let ref = FIRDatabase.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: AnyObject] else{
                return
            }
                let user = User()
                user.id = chatPartnerId
                user.setValuesForKeys(dictionary)
                self.showChatController(user: user)
            
        }, withCancel: nil)
    }
    
    func handleNewMessage() {
        print("New message")
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self //delegation
        
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    func checkIfUserIsLoggedIn() {
        // IF user is not logged in
        if FIRAuth.auth()?.currentUser == nil{
            perform(#selector(handleLogout), with: nil, afterDelay: 0) // prevent the "unbalance" error
        }else{
        // IF User is Logged IN
            self.fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else{
            //for some reason, uid is nil (opposite sa if let)
            return
        }
        FIRDatabase.database().reference().child("users").child(uid).observe(.value, with: { (snapshot) in
            print(snapshot)
            
            if let dictionary = snapshot.value as? [String : Any]{
                //self.navigationItem.title = dictionary["name"] as? String
                let user = User()
                user.setValuesForKeys(dictionary)
                self.setNavBarWithUser(user: user)
                
            }
        }, withCancel: nil)
    }
    func setNavBarWithUser(user: User) {
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)

        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        if let profileImage = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImage)
        }
        
        let nameLabel = UILabel()
        containerView.addSubview(nameLabel)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Profile Image constraints x,y,w,h
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // Name Label Constraints x,y,w,h
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true // width , y?  
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        //extendable
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))
        self.navigationItem.titleView = titleView
        
    }
    
    func showChatController(user: User){
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    
    }

    func handleLogout(){
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print(logoutError)
        }
        print("User has logged out")
        
        let loginController = LoginController()
        loginController.messagesController = self  // navbar title update fix
        
        present(loginController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

