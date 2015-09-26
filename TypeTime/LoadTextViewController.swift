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
    private var candidateTextLanguages = [String]() {
        didSet {
            textLanguagePopUpButton.removeAllItems()
            textLanguagePopUpButton.addItemsWithTitles(candidateTextLanguages)
        }
    }
    private var selectedTypeText: TypeText? {
        didSet {
            updateSampleLengthOptions()
            updateSampleLength()
            updateSplitNumberOptions()
            updateSplitNumber()
            updateSampleText()

        }
    }
    private var selectedSampleLength: Int?
    private var selectedSplitNumber: Int?

    @IBOutlet weak var textLanguagePopUpButton: NSPopUpButton!
    @IBOutlet weak var textTypeSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var typeTextTableView: NSTableView!
    @IBOutlet var sampleTextView: NSTextView!
    @IBOutlet weak var sampleLengthPopUpButton: NSPopUpButton!
    @IBOutlet weak var splitNumberPopUpBotton: NSPopUpButton!

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

    override func viewDidLoad() {
        super.viewDidLoad()

        typeTextTableView.delegate()

        // TypeText.clearStore()
        TypeText.updateStore()
        updateCandidateTextLanguages()

        selectedTextLanguage = textLanguagePopUpButton.titleOfSelectedItem
        let selectedSegment = textTypeSegmentedControl.selectedSegment
        selectedTextType = textTypeSegmentedControl.labelForSegment(selectedSegment)

        updateSampleLengthOptions()
        updateSampleLength()
        updateSplitNumberOptions()
        updateSplitNumber()
        updateSampleText()
    }

    override func viewDidAppear () {
        super.viewDidAppear()
        view.window?.title = "Load Type Text"
    }

    @IBAction func actInTypeTextInTableView(sender: NSTableView) {
        updateSelectedTypeText()
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

    @IBAction func cancel(sender: NSButton) {
        dismissViewController(self)
    }

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

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.candidateTypeTexts.count
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return "\(candidateTypeTexts[row].valueForKey(tableColumn!.identifier)!)"
    }

}