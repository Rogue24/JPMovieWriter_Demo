//
//  ViewController.swift
//  JPMovieWriter
//
//  Created by 周健平 on 03/21/2023.
//  Copyright (c) 2023 zhoujianping. All rights reserved.
//

import UIKit
import AVKit
import JPBasic
import Combine

class ViewController: UIViewController {
    static let colCount: Int = 2
    static let colMargin: CGFloat = 5.px
    static let rowMargin: CGFloat = 5.px
    static let edgeInsets = UIEdgeInsets(top: NavTopMargin + 8.px, left: 8.px, bottom: DiffTabBarH + 8.px, right: 8.px)
    
    lazy var startBtn: UIView = {
        let image = UIImage(named: "live_instructor_dark_bg")!
        let imageView = UIImageView(image: image)
        imageView.size = [150.px, 150.px * (image.size.height / image.size.width)]
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 12.px)
        label.textColor = UIColor(white: 1, alpha: 0.5)
        label.text = "点我开始创作"
        label.sizeToFit()
        label.origin = [HalfDiffValue(imageView.width, label.width), imageView.maxY + 12.px]
        
        let startBtn = UIView()
        startBtn.addSubview(label)
        startBtn.addSubview(imageView)
        startBtn.clipsToBounds = false
        startBtn.size = [imageView.width, label.maxY]
        startBtn.center = [PortraitScreenWidth * 0.5, PortraitScreenHeight * 0.5]
        startBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(startAction)))
        
        return startBtn
    }()
    
    lazy var collectionView: UICollectionView = {
        let waterfallLayout = WaterfallLayout()
        waterfallLayout.delegate = self
        let collectionView = UICollectionView(frame: PortraitScreenBounds, collectionViewLayout: waterfallLayout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isUserInteractionEnabled = false
        collectionView.register(WorksCell.self, forCellWithReuseIdentifier: "cell")
        return collectionView
    }()
    
    var worksCMs: [WorksCellModel] = []
    var store: WorksStore { .shared }
    var canceler: AnyCancellable?
    
    var insertIndex: Int?
    var deleteIndex: Int?
    var reloadIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let recordItem = UIBarButtonItem(image: UIImage(systemName: "video.fill.badge.plus"), style: .plain, target: self, action: #selector(gotoRecord))
        navigationItem.rightBarButtonItem = recordItem
        
        let albumItem = UIBarButtonItem(image: UIImage(systemName: "photo"), style: .plain, target: self, action: #selector(openAlbum))
        navigationItem.leftBarButtonItem = albumItem
        
        tryFirstRecord()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupSubscription()
    }
    
    deinit {
        canceler?.cancel()
    }
    
    /**
     * 由于`AVAssetWriter`【第一次】执行`startWriting`方法时会发生卡顿，之后就不会，目前还不知道该如何从根本上解决.....
     * 只好第一次初始化时就直接执行一次`startWriting`，确保后续不会再卡顿。
     */
    static var isFirstRecorded = false
    static var tmpWriter: JPMovieWriter?
    func tryFirstRecord() {
        guard !Self.isFirstRecorded else { return }
        Self.isFirstRecorded = true
        
        Asyncs.async {
            let writer = JPMovieWriter(fileType: AVFileType.mp4,
                                       videoSize: UIConfig.videoSize,
                                       videoSettings: RecordConfig.videoOutputSettings,
                                       recordedURLs: [])
            writer.startRecord()
            Self.tmpWriter = writer
            Asyncs.mainDelay(0.1) {
                writer.cancelRecord { urls in
                    urls.forEach { File.manager.deleteFile($0) }
                    Self.tmpWriter = nil
                }
            }
        }
    }
    
    func worksIndex(for identifier: Int) -> Int? {
        worksCMs.firstIndex { $0.works.cache.identifier == identifier }
    }
}

// MARK: - Setup
extension ViewController {
    func setupUI() {
        view.backgroundColor = UIConfig.mainBgColor
        view.insertSubview(collectionView, at: 0)
        view.insertSubview(startBtn, at: 0)
        navigationItem.title = "JPMovieWriter 🎬"
    }
    
    func setupSubscription() {
        guard canceler == nil else { return }
        
        canceler = store.$worksList
            .subscribe(on: DispatchQueue.global()) // 订阅在子线程
            .map { worksList -> [WorksCellModel] in
                return worksList.map { WorksCellModel($0) }
            }
            .receive(on: DispatchQueue.main) // 接收在主线程
            .sink { [weak self] worksCMs in
                self?.reloadList(worksCMs)
            }
        
        store.asyncFetchWorks()
    }
}

// MARK: - UIRespond Action
extension ViewController {
    @objc func startAction() {
        UIAlertController
            .build(.actionSheet)
            .addAction("开始录制") { self.startRecord() }
            .addAction("从相册导入") { self.importAlbumVideo() }
            .addCancel()
            .present(from: self)
    }
    
    @objc func gotoRecord() {
        startRecord()
    }
    
    @objc func openAlbum() {
        importAlbumVideo()
    }
}

// MARK: - <UICollectionViewDataSource, UICollectionViewDelegate>
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        worksCMs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! WorksCell
        cell.worksCM = worksCMs[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.setContentOffset(collectionView.contentOffset, animated: true)
        
        let worksCM = worksCMs[indexPath.row]
        let works = worksCM.works
        let cache = works.cache
        
        guard File.manager.fileExists(cache.recordCachePath) else {
            UIAlertController
                .build(.alert, title: "文件已丢失！")
                .addDestructive("删除") { self.deleteWorks(works)}
                .addCancel()
                .present(from: self)
            return
        }
        
        let alertCtr = UIAlertController.build(.actionSheet)
        alertCtr.addAction("播放") { self.tryPlay(at: indexPath.item) }
        
        if works.second <= (RecordConfig.videoMaxDuration - 1) {
            alertCtr
                .addAction("继续录制") { self.startRecord(from: cache) }
                .addAction("拼接相册视频") { self.montageAlbumVideo(from: works) }
        }
        
        alertCtr
            .addAction("制作GIF") { self.gifMake(from: works) }
            .addAction("编辑封面&标题") { self.editCoverAndTitle(from: works) }
            .addAction("保存到相册") { self.saveToAlbum(from: works) }
            .addDestructive("删除") { self.deleteWorks(works)}
            .addCancel()
            .present(from: self)
    }
}

