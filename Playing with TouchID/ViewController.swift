//
//  ViewController.swift
//  Playing with TouchID
//
//  Created by Varad Pathak on 12/10/16.
//  Copyright © 2016 Varad Pathak. All rights reserved.
//  Copyright © 2016 MobileFirst (http://mobilefirst.in)

//

import UIKit
import LocalAuthentication

class ViewController: UIViewController, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, EditNoteViewControllerDelegate {

    @IBOutlet weak var tblNotes: UITableView!
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var btnSettings: UIButton!
    @IBOutlet weak var settingsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var chromeView: UIView!
    @IBOutlet weak var touchIDToggle: UISwitch!
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var dataArray: NSMutableArray = NSMutableArray()
    
    var noteIndexToEdit: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tblNotes.delegate = self
        tblNotes.dataSource = self
        
        tblNotes.tableFooterView = UIView()
        
        tblNotes.allowsSelection = true
        
        //authenticateUser()
        
        self.makeBorders(sender: settingsView)
        
        initialSetUp()
        
        // animation constraints
        settingsViewHeightConstraint.constant = 500
        settingsViewWidthConstraint.constant = 400
        settingsView.alpha = 0.0
        chromeView.alpha = 0.0
        
        view.layoutIfNeeded()
        
        // set toggle according to userDefaults.
        if UserDefaults.standard.bool(forKey: "authRequired") == true {
            touchIDToggle.isOn = true
        }
        else {
            touchIDToggle.isOn = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        appDelegate.isShortcut = false
        
        print("did appear")
        
        if appDelegate.didComeFromShortcut == true {
            appDelegate.didComeFromShortcut = false
            
            self.noteWasSaved()
        }
        else {
            return
        }
    }
    
    func initialSetUp() {
        
        if (UserDefaults.standard.string(forKey: "password") == nil) {
            
            fireUpPasswordPrompt()
            UserDefaults.standard.set(true, forKey: "authRequired")
        }
            
        else {
            
            if UserDefaults.standard.bool(forKey: "authRequired") == true {
                
                if appDelegate.isShortcut == true {
                    print("Auth process will not fire")
                }
                else {
                    authenticateUser()
                }
                
            }
            else {
                
                loadData()
            }
        }
    }
    
    func makeBorders(sender: UIView) {
        
        sender.layer.borderWidth = 1.0
        sender.layer.borderColor = (UIColor(colorLiteralRed: 85/255, green: 85/255, blue: 85/255, alpha: 0.7)).cgColor
        sender.layer.cornerRadius = 5.0
    }

    // MARK: Hide All Notes
    @IBAction func hideNotesAction(_ sender: AnyObject) {
        
        if dataArray.count > 0 {
            dataArray.removeAllObjects()
            tblNotes.reloadData()
            
            closeSettingsAction(sender)
            return
        }
        else {
            print("No Notes Found")
        }
    }
    
