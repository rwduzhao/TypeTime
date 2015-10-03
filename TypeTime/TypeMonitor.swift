//
//  TypeMonitor.swift
//  TypeTime
//
//  Created by Rui-Wei Zhao on 5/1/15.
//  Copyright (c) 2015 Rui-Wei Zhao. All rights reserved.
//

import Cocoa

enum TypeState: CustomStringConvertible {
    case Off
    case On
    case Paused
    case End
    // case Locked

    var description: String {
        get {
            switch self {
            case .Off:
                return "后台"
            case .On:
                return "跟打"
            case .Paused:
                return "暂停"
            case .End:
                return "完成"
            }
        }
    }
}

class TypeMonitor: NSObject {

    private var state = TypeState.Off

    private var startDate: NSDate?
    private var referenceDate: NSDate?
    private var timer: NSTimer?

    private var timeInterval: NSTimeInterval = 0.0

    private var numKeyDown = 0
    private var numReferenceChar: Int?
    private var numCharIn = 0
    private var cursorLocation = 0
    private var charTimeIntervals = [NSTimeInterval]()
    private var typoIndices = [Int]()
    private var historyTypoIndices = [Int]()

    var infoLine: String {
        get {
            let numCorrectChar = cursorLocation - getNumTypo()
            let rateStats = calcRateStatistics()
            let rateKeyDown = rateStats["rateKeyDown"]!
            let rateCorrectChar = rateStats["rateCorrectChar"]!
            let line = "[\(state)] "
                + "正确：\(numCorrectChar)/\(num2String(numReferenceChar)) "
                + "字速：\(num2String(rateCorrectChar)) "
                + "击键：\(num2String(rateKeyDown))"
            return line
        }
    }

    //

    func getState() -> TypeState {
        return state
    }

    func incrementNumKeyDown() {
        ++numKeyDown
    }

    func addNumCharIn(n: Int) {
        numCharIn += n
    }

    func getCursorLocation() -> Int {
        return cursorLocation
    }

    func forwardCursorLocation(n: Int) {
        cursorLocation += n
    }

    func backwardCursorLocation(n: Int) {
        cursorLocation = max(cursorLocation - n, 0)
    }

    func getTypedCharTimeIntervals() -> [NSTimeInterval] {
        return Array(charTimeIntervals[0..<max(cursorLocation, 0)])
    }

    func setCharTimeIntervalsAt(n: Int, timeInterval: NSTimeInterval) {
        charTimeIntervals[n] = timeInterval
    }

    func addCharTimeIntervalsAt(n: Int, timeInterval: NSTimeInterval) {
        charTimeIntervals[n] += timeInterval
    }

    func getNumTypo() -> Int {
        return typoIndices.reduce(0, combine: +)
    }

    func setTypoIndicesAt(n: Int) {
        typoIndices[n] = 1
    }

    func clearTypoIndiceAt(n: Int) {
        typoIndices[n] = 0
    }

    func getHistoryTypoIndicesWithoutActiveTypos() -> Set<Int> {
        var set = Set<Int>()
        for index in 0..<historyTypoIndices.count {
            if historyTypoIndices[index] > 0 && typoIndices[index] == 0 {
                set.insert(index)
            }
        }
        return set
    }

    func clearHistoryTypoIndiceAt(n: Int) {
        historyTypoIndices[n] = 0
    }

    func setHistoryTypoIndicesAt(n: Int) {
        historyTypoIndices[n] = 1
    }

    // state changes

    func reset() {
        state = TypeState.Off

        startDate = nil
        referenceDate = nil
        timer = nil

        timeInterval = 0.0

        numKeyDown = 0
        numReferenceChar = nil
        numCharIn = 0
        cursorLocation = 0

        charTimeIntervals = []
        typoIndices = []
        historyTypoIndices = []
    }

    func resetAccordingToReference(referenceText: String) {
        reset()
        numReferenceChar = referenceText.characters.count
        charTimeIntervals = [NSTimeInterval](count: numReferenceChar!, repeatedValue: 0.0)
        typoIndices = [Int](count: numReferenceChar!, repeatedValue: 0)
        historyTypoIndices = [Int](count: numReferenceChar!, repeatedValue: 0)
    }

    func start() {
        switch state {
        case .Off:
            state = TypeState.On
            startDate = NSDate()
            referenceDate = startDate
        default:
            break
        }
    }

    func startOverAccordingToReference(referenceText: String) {
        resetAccordingToReference(referenceText)
        start()
    }

    func pause() {
        switch state {
        case .On:
            timeInterval += NSDate().timeIntervalSinceDate(referenceDate!)
            referenceDate = nil
            state = TypeState.Paused
        default:
            break
        }
    }

    func resume() {
        switch state {
        case .Paused:
            referenceDate = NSDate()
            state = TypeState.On
        default:
            break
        }
    }

    func end() {
        switch state {
        case .On:
            timeInterval += NSDate().timeIntervalSinceDate(referenceDate!)
            state = TypeState.End
        case .Paused:
            state = TypeState.End
        default:
            break
        }
    }
    
    func calcRateStatistics() -> [String: Double] {
        var rateStats = [String: Double]()
        rateStats["rateKeyDown"] = Double(numKeyDown) / Double(timeInterval)
        let numCorrectChar = cursorLocation - getNumTypo()
        rateStats["rateCorrectChar"] = Double(numCorrectChar) / Double(timeInterval) * 60.0
        return rateStats
    }
    
    func num2String(num: Double) -> String {
        return NSString(format: "%.2f", num) as String
    }
    
    func num2String(num: Int?) -> String {
        if let nonNilNum = num {
            return "\(nonNilNum)"
        } else {
            return "nil"
        }
    }

}