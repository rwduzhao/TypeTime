//
//  TypeText.swift
//  TypeTime
//
//  Created by Rui-Wei Zhao on 9/4/15.
//  Copyright (c) 2015 Rui-Wei Zhao. All rights reserved.
//

import CoreData
import Cocoa
import Foundation

@objc(TypeText)
class TypeText: NSManagedObject {

    @NSManaged var content: String?
    @NSManaged var creator: String?
    @NSManaged var identifier: String?
    @NSManaged var language: String?
    @NSManaged var title: String?
    @NSManaged var type: String?
    @NSManaged var count: NSNumber?
    @NSManaged var creationDate: NSDate?

    var nameTag: String {
        get {
            return "\(language)-\(type)-\(title)"
        }
    }

    func updateCount() {
        count = TypeText.countContent(content!, type: type!)
    }

    func getSampleText(sampleLength: Int, splitNumber: Int, isRandom: Bool) -> String {
        var sep: String?
        var items = [String]()
        switch type! {
        case "Character":
            sep = "\n"
        case "Phrase":
            sep = "\n"
        case "Article":
            sep = nil
        default:
            break
        }
        let startIndex = sampleLength * (splitNumber - 1)
        let endIndex = min(startIndex + sampleLength, count as! Int)
        var string = ""
        if sep != nil {
            items = content!.componentsSeparatedByString(sep!)
            let sampledItems = Array(items[startIndex..<endIndex])
            string = sampledItems.joinWithSeparator("")
        } else {
            let start = content!.startIndex.advancedBy(startIndex)
            let end = content!.startIndex.advancedBy(endIndex)
            string = content!.substringWithRange(Range<String.Index>(start: start, end: end))
        }
        return string
    }

    static func countContent(content: String, type: String) -> Int {
        let numCharacter = content.characters.count
        let numLine = content.componentsSeparatedByString("\n").count
        var count = 0
        switch type {
        case "Character":
            count = numLine
        case "Phrase":
            count = numLine
        case "Article":
            count = numCharacter
        default:
            count = numCharacter
        }
        return count
    }

    static func newObjectForInsertion() -> TypeText? {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext!
        let entity =  NSEntityDescription.entityForName("TypeText", inManagedObjectContext: context)
        return NSManagedObject(entity: entity!, insertIntoManagedObjectContext: context) as? TypeText
    }

    static func clearStore() {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext!
        for object in TypeText.getStoredObjects() {
            context.deleteObject(object)
        }
    }

    static func updateStore() {
        let storedTypeTexts = TypeText.getStoredObjects()
        if let filePaths = TypeText.getResourceTextFilePaths() {
            let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
            let context = appDelegate.managedObjectContext!
            for filePath in filePaths {
                var typeTextAttributes = TypeText.getAttributesFromTextFile(filePath)
                if typeTextAttributes != nil {
                    let nameTag = typeTextAttributes!["nameTag"] as! String
                    typeTextAttributes!.removeValueForKey("nameTag")

                    var isInsertionNeeded = true
                    var isUpdateNeeded = false

                    for storedTypeText in storedTypeTexts {
                        let isDuplicateNameTag = storedTypeText.nameTag == nameTag
                        let creationTime = typeTextAttributes!["creationDate"] as! NSDate
                        let comparisonResult = storedTypeText.creationDate!.compare(creationTime)
                        let isNewerThanStored = comparisonResult == NSComparisonResult.OrderedAscending

                        if isDuplicateNameTag && !isNewerThanStored {
                            isInsertionNeeded = false
                            break
                        }

                        isUpdateNeeded = isDuplicateNameTag && isNewerThanStored
                        if isUpdateNeeded {
                            isInsertionNeeded = false
                            storedTypeText.setValuesForKeysWithDictionary(typeTextAttributes!)
                            try! context.save()
                            break
                        }
                    }

                    if isInsertionNeeded {
                        let typeText = TypeText.newObjectForInsertion()
                        typeText!.setValuesForKeysWithDictionary(typeTextAttributes!)
                        try! context.save()
                    }
                }
            }
        }
    }

    static func getStoredObjects() -> [TypeText] {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "TypeText")
        fetchRequest.returnsObjectsAsFaults = false
        return try! context.executeFetchRequest(fetchRequest) as! [TypeText]
    }

    static func getStoredPropertyValues(propertyName: String, returnsDistinctResults: Bool) -> [AnyObject] {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "TypeText")
        let entity = NSEntityDescription.entityForName("TypeText", inManagedObjectContext: context)
        fetchRequest.entity = entity
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        fetchRequest.propertiesToFetch = [propertyName]
        fetchRequest.returnsDistinctResults = returnsDistinctResults
        fetchRequest.returnsObjectsAsFaults = false
        var values = [AnyObject]()
        let fetchResults = try! context.executeFetchRequest(fetchRequest)
        for fetchResult in fetchResults {
            if let value: AnyObject = fetchResult[propertyName] {
                values.append(value)
            }
        }
        return values
    }

    static func getAttributesFromTextFile(filePath: String) -> [String: AnyObject]? {
        func parseTextFileName(fileName: String) -> [String: AnyObject]? {
            let fileNameSplits = fileName.componentsSeparatedByString("-")
            if fileNameSplits.count >= 3 {
                let trimmingCharacterSet = NSCharacterSet.whitespaceCharacterSet()
                let language = fileNameSplits[0].stringByTrimmingCharactersInSet(trimmingCharacterSet)
                let type = fileNameSplits[1].stringByTrimmingCharactersInSet(trimmingCharacterSet)
                let title = ((fileNameSplits[2..<fileNameSplits.count]).joinWithSeparator("-")).stringByTrimmingCharactersInSet(trimmingCharacterSet)
                let nameTag = "\(language as String?)-\(type as String?)-\(title as String?)"
                let textFileAttributes = ["language": language, "type": type, "title": title, "nameTag": nameTag]
                return textFileAttributes
            } else {
                return nil
            }
        }

        let fileAttributes = try! NSFileManager.defaultManager().attributesOfItemAtPath(filePath) as NSDictionary?
        let fileName = NSURL(fileURLWithPath: filePath).URLByDeletingPathExtension?.lastPathComponent
        var attributes = parseTextFileName(fileName!)
        let fileContent = try! String(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
        if fileAttributes != nil && attributes != nil {
            attributes!["content"] = fileContent
            attributes!["count"] = TypeText.countContent(fileContent, type: attributes!["type"] as! String)
            attributes!["creationDate"] = fileAttributes!.fileCreationDate()
            attributes!["creator"] = "TypeTime"
        } else {
            attributes = nil
        }
        return attributes
    }
    
    static func getResourceTextFilePaths() -> [String]? {
        let fileManager = NSFileManager.defaultManager()
        let resourcePath = NSBundle.mainBundle().resourcePath!
        let paths = try! fileManager.contentsOfDirectoryAtPath(resourcePath) as [String]?
        return paths?.filter({path in path.hasSuffix("txt")}).map({"\(resourcePath)/\($0)"})
    }
    
}