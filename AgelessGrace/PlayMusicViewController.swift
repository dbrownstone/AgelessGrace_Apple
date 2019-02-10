//
//  PlayMusicViewController.swift
//  AgelessGrace
//
//  Created by David Brownstone on 21/12/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import MediaPlayer
import MarqueeLabel

var audioPlayer  = AudioPlayer.sharedInstance

class PlayMusicViewController: UIViewController, AVAudioPlayerDelegate {
    
    enum SelectedCancelAction: Int {
        case deferredAction = 0
        case tomorrowAction
        case postponeAction
    }
    
    @IBOutlet weak var totalTimeRemaining: UILabel!
    
    @IBOutlet weak var recordingImage: UIImageView!
    
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var artist: UILabel!
    @IBOutlet weak var songTimeRemaining: UILabel!
    
    @IBOutlet weak var tool1Name: UILabel!
    @IBOutlet weak var tool2Name: UILabel!
    @IBOutlet weak var tool3Name: UILabel!
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var marquee: MarqueeLabel!
    
    var selectedGroup:Array<String>!
    var selectedPlayList: MPMediaItemCollection!
    var initialSong: MPMediaItem!
    var selectionTypeIsManual = false
    
    var audioPlayerJustStarted = false
    
    var completedNoticeVisible = false
    
    //    var musicPlayer = MPMusicPlayerController.applicationMusicPlayer
    var timer:Timer!
    var sessionDuration = Double(SESSIONPERIOD)
    var baseTimerText = ""
    var toolTimeRemaining = (SESSIONPERIOD / 3) * 60
    var currentItemCnt = 0
    var isPaused = false
    var isPostponedForLater = false
    var currentItem: MPMediaItem!
    var lastItem = false
    
    var selectedAction: SelectedCancelAction!
    
    // MARK: - view
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        marquee.type = .continuous
        marquee.speed = .duration(35)
        marquee.animationCurve = .easeInOut
        marquee.fadeLength = 10.0
        marquee.leadingBuffer = 30.0
        marquee.trailingBuffer = 30.0
        marquee.layer.borderWidth = 1
        marquee.layer.borderColor = UIColor.gray.cgColor
        marquee.isUserInteractionEnabled = true
        
