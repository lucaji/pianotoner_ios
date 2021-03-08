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
//  PTViewController.swift
//  pianotoner
//
//  Created by Luca Cipressi on 21/06/2018 - lucaji()mail.ru
//

import UIKit
import SpriteKit
import AudioKit
import AudioKitUI

class PTViewController: UIViewController {
    
    // MARK: Oscillator
    let oscillatorRampTime = 0.2
    fileprivate var oscillatorBooster = AKBooster()
    fileprivate var oscillator = AKOscillator()
    public var oscillatorToneIsAudible = false
    func oscillatorToggle() {
        if oscillatorToneIsAudible {
            oscillatorSilence()
        } else {
            oscillatorPlay()
        }
    }
    public var oscillatorFrequencyText : String {
        get {
            return Formatter.frequency.string(from: NSNumber(value: self.oscillator.frequency))!
        }
    }
    func oscillatorPlay() {
        oscillatorToneIsAudible = true
        oscillatorBooster.gain = 1.0
        NotificationCenter.default.post(name: .mt_oscillatorDidStart, object: nil, userInfo: nil)
    }
    func oscillatorSilence() {
        oscillatorToneIsAudible = false
        oscillatorBooster.gain = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + oscillatorRampTime) {
            NotificationCenter.default.post(name: .mt_oscillatorDidStop, object: nil, userInfo: nil)
        }
    }
    func oscillatorChangeReferenceA(_ indexxo:Int) {
        PTNote.changeReferenceA(indexxo)
        oscillator.frequency = thePlayingNote.frequency
        postUpdatedFrequencyChange()
    }
    func postUpdatedFrequencyChange() {
        NotificationCenter.default.post(name: .mt_oscillatorDidUpdateFrequency,
                                        object: nil,
                                        userInfo: [LJK.NotificationKeys.referenceTuningHasChangedObjectKey:oscillator.frequency])
    }
    public var thePlayingNote = PTNote(number: 69)
    func transposeOctave(_ delta : Int) -> Bool {
        let currentNoteNumber = self.thePlayingNote.number
        let newNumber = currentNoteNumber + (12 * delta)
        
        if (newNumber >= 0 && newNumber < 108) {
            self.changeToMIDINoteNumber(newNumber)
            return true
        } else {
            StuffLogger.print("Out of range transpose \(newNumber) should be within 0..108")
            return false
        }
    }
    func changeToMIDINoteNumber(_ midiNumber : Int) {
        StuffLogger.print("changeToMIDINoteNumber \(midiNumber)")
        if (midiNumber >= 0 && midiNumber <= 108) {
            self.thePlayingNote.number = midiNumber
            self.oscillator.frequency = thePlayingNote.frequency
            postUpdatedFrequencyChange()
        }
    }
    var pedaleHoldActive : Bool = true {
        didSet {
            if pedaleHoldActive {
                
            } else {
                if oscillatorToneIsAudible {
                    oscillatorSilence()
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if oscillatorToneIsAudible {
            oscillatorSilence()
        }
    }

    // MARK: Oscilloscope View
    @IBOutlet weak var oscilloscopeView: SKView!
    var tubeScene: TubeScene?
    func oscilloscopeInit() {
        // Tube Scene with Microphone
        microphone = Microphone(sampleRate: AKSettings.sampleRate, sampleCount: 2048)
        microphone?.delegate = self
        tubeScene = TubeScene(size: oscilloscopeView.bounds.size)
        oscilloscopeView.presentScene(tubeScene)
        oscilloscopeView.ignoresSiblingOrder = true
        tubeScene?.scaleMode = SKSceneScaleMode.resizeFill // without does not work on simulator
        tubeScene?.customDelegate = self
        oscilloscopeView.isPaused = true
    }
    func checkMicPermission(withPresentingViewController vc:UIViewController?) -> Bool {
        var permissionCheck: Bool = false
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            permissionCheck = true
            break
        case AVAudioSession.RecordPermission.denied:
            if (vc != nil) {
                let controller = UIAlertController(title: "Permissions denied", message: "Grant the permissions in iOS Settings", preferredStyle: UIAlertController.Style.alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) in
                    // cancel action
                })
                controller.addAction(cancelAction)
                
                let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                
                            })
                        } else {
                            // Fallback on earlier versions
                            UIApplication.shared.openURL(settingsUrl)
                        }
                    }
                }
                controller.addAction(settingsAction)
                vc!.present(controller, animated: true, completion: nil)
            }
            permissionCheck = false
            break
        default:
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                if granted {
                    permissionCheck = true
                } else {
                }
            })
        }
        return permissionCheck
    }
    let processing = Processing(pointCount: 128)
    var microphone: Microphone?
    var microphoneIsTapping : Bool = false {
        didSet {
            if microphoneIsTapping {
                let granted = self.checkMicPermission(withPresentingViewController: self)
                if granted {
                    self.microphone?.activate()
                    oscilloscopeView.isPaused = false
                }
            } else {
                self.microphone?.inactivate()
                self.tubeScene?.cleanWave()
                oscilloscopeView.isPaused = true
            }
        }
    }

    // MARK: IBOutlets and Actions
    @IBOutlet weak var pedaleButton: UIBarButtonItem!
    @IBAction func pedaleHoldButtonAction(_ sender: UIBarButtonItem) {
        pedaleHoldActive = !pedaleHoldActive
        if pedaleHoldActive {
            sender.title = "Pedale"
        } else {
            sender.title = "Hold"
        }
    }
    
    @IBOutlet weak var notationBarButtonItem: UIBarButtonItem!
    @IBAction func notationBarButtonItemAction(_ sender: UIBarButtonItem) {
        PTNote.usingSharps = !PTNote.usingSharps
        if (PTNote.usingSharps) {
            sender.title = "Use ♯"
        } else {
            sender.title = "Use ♭"
        }
        // should not needed to update
        // pianoview labels as they are drawed
        // on the white keys only
        // self.pianoView.setNeedsLayout()
        updateNoteName()
    }
    func updateNoteName() {
        let name = self.thePlayingNote.string
        label1.text = "\(name)"
    }
    
    @IBOutlet weak var ottavabassaButton: UIBarButtonItem!
    @IBOutlet weak var ottavaaltaButton: UIBarButtonItem!
    
    @IBOutlet weak var playStopButton: UIButton!
    @IBAction func playStopButtonAction(_ sender: UIButton) {
        self.oscillatorToggle()
    }
    
    @IBAction func ottavabassaButtonAction(_ sender: UIBarButtonItem) {
        if (self.transposeOctave(-1)) {
            self.pianoView.ottavaBassa()
            updatePianoViewZoom()
        }
    }
    
    @IBAction func ottavaaltaButtonAction(_ sender: UIBarButtonItem) {
        if (self.transposeOctave(+1)) {
            self.pianoView.ottavaAlta()
            updatePianoViewZoom()
        }
    }

    @IBOutlet weak var pianoView: GLNPianoView!
    @IBOutlet weak var pianoViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    
    @IBOutlet weak var refTuningSegmentedControl: UISegmentedControl!
    @IBAction func refTuningChanged(_ sender: UISegmentedControl) {
        self.oscillatorChangeReferenceA(sender.selectedSegmentIndex)
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        self.oscillatorToggle()
    }
    
    @IBOutlet weak var keybdZoomMinusButton: UIBarButtonItem!
    @IBAction func keybdZoomMinusButtonAction(_ sender: UIBarButtonItem) {
        self.pianoView.numberOfKeys += 12
        updatePianoViewZoom()
    }
    
    @IBOutlet weak var keybdZoomPlusButton: UIBarButtonItem!
    @IBAction func keybdZoomPlusButtonAction(_ sender: UIBarButtonItem) {
        self.pianoView.numberOfKeys -= 12
        updatePianoViewZoom()
    }
    
    func updatePianoViewZoom() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.pianoViewHeightConstraint.constant = CGFloat(480.0 - (Double(self.pianoView.numberOfKeys) * 3.8))
        }
        let canZoomIn = self.pianoView.canZoomIn
        self.keybdZoomPlusButton.isEnabled = canZoomIn
        
        let canZoomOut = self.pianoView.canZoomOut
        self.keybdZoomMinusButton.isEnabled = canZoomOut

        let canTransposeUp = self.pianoView.canTransposeUp
        self.ottavaaltaButton.isEnabled = canTransposeUp
        
        let canTransposeDown = self.pianoView.canTransposeDown
        self.ottavabassaButton.isEnabled = canTransposeDown
    }
    
    func addObservers() {
        if !observersLoaded {
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(appMovingToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
            
            notificationCenter.addObserver(forName: .mt_oscillatorDidStart, object: nil, queue: nil) { (note) in
                self.playStopButton.setImage(UIImage(named:"diapasonOn-bigIcon"), for: .normal)
                //self.tapping = true
            }
            notificationCenter.addObserver(forName: .mt_oscillatorDidStop, object: nil, queue: nil) { (note) in
                self.playStopButton.setImage(UIImage(named:"diapasonOff-bigIcon"), for: .normal)
                //self.tapping = false
            }
            
            notificationCenter.addObserver(forName: .mt_oscillatorDidUpdateFrequency, object: nil, queue: nil) { (note) in
                StuffLogger.print("oscillator changed freq.")
                self.updateNoteName()
                self.label2.text = "\(self.oscillatorFrequencyText) Hz"
            }
            observersLoaded = true
        }
    }
    
    func removeObservers() {
        if observersLoaded {
            let notificationCenter = NotificationCenter.default
            notificationCenter.removeObserver(self)
            notificationCenter.removeObserver(self, name: .mt_oscillatorDidStart, object: nil)
            notificationCenter.removeObserver(self, name: .mt_oscillatorDidStop, object: nil)
            notificationCenter.removeObserver(self, name: .mt_oscillatorDidUpdateFrequency, object: nil)
            observersLoaded = false
        }
    }
    
    func initializeAudioStack() {
        if !audioStackLoaded {
            AKSettings.audioInputEnabled = true // needed to get microphone working
            
            oscillator >>> oscillatorBooster
            oscillatorBooster.gain = 0
            AudioKit.output = oscillatorBooster
            do {
                try AudioKit.start()
                audioStackLoaded = true
            } catch {
                StuffLogger.print("AudioKit did not start!")
            }
            oscillatorBooster.rampDuration = oscillatorRampTime
        }
    }
    
    func deinitAudioStack() {
        if audioStackLoaded {
            oscillatorSilence()
            oscillator.stop()
            
            do {
                try AudioKit.stop()
                audioStackLoaded = false
            } catch {
                StuffLogger.print("AudioKit did not stop!")
            }
        }
    }
    
    // MARK: ViewController lifecycle
    var audioStackLoaded = false
    var observersLoaded = false
    
    deinit {
        self.microphoneIsTapping = false
        deinitAudioStack()
        removeObservers()
    }
    
    @objc func appMovingToForeground() {
        print("App moving to foreground!")
        oscillatorSilence()
        
    }

    @objc func appMovedToBackground() {
        print("App moved to background!")
        oscillatorSilence()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.addObservers()

        initializeAudioStack()

        oscilloscopeInit()
        
        // set up Piano view
        pianoView.delegate = self
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.pianoView.octave = 4
            self.pianoView.numberOfKeys = 48
        } else {
            self.pianoView.octave = 4
            self.pianoView.numberOfKeys = 24
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updatePianoViewZoom()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // prevent an audio glitch by starting the oscillator here
        oscillator.start()
        self.microphoneIsTapping = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.microphoneIsTapping = false
        removeObservers()
        deinitAudioStack()
    }
}

