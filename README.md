# Secret Swift

An iOS app that demonstrates the use of Keychain, Notification Center, as well as Local Authentication.

<img src="https://github.com/igibliss00/Secret-Swift/blob/master/README_assets/3.png" width="400">

<img src="https://github.com/igibliss00/Secret-Swift/blob/master/README_assets/4.png" width="400">

<img src="https://github.com/igibliss00/Secret-Swift/blob/master/README_assets/5.png" width="400">

## Features

Notification Center is part of the Foundation framework that broadcasts information to registered observers.  The method to register an observer is addObserver(_:selector:name:object: ).  
- The first parameter, which is the underscore here, is the object to register as an observer, which is usually the self. 
- selector: This is the method to be called when the observed event happens.  The method receives a single argument, which is the instance of NSNotification.  
- name: The third parameter is the name of the notification to be observed
- object: The final parameter is an optional object whose notifications you want to receive from only. 

In order for the notification process to work, there has to be three parties involved: the sender, the observer, and the notification centre.  The sender and the observer don’t have to know each other since the notification centre relays the messages for them.  You can create your own sender function:

```
NotificationCenter.default.post(name: .didReceiveData, object: nil)
```

and register the name so that when you create an observer,  you know to specify which event you want to listen for. 

```
extension Notification.Name {
    static let didReceiveData = Notification.Name("didReceiveData")
}
```

Above defines the custom name of the event that you want to broadcast and observe.

There are iOS built-in events that you don’t have to create the methods for yourself, nor create the name of the event for, but only have to listen for. One of them is the UIResponder that we used in this current project.

UIResponder is part of the UIKit that deals with all the UI-related events. To be more precise, as an event gets generated from either UIViewController, UIView, or UIApplication, UIKit dispatches the events to the responder object, which is an instance of UIResponder, to be handled.  The events are things like motion events, touch events, remote-control events, and press events.  

```
notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object:nil)
notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
```

Here, you don’t have to create the “post” method to broadcast the changes in the keyboard’s state because UIKit will automatically broadcast that for you.  You also don’t have to create your own custom name to listen for because UIResponder.keyboardWillHideNotification and UIResponder.keyboardWillChangeFrameNotification are already the designated names.


### Responder Chain

As specified above, a responder object, which is an instance of the UIResponder (whose subclass includes UIView, UIViewController, and UIApplication), receives the raw event data when some event happens.  But, which responder object?  UIKit determines which responder object is the most appropriate, known as the first responder.  So, depending on where the even was generated from, whether it be from UIApplication or UIView, or depending on what type of an event it is, whether it be a touch event, or a motion event, etc, UIKit will feed the raw data to what it deems as the first responder.   

<img src="https://github.com/igibliss00/Secret-Swift/blob/master/README_assets/1.png" width="400">

When the first responder object doesn’t handle the event, however, it can pass it forward to another responder object and this is called the responder chain. 

<img src="https://github.com/igibliss00/Secret-Swift/blob/master/README_assets/2.png" width="400">

You can also deliberately make a responder relinquish its status as first responder.  In fact, that’s exactly happens in this project:

```
@objc func saveSecretMessage() {
    guard secret.isHidden == false else { return }

    KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
    secret.resignFirstResponder()
    secret.isHidden = true
    title = "Nothing to see here"
}
```

“Secret”, which is the UITextView, is the first responder because it’s the control that activates the keyboard and is receiving input.  By using the “resignFirstResponder()” method, Secret stops waiting for input and dismisses the keyboard.  The event gets passed onto another responder object. 

### Main Thread

Face ID and Touch ID should be executed on the main thread using DispatchQueue’s async() method:

```
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
    let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication", preferredStyle: .alert)
    ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    present(ac, animated: true)
}
```
