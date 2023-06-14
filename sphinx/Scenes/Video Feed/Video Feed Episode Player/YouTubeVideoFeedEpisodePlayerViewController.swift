// YouTubeVideoFeedEpisodePlayerViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit
import youtube_ios_player_helper
import AVKit


class YouTubeVideoFeedEpisodePlayerViewController: UIViewController, VideoFeedEpisodePlayerViewController {
    
    @IBOutlet private weak var videoPlayerView: YTPlayerView!
    @IBOutlet private weak var dismissButton: UIButton!
    @IBOutlet private weak var episodeTitleLabel: UILabel!
    @IBOutlet private weak var episodeViewCountLabel: UILabel!
    @IBOutlet weak var episodeSubtitleCircularDivider: UIView!
    @IBOutlet private weak var episodePublishDateLabel: UILabel!
    @IBOutlet weak var localVideoPlayerContainer: UIView!
    var avPlayer : AVPlayerViewController? = nil
    
    let actionsManager = ActionsManager.sharedInstance
    let podcastPlayerController = PodcastPlayerController.sharedInstance
    
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
    
    public func seekTo(time:Int){
        videoPlayerView.seek(toSeconds: Float(time), allowSeekAhead: true)
    }
    
    public func play(at:Int){
        videoPlayerView.playVideo(at: Int32(at))
    }
    
    public func startPlay(){
        videoPlayerView.playVideo()
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
        
        if videoPlayerEpisode.isDownloaded{
            localVideoPlayerContainer.isHidden = false
            if let url = //URL(string: "http://wilcal.test.website.bucket.s3-website-us-west-1.amazonaws.com/h.264/big_buck_bunny_h.264.mp4")
            videoPlayerEpisode.getVideoUrl()
            {
                avPlayer = createVideoPlayerView(withVideoURL: url)
                avPlayer?.delegate = self
                //avPlayer.player?.play()
            }
            
        }
    }
    
    func createVideoPlayerView(withVideoURL videoURL: URL) -> AVPlayerViewController {
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.videoGravity = .resizeAspectFill
        playerViewController.showsPlaybackControls = true
        
        // Set the aspect ratio to 16:9
        let aspectRatio = 16.0 / 9.0
        let width = localVideoPlayerContainer.bounds.width
        let height = width / CGFloat(aspectRatio)
        playerViewController.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        // Add the video player view as a subview of localVideoPlayerContainer
        localVideoPlayerContainer.addSubview(playerViewController.view)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: localVideoPlayerContainer.topAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: localVideoPlayerContainer.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: localVideoPlayerContainer.trailingAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: localVideoPlayerContainer.bottomAnchor)
        ])
        
        // Play the video
        player.play()
        
        return playerViewController
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


extension YouTubeVideoFeedEpisodePlayerViewController : AVPlayerViewControllerDelegate{
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
    ) {
        playerViewController.player = avPlayer?.player
    }
}
