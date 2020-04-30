//
//  DownloadViewController.swift
//  EbookReader
//
//  Created by 黄文博 on 2020/4/9.
//  Copyright © 2020 CN. All rights reserved.
//

import UIKit
import AFNetworking
import FolioReaderKit
import RealmSwift

class DownloadViewController: UIViewController {
    fileprivate var bookImageView: UIImageView!
    fileprivate var titleLabel: UILabel!
    fileprivate var authorLabel: UILabel!
    fileprivate var publicationDateLabel: UILabel!
    fileprivate var publicationPressLabel: UILabel!
    fileprivate var isbnLabel: UILabel!
    fileprivate var introductionLabel: UILabel!
    fileprivate var downloadView: UIView!
    fileprivate var downloadImageView: UIImageView!
    fileprivate var downloadLabel: UILabel!

    fileprivate var book: Book!
    fileprivate var path: String!

    fileprivate var progressBar: UIProgressView!

    init(book: Book) {
        super.init(nibName: nil, bundle: nil)
        self.book = book
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white

        // Do any additional setup after loading the view.
        bookImageView = UIImageView()
        self.view.addSubview(bookImageView)
        bookImageView.snp.makeConstraints { (make) in
            make.top.equalTo(130)
            make.left.equalTo(44)
            make.width.equalTo(180)
            make.height.equalTo(240)
        }

        titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        self.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(125)
            make.left.equalTo(bookImageView.snp.right).offset(37)
            make.right.equalTo(-35)
        }

