//
//  ReferenceTextView.swift
//  TypeTime
//
//  Created by Rui-Wei Zhao on 5/6/15.
//  Copyright (c) 2015 Rui-Wei Zhao. All rights reserved.
//

import Cocoa

class ReferenceTextView: NSTextView {

    let activeBackgroundColor = NSColor.textBackgroundColor()
    let inactiveBackgroundColor = NSColor.windowBackgroundColor()

    let normalStringAttributes: [String: AnyObject] = [NSFontAttributeName: NSFont(name: "Menlo", size: 24.0) as! AnyObject, NSForegroundColorAttributeName: NSColor.textColor(), NSBackgroundColorAttributeName: NSColor.windowBackgroundColor()]

    let enTypedStringAttributes: [String: AnyObject] = [NSBackgroundColorAttributeName: NSColor.controlShadowColor()]
    let deTypedStringAttributes: [String: AnyObject] = [NSBackgroundColorAttributeName: NSColor.clearColor()]

    let enTypoStringAttributes: [String: AnyObject] = [NSForegroundColorAttributeName: NSColor.redColor().colorWithAlphaComponent(0.5)]
    let deTypoStringAttributes: [String: AnyObject] = [NSForegroundColorAttributeName: NSColor.textColor()]

    let enHistoryTypoStringAttributes: [String: AnyObject] = [NSForegroundColorAttributeName: NSColor.blueColor().colorWithAlphaComponent(0.5)]
    let deHistroyTypoStringAttributes: [String: AnyObject] = [NSForegroundColorAttributeName: NSColor.textColor()]

    let helpMessagePath = NSBundle.mainBundle().pathForResource("Simplified Chinese - Article - Welcome", ofType: "txt")

    func shrinkString() {
        let string = textStorage!.string
        let components = string.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).filter({!$0.characters.isEmpty})
        let shrinkedString = components.joinWithSeparator("")
        textStorage!.mutableString.setString(shrinkedString)
    }

    func shuffleString() {
        func shuffle<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
            let c = list.count
            for i in 0..<(c - 1) {
                let j = Int(arc4random_uniform(UInt32(c - i))) + i
                swap(&list[i], &list[j])
            }
            return list
        }

        let string = textStorage!.mutableString
        let shuffledString = textStorage!.mutableCopy() as! NSMutableAttributedString
        let shuffledIndices = shuffle([Int](0..<string.length))
        var charLocation = 0
        for index in shuffledIndices {
            let replaceString = string.substringWithRange(NSMakeRange(index, 1))
            shuffledString.replaceCharactersInRange(NSMakeRange(charLocation, 1), withString: replaceString)
            ++charLocation
        }
        textStorage!.mutableString.setString(shuffledString.string)
    }

    func setupInitLookup() {
        inactivate()
        let helpMessage = try? String(contentsOfFile: helpMessagePath!, encoding: NSUTF8StringEncoding)
        textStorage?.mutableString.setString(helpMessage!)
        markAllTextAsNormal()
    }

    func setDefaultFont() {
        font = NSFont(name: "Menlo", size: 24.0)
    }

    func activate() {
        backgroundColor = activeBackgroundColor
        editable = true
        window?.makeFirstResponder(self)
    }

    func inactivate() {
        editable = false
        backgroundColor = inactiveBackgroundColor
    }

    func markAllTextAsNormal() {
        textStorage!.addAttributes(normalStringAttributes, range: NSMakeRange(0, textStorage!.length))
    }

    func clearTextMarkAtIndex(index: Int) {
        textStorage!.addAttributes(normalStringAttributes, range: NSMakeRange(index, 1))
    }

    func markTextAsTypedAtIndex(index: Int) {
        textStorage!.addAttributes(enTypedStringAttributes, range: NSMakeRange(index, 1))
    }

    func markTextAsTypoAtIndex(index: Int) {
        textStorage!.addAttributes(enTypoStringAttributes, range: NSMakeRange(index, 1))
    }

    func markTextAsNontypoAtIndex(index: Int) {
        textStorage!.addAttributes(deTypoStringAttributes, range: NSMakeRange(index, 1))
    }

    func markTextAsHistoryTypoAtIndex(index: Int) {
        textStorage!.addAttributes(enHistoryTypoStringAttributes, range: NSMakeRange(index, 1))
    }

    func markTextAsHistoryTypoAtIndices(indices: Set<Int>) {
        let attributedString = textStorage!.mutableCopy() as! NSMutableAttributedString
        for index in indices {
            if index < attributedString.length {
                attributedString.addAttributes(enHistoryTypoStringAttributes, range: NSMakeRange(index, 1))
            }
        }
        textStorage?.setAttributedString(attributedString)
    }

    func markTextTimeInteval(timeIntervals: [NSTimeInterval]) {
        if timeIntervals.count > 0 {
            let maxTimeInterval = timeIntervals.reduce(timeIntervals[0], combine: { max($0, $1) })
            let attributedString = textStorage!.mutableCopy() as! NSMutableAttributedString
            for index in 0..<timeIntervals.count {
                let alphaValue = (1.0 - CGFloat(timeIntervals[index] / maxTimeInterval))
                let color = NSColor.grayColor().colorWithAlphaComponent(alphaValue)
                let stringAttributes: [String: AnyObject] = [NSBackgroundColorAttributeName: color]
                attributedString.addAttributes(stringAttributes, range: NSMakeRange(index, 1))
            }
            textStorage?.setAttributedString(attributedString)
        }
    }

}