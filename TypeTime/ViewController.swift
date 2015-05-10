//
//  ViewController.swift
//  TypeTime
//
//  Created by Rui-Wei Zhao on 5/1/15.
//  Copyright (c) 2015 Rui-Wei Zhao. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, TypeTextViewDelegate {

    @IBOutlet var referenceTextView: ReferenceTextView!
    @IBOutlet var typeTextView: TypeTextView!

    var typeMonitor = TypeMonitor()
    var snapshotTypeString: String?
    var bufferKeyCode: UInt16?
    var numBufferKeyDown = 0
    var bufferDate: NSDate?
    var bufferTimeOffset: NSTimeInterval = 0.0
    var lastTypeTextLength = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        addObserver()

        typeTextView.delegate = self

        referenceTextView.setupInitLookup()
        typeTextView.setupInitLookup()

        resetTypeInformationAccordingToReference()
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
        notificationCenter.addObserver(self, selector: "shrinkReference",
            name: "ShrinkReferenceNotification", object: nil)
        notificationCenter.addObserver(self, selector: "shuffleReference",
            name: "ShuffleReferenceNotification", object: nil)

        notificationCenter.addObserver(self, selector: "keyDownInInputTextView:",
            name: "KeyDownInTypeTextViewNotification", object: typeTextView)
    }

    func startType() {
        referenceTextView.inactivate()
        referenceTextView.markAllTextAsNormal()
        referenceTextView.scrollToBeginningOfDocument(nil)

        typeTextView.clearString()
        snapshotTypeString = nil
        bufferKeyCode = 0
        numBufferKeyDown = 0
        lastTypeTextLength = 0
        bufferDate = NSDate()
        typeTextView.activate()
        typeTextView.setDefaultFont()

        typeMonitor.StartOverAccordingToReference(referenceTextView.textStorage!.mutableString.length)
    }

    func togglePauseType() {
        switch typeMonitor.getState() {
        case .On:
            typeTextView.inactivate()
            let cursorLocation = typeMonitor.getCursorLocation()
            let bufferTimeInterval = 0 - bufferDate!.timeIntervalSinceNow
            bufferDate = nil
            typeMonitor.addCharTimeIntervalsAt(cursorLocation, timeInterval: bufferTimeInterval)
            typeMonitor.pause()
            snapshotTypeString = typeTextView.textStorage?.mutableString as? String
            typeTextView.textStorage?.mutableString.setString(typeMonitor.infoLine)
            typeTextView.setDefaultFont()
        case .Paused:
            typeTextView.textStorage?.mutableString.setString(snapshotTypeString!)
            snapshotTypeString = nil
            typeMonitor.resume()
            bufferDate = NSDate()
            typeTextView.activate()
            typeTextView.setDefaultFont()
        default:
            break
        }
    }

    func submitType() {
        var isNeedMarkReference = false
        switch typeMonitor.getState() {
        case .On:
            typeTextView.inactivate()
            typeMonitor.end()
            isNeedMarkReference = true
        case .Paused:
            typeTextView.inactivate()
            typeMonitor.end()
            typeTextView.textStorage?.mutableString.setString(snapshotTypeString!)
            snapshotTypeString = nil
            isNeedMarkReference = true
        default:
            break
        }

        if isNeedMarkReference {
            typeTextView.textStorage?.mutableString.setString("标计跟打信息，请稍候...")
            typeTextView.setDefaultFont()
            referenceTextView.markTextAsHistoryTypoAtIndices(typeMonitor.getHistoryTypoIndicesWithoutActiveTypos())
            referenceTextView.markTextTimeInteval(typeMonitor.getTypedCharTimeIntervals())
        }

        typeTextView.textStorage?.mutableString.setString(typeMonitor.infoLine)
        typeTextView.setDefaultFont()
    }

    func resetTypeInformationAccordingToReference() {
        typeMonitor.resetAccordingToReference(referenceTextView.textStorage!.length)
        typeTextView.textStorage?.mutableString.setString(typeMonitor.infoLine)
        typeTextView.setDefaultFont()
    }

    func toggleEditReference(notification: NSNotification) {
        switch referenceTextView.editable {
        case true:
            typeMonitor.reset()
            typeTextView.inactivate()
            typeTextView.setupInitLookup()
            typeTextView.setDefaultFont()
            referenceTextView.inactivate()
            referenceTextView.markAllTextAsNormal()
            resetTypeInformationAccordingToReference()
        case false:
            typeMonitor.reset()
            typeTextView.inactivate()
            let keyEquivalent = "Shift + Command + I"
            typeTextView.textStorage?.mutableString.setString("结束编辑请按：" + keyEquivalent)
            typeTextView.setDefaultFont()
            referenceTextView.activate()
            referenceTextView.setDefaultFont()
        default:
            break
        }
    }

    func shrinkReference() {
        typeMonitor.reset()
        typeTextView.inactivate()
        typeTextView.setupInitLookup()
        typeTextView.setDefaultFont()
        referenceTextView.inactivate()
        referenceTextView.shrinkString()
        referenceTextView.markAllTextAsNormal()
        resetTypeInformationAccordingToReference()
    }

    func shuffleReference() {
        typeMonitor.reset()
        typeTextView.inactivate()
        typeTextView.setupInitLookup()
        typeTextView.setDefaultFont()
        referenceTextView.inactivate()
        referenceTextView.shuffleString()
        referenceTextView.markAllTextAsNormal()
        resetTypeInformationAccordingToReference()
    }

    func keyDownInInputTextView(notification: NSNotification) {
        switch typeMonitor.getState() {
        case .On:
            ++numBufferKeyDown
            typeMonitor.incrementNumKeyDown()

            let userInfo = notification.userInfo as! [String: AnyObject]
            let event = userInfo["event"] as! NSEvent
            bufferKeyCode = event.keyCode

            // delete action in blank typeTextView
            if typeTextView.textStorage!.length == 0 && bufferKeyCode == 51 {
                typeMonitor.backwardCursorLocation(1)
                let cursorLocation = typeMonitor.getCursorLocation()
                typeMonitor.clearTypoIndiceAt(cursorLocation)
                referenceTextView.clearTextMarkAtIndex(cursorLocation)
                --numBufferKeyDown
                numBufferKeyDown = 0
            }
        default:
            break
        }
    }

    func textDidChange(notification: NSNotification) {
        switch typeMonitor.getState() {
        case .On:
            let typeString = typeTextView.textStorage!.mutableString
            let referenceString = referenceTextView.textStorage!.mutableString

            let numBufferCharDiff = typeString.length - lastTypeTextLength
            if numBufferCharDiff > 0 {  // type in new chars
                typeMonitor.addNumCharIn(numBufferCharDiff)
                let bufferTimeInterval = bufferTimeOffset - bufferDate!.timeIntervalSinceNow

                // check typoes and do markups
                var numBufferTypo = 0
                for bufferCharIndex in lastTypeTextLength..<typeString.length {
                    let bufferChar = typeString.characterAtIndex(bufferCharIndex)
                    let referenceCharIndex = typeMonitor.getCursorLocation()
                    if referenceCharIndex < referenceString.length {  // type within reference length
                        typeMonitor.addCharTimeIntervalsAt(referenceCharIndex, timeInterval: bufferTimeInterval)
                        referenceTextView.markTextAsTypedAtIndex(referenceCharIndex)
                        let referenceChar = referenceString.characterAtIndex(referenceCharIndex)
                        if referenceChar != bufferChar {
                            ++numBufferTypo
                            typeMonitor.setHistoryTypoIndicesAt(referenceCharIndex)
                            typeMonitor.setTypoIndicesAt(referenceCharIndex)
                            referenceTextView.markTextAsTypoAtIndex(referenceCharIndex)
                        }
                        typeMonitor.forwardCursorLocation(1)
                    } else {  // type out of reference text bound
                        typeTextView.clearString()
                        break
                    }
                }

                // commit buffer and clear
                let isCommitKeyCodeBuffered = (bufferKeyCode == 36 || bufferKeyCode == 48 || bufferKeyCode == 49)
                if numBufferTypo == 0 && isCommitKeyCodeBuffered {
                    typeTextView.clearString()
                    numBufferKeyDown = 0
                }

                // auto submit
                let isCursorAfterLastReferenceChar = typeMonitor.getCursorLocation() == referenceString.length
                if isCursorAfterLastReferenceChar && referenceString.length > 0 && typeMonitor.getNumTypo() == 0 {
                    submitType()
                }
            } else if numBufferCharDiff < 0 {
                let numBufferCharDeleted = -numBufferCharDiff
                if bufferKeyCode == 51 {  // delete by keyboard
                    for location in typeString.length..<lastTypeTextLength {
                        typeMonitor.backwardCursorLocation(1)
                        let cursorLocation = typeMonitor.getCursorLocation()
                        typeMonitor.clearTypoIndiceAt(cursorLocation)
                        referenceTextView.clearTextMarkAtIndex(cursorLocation)
                    }
                } else {  // smart replacemet
                    // FIXME may encounter potential runtime issues
                    for location in typeString.length..<lastTypeTextLength {
                        typeMonitor.backwardCursorLocation(1)
                        let cursorLocation = typeMonitor.getCursorLocation()
                        typeMonitor.clearTypoIndiceAt(cursorLocation)
                        typeMonitor.clearHistoryTypoIndiceAt(cursorLocation)
                        referenceTextView.clearTextMarkAtIndex(cursorLocation)
                    }
                    let compareCharLocation = typeMonitor.getCursorLocation() - 1
                    let bufferChar = typeString.characterAtIndex(compareCharLocation)
                    let referenceChar = referenceString.characterAtIndex(compareCharLocation)
                    if bufferChar == referenceChar {
                        typeMonitor.clearTypoIndiceAt(compareCharLocation)
                        typeMonitor.clearHistoryTypoIndiceAt(compareCharLocation)
                        referenceTextView.clearTextMarkAtIndex(compareCharLocation)
                        typeTextView.clearString()
                        numBufferKeyDown = 0
                    }
                }
            } else {
                let compareCharLocation = typeMonitor.getCursorLocation() - 1
                let bufferChar = typeString.characterAtIndex(compareCharLocation)
                let referenceChar = referenceString.characterAtIndex(compareCharLocation)
                if bufferChar == referenceChar {
                    typeMonitor.clearTypoIndiceAt(compareCharLocation)
                    typeMonitor.clearHistoryTypoIndiceAt(compareCharLocation)
                    referenceTextView.clearTextMarkAtIndex(compareCharLocation)
                    typeTextView.clearString()
                    numBufferKeyDown = 0
                }
            }
            lastTypeTextLength = typeString.length
            bufferDate = NSDate()
        default:
            break
        }
    }

}