//
//  NewMessageController.swift
//  GameOfChats
//
//  Created by Abz Maxey on 18/01/2017.
//  Copyright © 2017 Abz Maxey. All rights reserved.
//

import UIKit
import Firebase


class NewMessageController:UITableViewController {
    let cellID = "cellID"
    var users = [User]()
    var messagesController: MessagesViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "New Message"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        //register table cell
        tableView.register(UserCell.self, forCellReuseIdentifier: cellID)
        fetchUSer()
    }
    
     func fetchUSer()  {
        FIRDatabase.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            print(snapshot)
            if let dictionary = snapshot.value as? [String: Any]{
                let user = User()
                user.id = snapshot.key
                // if you use this setter , your app will crash if your class properties does not match Firebase properties
                user.setValuesForKeys(dictionary)
               // print(user.name, user.email)
                self.users.append(user)
                
                // this will crash because of background thread, so lets use dispatch_async to fix
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
    
    func handleCancel()  {
        print("Cancel")
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellID)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? UserCell
        let user = users[indexPath.row]
        cell?.textLabel?.text = user.name
        cell?.detailTextLabel?.text = user.email

        if let profileImageUrl = user.profileImageUrl{
            cell?.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: nil)
        print("dismiss completed")
        let user = self.users[indexPath.row]
        self.messagesController?.showChatController(user: user)
    }
}

