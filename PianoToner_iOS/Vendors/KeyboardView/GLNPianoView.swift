//
//  GLNPianoView.swift
//  GLNPianoView
//
//  Created by Gary Newby on 16/05/2016.
//  Copyright © 2016 Gary Newby. All rights reserved.
//

import UIKit
import QuartzCore

@objc public protocol GLNPianoViewDelegate: class {
    func pianoKeyUp(_ keyNumber: Int)
    func pianoKeyDown(_ keyNumber: Int)
    func noteIsPlaying() -> Bool
    func playingNoteNumber() -> Int
}

@objc public class GLNPianoView: UIView {
    
    @IBInspectable var showNotes: Bool = true
    public weak var delegate: GLNPianoViewDelegate?
    private var _octave: Int = 4
    
    private var keyObjectsArray: [GLNPianoKey?] = []
    
    private var _numberOfKeys: Int = 24
    private static let minNumberOfKeys = 12
    private static let maxNumberOfKeys = 61
    private var _blackKeyHeight: CGFloat = 0.60
    private var _blackKeyWidth: CGFloat = 0.80
    private var currentTouches = NSMutableSet(capacity: maxNumberOfKeys)
    private var whiteKeyCount = 0
    private var keyCornerRadius: CGFloat = 0

    
    func ottavaBassa() {
        if canTransposeDown {
            _octave -= 1
            setNeedsLayout()
        } else {
            StuffLogger.print("Cannot traspose down from \(_octave) with \(_numberOfKeys). ")
        }
    }
    
    func ottavaAlta() {
        if canTransposeUp {
            _octave += 1
            setNeedsLayout()
        } else {
            StuffLogger.print("Cannot traspose up from \(_octave) with already \(_numberOfKeys). ")
        }
    }
    
    var canTransposeUp : Bool {
        get {
            let first = (_octave + 2 ) * 12
            return first + _numberOfKeys <= 108
        }
    }
    
    var canTransposeDown : Bool {
        get {
            return _octave >= -2
        }
    }
    
    var canZoomIn : Bool {
        get {
            return _numberOfKeys - GLNPianoView.minNumberOfKeys >= 12
        }
    }
    
    var canZoomOut : Bool {
        get {
            return GLNPianoView.maxNumberOfKeys - _numberOfKeys >= 12
        }
    }
    
    @IBInspectable public var numberOfKeys: Int {
        get {
            return _numberOfKeys
        }
        set {
            _numberOfKeys = clamp(value: newValue, min: GLNPianoView.minNumberOfKeys, max: GLNPianoView.maxNumberOfKeys)
            let lastMidiNum = (_octave + 2) * 12 + _numberOfKeys
            let diff = (lastMidiNum - 108) % 12
            _octave = _octave + diff
            setNeedsLayout()
        }
    }

    @IBInspectable public var blackKeyHeight: CGFloat {
        get {
            return _blackKeyHeight
        }
        set {
            let value = CGFloat(clamp(value: Int(newValue), min: 0, max: 10))
            _blackKeyHeight = (value + 5) * 0.05
        }
    }

    @IBInspectable public var blackKeyWidth: CGFloat {
        get {
            return _blackKeyWidth
        }
        set {
            let value = CGFloat(clamp(value: Int(newValue), min: 0, max: 8))
            _blackKeyWidth = (value + 10) * 0.05
        }
    }
    