    // MARK: FIRST TIME PASSWORD
    func fireUpPasswordPrompt() {
        
        let alert: UIAlertController = UIAlertController(title: "Set a Password", message: "This is the first time you have launched the app.", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField(configurationHandler: {(txtField: UITextField!) in
            txtField.placeholder = "Password"
            txtField.keyboardType = UIKeyboardType.numberPad
            txtField.isSecureTextEntry = true
        })
        
        alert.addTextField(configurationHandler: {(txtField: UITextField!) in
            txtField.placeholder = "ReEnter Password"
            txtField.keyboardType = UIKeyboardType.numberPad
            txtField.isSecureTextEntry = true
        })
        
        let confirmAction: UIAlertAction = UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) -> Void in
            
            if (!(alert.textFields?[0].text?.isEmpty)! && !(alert.textFields?[1].text?.isEmpty)!) {
                
                if (alert.textFields![0].text == alert.textFields![1].text) {
                
                UserDefaults.standard.set(alert.textFields![0].text!, forKey: "password")
                
                self.authenticateUser()
                
                }
                    
                else {
                
                    self.fireUpPasswordPrompt()
                }
            
            }
            
            else {
                
                self.fireUpPasswordPrompt()
            }
            
        })
        
        alert.addAction(confirmAction)
        
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: AUTHENTICATE USER (Local Authentication)
    func authenticateUser() {
        
        // 1 Get Local Authentication Context.
        let context : LAContext = LAContext()
        
        // 2 Declare a NSError Variable
        var error: NSError?
        
        // 3 Set the reson string that will appear for on authentication alert.
        let reasonString = "Authentication is needed to access notes."
        
        
        // 4 Check if device can evaluate the policy.
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            // 5 Check for the finger print.
            [ context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: {(success, error) -> Void in
            
                if (success) {
                    
                    OperationQueue.main.addOperation {
                        self.loadData()
                    }
                    
                }
                
                else {
                    // If authentication failed then show a message to the console with a short description.
                    // In case that the error is a user fallback, then show the password alert view.
                    
                    let evalPolicyError = error as! NSError
                    
                    print(evalPolicyError.localizedDescription)
                    
                    switch evalPolicyError.code {
                        
                    case LAError.systemCancel.rawValue:
                        print("Authentication was canceled by the system.")
                        
                    case LAError.userCancel.rawValue:
                        print("User canceled the Authentication.")
                        OperationQueue.main.addOperation({ () -> Void in
                            self.showPasswordAlert()
                        })
                        
                    case LAError.userFallback.rawValue:
                        print("User selected to enter custom password.")
                        OperationQueue.main.addOperation({ () -> Void in
                            self.showPasswordAlert()
                        })
                        
                    default:
                        print("Authentication Failed")
                        OperationQueue.main.addOperation({ () -> Void in
                            self.showPasswordAlert()
                        })
                        
                    }
                }
            
            })]
        }
        
        else {
            
            switch error!.code {
            case LAError.touchIDNotEnrolled.rawValue:
                print("TouchID not enrolled.")
                
            case LAError.passcodeNotSet.rawValue:
                print("A passcode has not been set.")
                
            case LAError.touchIDNotAvailable.rawValue:
                print("TouchID not Available")
        
            default:
                print("Error.")
            }
            
            print(error?.localizedDescription)
            
            self.showPasswordAlert()
        }
    }
    
    // MARK: SHOW PASSWORD ALERT
    func showPasswordAlert() {
        
        let passwordAlert: UIAlertController = UIAlertController(title: "Biometrics ID", message: "Please Type Your Password.", preferredStyle: UIAlertControllerStyle.alert)
        
        passwordAlert.addTextField(configurationHandler: {(txtField: UITextField!) in
            txtField.placeholder = "Password"
            txtField.keyboardType = UIKeyboardType.numberPad
            txtField.isSecureTextEntry = true
            txtField.becomeFirstResponder()
        })
        
        let doneAction: UIAlertAction = UIAlertAction(title: "DONE", style: UIAlertActionStyle.default, handler: { (action:UIAlertAction!) -> Void in
            
            self.alertView(alertView: passwordAlert)
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        passwordAlert.addAction(doneAction)
        passwordAlert.addAction(cancelAction)
        
        present(passwordAlert, animated: true, completion: nil)

    }
    
    func alertView(alertView: UIAlertController!) {
        
            if !(alertView.textFields?[0].text?.isEmpty)! {
                
                if alertView.textFields?[0].text == UserDefaults.standard.string(forKey: "password")! {
                    //self.performSegue(withIdentifier: "toCreateNotes", sender: self)
                    
                    loadData()
                    
                }
                    
                else{
                    showPasswordAlert()
                }
            }
            else {
                showPasswordAlert()
        }

    }
    
    // MARK: SETTINGS ACTION
    
    @IBAction func settingsAction(_ sender: AnyObject) {
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.settingsViewHeightConstraint.constant = 320
            self.settingsViewWidthConstraint.constant = 250
            self.chromeView.alpha = 1.0
            self.view.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.4, animations: {
            
                self.settingsView.alpha = 1.0
                self.view.layoutIfNeeded()
                
            })
        })
    }
    
    @IBAction func closeSettingsAction(_ sender: AnyObject) {
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.settingsViewHeightConstraint.constant = 500
            self.settingsViewWidthConstraint.constant = 400
            self.view.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.settingsView.alpha = 0.0
                self.chromeView.alpha = 0.0
                self.view.layoutIfNeeded()
            })
        })
    }
    
    @IBAction func reloadTheData(_ sender: AnyObject) {
    
        if tblNotes.visibleCells.count == 0 {
            
            if UserDefaults.standard.bool(forKey: "authRequired") == true {
                self.authenticateUser()
            }
            else {
                loadData()
            }
        }
        else {
            print("No reload needed")
        }
    }
    
    // MARK: LOAD DATA
    
    func loadData() {
        
        if (appDelegate.checkIfDataFileExists()) {
            
            self.dataArray = NSMutableArray(contentsOfFile: appDelegate.getPathOfDataFile())!
            self.tblNotes.reloadData()
        }
        
        else {
            print("File does not exist.")
        }
    }
    
    // MARK: TABLEVIEW DELEGATE METHODS
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if dataArray != nil {
            return dataArray.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCell")! as! UITableViewCell
        
        let currentNote = self.dataArray.object(at: indexPath.row) as! Dictionary <String, String>
        
        cell.textLabel?.text = currentNote["title"]
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        cell.textLabel?.textColor = UIColor(colorLiteralRed: 4/255, green: 133/255, blue: 163/255, alpha: 1.0)
        
        cell.selectionStyle = .none
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        noteIndexToEdit = indexPath.row
        
        performSegue(withIdentifier: "toCreateNotes", sender: self)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // Delete the respective object from the dataArray array.
            dataArray.removeObject(at: indexPath.row)
            
            // Save the Array to disk.
            dataArray.write(toFile: appDelegate.getPathOfDataFile(), atomically: true)
            
            // Reload the tableView.
            tblNotes.reloadSections(NSIndexSet(index: 0) as IndexSet, with: UITableViewRowAnimation.fade)
        }
    }
    
    // MARK: PROTOCOL-DELEGATE METHOD
    
    func noteWasSaved() {
        
        // Reload Data after receiving a confirmation.
        if UserDefaults.standard.bool(forKey: "authRequired") == true {
            
            //self.authenticateUser()
            
            if tblNotes.visibleCells.count > 0 {
                loadData()
            }
            else {
                print("Authentication Required")
            }
        }
        else {
            loadData()
        }
        
    }
    
    // MARK: NAVIGATION
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "toCreateNotes" {
            
            let editNotesViewController: EditNotesViewController = segue.destination as! EditNotesViewController

            if (noteIndexToEdit != nil) {
                editNotesViewController.indexOfEditedNote = noteIndexToEdit
                
                noteIndexToEdit = nil
            }
            
            editNotesViewController.delegate = self
        }
    }
    
    
    // MARK: CHANGE PASSWORD
    @IBAction func changePasswordAction(_ sender: AnyObject) {
        
        checkOldPassword()
    }
    
    func checkOldPassword() {
        
        let alert: UIAlertController = UIAlertController(title: "Change Password", message: "Enter the Old Password to Authenticate password change.", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            
            textField.placeholder = "Enter Old Password"
            textField.keyboardType = UIKeyboardType.numberPad
            textField.isSecureTextEntry = true
        })
        
        let continueAction: UIAlertAction = UIAlertAction(title: "Continue", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction) -> Void in

            if !(alert.textFields?[0].text?.isEmpty)! {
                
                if (alert.textFields![0].text! == UserDefaults.standard.string(forKey: "password")) {
                
                    self.setNewPassword()
                }
                else{
                    self.checkOldPassword()
                }
            }
            else {
             
                self.checkOldPassword()
            }
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alert.addAction(continueAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func setNewPassword() {
        
        let alert: UIAlertController = UIAlertController(title: "Change Password", message: "Enter new password.", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            
            textField.placeholder = "Enter New Password"
            textField.keyboardType = UIKeyboardType.numberPad
            textField.isSecureTextEntry = true
        })
        
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            
            textField.placeholder = "Re-Enter New Password"
            textField.keyboardType = UIKeyboardType.numberPad
            textField.isSecureTextEntry = true
        })
        
        let doneAction: UIAlertAction = UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction) -> Void in
            
            if (!(alert.textFields?[0].text?.isEmpty)! && !(alert.textFields?[1].text?.isEmpty)!) {
                
                if ((alert.textFields![0].text!) == (alert.textFields![1].text!)) {
                    
                    UserDefaults.standard.set(alert.textFields![0].text!, forKey: "password")
                    self.closeSettingsAction(UIAlertAction.self)
                }
                else {
                    self.setNewPassword()
                }
            }
            else {
                self.setNewPassword()
            }
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alert.addAction(doneAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: TOGGLE ACTION
    @IBAction func touchIDToggleAction(_ sender: AnyObject) {
        
        if touchIDToggle.isOn {
            UserDefaults.standard.set(true, forKey: "authRequired")
        }
        else {
        
            self.checkPassword()
        }
        
    }
    
    func checkPassword() {
        
        let alert: UIAlertController = UIAlertController(title: "Authetication Required", message: "Enter password to disable TouchID.", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            
            textField.placeholder = "Enter Password"
            textField.keyboardType = UIKeyboardType.numberPad
            textField.isSecureTextEntry = true
        })
        
        let doneAction: UIAlertAction = UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction) -> Void in
            
            if !(alert.textFields?[0].text?.isEmpty)! {
                
                if (alert.textFields![0].text! == UserDefaults.standard.string(forKey: "password")) {
                    
                    UserDefaults.standard.set(false, forKey: "authRequired")
                    self.showAlertWithTitle(title: "Disabled", message: "TouchID is disabled.", actionTitle: "OK")
                    self.touchIDToggle.isOn = false
                    
                    self.closeSettingsAction(UIAlertAction.self)
                }
                else{
                    self.showAlertWithTitle(title: "Authentication Failed", message: "Invalid password.", actionTitle: "OK")
                    
                    self.touchIDToggle.isOn = true
                    
                    //self.closeSettingsAction(UIAlertAction.self)
                }
            }
            else {
                
                self.checkPassword()
                self.touchIDToggle.isOn = true
            }
        })
        
        let cancelAction : UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action: UIAlertAction) -> Void in
            
            self.touchIDToggle.isOn = true
        
        })
        
        alert.addAction(doneAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)

    }
    
    func showAlertWithTitle(title: String, message: String, actionTitle: String) {
        
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction: UIAlertAction = UIAlertAction(title: actionTitle, style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

