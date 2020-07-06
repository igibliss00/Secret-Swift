//
//  ViewController.swift
//  Project28
//
//  Created by jc on 2020-07-05.
//  Copyright © 2020 J. All rights reserved.
//
import LocalAuthentication
import UIKit

class ViewController: UIViewController {
    @IBOutlet var secret: UITextView!
    var isUnlocked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object:nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @IBAction func authenticateTapped(_ sender: Any) {
        let context = LAContext()
        // objc for Swift error type
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self](success, authenticationError) in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            // no biemetry
            let ac = UIAlertController(title: "Biometry unavailable", message: "Use your passowrd to log in", preferredStyle: .alert)
            ac.addTextField()
            let password = KeychainWrapper.standard.string(forKey: "password")
            if password != "" {
                ac.addAction(UIAlertAction(title: "Enter", style: .default, handler: { [weak self, weak ac](_) in
                    guard let answer = ac?.textFields?[0].text else { return }
                    if password == answer {
                        self?.unlockSecretMessage()
                    } else {
                        // wrong password
                        let wrongPasswordController = UIAlertController(title: "Wrong Password", message: nil, preferredStyle: .alert)
                        wrongPasswordController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self?.present(wrongPasswordController, animated: true)
                    }
                }))
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(ac, animated: true)
            } else {
                // no pre-existing password. Create a new one
                let passwordController = UIAlertController(title: "Create a new password", message: nil, preferredStyle: .alert)
                passwordController.addTextField()
                passwordController.addAction(UIAlertAction(title: "Done", style: .default, handler: { (_) in
                    guard let newPassword = passwordController.textFields?[0].text else { return }
                    KeychainWrapper.standard.set(newPassword, forKey: "password")
                }))
                passwordController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(passwordController, animated: true)
            }
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEnd = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEnd, from:view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    func unlockSecretMessage() {
        secret.isHidden = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveSecretMessage))
        title = "Secret Stuff!"
        secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
    }
    
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return }
        
        KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
        secret.resignFirstResponder()
        secret.isHidden = true
        navigationItem.rightBarButtonItem = nil
        title = "Nothing to see here"
    }
}