// MARK: - <WaterfallLayoutDelegate>
extension ViewController: WaterfallLayoutDelegate {
    func waterfallLayout(_ waterfallLayout: WaterfallLayout, heightForItemAtIndex index: Int, itemWidth: CGFloat) -> CGFloat {
        let worksCM = worksCMs[index]
        return worksCM.cellSize.height
    }
    
    func colCountInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> Int {
        Self.colCount
    }
    
    func colMarginInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> CGFloat {
        Self.colMargin
    }
    
    func rowMarginInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> CGFloat {
        Self.rowMargin
    }
    
    func edgeInsetsInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> UIEdgeInsets {
        Self.edgeInsets
    }
}

// MARK: - Reload List
extension ViewController {
    func reloadList(_ worksCMs: [WorksCellModel]) {
        self.worksCMs = worksCMs
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 1) {
            self.startBtn.alpha = worksCMs.count == 0 ? 1 : 0
            self.collectionView.isUserInteractionEnabled = worksCMs.count > 0
            self.collectionView.performBatchUpdates {
                if let insertIndex = self.insertIndex {
                    self.collectionView.insertItems(at: [IndexPath(item: insertIndex, section: 0)])
                } else if let deleteIndex = self.deleteIndex {
                    self.collectionView.deleteItems(at: [IndexPath(item: deleteIndex, section: 0)])
                } else if let reloadIndex = self.reloadIndex {
                    self.collectionView.reloadItems(at: [IndexPath(item: reloadIndex, section: 0)])
                } else {
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
                self.insertIndex = nil
                self.deleteIndex = nil
                self.reloadIndex = nil
            }
        }
    }
}