        currentItemCnt = 0
        displayMusicDetails();
        let mins = SESSIONPERIOD/60
        let secs = SESSIONPERIOD - mins*60
        baseTimerText = NSString(format:"%1.0f:%02.0f",mins,secs) as String
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isPostponedForLater {
            return
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemIsChanged(_:)),
            name:NSNotification.Name(rawValue: "MusicChangedNotification"),
            object: nil
        )
        
        sessionDuration = Double(toolControl.getSessionPeriod())
        sessionDuration *= 60
        totalTimeRemaining.text = baseTimerText
        self.loadTheToolLabels(0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        print("Play music disappears")
    }
    // MARK: - Start Session
    
    @IBAction func startTheSession(_ sender: UIBarButtonItem) {
        startTheTimer()
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(self.pause(_ :))), animated: true)
//        self.navigationItem.rightBarButtonItem = nil
    }
    
    func loadTheToolLabels(_ startingIndex:Int) {
        for var i in startingIndex..<startingIndex+3 {
            if i >= selectedGroup.count {
                i = selectedGroup.count - 1
            }
            let title = selectedGroup[i]
            let idx = (appDelegate.getRequiredArray("AGToolNames")).index(of: title)
            let partialStr = "\(NSLocalizedString("Tool", comment:""))#" + "\(idx! + 1)" + ": " + title
            switch (i - startingIndex) {
            case 0:
                tool1Name.textColor = .red
                tool1Name.text = partialStr
                self.title = title
            case 1:
                tool2Name.textColor = .black
                tool2Name.text = partialStr
            case 2:
                tool3Name.textColor = .black
                tool3Name.text = partialStr

            default:
                break
            }
            
        }
    }
    
    func startTheTimer() {
        UIApplication.shared.isIdleTimerDisabled = true
        toolTimeRemaining = (SESSIONPERIOD / 3) * 60
        currentItemCnt = 0
        setupTickerTape(0)
        
        isPaused = false
        if UIDevice.isSimulator == false {
            /* Start playing the items in the collection */
            audioPlayer.playMusic(selectedPlayList!)
            audioPlayerJustStarted = true
        } else {
            recordingImage.image = UIImage(named:"missingCover")!
        }
        sessionCount(sessionDuration)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: true)
        if audioPlayer.isCurrentlyPlaying {
            currentItem = audioPlayer.currentlyPlaying()
            recordingImage.image = currentItem.value(forProperty: MPMediaItemPropertyArtwork) as? UIImage
            songTitle.text = currentItem.value(forProperty:MPMediaItemPropertyTitle) as? String
            artist.text = currentItem.value(forProperty:MPMediaItemPropertyArtist) as? String
            songTimeRemaining.text = currentItem.value(forProperty: MPMediaItemPropertyPlaybackDuration) as? String
        }
        
    }
    
    @objc func restartTheTimer(_ sender:UIBarButtonItem) {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: true)
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(self.pause(_ :))), animated: true)
        if !UIDevice.isSimulator {
            let song = (selectedPlayList.items)[currentItemCnt] as MPMediaItem
            print("\(String(describing: song.value(forProperty: MPMediaItemPropertyTitle) as? String))")
        }
        audioPlayer.playNextPiece()
    }
    
    func setupTickerTape(_ itemCnt:Int) {
        marquee.text = getTheText(itemCnt)
    }
    
    func getTheText(_ itemCnt:Int) -> String {
        var indx = itemCnt
        if indx >= selectedGroup.count {
            indx = selectedGroup.count - 1
        }
        var theString = ""
        let idx = getToolId(selectedGroup[indx])
        theString = selectedGroup[indx] + ": " + (appDelegate.getRequiredArray("AGToolBodyPartsToMove"))[idx] + " ~  " + (appDelegate.getRequiredArray("AGToolMovementSuggestions"))[idx]
        return (theString.components(separatedBy: "\n")).joined(separator: ", ")
    }
    
    func getToolId(_ toolStr: String) -> Int {
        return (appDelegate.getRequiredArray("AGToolNames")).index(of: toolStr)!
    }
    
    // MARK: - Timer Action
    
    @objc func timerAction(_ sender: UIBarButtonItem) {
        audioPlayerJustStarted = false
        if toolTimeRemaining <= 0 {
            audioPlayer.stopPlayingCurrentAudio()
            timer.invalidate()
            selectTheNextTool()
            if datastore.pauseBetweenTools() {
                self.navigationItem.setRightBarButton(
                    UIBarButtonItem(barButtonSystemItem: .play,
                                    target: self, action: #selector(self.restartTheTimer(_ :))),
                    animated: true
                )
            }
            return
        } else {
            toolTimeRemaining -= 1
        }
        sessionDuration -= 1
        sessionCount(sessionDuration)
        if sessionDuration == 0 {
            // session end
            timer.invalidate()
            totalTimeRemaining.text = baseTimerText
            audioPlayer.stopPlayingAudio()
            datastore.setDateOfLastCompletedExercise()
            UIApplication.shared.isIdleTimerDisabled = false
            self.performSegue(withIdentifier: "returnToMainMenu", sender: self)
        } else {
            var remainingTime = audioPlayer.setRemainingTime(lastItem)
            if remainingTime <= 0 && toolTimeRemaining > 5 {
                audioPlayer.repeatCurrentItem()
                remainingTime = toolTimeRemaining
            } else if lastItem  && sessionDuration > remainingTime && remainingTime < SESSIONPERIOD {
                audioPlayer.repeatCurrentItem()
                remainingTime = audioPlayer.setRemainingTime(lastItem)
                
            }
            musicCount(Float(remainingTime))
        }
    }
    
    func selectTheNextTool() {
        currentItemCnt += 1
        switch (currentItemCnt) {
        case 1:
            tool2Name.textColor = .red
            tool1Name.textColor = .black
            tool3Name.textColor = .black
            self.title = selectedGroup[currentItemCnt]
        case 2:
            tool3Name.textColor = .red
            tool1Name.textColor = .black
            tool2Name.textColor = .black
            self.title = selectedGroup[currentItemCnt]
        default:
            break
        }
        setupTickerTape(currentItemCnt)
        displayMusicDetails()
        toolTimeRemaining = (SESSIONPERIOD / 3) * 60
        
    }
    
    func musicCount(_ cnt:Float) {
        let mins = floor(cnt/60)
        let secs = cnt - mins*60
        songTimeRemaining.text = NSString(format:"%1.0f:%02.0f",mins,secs) as String
    }
    
    func sessionCount(_ cnt:Double) {
        let mins = floor(cnt/60)
        let secs = cnt - mins*60
        totalTimeRemaining.text = NSString(format:"%1.0f:%02.0f",mins,secs) as String
    }
    
    func displayMusicDetails() {
        if UIDevice.isSimulator {
            recordingImage.image = UIImage(named:"missingCover")!
            return
        }
        let song = (selectedPlayList.items)[currentItemCnt] as MPMediaItem
        let duration = song.value(forProperty: MPMediaItemPropertyPlaybackDuration)! as! Double
        let timeReqd = " (" + (NSString(format: "%01.0f:%02.0f",duration/60,duration.truncatingRemainder(dividingBy: 60)) as String) as String + ")"
        
        songTimeRemaining.text = timeReqd
        songTitle.text = song.value(forProperty: MPMediaItemPropertyTitle) as? String
        artist.text = song.value(forProperty: MPMediaItemPropertyArtist) as? String
        let artwork = song.value(forProperty: MPMediaItemPropertyArtwork)
        if artwork != nil {
            recordingImage.image = (artwork! as AnyObject).image(at: CGSize (width: 240, height: 240))
        } else {
            recordingImage.image = UIImage(named:"missingCover")!
        }
    }
    
    @objc func nowPlayingItemIsChanged(_ notification: Notification) {
        if notification.userInfo?["playbackState"] != nil && notification.userInfo?["playbackState"] as! String == "interrupted" {
            self.pause()
            return
        }
        lastItem = false
        if selectedPlayList != nil {
            displayMusicDetails()
        }
    }
    
    // MARK: - Actions
    @objc func pause(_ sender:UIBarButtonItem) {
        self.pause()
    }
    
    func pause() {
        print("timer paused at: \(String(describing: (totalTimeRemaining.text)!))")
        timer.invalidate()
        audioPlayer.pauseTheMusicPlayer()
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(self.resume(_ :))), animated: true)
    }
    
    @objc func resume(_ sender:UIBarButtonItem) {
        audioPlayer.resumeTheMusicPlayer();
    }
    
    @IBAction func next(_ sender: Any) {
        currentItemCnt += 1
        if currentItemCnt == (selectedPlayList.items).count {
            currentItemCnt = 0
            audioPlayer.restartTheSelectionList()
        } else {
            audioPlayer.playNextPiece()
        }
        currentItem = audioPlayer.currentlyPlaying()
        //        currentItemCnt += 1
        displayMusicDetails()
    }
    
    @IBAction func cancel(_ sender: Any) {
        showActionSheet()
    }
    
    @objc func showActionSheet() {
        var title = NSLocalizedString("Session Incomplete", comment: " ")
        let message = NSLocalizedString("Touch 'Later' to restart later on today,\n'Tomorrow' to restart tomorrow or\n'Postpone' to the last of the 10 minute sessions", comment: " ")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        title = NSLocalizedString("Later", comment: " ")
        let firstAction = UIAlertAction(title: title, style: .default) { (alert: UIAlertAction!) -> Void in
            self.selectedAction = .deferredAction
            self.performSegue(withIdentifier: "laterPlay", sender: self)
        }
        alertController.addAction(firstAction)
        title = NSLocalizedString("Tomorrow", comment: " ")
        let secAction = UIAlertAction(title: title, style: .default) { (alert: UIAlertAction!) -> Void in
            self.selectedAction = .tomorrowAction
            self.performSegue(withIdentifier: "laterPlay", sender: self)
        }
        alertController.addAction(secAction)
        title = NSLocalizedString("Postpone", comment: " ")
        let thirdAction = UIAlertAction(title: title, style: .default) { (alert: UIAlertAction!) -> Void in
            self.selectedAction = .postponeAction
            self.performSegue(withIdentifier: "laterPlay", sender: self)
        }
        alertController.addAction(thirdAction)
        title = NSLocalizedString("Cancel", comment: " ")
        let cancelAction = UIAlertAction(title: title, style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion:nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if self.timer != nil {
            self.timer.invalidate()
            audioPlayer.stopPlayingAudio()
        }
        if segue.identifier == "returnToMainMenu" {
            let controller = segue.destination as! ToolsViewController
            if self.selectionTypeIsManual {
                self.selectionTypeIsManual = false
                for tool in selectedGroup {
                    controller.completedManualTools.append(tool)
                }
                let cMT = controller.completedManualTools
                var cMTIds = [Int]()
                for i in 0..<cMT!.count {
                    cMTIds.append(getToolId((cMT![i])))
                }
                controller.completedManualToolIds = cMTIds
            }
            controller.toolGroupHasBeenCompleted = true
             
        }
    }
}