// MARK: GLNPianoViewDelegate

extension PTViewController : GLNPianoViewDelegate {
    func noteIsPlaying() -> Bool {
        return oscillatorToneIsAudible
    }
    
    func playingNoteNumber() -> Int {
        return thePlayingNote.number
    }
    
    func pianoKeyUp(_ keyNumber: Int) {
        if keyNumber >= 0 && keyNumber <= 108 {
            if pedaleHoldActive {
            } else {
                if (keyNumber == self.thePlayingNote.number) {
                    oscillatorSilence()
                }
            }
        }
    }
    
    func pianoKeyDown(_ keyNumber: Int) {
        if keyNumber >= 0 && keyNumber <= 108 {
            self.changeToMIDINoteNumber(keyNumber)
            if (!oscillatorToneIsAudible) {
                oscillatorPlay()
            }
            updateNoteName()
        } else {
            oscillatorSilence()
        }
    }
    
}

// MARK: Scene Delegate

extension PTViewController: TubeSceneDelegate {
    //    func getNotePosition() -> CGFloat {
    //        return CGFloat(tuner.notePosition())
    //    }
    
    func getPulsation() -> CGFloat {
        return CGFloat(processing.pulsation())
    }
}

// MARK: SciTunerMicrophone Delegate

extension PTViewController: MicrophoneDelegate {
    