// MARK: - Play Video
private extension ViewController {
    func tryPlay(at index: Int) {
        let works = worksCMs[index].works
        tryPlay(withPath: works.recordCachePath) {
            UIAlertController
                .build(.alert, title: "文件不存在！")
                .addDestructive("删除") { self.deleteWorks(works)}
                .addCancel()
                .present(from: self)
        }
    }
    
    func tryPlay(withPath path: String, nullHandler: (() -> Void)? = nil) {
        guard File.manager.fileExists(path) else {
            nullHandler?()
            return
        }
        
        let playerVC = AVPlayerViewController()
        playerVC.player = AVPlayer(url: URL(fileURLWithPath: path))
        present(playerVC, animated: true) { [weak playerVC] in playerVC?.player?.play() }
    }
}

private extension ViewController {
    func gifMake(from works: Works) {
        let gifMakeVC = GifMakeViewController()
        gifMakeVC.videoURL = URL(fileURLWithPath: works.recordCachePath)
        navigationController?.pushViewController(gifMakeVC, animated: true)
    }
}

private extension ViewController {
    // MARK: - 开始/继续录制
    func startRecord(from oldCache: RecordCache? = nil) {
        RecordViewController.show(oldCache) { [weak self] newCache in
            guard let self = self else { return }
            if oldCache != nil {
                if newCache.recordTimeInt != 0 {
                    self.reloadIndex = self.worksIndex(for: newCache.identifier)
                }
            } else {
                self.insertIndex = 0
            }
            WorksStore.shared.asyncFetchWorks()
            self.tryPlay(withPath: newCache.recordCachePath)
        }
    }
    
