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

    let normalStringAttributes: [String: AnyObject] = [NSFontAttributeName: NSFont(name: "Menlo", size: 24.0) as! AnyObject,
        NSForegroundColorAttributeName: NSColor.textColor(),
        NSBackgroundColorAttributeName: NSColor.windowBackgroundColor()]

    let enTypedStringAttributes: [String: AnyObject] = [NSBackgroundColorAttributeName: NSColor.controlShadowColor()]
    let deTypedStringAttributes: [String: AnyObject] = [NSBackgroundColorAttributeName: NSColor.windowBackgroundColor()]

    let enTypoStringAttributes: [String: AnyObject] = [NSForegroundColorAttributeName: NSColor.redColor()]
    let deTypoStringAttributes: [String: AnyObject] = [NSForegroundColorAttributeName: NSColor.textColor()]

    let enHistoryTypoStringAttributes: [String: AnyObject] = [NSBackgroundColorAttributeName: NSColor.yellowColor()]
    let deHistroyTypoStringAttributes: [String: AnyObject] = [NSBackgroundColorAttributeName: NSColor.windowBackgroundColor()]

    let helpMessage = "欢迎使用TypeTime跟打器\n\n"
        + "操作说明：\n"
        + "开始新的跟打：Command + L\n"
        + "暂停及恢复跟打：Command + P\n"
        + "完成跟打并递交成绩：Command + Enter\n"
        + "文段编辑：Shift + Command + Enter\n\n"
        + "开发与测试环境：OS X Yosemite"

    func setupInitLookup() {
        inactivate()
        textStorage?.mutableString.setString(helpMessage)
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
        var attributedString = textStorage!.mutableCopy() as! NSMutableAttributedString
        for index in indices {
            if index < attributedString.length {
                attributedString.addAttributes(enHistoryTypoStringAttributes, range: NSMakeRange(index, 1))
            }
        }
        textStorage?.setAttributedString(attributedString)
    }

}