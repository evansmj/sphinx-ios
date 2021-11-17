//
//  PodcastEpisodeTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol PodcastEpisodeRowDelegate : class {
    func shouldStartDownloading(episode: PodcastEpisode, cell: PodcastEpisodeTableViewCell)
    func shouldDeleteFile(episode: PodcastEpisode, cell: PodcastEpisodeTableViewCell)
}

class PodcastEpisodeTableViewCell: SwipableCell {
    
    weak var delegate: PodcastEpisodeRowDelegate?
    
    @IBOutlet weak var episodeLabel: UILabel!
    @IBOutlet weak var playArrow: UILabel!
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var downloadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var progressLabel: UILabel!
    
    var episode: PodcastEpisode! = nil
    
    public static var podcastImage: UIImage? = nil
    
    var downloading = false {
        didSet {
            downloadButton.isHidden = downloading
            LoadingWheelHelper.toggleLoadingWheel(loading: downloading, loadingWheel: downloadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        numberOfButtons = .oneButton
        button3 = button1
        button1.tintColorDidChange()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWith(podcast: PodcastFeed?,
                       and episode: PodcastEpisode,
                       download: Download?,
                       delegate: PodcastEpisodeRowDelegate,
                       isLastRow: Bool,
                       playing: Bool) {
        
        self.episode = episode
        self.delegate = delegate
        
        contentView.backgroundColor = playing ? UIColor.Sphinx.ChatListSelected : UIColor.clear
        playArrow.isHidden = !playing
        
        episodeLabel.text = episode.title ?? "No title"
        divider.isHidden = isLastRow
        
        configureDownload(episode: episode, download: download)
        
        if let img = PodcastEpisodeTableViewCell.podcastImage {
            loadEpisodeImage(episode: episode, with: img)
        } else if let imageURLPath = podcast?.imageURLPath, let url = URL(string: imageURLPath) {
            MediaLoader.asyncLoadImage(imageView: episodeImageView, nsUrl: url, placeHolderImage: UIImage(named: "profile_avatar"), completion: { img in
                PodcastEpisodeTableViewCell.podcastImage = img
                self.loadEpisodeImage(episode: episode, with: img)
            }, errorCompletion: { _ in
                self.loadEpisodeImage(episode: episode, with: UIImage(named: "profile_avatar")!)
            })
        }
    }
    
    func configureDownload(episode: PodcastEpisode, download: Download?) {
        downloading = false
        
        downloadButton.setTitle("", for: .normal)
        downloadButton.setTitleColor(UIColor.Sphinx.Text, for: .normal)
        
        self.contentView.alpha = episode.isAvailable() ? 1.0 : 0.5

        // Disable swipe actions if the episode hasn't been downloaded yet.
        recognizer?.isEnabled = episode.isDownloaded

        if episode.isDownloaded {
            downloadButton.setTitle("", for: .normal)
            downloadButton.setTitleColor(UIColor.Sphinx.PrimaryGreen, for: .normal)
            return
        }
        
        if let _ = download {
            downloading = true
        }
    }
    
    func updateProgress(progress: Float) {
        progressLabel.text = progress == 1 ? "" : "\(Int(progress * 100))%"
    }
    
    func loadEpisodeImage(episode: PodcastEpisode, with defaultImg: UIImage) {
        if let imageURLPath = episode.imageURLPath, let url = URL(string: imageURLPath) {
            MediaLoader.asyncLoadImage(imageView: episodeImageView, nsUrl: url, placeHolderImage: defaultImg, id: Int(episode.itemID) ?? -1, completion: { (img, id) in
                if self.isDifferentEpisode(episodeId: id) { return }
                self.episodeImageView.image = img
            }, errorCompletion: { _ in
                self.episodeImageView.image = defaultImg
            })
        } else {
            self.episodeImageView.image = defaultImg
        }
    }
    
    func isDifferentEpisode(episodeId: Int) -> Bool {
        return episodeId != Int(episode.itemID)
    }
    
    @IBAction func downloadButtonTouched() {
        self.delegate?.shouldStartDownloading(episode: episode, cell: self)
    }
    
    
    @IBAction func deleteButtonTouched() {
        delegate?.shouldDeleteFile(episode: episode, cell: self)
    }
}
