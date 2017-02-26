//
//  LoginController+handlers.swift
//  GameOfChats
//
//  Created by Abz Maxey on 18/01/2017.
//  Copyright © 2017 Abz Maxey. All rights reserved.
//

import UIKit
import Firebase


extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    
    // MARK: Segmented Control Action
    func handleLoginRegisterSC() {
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        
        //Change height of Inputs Container View Height
        inputsContainerViewHeightAnchor?.constant =
            loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 100 : 150
        
        // Hide Name Textfield, Name Separator
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0: 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        nameTextField.isHidden = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? true : false
        nameSeparatorView.isHidden = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? true : false
        
        // 1/2 them
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
        
    }

    // MARK: Profile Image
    func handleProfileImageView()  {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print(info)
        
        var selectedImageFromPicker: UIImage?
        
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        print(selectedImageFromPicker?.size ?? "")
        if let selectedImage = selectedImageFromPicker {
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.image = selectedImage
        }
        


        dismiss(animated: true, completion: nil)

    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("ic cancelled image picker")
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: User Authentication
    func handleLoginRegister(){
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0{
            handleLogin()
        }else{
            handleRegister()
         }
    }
    
    // LOGIN
    func handleLogin(){
        guard
            let email = emailTextField.text,
            let password = passwordTextField.text else{
                print("Form is not valid")
                return
        }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil{
                print(error?.localizedDescription ?? "")
                // Display a pop-up warning/error
                let alert = UIAlertController(title: "Try Again", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            //updates messages view controllers navbar title
            self.messagesController?.fetchUserAndSetupNavBarTitle()
            
            self.dismiss(animated: true, completion: nil)
            //Successful User Login
            print("Existing User has successfully logged in.")
            
        })
    }
    // REGISTER
    func handleRegister(){
        print("Register")
        guard
            let email = emailTextField.text,
            let password = passwordTextField.text,
            let name = nameTextField.text else{
                print("Form is not valid")
                return
        }
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            if error != nil{

                let errorString: String
                
                // Handle errors
                if let errCode = FIRAuthErrorCode(rawValue: error!._code) {
                    switch errCode {
                        case .errorCodeInvalidEmail: errorString = "Invalid Email"
                        default:  errorString = (error?.localizedDescription)!
                    }
                    // Display a pop-up warning/error
                    let alert = UIAlertController(title: "Try Again", message: errorString, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            // ---- After a successful registration, user is automatically logged-in / authenticated -----
            
            // User ID to be primary Key
            guard let uid = user?.uid else{
                return
            }
            
            let imageName = UUID().uuidString
            
            // Call Firebase Storage for uploading of profile image
            let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            
            // JPEG compression
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1){
                storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                    if error != nil{
                        print(error ?? "")
                        return
                    }
                    //Successful upload
                    print(metadata ?? "")
                    
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString{
                        let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl]
                        self.registerUserIntoDatabaseWithUID(uid: uid, values: values as [String : AnyObject])
                    }
                    
                
                        
                })
            }
            
        })
    }

    
           
    
    func registerUserIntoDatabaseWithUID(uid: String, values: [String : AnyObject]) {
        // Call Firebase Database to store new user
        let ref = FIRDatabase.database().reference() //(fromURL: "https://chatapp-c130d.firebaseio.com/") pwede hardcoded
        let userRef = ref.child("users").child(uid)
        //
        
        userRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil{
                print(error?.localizedDescription ?? "")
                return
            }
            
            //Successful Update database
            print("User saved successfully authenticated into Firebase DB.")
            
            //updates messages view controllers navbar title
            //self.messagesController?.fetchUserAndSetupNavBarTitle()
            //self.messagesController?.navigationItem.title = values["name"] as? String
            let user = User()
            user.setValuesForKeys(values)
            self.messagesController?.setNavBarWithUser(user: user)
            
            //Dismiss current View Controller
            self.dismiss(animated: true, completion: nil)
        })

    }

}
