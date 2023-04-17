// YouTubeVideoFeedEpisodePlayerViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import youtube_ios_player_helper


class YouTubeVideoFeedEpisodePlayerViewController: UIViewController, VideoFeedEpisodePlayerViewController {
    
    @IBOutlet private weak var videoPlayerView: YTPlayerView!
    @IBOutlet private weak var dismissButton: UIButton!
    @IBOutlet private weak var episodeTitleLabel: UILabel!
    @IBOutlet private weak var episodeViewCountLabel: UILabel!
    @IBOutlet weak var episodeSubtitleCircularDivider: UIView!
    @IBOutlet private weak var episodePublishDateLabel: UILabel!
    
    let actionsManager = ActionsManager.sharedInstance
    let podcastPlayerController = PodcastPlayerController.sharedInstance
    var paymentsTimer : Timer? = nil
    var playedSeconds : Int = 0
    
    var videoPlayerEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateVideoPlayer(withNewEpisode: self.videoPlayerEpisode, previousEpisode: oldValue)
            }
        }
    }
    
    var currentTime: Float = 0 {
        didSet{
            let id = videoPlayerEpisode.videoID
            UserDefaults.standard.setValue(Int(currentTime), forKey: "videoID-\(id)-currentTime")
        }
    }
    var currentState: YTPlayerState = .unknown
    
    var dismissButtonStyle: ModalDismissButtonStyle = .downArrow
    var onDismiss: (() -> Void)?
    var feedBoostHelper : FeedBoostHelper = FeedBoostHelper()
    
    public func seekTo(time:Int){
        videoPlayerView.seek(toSeconds: Float(time), allowSeekAhead: true)
    }
    
    public func play(at:Int){
        videoPlayerView.playVideo(at: Int32(at))
    }
    
    public func startPlay(){
        videoPlayerView.playVideo()
    }
    
    public func getPlayState(completion: @escaping(Bool)->Void){
        videoPlayerView.playerState({state, _ in
            if(state == .playing){
                completion(true)
            }
            else{
                completion(false)
            }
        })
    }
    
    func configureTimer() {
        paymentsTimer?.invalidate()
        paymentsTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updatePlayedTime),
            userInfo: nil,
            repeats: true
        )
        
        setupFeedBoostHelper()
    }
    
    func setupFeedBoostHelper() {
        if let contentFeed = videoPlayerEpisode.videoFeed {
            feedBoostHelper.configure(with: contentFeed.objectID, and: contentFeed.chat)
        }
    }
    
    @objc func updatePlayedTime() {
        getPlayState(completion: {isPlaying in
            self.playedSeconds = self.playedSeconds + ((isPlaying) ? 1 : 0)
            
            if self.playedSeconds > 0 && self.playedSeconds % 60 == 0 {
                DispatchQueue.global().async {
                    self.processPayment()
                }
            }
        })
    }
    
    func processPayment(){
        feedBoostHelper.processPayment(itemID: videoPlayerEpisode.id, amount: 5)
    }
}


// MARK: -  Static Methods
extension YouTubeVideoFeedEpisodePlayerViewController {
    
    static func instantiate(
        videoPlayerEpisode: Video,
        dismissButtonStyle: ModalDismissButtonStyle = .downArrow,
        onDismiss: (() -> Void)?
    ) -> YouTubeVideoFeedEpisodePlayerViewController {
        let viewController = StoryboardScene
            .VideoFeed
            .youtubeVideoFeedEpisodePlayerViewController
            .instantiate()
        
        viewController.videoPlayerEpisode = videoPlayerEpisode
        viewController.dismissButtonStyle = dismissButtonStyle
        viewController.onDismiss = onDismiss
    
        return viewController
    }
}


