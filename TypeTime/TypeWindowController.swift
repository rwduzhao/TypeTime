//
//  TypeWindowController.swift
//  TypeTime
//
//  Created by Rui-Wei Zhao on 9/7/15.
//  Copyright (c) 2015 Rui-Wei Zhao. All rights reserved.
//

import Cocoa

class TypeWindowController: NSWindowController {

  override func windowDidLoad() {
    super.windowDidLoad()
  }

  @IBAction func loadTypeText(sender: NSToolbarItem) {
    let sharedApplication = NSApplication.sharedApplication()
    let keyWindow = sharedApplication.keyWindow
    if let viewController = keyWindow?.contentViewController as? TypeViewController {
      viewController.presentLoadTextView()
    }
  }

}