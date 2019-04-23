//
//  ViewController.swift
//  collectionViewLayout
//
//  Created by Floyd 2001 on 2/28/19.
//  Copyright © 2019 Agora.io. All rights reserved.
//

import UIKit

import UIKit
import AgoraRtcEngineKit
import collection_view_layouts

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            let contentFlowLayout: ContentDynamicLayout = FacebookStyleFlowLayout()
            
            contentFlowLayout.delegate = self
            contentFlowLayout.contentPadding = ItemsPadding(horizontal: 10, vertical: 10)
            contentFlowLayout.cellsPadding = ItemsPadding(horizontal: 8, vertical: 8)
            contentFlowLayout.contentAlign = .left
            
            collectionView.collectionViewLayout = contentFlowLayout
        }
    }
    
    var agoraKit: AgoraRtcEngineKit!
    
    var uIds: [Int64] = [] {
        didSet {
            cellsSizes.removeAll()
            (0..<uIds.count).forEach({ _ in cellsSizes.append(CGSize(width: collectionView.bounds.width/2, height: 300)) })
        }
    }
    
    var cellsSizes: [CGSize] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeAgoraEngine()
        setupVideo()
        setChannelProfile()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showJoinAlert()
    }
    
    func showJoinAlert() {
        let alertController = UIAlertController(title: nil, message: "Ready to join channel.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Join", style: .destructive) { (action:UIAlertAction) in
            self.joinChannel()
        }
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
    
    func initializeAgoraEngine() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: AppID, delegate: self)
    }
    
    func setChannelProfile() {
        agoraKit.setChannelProfile(.communication)
    }
    
    func setupVideo() {
        agoraKit.enableVideo()
        agoraKit.setVideoEncoderConfiguration(
            AgoraVideoEncoderConfiguration(size: AgoraVideoDimension640x360,
                                           frameRate: .fps15,
                                           bitrate: AgoraVideoBitrateStandard,
                                           orientationMode: .adaptative)
        )
    }
    
    func joinChannel() {
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        
        guard let uid = (1...100).randomElement() else { return }
        
        agoraKit.joinChannel(byToken: nil,
                             channelId: "DemoChannel",
                             info: nil,
                             uid: UInt(uid)) { [weak self] (sid, uid, elapsed) -> Void in
                                
                                guard let _self = self else { return }
                                DispatchQueue.main.async {
                                    _self.uIds.append(Int64(uid))
                                    _self.collectionView.reloadData()
                                }
                                
        }
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @IBAction func didClickHangUpButton(_ sender: UIButton) {
        leaveChannel()
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel(nil)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    @IBAction func didClickMuteButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        agoraKit.muteLocalAudioStream(sender.isSelected)
    }
}

extension ViewController: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid:UInt, size:CGSize, elapsed:Int) {
        
        uIds.append(Int64(uid))
        collectionView.reloadData()
    }
    
    internal func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid:UInt, reason:AgoraUserOfflineReason) {
        
        if let index = uIds.firstIndex(where: { $0 == uid }) {
            uIds.remove(at: index)
            collectionView.reloadData()
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted:Bool, byUid:UInt) {
        //        remoteVideoMutedIndicator.isHidden = !muted
    }
}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Returning ", uIds.count)
        return uIds.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        let uid = uIds[indexPath.row]
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = UInt(uid)
        videoCanvas.view = cell.contentView
        videoCanvas.renderMode = .hidden
        
        if indexPath.row == 0 {
            agoraKit.setupLocalVideo(videoCanvas)
        } else {
            agoraKit.setupRemoteVideo(videoCanvas)
        }
        
        return cell
    }
}

extension ViewController: ContentDynamicLayoutDelegate {
    
    func cellSize(indexPath: IndexPath) -> CGSize {
        return cellsSizes[indexPath.row]
    }
}