// MARK: -  Lifecycle
extension YouTubeVideoFeedEpisodePlayerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        podcastPlayerController.shouldPause()
        podcastPlayerController.finishAndSaveContentConsumed()

        setupViews()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        UserDefaults.standard.setValue(nil, forKey: "videoID-\(videoPlayerEpisode.id)-currentTime")
        videoPlayerView.stopVideo()
        podcastPlayerController.finishAndSaveContentConsumed()
    }
}


// MARK: - Computeds
extension YouTubeVideoFeedEpisodePlayerViewController {
}


// MARK: -  Action Handling
extension YouTubeVideoFeedEpisodePlayerViewController {
    
    @IBAction func dismissButtonTouched() {
        onDismiss?()
    }
}


// MARK: -  Private Helpers
extension YouTubeVideoFeedEpisodePlayerViewController {
    
    private func setupViews() {
        videoPlayerView.delegate = self
        
        episodeSubtitleCircularDivider.makeCircular()
        
        episodeTitleLabel.text = videoPlayerEpisode.titleForDisplay
        episodeViewCountLabel.text = "\(Int.random(in: 100...999)) Views"
        episodePublishDateLabel.text = videoPlayerEpisode.publishDateText
        
        setupDismissButton()
        
        configureTimer()
    }
    
    
    private func setupDismissButton() {
        switch dismissButtonStyle {
        case .downArrow:
            dismissButton.setImage(
                UIImage(systemName: "chevron.down"),
                for: .normal
            )
        case .backArrow:
            dismissButton.setImage(
                UIImage(systemName: "chevron.backward"),
                for: .normal
            )
        }
    }
    
    
    private func updateVideoPlayer(withNewEpisode video: Video, previousEpisode: Video?) {
        if let previousEpisode = previousEpisode {
            currentState = .ended
            
            trackItemFinished(
                videoId: previousEpisode.videoID,
                currentTime,
                shouldSaveAction: true
            )
        }
        
        videoPlayerView.load(withVideoId: videoPlayerEpisode.youtubeVideoID)
        
        episodeTitleLabel.text = videoPlayerEpisode.titleForDisplay
        episodeViewCountLabel.text = "\(Int.random(in: 100...999)) Views"
        episodePublishDateLabel.text = videoPlayerEpisode.publishDateText
    }
}


// MARK: -  YTPlayerViewDelegate
extension YouTubeVideoFeedEpisodePlayerViewController: YTPlayerViewDelegate {
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        currentTime = playTime
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        currentState = state
        
        playerView.currentTime({ (time, error) in
            switch (state) {
            case .playing:
                self.videoPlayerEpisode?.videoFeed?.chat?.updateWebAppLastDate()
                
                if let feedID = self.videoPlayerEpisode.videoFeed?.feedID {
                    FeedsManager.sharedInstance.updateLastConsumedWithFeedID(feedID: feedID)
                }

                self.trackItemStarted(
                    videoId: self.videoPlayerEpisode.videoID,
                    time
                )
                break
            case .paused:
                self.trackItemFinished(
                    videoId: self.videoPlayerEpisode.videoID,
                    self.currentTime
                )
                break
            case .ended:
                self.trackItemFinished(
                    videoId: self.videoPlayerEpisode.videoID,
                    time,
                    shouldSaveAction: true
                )
                break
            default:
                break
            }
        })
    }
    
    func trackItemStarted(
        videoId: String,
        _ currentTime: Float
    ) {
        if let feedItem: ContentFeedItem = ContentFeedItem.getItemWith(itemID: videoId) {
            let time = Int(round(currentTime)) * 1000
            actionsManager.trackItemStarted(item: feedItem, startTimestamp: time)
        }
    }

    func trackItemFinished(
        videoId: String,
        _ currentTime: Float,
        shouldSaveAction: Bool = false
    ) {
        if let feedItem: ContentFeedItem = ContentFeedItem.getItemWith(itemID: videoId) {
            let time = Int(round(currentTime)) * 1000
            actionsManager.trackItemFinished(item: feedItem, timestamp: time, shouldSaveAction: shouldSaveAction)
        }
    }
}
