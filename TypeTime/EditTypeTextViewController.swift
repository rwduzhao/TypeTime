//
//  EditTypeTextViewController.swift
//  TypeTime
//
//  Created by Rui-Wei Zhao on 10/3/15.
//  Copyright © 2015 Rui-Wei Zhao. All rights reserved.
//

import Cocoa

class EditTypeTextViewController: NSViewController {

    var typeText: TypeText?
    var selectableLanguages: [String]?
    var preferredLanguage: String?
    var preferredType: String?
    var loadTextViewController: LoadTextViewController?

    @IBOutlet weak var languageComboBox: NSComboBox!
    @IBOutlet weak var typePopUpButton: NSPopUpButton!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet var textView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if typeText == nil {  // add
            // language, type and title
            languageComboBox.addItemsWithObjectValues(selectableLanguages!)
            if preferredLanguage != nil {
                languageComboBox.stringValue = preferredLanguage!
            }
            typePopUpButton.selectItemWithTitle(preferredType!)
        } else {  // edit
            // language, type and title
            languageComboBox.addItemsWithObjectValues(selectableLanguages!)
            preferredLanguage = typeText!.language
            languageComboBox.stringValue = preferredLanguage!
            preferredType = typeText!.type
            typePopUpButton.selectItemWithTitle(preferredType!)
            titleTextField.stringValue = typeText!.title!
            textView.string = typeText!.content
        }
    }

    @IBAction func done(sender: NSButton) {
        if checkValid() == true {
            let language = languageComboBox.stringValue
            let type = typePopUpButton.selectedItem?.title
            let title = titleTextField.stringValue
            let content = textView.string
            let creator = "User"
            let creationDate = NSDate()
            if typeText == nil {  // add
                if TypeText.insertTypeText(language, type: type!, title: title, content: content!, creator: creator, creationDate: creationDate) == true {
                    loadTextViewController?.refresh()
                    dismissController(self)
                }
            } else { // edit
                if TypeText.updateTypeText(typeText!, language: language, type: type!, title: title, content: content!, creator: creator, creationDate: creationDate) == true {
                    loadTextViewController?.refresh()
                    dismissController(self)
                }
            }

        }
    }

    @IBAction func cancel(sender: NSButton) {
        dismissViewController(self)
    }

    func checkValid() -> Bool {
        if typeText != nil {
            if typeText!.creator == "TypeTime" {
                return false
            }
        }
        if languageComboBox.stringValue.characters.count == 0 {
            return false
        }
        if titleTextField.stringValue.characters.count == 0 {
            return false
        }
        if textView.string?.characters.count == 0 {
            return false
        }
        return true
    }

}