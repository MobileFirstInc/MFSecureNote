//
//  EditNotesViewController.swift
//  Playing with TouchID
//
//  Created by Varad Pathak on 12/10/16.
//  Copyright © 2016 Varad Pathak. All rights reserved.
//  Copyright © 2016 MobileFirst (http://mobilefirst.in)

//

import UIKit

protocol EditNoteViewControllerDelegate {
    func noteWasSaved()
}

class EditNotesViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var txtNotesTitle: UITextField!
    
    @IBOutlet weak var txtNotesBody: UITextView!
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var delegate:EditNoteViewControllerDelegate?
    
    var indexOfEditedNote : Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //self.txtNotesTitle.becomeFirstResponder()
        txtNotesTitle.delegate = self
        
        self.makeBorders(sender: txtNotesBody)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (indexOfEditedNote != nil) {
            
            editNotes()
        }
    }
    
    func makeBorders(sender: UIView) {
        
        sender.layer.borderWidth = 1.0
        sender.layer.borderColor = (UIColor(colorLiteralRed: 85/255, green: 85/255, blue: 85/255, alpha: 0.5)).cgColor
        sender.layer.cornerRadius = 5.0
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        txtNotesTitle.resignFirstResponder()
        
        txtNotesBody.becomeFirstResponder()
        
        return true
    }
    
    @IBAction func didTapSave(_ sender: AnyObject) {
        
        if (self.txtNotesTitle.text?.isEmpty)! {
            print("No title for the note was typed.")
            return
        }
        
        // Create an directory with the note data.
        let noteDict = ["title" : self.txtNotesTitle.text!, "body" : self.txtNotesBody.text!]
        
        // Declare an NSMutable Array
        var dataArray : NSMutableArray
        
        // If the notes data file exists then load its contents and add the new note data too, otherwisejust initialize the dataArray array and add the new note data.
        if appDelegate.checkIfDataFileExists() {
            
            // Load any existing notes.
            dataArray = NSMutableArray(contentsOfFile: appDelegate.getPathOfDataFile())!
            
            // Check if is editing note or not.
            if indexOfEditedNote == nil {
                // Add the dictionary to the Array.
                dataArray.add(noteDict)
            }
            else {
                // Replace the existing dictionary to the array.
                dataArray.replaceObject(at: indexOfEditedNote, with: noteDict)
            }
            
            
        }
        
        else {
            // Create a new mutable array and add the noteDict object to it.
            dataArray = NSMutableArray(object: noteDict)
        }
        
        // Save the array contents to file.
        
       //dataArray.write(toFile: appDelegate.getPathOfDataFile(), atomically: false)
        
        let result = dataArray.write(toFile: appDelegate.getPathOfDataFile(), atomically: false)
        
//        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
//        let path = (paths as NSString).appendingPathComponent("notesData.plist")
//        dataArray.write(toFile: path, atomically: true)
        
        //dataArray.write(toFile: <#T##String#>, atomically: <#T##Bool#>)
        
        if result == true {
            
            print("Successfully Written")
        }
        
        
        // Notify the delegate class that the note has been saved.
        delegate?.noteWasSaved()
        
        
        // Pop the ViewController
        self.navigationController?.popViewController(animated: true)
        
    }
    
    // MARK: EDIT NOTES:
    
    func editNotes() {
        // Load all notes.
        let notesArray: NSArray = NSArray(contentsOfFile: appDelegate.getPathOfDataFile())!
        
        // Get the directory at specified index.
        let noteDict: Dictionary = notesArray.object(at: indexOfEditedNote) as! Dictionary<String, String>
        
        // Set the text field.
        txtNotesTitle.text = noteDict["title"]
        
        // Set the textView.
        txtNotesBody.text = noteDict["body"]
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
     
    }
     */
    

}
