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
    @IBOutlet weak var typeTextScrollView: NSScrollView!

    var typeMonitor = TypeMonitor()
    var snapshotTypeString: String?
    var numBufferKeyDown = 0
    var bufferDate: NSDate?

    override func viewDidLoad() {
        super.viewDidLoad()

        referenceTextView.setupInitLookup()
        typeTextView.setupInitLookup()

        typeTextView.delegate = self
        typeTextScrollView.contentView.postsBoundsChangedNotifications = true

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
        numBufferKeyDown = 0
        bufferDate = nil
        typeTextView.activate()
        typeTextView.setDefaultFont()

        typeMonitor.StartOverAccordingToReference(referenceTextView.textStorage!.mutableString.length)
    }

    func togglePauseType() {
        switch typeMonitor.getState() {
        case .On:
            typeTextView.inactivate()
            typeMonitor.pause()
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
            typeTextView.textStorage?.mutableString.setString("标计跟打信息中...")
            typeTextView.setDefaultFont()
            referenceTextView.markTextAsHistoryTypoAtIndices(typeMonitor.getHistoryTypoIndices())
        }

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
        case false:
            typeMonitor.reset()
            typeTextView.inactivate()
            let keyEquivalent = "Shift + Command + Enter"
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
    }

    func shuffleReference() {
        typeMonitor.reset()
        typeTextView.inactivate()
        typeTextView.setupInitLookup()
        typeTextView.setDefaultFont()
        referenceTextView.inactivate()
        referenceTextView.shuffleString()
        referenceTextView.markAllTextAsNormal()
    }

    func keyDownInInputTextView(notification: NSNotification) {
        switch typeMonitor.getState() {
        case .On:
            typeMonitor.incrementNumKeyDown()
            let userInfo = notification.userInfo as! [String: AnyObject]
            let event = userInfo["event"] as! NSEvent
            let keyCode = event.keyCode
            if numBufferKeyDown == 0 && keyCode == 51 {  // backspace as delete previous char
                typeMonitor.backwardCursorLocation(1)
                let cursorLocation = typeMonitor.getCursorLocation()
                typeMonitor.clearTypoIndiceAt(cursorLocation)
                referenceTextView.clearTextMarkAtIndex(cursorLocation)
            } else if keyCode == 51 {
                numBufferKeyDown = max(--numBufferKeyDown, 0)
            } else {
                ++numBufferKeyDown
                if numBufferKeyDown == 1 {  // on first new type in
                    typeTextView.clearString()
                    bufferDate = NSDate()
                }
            }
        default:
            break
        }
    }

    func textDidChange(notification: NSNotification) {
        switch typeMonitor.getState() {
        case .On:
            if numBufferKeyDown != 0 {  // not delete last char in typeTextView
                let bufferTimeInterval = 0 - bufferDate!.timeIntervalSinceNow
                bufferDate = nil

                let referencStringLength = referenceTextView.textStorage!.mutableString.length
                let bufferCharLength = typeTextView.textStorage!.mutableString.length
                typeMonitor.addNumCharIn(bufferCharLength)
                let averageBufferCharTimeInterval = bufferTimeInterval / Double(bufferCharLength)

                // check typoes and do markups
                var numBufferTypo = 0
                let bufferCharStartIndex = 0
                let bufferCharEndIndex = bufferCharLength - 1
                for bufferCharIndex in bufferCharStartIndex...bufferCharEndIndex {
                    let bufferChar = typeTextView.textStorage!.mutableString.substringWithRange(NSMakeRange(bufferCharIndex, 1))
                    let referenceCharIndex = typeMonitor.getCursorLocation()
                    if referenceCharIndex < referencStringLength {  // type within reference length
                        typeMonitor.setCharTimeItervalsAt(referenceCharIndex, timeInterval: averageBufferCharTimeInterval)
                        referenceTextView.markTextAsTypedAtIndex(referenceCharIndex)
                        let referenceChar = referenceTextView.textStorage!.mutableString.substringWithRange(NSMakeRange(referenceCharIndex, 1))
                        if referenceChar != bufferChar {
                            ++numBufferTypo
                            typeMonitor.setHistoryTypoIndicesAt(referenceCharIndex)
                            typeMonitor.setTypoIndicesAt(referenceCharIndex)
                            referenceTextView.markTextAsTypoAtIndex(referenceCharIndex)
                        }
                        typeMonitor.forwardCursorLocation(1)
                    } else {
                        typeTextView.clearString()
                        break
                    }
                }

                // clean buffer
                if numBufferTypo == 0 {
                    typeTextView.clearString()
                }
                numBufferKeyDown = 0

                // auto submit
                let isCursorAfterLastReferenceChar = typeMonitor.getCursorLocation() == referencStringLength
                if isCursorAfterLastReferenceChar && referencStringLength > 0 && typeMonitor.getNumTypo() == 0 {
                    submitType()
                }
            }
        default:
            break
        }
    }

}