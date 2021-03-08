/*
 
 PianoToneriOS - piano tone generator
 Copyright (C) 2017-2021  Luca Cipressi lucaji()mail.ru

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>
 
 */

//
//  MTPitchedNode.swift
//  PianoToner
//
//  Created by Luca Cipressi on 2017.04.11 - lucaji()mail.ru
//

import Foundation

struct PTNote: Comparable, CustomStringConvertible{
    typealias `Self` = PTNote
    
    fileprivate static var currentAFrequency : Double = 440.0
    
    public static let aTunings : [Double] = [415.0, 432.0, 435.0, 440.0, 444.0];
    public static var usingSharps : Bool = true
    
    public static let flats = ["C", "D♭","D","E♭","E","F","G♭","G","A♭","A","B♭","B"]
    public static let sharps = ["C", "C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"]
    public static let frequencies: [Double] = [
        16.35, 17.32, 18.35, 19.45, 20.60, 21.83, 23.12, 24.50, 25.96, 27.50, 29.14, 30.87, // 0
        32.70, 34.65, 36.71, 38.89, 41.20, 43.65, 46.25, 49.00, 51.91, 55.00, 58.27, 61.74, // 1
        65.41, 69.30, 73.42, 77.78, 82.41, 87.31, 92.50, 98.00, 103.8, 110.0, 116.5, 123.5, // 2
        130.8, 138.6, 146.8, 155.6, 164.8, 174.6, 185.0, 196.0, 207.7, 220.0, 233.1, 246.9, // 3
        261.6, 277.2, 293.7, 311.1, 329.6, 349.2, 370.0, 392.0, 415.3, 440.0, 466.2, 493.9, // 4
        523.3, 554.4, 587.3, 622.3, 659.3, 698.5, 740.0, 784.0, 830.6, 880.0, 932.3, 987.8, // 5
        1047, 1109, 1175, 1245, 1319, 1397, 1480, 1568, 1661, 1760, 1865, 1976,             // 6
        2093, 2217, 2349, 2489, 2637, 2794, 2960, 3136, 3322, 3520, 3729, 3951,             // 7
        4186, 4435, 4699, 4978, 5274, 5588, 5920, 6272, 6645, 7040, 7459, 7902              // 8
    ]
    
    static func changeReferenceA(_ indexxo : Int) {
        let count = PTNote.aTunings.count
        if (indexxo < count && indexxo >= 0) {
            let newRefAFrequency = PTNote.aTunings[indexxo]
            PTNote.currentAFrequency = newRefAFrequency
        }
    }
    
    static func f(_ midiNoteNumber : Int) -> (Double) {
        /// problem with range from c-2 to c8
        if (midiNoteNumber < 0) {
            return currentAFrequency * exp(0.057762265 * 69.0);
        }
        let x = currentAFrequency * exp(0.057762265 * Double((midiNoteNumber - 69)));
        return x;
    }
    
    public var frequency : Double {
        get {
            return PTNote.f(self.number)
        }
    }
    
    static func midinumberToNoteName(midiNote : Int) -> String {
        
        // StuffLogger.print("midinumberToNoteName \(midiNote)")
        
        let octave = (midiNote / 12) - 1
        let noteIndex = abs(midiNote % 12)
        
        var note : String
        if usingSharps {
            note = PTNote.sharps[noteIndex]
        } else {
            note = PTNote.flats[noteIndex]
        }
        let noteString = "\(note)\(octave)"
        return noteString
    }
    
    static func noteNameByName(_ noteName :String) -> String {
        let offset = noteName.count == 3 ? 2 : 1
        return String(noteName.prefix(offset))
    }
    
    static func noteOctaveByName(_ noteName:String) -> Int {
        var octave = -2
        for i in -2...8 {
            if noteName.hasSuffix(String(i)) { octave = i }
        }
        return octave
    }
    
    fileprivate static func noteIndexInFlats(_ noteName:String) -> Int {
        var semitone = -1
        for (i, n) in flats.enumerated() {
            if noteName.hasPrefix(n) { semitone = i }
        }
        return semitone
    }
    
    
    fileprivate static func noteIndexInSharps(_ noteName:String) -> Int {
        var semitone = -1
        for (i, n) in sharps.enumerated() {
            if noteName.hasPrefix(n) { semitone = i }
        }
        return semitone
    }

    static func noteFrequencyByName(_ noteName:String, playingTranspose traspo:Int) -> Double {
        let octave = noteOctaveByName(noteName)
        let f = 0 //indexForNoteName(noteName)
        let index = f + (12 * (octave + traspo))
        return frequencies[index]
    }

//    static func frequency(of note: PTNote) -> Double {
//            let (baseNote, baseFrequency) = self.noteAndFrequency()
//            let (b, n) = (baseNote.number, note.number)
//
//            return currentAFrequency * pow(2.0, Double(n - b) / 12.0);
//        }
    
    
    var number: Int = 0
//    var frequency: Double { return PTNote.frequencies[number] }
    
    var octave: Int { return (number / 12) - 2 }
    var semitone: Int { return number % 12 }
    var noteName: String {
        get {
            if PTNote.usingSharps {
                return PTNote.sharps[semitone]
            } else {
                return PTNote.flats[semitone]
            }
        }
    }
    var string: String {
        get { return PTNote.midinumberToNoteName(midiNote: self.number) }
    }
    
    var description: String { return string }

    init(number: Int) {
        self.number = number
    }
    
    
    init(withOctave octave: Int, andSemitone semitone: Int) {
        number = 12 * octave + semitone
    }
    
    init?(withMidiNoteName name: String) {
        let uppercased = name.uppercased().trimmingCharacters(in: .whitespaces)
        var semitone = 0
        var octave = 0
        var success = false
        
        for (i, n) in PTNote.sharps.enumerated() {
            if uppercased.hasPrefix(n) {
                success = true
                semitone = i
            }
        }
        if !success { return nil }
        
        success = false
        for i in 0...8 {
            if uppercased.hasSuffix(String(i)) {
                success = true
                octave = i
            }
        }
        if !success { return nil }
        number = 12 * octave + semitone
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.number <= rhs.number
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.number == rhs.number
    }
    
    static func + (lhs: Self, rhs: Int) -> PTNote {
        return PTNote(number: lhs.number + rhs)
    }
}



// MARK: String extension

extension String {
    func toSinglePTNote() -> PTNote? {
        return PTNote(withMidiNoteName: self)
    }
    
    func toPTNoteArray() -> [PTNote] {
        var foundNotes = [PTNote]()
        let notes = self.components(separatedBy: "-")
        for note in notes {
            let nuNote = note.toSinglePTNote()
            if let theNewNote = nuNote {
                foundNotes.append(theNewNote)
            }
        }
        return foundNotes
    }
}