        isbnLabel = UILabel()
        self.view.addSubview(isbnLabel)
        isbnLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(bookImageView).offset(-5)
            make.left.equalTo(titleLabel)
        }

        publicationDateLabel = UILabel()
        self.view.addSubview(publicationDateLabel)
        publicationDateLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(isbnLabel.snp.top).offset(-10)
            make.left.equalTo(titleLabel)
        }

        publicationPressLabel = UILabel()
        self.view.addSubview(publicationPressLabel)
        publicationPressLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(publicationDateLabel)
            make.left.equalTo(publicationDateLabel.snp.right).offset(10)
        }

        authorLabel = UILabel()
        self.view.addSubview(authorLabel)
        authorLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(publicationDateLabel.snp.top).offset(-6)
            make.left.equalTo(titleLabel)
        }

        let introductionTitleLabel = UILabel()
        introductionTitleLabel.text = "Introduction"
        self.view.addSubview(introductionTitleLabel)
        introductionTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(bookImageView.snp.bottom).offset(50)
            make.left.equalTo(35)
        }

        introductionLabel = UILabel()
        introductionLabel.numberOfLines = 0
        self.view.addSubview(introductionLabel)
        introductionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(introductionTitleLabel.snp.bottom).offset(30)
            make.left.equalTo(introductionTitleLabel)
            make.right.equalTo(-35)
        }

        progressBar = UIProgressView()
        progressBar.isUserInteractionEnabled = true
        progressBar.layer.cornerRadius = 8
        progressBar.layer.masksToBounds = true
        progressBar.progressTintColor = UIColor(red: 0, green: 0.62, blue: 0.63, alpha: 1)
        self.view.addSubview(progressBar)
        progressBar.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(-50)
            make.width.equalTo(454)
            make.height.equalTo(66)
        }
        downloadView = UIView()
        progressBar.addSubview(downloadView)
        downloadView.snp.makeConstraints { (make) in
            make.top.bottom.centerX.equalTo(progressBar)
        }
        downloadImageView = UIImageView()
        downloadView.addSubview(downloadImageView)
        downloadImageView.snp.makeConstraints { (make) in
            make.left.centerY.equalTo(downloadView)
        }
        downloadLabel = UILabel()
        downloadLabel.textColor = UIColor.white
        downloadView.addSubview(downloadLabel)
        downloadLabel.snp.makeConstraints { (make) in
            make.right.centerY.equalTo(downloadView)
            make.left.equalTo(downloadImageView.snp.right).offset(20)
        }

        searchBook()
    }

    fileprivate func setObject() {
        bookImageView.kf.setImage(with: URL(string: book.thumbnail))
        titleLabel.text = book.title
        introductionLabel.text = book.abs
        if (book.authorsPrimary.count > 0) {
            var text = "Author: "
            for author in book.authorsPrimary {
                text = text + author + ", "
            }
            text = String(text.dropLast(2))
            authorLabel.text = text
        }
        if (book.isbns.count > 0) {
            var text = "ISBN: ["
            for isbn in book.isbns {
                text = text + isbn + ","
            }
            text = String(text.dropLast(1))
            text += "]"
            isbnLabel.text = text
        }
        if (book.publicationDates.count > 0) {
            publicationDateLabel.text = book.publicationDates[0]
        }
        if (book.publishers.count > 0) {
            publicationPressLabel.text = book.publishers[0]
        }

        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        path = paths[0] + "/" + book.id
        if (checkFileExisted(path)) {
            progressBar.progress = 100
            downloadLabel.text = "Start Reading"
            downloadImageView.image = UIImage(named: "icon-downloaded")
            progressBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOpenBookTapped)))
        } else {
            progressBar.progress = 0
            downloadLabel.text = "Download"
            downloadImageView.image = UIImage(named: "icon-download")
            progressBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onDownloadTapped)))
        }
    }

    fileprivate func searchBook() {
        PopupView.showLoading(true)
        NetworkManager.sharedInstance().GET(path: "record?id=" + book.id,
            parameters: nil,
            modelClass: Book.self,
            success: { (books) in
                if let books = books as? [Book] {
                    self.book = books[0]
                }

                self.setObject()
                PopupView.showLoading(false)
            }, failure:  { (error) in
                PopupView.showLoading(false)
            })
    }

    @objc func onOpenBookTapped() {
        if book.isPdf {
            let url = URL(fileURLWithPath: path)
            let pdfReaderViewController = PdfReaderViewController(url: url)
            self.present(pdfReaderViewController, animated: true, completion: nil)
        } else {
            let config = FolioReaderConfig()
            let folioReader = FolioReader()
            if keepScreenOnWhileReading {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            folioReader.presentReader(parentViewController: self, withEpubPath: path, unzipPath: nil, andConfig: config, shouldRemoveEpub: false, animated: true)
        }
    }
    
    @objc func onDownloadTapped(_ sender: Any) {
        if downloadWithWifiOnly && (AFNetworkReachabilityManager.shared().networkReachabilityStatus == .notReachable || AFNetworkReachabilityManager.shared().networkReachabilityStatus == .reachableViaWWAN) {
            PopupView.showWithContent("Download on Wifi Only")
            return
        }
        guard book.downloadUrl != "" else {
            PopupView.showWithContent("该书没有下载链接")
            return
        }
        var fileUrl = book.downloadUrl
        let manager = AFURLSessionManager(sessionConfiguration: .default)
        fileUrl = fileUrl.replacingOccurrences(of: " ", with: "%20")
        let url = URL(string: fileUrl)!
        let request = URLRequest(url: url)

        let downloadTask = manager.downloadTask(with: request, progress: { (progress) in
            DispatchQueue.main.async {
                self.progressBar.setProgress(Float(progress.completedUnitCount) / Float(progress.totalUnitCount), animated: true)
                self.downloadLabel.text = "Downloading"
            }
        }, destination: { (url, response) -> URL in
            return URL(fileURLWithPath: self.path)
        }, completionHandler: { (response, url, error) in
            if self.checkFileExisted(self.path) {
                self.setObject()
                self.saveBook()
            } else {
                PopupView.showWithContent("下载失败，请重试")
            }
        })
        downloadTask.resume()
    }

    fileprivate func saveBook() {
        let realm = try! Realm()

        let predicate = NSPredicate(format: "id == %@", book.id)
        if !realm.objects(Book.self).filter(predicate).isEmpty {
            PopupView.showWithContent("书已经存在")
            return
        }

        try! realm.write {
            realm.add(book)
        }
    }

    fileprivate func checkFileExisted(_ path: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path)
    }

}
