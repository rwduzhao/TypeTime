//
//  TypeMonitor.swift
//  TypeTime
//
//  Created by Rui-Wei Zhao on 5/1/15.
//  Copyright (c) 2015 Rui-Wei Zhao. All rights reserved.
//

import Cocoa

enum TypeState: Printable {
    case Off
    case On
    case Paused
    case End
    // case Locked

    var description: String {
        get {
            switch self {
            case .Off:
                return "关闭"
            case .On:
                return "进行"
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
    private var numCharIn = 0
    private var cursorLocation = 0
    private var charTimeIntervals = [Double]()
    private var typoIndices = [Int]()
    private var historyTypoIndices = [Int]()

    var infoLine: String {
        get {
            let rateStats = calcRateStatistics()
            let rateKeyDown = rateStats["rateKeyDown"]!
            let rateCorrectChar = rateStats["rateCorrectChar"]!
            let line = "\(state)：正确\(cursorLocation - getNumTypo())字符 "
                + "每分\(num2String(rateCorrectChar))字符 "
                + "每秒\(num2String(rateKeyDown))击键"
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

    func setCharTimeItervalsAt(n: Int, timeInterval: NSTimeInterval) {
        charTimeIntervals[n] = timeInterval
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

    func getHistoryTypoIndices() -> Set<Int> {
        var set = Set<Int>()
        for index in historyTypoIndices {
            if index > 0 {
                set.insert(index)
            }
        }
        return set
    }

    func setHistoryTypoIndicesAt(n: Int) {
        historyTypoIndices[n] = 0
    }

    // state changes

    func reset() {
        state = TypeState.Off

        startDate = nil
        referenceDate = nil
        timer = nil

        timeInterval = 0.0

        numKeyDown = 0
        numCharIn = 0
        cursorLocation = 0

        charTimeIntervals = []
        typoIndices = []
        historyTypoIndices = []
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

    func StartOverAccordingToReference(referenceTextLength: Int) {
        reset()
        charTimeIntervals = [NSTimeInterval](count: referenceTextLength, repeatedValue: 0.0)
        typoIndices = [Int](count: referenceTextLength, repeatedValue: 0)
        historyTypoIndices = [Int](count: referenceTextLength, repeatedValue: 0)
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
        rateStats["rateCorrectChar"] = Double(cursorLocation - getNumTypo()) / Double(timeInterval) * 60.0
        return rateStats
    }

    func num2String(num: Double) -> String {
        return NSString(format: "%.2f", num) as String
    }

}