    func microphone(_ microphone: Microphone?, didReceive data: [Double]?) {
        if !microphoneIsTapping {
            return
        }
        
        //        if let tf = tuner.targetFrequency() {
        //            processing.setTargetFrequency(tf)
        //        }
        
        guard let micro = microphone else {
            return
        }
        
        var wavePoints = [Double](repeating: 0, count: Int(processing.pointCount-1))
        //        let band = tuner.band()
        processing.setBand(fmin: 10.0, fmax: 4000.0)
        
        processing.push(&micro.sample)
        processing.savePreview(&micro.preview)
        processing.recalculate()
        processing.buildSmoothStandingWave2(&wavePoints, length: wavePoints.count)
        tubeScene?.draw(wave: wavePoints)
        
        
        //        if (tunerActivated && !useTuningFork) {
        //            let frequency = processing.getFrequency()
        //            var norm = frequency
        //            if (frequency > 30) {
        //                while norm > MTTuningUtils.frequencies[MTTuningUtils.frequencies.count - 1] {
        //                    norm = norm / 2.0
        //                }
        //                while norm < MTTuningUtils.frequencies[0] {
        //                    norm = norm * 2.0
        //                }
        //
        //                var i = -1
        //                var min = Double.infinity
        //                for n in 0...MTTuningUtils.frequencies.count-1 {
        //                    let diff = MTTuningUtils.frequencies[n] - norm
        //                    if abs(diff) < abs(min) {
        //                        min = diff
        //                        i = n
        //                    }
        //                }
        //
        //                let octave = i / 12
        //                let distance = frequency - MTTuningUtils.frequencies[i]
        //                let pitch = String(format: "%@", MTTuningUtils.sharps[i % MTTuningUtils.sharps.count], MTTuningUtils.flats[i % MTTuningUtils.flats.count])
        //                let noteName = pitch + "\(octave)"
        //                //        DispatchQueue.main.async {
        //                self.gaugeView.value = Float(tuner.noteDeviation())
        //                //        self.gaugeView.value = Float(tuner.noteDeviation())
        //                self.pitchLabel.text = noteName
        //                //        }
        //            } else {
        //                self.gaugeView.value = 0.0
        //                self.pitchLabel.text = nil
        //            }
        //            tuner.frequency = frequency
        //            tuner.updateTargetFrequency()
        //        }
        
    }
    
    
}

