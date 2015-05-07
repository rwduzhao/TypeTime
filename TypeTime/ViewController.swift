//
//  ViewController.swift
//  TypeTime
//
//  Created by Rui-Wei Zhao on 5/1/15.
//  Copyright (c) 2015 Rui-Wei Zhao. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextViewDelegate {

    @IBOutlet var referenceTextView: ReferenceTextView!
    @IBOutlet var typeTextView: TypeTextView!
    var typeMonitor = TypeMonitor()
    var oldTypeLength: Int?
    var snapshotTypeString: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        referenceTextView.delegate = self
        referenceTextView.setupInitLookup()

        typeTextView.delegate = self
        typeTextView.setupInitLookup()

        addObserver()
    }

    deinit {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self)
    }

    func addObserver() {
        let notificationCenter = NSNotificationCenter.defaultCenter()

        notificationCenter.addObserver(self, selector: "startType",
            name: "StartTypeNotification", object: nil)
        notificationCenter.addObserver(self, selector: "togglePauseType",
            name: "TogglePauseTypeNotification", object: nil)
        notificationCenter.addObserver(self, selector: "submitType",
            name: "SubmitTypeNotification", object: nil)
        notificationCenter.addObserver(self, selector: "toggleEditReference:",
            name: "ToggleEditReferenceNotification", object: nil)

        notificationCenter.addObserver(self, selector: "keyDownInInputTextView:",
            name: "KeyDownInTypeTextViewNotification", object: typeTextView)
    }

    func startType() {
        referenceTextView.inactivate()
        referenceTextView.markAllTextAsNormal()

        typeTextView.clearString()
        snapshotTypeString = nil
        oldTypeLength = 0
        typeTextView.activate()
        typeTextView.setDefaultFont()

        typeMonitor.startOver()
    }

    func togglePauseType() {
        switch typeMonitor.getState() {
        case .On:
            typeTextView.inactivate()
            typeMonitor.pause()
            typeMonitor.setTypeLength(typeTextView.textStorage!.mutableString.length)
            snapshotTypeString = typeTextView.textStorage?.mutableString as? String
            typeTextView.textStorage?.mutableString.setString(typeMonitor.infoLine)
            typeTextView.setDefaultFont()
        case .Paused:
            typeTextView.textStorage?.mutableString.setString(snapshotTypeString!)
            snapshotTypeString = nil
            typeMonitor.resume()
            typeTextView.activate()
            typeTextView.setDefaultFont()
        default:
            break
        }
    }

    func submitType() {
        switch typeMonitor.getState() {
        case .On:
            typeMonitor.setTypeLength(typeTextView.textStorage!.mutableString.length)
            typeMonitor.end()
        case .Paused:
            typeTextView.textStorage?.mutableString.setString(snapshotTypeString!)
            snapshotTypeString = nil
            typeMonitor.end()
        default:
            break
        }
        typeTextView.inactivate()
        typeTextView.textStorage?.mutableString.setString(typeMonitor.infoLine)
        typeTextView.setDefaultFont()

        for index in typeMonitor.getHistoryTypoIndices() {
            if index < referenceTextView.textStorage!.mutableString.length {
                referenceTextView.markTextAsHistoryTypoAtIndex(index)
            }
        }
    }

    func toggleEditReference(notification: NSNotification) {
        switch referenceTextView.editable {
        case true:
            typeMonitor.reset()
            typeTextView.inactivate()
            let keyEquivalent = "Command + Return"
            typeTextView.textStorage?.mutableString.setString("开始跟打请按：" + keyEquivalent)
            typeTextView.setDefaultFont()
            referenceTextView.inactivate()
            referenceTextView.markAllTextAsNormal()
        case false:
            typeMonitor.reset()
            typeTextView.inactivate()
            let keyEquivalent = "Shift + Command + E"
            typeTextView.textStorage?.mutableString.setString("结束编辑请按：" + keyEquivalent)
            typeTextView.setDefaultFont()
            referenceTextView.activate()
            referenceTextView.setDefaultFont()
        default:
            break
        }
    }

    func keyDownInInputTextView(notification: NSNotification) {
        switch typeMonitor.getState() {
        case .On:
            typeMonitor.incrementNumKeyDown()
        default:
            break
        }
    }

    func textDidChange(notification: NSNotification) {
        switch typeMonitor.getState() {
        case .On:
            // check typoes and do markups
            let referencStringLength = referenceTextView.textStorage!.mutableString.length
            let newTypeLength = typeTextView.textStorage!.mutableString.length
            if newTypeLength > oldTypeLength {  // type in new text
                typeMonitor.addNumCharIn(newTypeLength - oldTypeLength!)
                let startIndex = oldTypeLength!
                let endIndex = newTypeLength - 1
                for index in startIndex...endIndex {
                    var charRange = NSMakeRange(index, 1)
                    let typeChar = typeTextView.textStorage!.mutableString.substringWithRange(charRange)
                    if index < referencStringLength {  // type within reference length
                        let referenceChar = referenceTextView.textStorage!.mutableString.substringWithRange(charRange)
                        referenceTextView.markTextAsTypedAtIndex(index)
                        if referenceChar != typeChar {
                            typeMonitor.insertIntoTypoIndices(index)
                            typeMonitor.insertIntoHistoryTypoIndices(index)
                            referenceTextView.markTextAsTypoAtIndex(index)
                        }
                    } else {  // must be typos
                        typeMonitor.insertIntoTypoIndices(index)
                        typeMonitor.insertIntoHistoryTypoIndices(index)
                    }

                }
            } else if newTypeLength < oldTypeLength {  // delete old text
                let startIndex = newTypeLength
                let endIndex = oldTypeLength! - 1
                for index in startIndex...endIndex {
                    typeMonitor.removeFromTypoIndices(index)
                    if index < referencStringLength {
                        referenceTextView.clearTextMarkAtIndex(index)
                    }
                }
            }

            // auto submit
            if referencStringLength > 0 && newTypeLength == referencStringLength {
                if referenceTextView.textStorage!.mutableString.isEqualToString(typeTextView.textStorage!.mutableString as String) {
                    submitType()
                }
            }

            oldTypeLength = newTypeLength
        default:
            break
        }
    }

}