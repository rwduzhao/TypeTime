//
//  LoadTextViewController.swift
//  TypeTime
//
//  Created by Rui-Wei Zhao on 8/28/15.
//  Copyright (c) 2015 Rui-Wei Zhao. All rights reserved.
//

import Cocoa
import CoreData

class LoadTextViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: - Variables

    private var candidateTextLanguages = [String]() {
        didSet {
            textLanguagePopUpButton.removeAllItems()
            textLanguagePopUpButton.addItemsWithTitles(candidateTextLanguages)
        }
    }
    private var selectedTextLanguage: String? {
        didSet {
            if selectedTextLanguage != nil && selectedTextType != nil {
                updateCandidateTypeTexts()
            }
        }
    }

    private var selectedTextType: String? {
        didSet {
            if selectedTextLanguage != nil && selectedTextType != nil {
                updateCandidateTypeTexts()
            }
        }
    }

    private var candidateTypeTexts = [TypeText]() {
        didSet {
            typeTextTableView.reloadData()
            updateSelectedTypeText()
        }
    }
    private var selectedTypeText: TypeText? {
        didSet {
            updateSampleLengthOptions()
            updateSampleLength()
            updateSplitNumberOptions()
            updateSplitNumber()
            updateSampleText()

            if selectedTypeText == nil {
                deleteTypeTextButton.enabled = false
                editTypeTextButton.enabled = false
                loadButton.enabled = false
            } else {
                if selectedTypeText!.creator == "TypeTime" {
                    deleteTypeTextButton.enabled = false
                    editTypeTextButton.enabled = false
                    loadButton.enabled = true
                } else {
                    deleteTypeTextButton.enabled = true
                    editTypeTextButton.enabled = true
                    loadButton.enabled = true
                }
            }
        }
    }

    private var selectedSampleLength: Int?
    private var selectedSplitNumber: Int?

    var delegate: TypeViewDelegate?

    // MARK: - UI variables

    @IBOutlet var sampleTextView: NSTextView!
    @IBOutlet weak var textLanguagePopUpButton: NSPopUpButton!
    @IBOutlet weak var textTypeSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var typeTextTableView: NSTableView!
    @IBOutlet weak var addTypeTextButton: NSButton!
    @IBOutlet weak var deleteTypeTextButton: NSButton!
    @IBOutlet weak var editTypeTextButton: NSButton!
    @IBOutlet weak var sampleLengthPopUpButton: NSPopUpButton!
    @IBOutlet weak var splitNumberPopUpBotton: NSPopUpButton!
    @IBOutlet weak var loadButton: NSButton!

    // MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()

        typeTextTableView.delegate()
        refresh()
    }

    // MARK: - General

    func refresh() {
        // TypeText.clearStore()
        TypeText.updateStore()
        updateCandidateTextLanguages()

        selectedTextLanguage = textLanguagePopUpButton.titleOfSelectedItem
        let selectedSegment = textTypeSegmentedControl.selectedSegment
        selectedTextType = textTypeSegmentedControl.labelForSegment(selectedSegment)
        selectedTypeText = nil

        updateSampleLengthOptions()
        updateSampleLength()
        updateSplitNumberOptions()
        updateSplitNumber()
        updateSampleText()
    }

    // MARK: - Candidate type texts

    func updateCandidateTypeTexts() {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "TypeText")
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.predicate = NSPredicate(format: "language = %@ AND type = %@", selectedTextLanguage!, selectedTextType!)
        candidateTypeTexts = (try! context.executeFetchRequest(fetchRequest)) as! [TypeText]
    }

    func updateCandidateTextLanguages() {
        let languages = TypeText.getStoredPropertyValues("language", returnsDistinctResults: true) as! [String]
        candidateTextLanguages = Array(Set(languages.sort()))
    }

    func updateSelectedTypeText() {
        let row = typeTextTableView.selectedRow
        var typeText: TypeText?
        if row >= 0 {
            typeText = candidateTypeTexts[row]
        }
        if selectedTypeText != typeText {
            selectedTypeText = typeText
        }
    }

    @IBAction func selectTextLanguage(sender: NSPopUpButton) {
        if selectedTextLanguage != textLanguagePopUpButton.titleOfSelectedItem {
            selectedTextLanguage = textLanguagePopUpButton.titleOfSelectedItem
        }
    }

    @IBAction func selectTextType(sender: NSSegmentedControl) {
        let selectedSegment = textTypeSegmentedControl.selectedSegment
        if let selectedSegmentLabel = textTypeSegmentedControl.labelForSegment(selectedSegment) {
            if selectedTextType != selectedSegmentLabel {
                selectedTextType = selectedSegmentLabel
            }
        }
    }

    @IBAction func addTypeText(sender: NSButton) {
        typeTextTableView.deselectAll(typeTextTableView)
        let editTypeTextViewController = storyboard!.instantiateControllerWithIdentifier("Edit Type Text View Controller") as! EditTypeTextViewController
        editTypeTextViewController.typeText = nil
        editTypeTextViewController.selectableLanguages = candidateTextLanguages
        editTypeTextViewController.preferredLanguage = selectedTextLanguage
        editTypeTextViewController.preferredType = selectedTextType
        editTypeTextViewController.loadTextViewController = self
        presentViewControllerAsSheet(editTypeTextViewController)
    }

    @IBAction func deleteTypeText(sender: NSButton) {
        if selectedTypeText != nil {
            TypeText.deleteTypeText(selectedTypeText!)
            refresh()
        }
    }

    @IBAction func editTypeText(sender: NSButton) {
        let editTypeTextViewController = storyboard!.instantiateControllerWithIdentifier("Edit Type Text View Controller") as! EditTypeTextViewController
        editTypeTextViewController.typeText = selectedTypeText!
        editTypeTextViewController.selectableLanguages = candidateTextLanguages
        editTypeTextViewController.loadTextViewController = self
        presentViewControllerAsSheet(editTypeTextViewController)
    }

    // MARK: - Sample type text

    func updateSampleLengthOptions() {
        sampleLengthPopUpButton.removeAllItems()
        var lengths = [String]()
        var maxLength: Int = 0
        if selectedTypeText?.content != nil {
            maxLength = selectedTypeText!.count as! Int
            lengths.append("\(maxLength)")
            let allowedLengths = [10, 20, 30, 50, 100, 200, 500]
            for length in allowedLengths {
                if length < maxLength {
                    lengths.append("\(length)")
                }
            }
        }
        sampleLengthPopUpButton.addItemsWithTitles(lengths)
        updateSplitNumberOptions()
    }

    func updateSplitNumberOptions() {
        splitNumberPopUpBotton.removeAllItems()
        var splits = [String]()
        if let sampleLengthText = sampleLengthPopUpButton.titleOfSelectedItem {
            let sampleLength = Int(sampleLengthText)
            let numSplit = Int(ceil(selectedTypeText!.count as! Double / Double(sampleLength!)))
            for splitNumber in 1...numSplit {
                splits.append("\(splitNumber)")
            }
        }
        splitNumberPopUpBotton.addItemsWithTitles(splits)
    }

    func updateSampleLength() {
        var length: Int?
        if let lengthText = sampleLengthPopUpButton.titleOfSelectedItem {
            length = Int(lengthText)
        }
        if selectedSampleLength != length {
            selectedSampleLength = length
        }
    }

    func updateSplitNumber() {
        var splitNumber: Int?
        if let splitNumberText = splitNumberPopUpBotton.titleOfSelectedItem {
            splitNumber = Int(splitNumberText)
        }
        if selectedSplitNumber != splitNumber {
            selectedSplitNumber = splitNumber
        }
    }

    func updateSampleText() {
        var string = ""
        if selectedTypeText?.content != nil {
            string = selectedTypeText!.getSampleText(selectedSampleLength!, splitNumber: selectedSplitNumber!, isRandom: false)
        }
        sampleTextView.textStorage?.mutableString.setString(string)
    }

    @IBAction func selectSampleLength(sender: NSPopUpButton) {
        updateSampleLength()
        updateSplitNumberOptions()
        updateSplitNumber()
        updateSampleText()
    }

    @IBAction func selectSplitNumber(sender: NSPopUpButton) {
        updateSplitNumber()
        updateSampleText()
    }

    // MARK: - Load and cancel

    @IBAction func load(sender: NSButton) {
        if let string = sampleTextView.string {
            if string.characters.count > 0 {
                self.delegate?.loadTypeText(string)
                dismissViewController(self)
            }
        }
    }

    @IBAction func cancel(sender: NSButton) {
        dismissViewController(self)
    }

    // MARK: - typeText table view

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.candidateTypeTexts.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return "\(candidateTypeTexts[row].valueForKey(tableColumn!.identifier)!)"
    }

    @IBAction func actInTypeTextInTableView(sender: NSTableView) {
        updateSelectedTypeText()
    }

}