struct LJK {
    struct NotificationKeys {
        
        
        static let oscillatorDidUpdateFrequency = "org.themilletgrainfromouterspace.MyTuna.oscillatordidChangeFrequency"
        static let oscillatorDidUpdateWaveform = "org.themilletgrainfromouterspace.MyTuna.oscillatorDidUpdateWaveform"
        static let oscillatorDidStart = "org.themilletgrainfromouterspace.MyTuna.oscillatorDidStart"
        static let oscillatorDidStop = "org.themilletgrainfromouterspace.MyTuna.oscillatorDidStop"
        
        static let playTransposeDidChange = "org.themilletgrainfromouterspace.MyTuna.playTransposeDidChange"
        static let referenceTuningHasChanged = "org.themilletgrainfromouterspace.MyTuna.SignalPlayerTuningChanged"
        static let referenceTuningHasChangedObjectKey = "tuningObjectKey"
        
        static let arpeggiatorDidStart = "org.themilletgrainfromouterspace.MyTuna.arpeggiatorDidStart"
        static let arpeggiatorDidStop = "org.themilletgrainfromouterspace.MyTuna.arpeggiatorDidStop"
        
        static let tunerDidStart = "org.themilletgrainfromouterspace.MyTuna.tunerDidStart"
        static let tunerDidUpdate = "org.themilletgrainfromouterspace.MyTuna.tunerDidUpdate"
        static let tunerDidFail = "org.themilletgrainfromouterspace.MyTuna.tunerDidFail"
        static let tunerDidStop = "org.themilletgrainfromouterspace.MyTuna.tunerDidStop"
        static let tunerDidUpdateObjectKey = "tuningUpdateObjectKey"
        
        static let coreDataImportedCsvKey = "coreDataImportedCsvKey"
        static let coreDataImportedCsvObjectKey = "coreDataImportedCsvObjectKey"
        static let coreDataTuningsShallReloadKey = "coreDataTuningsShallReloadKey"
    }
    
    struct AppDefaultsKeys {
        static let volumeKey = "volumeKey"
        static let thresholdKey = "thresholdKey"
        static let transposeKey = "transposeKey"
        static let referenceATuningKey = "referenceATuningKey"
        
        static let lastStandardTuningNotesKey = "lastStandardTuningNotes"
        static let isSpeakerOverriddenKey = "isSpeakerOverridden"
    }
    
    //    struct Path {
    //        static let Documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
    //        static let Tmp = NSTemporaryDirectory()
    //    }
}


extension Notification.Name {
    static let mt_oscillatorDidUpdateFrequency = Notification.Name(LJK.NotificationKeys.oscillatorDidUpdateFrequency)
    static let mt_oscillatorDidStart = Notification.Name(LJK.NotificationKeys.oscillatorDidStart)
    static let mt_oscillatorDidStop = Notification.Name(LJK.NotificationKeys.oscillatorDidStop)
    static let mt_referenceTuningHasChanged = Notification.Name(LJK.NotificationKeys.referenceTuningHasChanged)
    static let mt_playTransposeDidChange = Notification.Name(LJK.NotificationKeys.playTransposeDidChange)

}