    // MARK: - 从相册导入视频
    func importAlbumVideo() {
        ImagePicker.openAlbumForVideoURL { result in
            switch result {
            case let .success(url):
                JPProgressHUD.show()
                VideoTool.mergeVideos([url],
                                      maxDuration: CMTime(seconds: RecordConfig.videoMaxDuration, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                { mergedFilePath in
                    Asyncs.async {
                        self.insertIndex = 0
                        RecordCacheTool.recordDoneToSave(RecordCache(), recordFilePath: mergedFilePath)
                        WorksStore.shared.fetchWorks()
                    } mainTask: {
                        JPProgressHUD.dismiss()
                    }
                } faild: { kError in
                    JPProgressHUD.showError(withStatus: (kError as? NSError)?.localizedDescription ?? "合成失败", userInteractionEnabled: true)
                }
            case let .failure(error):
                guard !error.isUserCancel else { return }
                JPProgressHUD.showError(withStatus: "视频获取失败", userInteractionEnabled: true)
            }
        }
    }
    
    // MARK: - 拼接相册视频
    func montageAlbumVideo(from works: Works) {
        ImagePicker.openAlbumForVideoURL { result in
            switch result {
            case let .success(url):
                JPProgressHUD.show()
                let cache = works.cache
                VideoTool.mergeVideos(
                    [
                        URL(fileURLWithPath: cache.recordCachePath),
                        url,
                    ],
                    videoSize: UIConfig.videoSize,
                    contentMode: .scaleAspectFit,
                    maxDuration: CMTime(seconds: RecordConfig.videoMaxDuration, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                { mergedFilePath in
                    Asyncs.async {
                        if cache.recordTimeInt != 0 {
                            self.reloadIndex = self.worksIndex(for: cache.identifier)
                        }
                        RecordCacheTool.recordDoneToSave(cache, recordFilePath: mergedFilePath)
                        WorksStore.shared.fetchWorks()
                        
                        Asyncs.main {
                            JPProgressHUD.dismiss()
                            self.tryPlay(withPath: cache.recordCachePath)
                        }
                    }
                } faild: { kError in
                    JPProgressHUD.showError(withStatus: (kError as? NSError)?.localizedDescription ?? "合成失败", userInteractionEnabled: true)
                }
            case let .failure(error):
                guard !error.isUserCancel else { return }
                JPProgressHUD.showError(withStatus: "视频获取失败", userInteractionEnabled: true)
            }
        }
    }
    
    // MARK: - 编辑作品封面&标题
    func editCoverAndTitle(from works: Works) {
        let vc = EditViewController()
        vc.works = works
        vc.saveHandler = { [weak self] kWorks, kImage, kTitle in
            guard let self = self else { return }
            JPProgressHUD.show()
            Asyncs.async {
                var isUpdate = false
                let cache = kWorks.cache
                
                if let image = kImage, let imageData = image.jpegData(compressionQuality: 0.9) {
                    File.manager.deleteFile(cache.coverPath)
                    cache.coverRatio = 1
                    cache.coverTag += 1
                    cache.isEditedCover = true
                    do {
                        try imageData.write(to: URL(fileURLWithPath: cache.coverPath))
                        cache.coverRatio = image.size.width / image.size.height
                    } catch {}
                    isUpdate = true
                }
                
                if let title = kTitle {
                    cache.videoTitle = title
                    isUpdate = true
                }
                
                guard isUpdate else { return }

                if let index = self.worksIndex(for: cache.identifier) {
                    self.reloadIndex = index
                }
                RecordCacheTool.update(cache.identifier,
                                       videoTitle: cache.videoTitle,
                                       coverRatio: cache.coverRatio,
                                       coverTag: cache.coverTag,
                                       isEditedCover: cache.isEditedCover)
                WorksStore.shared.fetchWorks()
            } mainTask: {
                JPProgressHUD.dismiss()
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - 保存作品到相册
    func saveToAlbum(from works: Works) {
        let videoURL = URL(fileURLWithPath: works.recordCachePath)
        JPProgressHUD.show()
        Photo.shared.save(.video(videoURL)) { result in
            switch result {
            case .success:
                JPProgressHUD.showSuccess(withStatus: "保存成功", userInteractionEnabled: true)
            case .failure:
                JPProgressHUD.showSuccess(withStatus: "保存失败", userInteractionEnabled: true)
            }
        }
    }
    
    // MARK: - 删除作品
    func deleteWorks(_ works: Works) {
        let cache = works.cache
        Asyncs.async {
            self.deleteIndex = self.worksIndex(for: cache.identifier)
            RecordCacheTool.delete(cache)
            WorksStore.shared.fetchWorks()
        }
    }
}

// MARK: - Test
private extension ViewController {
    func testMontageVideos() {
        ImagePicker.openAlbumForVideoURL { result in
            switch result {
            case let .success(url):
                JPProgressHUD.show()
                VideoTool.mergeVideos([
                    URL(fileURLWithPath: Bundle.main.path(forResource: "babygirl", ofType: "mp4")!),
                    URL(fileURLWithPath: Bundle.main.path(forResource: "ali", ofType: "mp4")!),
                    url,
                ], videoSize: UIConfig.videoSize, contentMode: .scaleAspectFit, maxDuration: nil) { mergedFilePath in
                    Asyncs.async {
                        let videoSize = File.manager.fileSize(mergedFilePath)
                        let sizeStr = File.fileSizeString(videoSize)
                        let asset = AVURLAsset(url: URL(fileURLWithPath: mergedFilePath))
                        if let videoTrack = asset.tracks(withMediaType: .video).first {
                            JPrint("videoTrack.nominalFrameRate", videoTrack.nominalFrameRate)
                            JPrint("videoTrack.estimatedDataRate", videoTrack.estimatedDataRate)
                            JPrint("videoTrack.naturalSize", videoTrack.naturalSize)
                            JPrint("videoFileSize", sizeStr)
                            JPrint("=================")
                        }
                    } mainTask: {
                        JPProgressHUD.dismiss()
                        let playerVC = AVPlayerViewController()
                        playerVC.player = AVPlayer(url: URL(fileURLWithPath: mergedFilePath))
                        self.present(playerVC, animated: true) { [weak playerVC] in playerVC?.player?.play() }
                    }
                } faild: { kError in
                    JPProgressHUD.showError(withStatus: (kError as? NSError)?.localizedDescription ?? "合成失败", userInteractionEnabled: true)
                }
            case let .failure(error):
                guard !error.isUserCancel else { return }
                JPProgressHUD.showError(withStatus: "视频获取失败", userInteractionEnabled: true)
            }
        }
    }
}