    @IBInspectable var octave: Int {
        get {
            return _octave
        }
        set {
            _octave = newValue
            setNeedsLayout()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        keyCornerRadius = _blackKeyWidth * 8.0
        whiteKeyCount = 0
        currentTouches = NSMutableSet()
        keyObjectsArray = [GLNPianoKey?](repeating: nil, count: (_numberOfKeys + 1))

        for i in 1 ..< _numberOfKeys + 1 {
            if isWhiteKey(i) {
                whiteKeyCount += 1
            }
        }

        isMultipleTouchEnabled = true
        layer.masksToBounds = true
        if let subLayers = layer.sublayers {
            for layer in subLayers {
                layer.removeFromSuperlayer()
            }
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        commonInit()

        let rect: CGRect = bounds
        let whiteKeyHeight = rect.size.height
        let whiteKeyWidth = whiteKeyWidthForRect(rect)
        let blackKeyHeight = rect.size.height * _blackKeyHeight
        let blackKeyWidth = whiteKeyWidth * _blackKeyWidth
        let blackKeyOffset = blackKeyWidth / 2.0

        var currentNoteNumber = ( octave + 2 ) * 12

        // White Keys
        var x: CGFloat = 0
        for i in 0 ..< _numberOfKeys {
            if isWhiteKey(i) {
                let newX = (x + 0.5)
                let newW = ((x + whiteKeyWidth + 0.5) - newX)
                let keyRect = CGRect(x: newX, y: 0, width: newW, height: whiteKeyHeight - 1)
                let key = GLNPianoKey(color: UIColor.white, aRect: keyRect, whiteKey: true, blackKeyWidth: blackKeyWidth,
                                      blackKeyHeight: blackKeyHeight, keyCornerRadius: keyCornerRadius, showNotes: showNotes, noteNumber: currentNoteNumber)
                keyObjectsArray[i] = key
                layer.addSublayer(key.layer)
                x += whiteKeyWidth
                
            }
            currentNoteNumber += 1
        }
        
        // Black Keys
        currentNoteNumber = ( octave + 2 ) * 12
        x = 0.0
        for i in 0 ..< _numberOfKeys {
            if isWhiteKey(i) {
                x += whiteKeyWidth
            } else {
                let keyRect = CGRect(x: (x - blackKeyOffset), y: 0, width: blackKeyWidth, height: blackKeyHeight)
                let key = GLNPianoKey(color: UIColor.black, aRect: keyRect, whiteKey: false, blackKeyWidth: blackKeyWidth,
                                      blackKeyHeight: blackKeyHeight, keyCornerRadius: keyCornerRadius, showNotes: showNotes, noteNumber: currentNoteNumber)
                keyObjectsArray[i] = key
                layer.addSublayer(key.layer)
            }
            currentNoteNumber += 1
        }
        
//        // reassing MIDI note numbering
//        for i in 0 ..< _numberOfKeys {
//            let key = keyObjectsArray[i]
//            key!.noteNumber = currentNoteNumber
//            currentNoteNumber += 1
//        }
    }

    func isWhiteKey(_ keyNumber: Int) -> Bool {
        let k = keyNumber % 12
        return (k == 0 || k == 2 || k == 4 || k == 5 || k == 7 || k == 9 || k == 11)
    }

    func whiteKeyWidthForRect(_ rect: CGRect) -> CGFloat {
        return (rect.size.width / CGFloat(whiteKeyCount))
    }

    public var usingPedale : Bool = false
    
//    func releaseAllKeys() {
//        for i in 0 ..< _numberOfKeys {
//            if let key = keyObjectsArray[i] {
//                key.setImage(keyNum: i, isDown: false)
//                key.isDown = false
//            }
//        }
//    }
    
    func updateKeys() {
        let touches = currentTouches.allObjects as Array
        let count = touches.count
        var keyIsDownAtIndex = [Bool](repeating: false, count: _numberOfKeys)

        let noteIsPlaying = delegate?.noteIsPlaying() ?? false
        
        if usingPedale && noteIsPlaying {
            let touch = touches.last
            let point = (touch as AnyObject).location(in: self)
            let index = getKeyContaining(point)
            if index != NSNotFound {
                if let key = keyObjectsArray[index] {
                    if let delegatto = delegate {
                        if delegatto.playingNoteNumber() == key.noteNumber {
                            key.setImage(keyNum: index, isDown: true)
                            key.isDown = true
                        }
                    }
                }
            }
            
        } else {
            for i in 0 ..< count {
                let touch = touches[i]
                let point = (touch as AnyObject).location(in: self)
                let index = getKeyContaining(point)
                if index != NSNotFound {
                    keyIsDownAtIndex[index] = true
                }
            }
        
            for i in 0 ..< _numberOfKeys {
                if let key = keyObjectsArray[i] {
                    if key.isDown != keyIsDownAtIndex[i] {
                        if keyIsDownAtIndex[i] {
//                            if key.noteNumber >= 0 && key.noteNumber <= 108 {
                                delegate?.pianoKeyDown(key.noteNumber)
//                            }
                            key.setImage(keyNum: i, isDown: true)
                        } else {
//                            if key.noteNumber >= 0 && key.noteNumber <= 108 {
                                delegate?.pianoKeyUp(key.noteNumber)
//                            }
                            key.setImage(keyNum: i, isDown: false)
                        }
                        key.isDown = keyIsDownAtIndex[i]
                    }
                }
            }
            
        }
        setNeedsDisplay()
    }

    func getKeyContaining(_ point: CGPoint) -> Int {
        var keyNum = NSNotFound
        for i in 0 ..< _numberOfKeys {
            if let frame = keyObjectsArray[i]?.layer.frame, frame.contains(point) {
                keyNum = i
                if !isWhiteKey(i) {
                    break
                }
            }
        }
        return keyNum
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        for touch in touches {
            currentTouches.add(touch)
        }
        updateKeys()
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        for touch in touches {
            currentTouches.add(touch)
        }
        updateKeys()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
        for touch in touches {
            currentTouches.remove(touch)
        }
        updateKeys()
    }

    func toggleShowNotes() {
        showNotes = !showNotes
        setNeedsLayout()
    }
    
    func clamp(value: Int, min: Int, max: Int) -> Int {
        let r = value < min ? min : value
        return r > max ? max : r
    }
}
