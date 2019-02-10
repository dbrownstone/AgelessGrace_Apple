//
//  AudioPlayer.swift
//  AgelessGrace
//
//  Created by David Brownstone on 21/12/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    static let sharedInstance:AudioPlayer = AudioPlayer()
    var musicPlayer = MPMusicPlayerController.applicationMusicPlayer
    
    var UIDictionary = Dictionary<String, AnyObject>()
    
    var currentItemCnt = 0
    
    var tickerFrame:CGRect!
    
    var mediaItemCollection:MPMediaItemCollection!
    
    var isCurrentlyPlaying = false
    var isCurrentlyPaused = false
    
    fileprivate override init() {
        super.init()
    }
    
    func stopMusicPlayerNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self,
                                          name:.MPMusicPlayerControllerNowPlayingItemDidChange,
                                          object:musicPlayer)
        notificationCenter.removeObserver(self,
                                          name:.MPMusicPlayerControllerPlaybackStateDidChange,
                                          object:musicPlayer)
    }
    
    func shuffleTheMusic(_ shuffle:Bool) {
        if shuffle == true {
            musicPlayer.shuffleMode = .songs
        } else {
            musicPlayer.shuffleMode = .off
        }
    }
    
    func repeatTheMusic(_ repeatSongs:Bool) {
        if repeatSongs == true {
            musicPlayer.repeatMode = .all
        } else {
            musicPlayer.repeatMode = .none
        }
    }
    
    func pauseTheMusicPlayer() {
        if musicPlayer.playbackState == .paused {
            musicPlayer.play()
            isCurrentlyPaused = false
        } else {
            musicPlayer.pause()
            isCurrentlyPaused = true
        }
    }
    
    func resumeTheMusicPlayer() {
        musicPlayer.play()
    }
    
    @objc func musicPlayerStateChanged(_ notification: Notification){
        
        let notificationCenter = NotificationCenter.default

        isCurrentlyPlaying = false
        /* Get the state of the player */
        switch musicPlayer.playbackState {
        case .stopped:
            /* The media player has ceased playing the queue. */
            print("Stopped")
        case .playing:
            /* The media player is playing the queue. */
            isCurrentlyPlaying = true
            let index = musicPlayer.indexOfNowPlayingItem
            print("Playing index: \(index)")
        case .paused:
            /* The media playback is paused here. You might want
             to indicate by showing graphics to the user */
            print("Paused")
       case .interrupted:
            /* An interruption stopped the playback of the media queue */
            print("Interrupted")
            notificationCenter.post(name: Notification.Name(rawValue: "MusicChangedNotification"), object: self, userInfo:["playbackState": "interrupted"])
        case .seekingForward:
            /* The user is seeking forward in the queue */
            print("Seeking Forward")
        case .seekingBackward:
            /* The user is seeking backward in the queue */
            print("Seeking Backward")
        }
    }
    
    @objc func nowPlayingItemIsChanged(_ notification: Notification) {
        let currentItem = musicPlayer.nowPlayingItem
        if currentItem == nil {
            return
        }
        let artwork = currentItem!.value(forProperty: MPMediaItemPropertyArtwork)
        var image:UIImage!
        if artwork != nil {
            image = (artwork! as AnyObject).image(at: CGSize (width: 240, height: 240))
        } else {
            image = UIImage(named:"missingCover")!
        }
        UIDictionary = ["ArtworkImage":image!]
        if currentItem!.value(forProperty: MPMediaItemPropertyTitle) != nil {
            UIDictionary["SongTitle"] = currentItem!.value(forProperty: MPMediaItemPropertyTitle)! as AnyObject
        }
        if currentItem!.value(forProperty: MPMediaItemPropertyArtist) != nil {
            UIDictionary["Artist"] = currentItem!.value(forProperty: MPMediaItemPropertyArtist)! as AnyObject
        }
        if currentItem!.value(forProperty: MPMediaItemPropertyPlaybackDuration) != nil {
            UIDictionary["PlayingTime"] = currentItem!.value(forProperty: MPMediaItemPropertyPlaybackDuration)! as AnyObject
        }
        let notificationCenter = NotificationCenter.default
        notificationCenter.post(name: Notification.Name(rawValue: "MusicChangedNotification"), object: self, userInfo:UIDictionary)
    }
    
    func getUIDictionary() -> Dictionary <String,AnyObject> {
        return UIDictionary
    }
    
    func getCurrentPlaybackTime() -> Double {
        return musicPlayer.currentPlaybackTime
    }
    
    func getPlaybackDuration() -> NSNumber {
        return musicPlayer.nowPlayingItem!.value(forProperty: MPMediaItemPropertyPlaybackDuration)! as! NSNumber
    }
    
    func setRemainingTime(_ lastItem:Bool) -> Double {
        let currentItem = musicPlayer.nowPlayingItem
        if currentItem == nil {
            return 0
        }
        let nowPlayingItemDuration = ((currentItem!.value(forProperty: MPMediaItemPropertyPlaybackDuration))! as AnyObject).doubleValue
        let currentTime = musicPlayer.currentPlaybackTime
        let remainingTime = nowPlayingItemDuration! - currentTime
        
        return remainingTime
    }
    
    func currentlyPlaying() -> MPMediaItem {
        return musicPlayer.nowPlayingItem!
    }
    
    func restartTheSelectionList() {
        playMusic(mediaItemCollection)
    }
    
    func playMusic(_ selectedList:MPMediaItemCollection) {
        self.mediaItemCollection = selectedList
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self,
                                       selector:#selector(AudioPlayer.nowPlayingItemIsChanged(_:)),
                                       name:NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
                                       object:musicPlayer)
        notificationCenter.addObserver(self,
                                       selector:#selector(AudioPlayer.musicPlayerStateChanged(_:)),
                                       name:NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
                                       object:musicPlayer)
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        musicPlayer.setQueue(with: selectedList)
        musicPlayer.play()
    }
    
    func playSelectedMusic(_ query:MPMediaQuery) {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self,
                                       selector:#selector(AudioPlayer.nowPlayingItemIsChanged(_:)),
                                       name:NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
                                       object:musicPlayer)
        notificationCenter.addObserver(self,
                                       selector:#selector(AudioPlayer.musicPlayerStateChanged(_:)),
                                       name:NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
                                       object:musicPlayer)
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        musicPlayer.setQueue(with: query)
        musicPlayer.play()
    }
    
    func repeatCurrentItem() {
        musicPlayer.skipToBeginning()
    }
    
    func playNextPiece() {
        musicPlayer.skipToNextItem()
        musicPlayer.play()
    }
    
    func stopPlayingCurrentAudio() {
        musicPlayer.stop()
    }


    func stopPlayingAudio(){
        musicPlayer.stop()
        //        musicPlayer.endGeneratingPlaybackNotifications()
        stopMusicPlayerNotifications()
    }
}
