//
//  UploadFileViewController.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 7/5/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Cocoa
import RevKit

protocol UploadFileViewControllerDelegate : AnyObject {
    func uploadCompletedSuccessfully(file: URL, location: String)
}

class UploadFileViewController : NSViewController {
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var statsLabel: NSTextField!
    
    weak var delegate: UploadFileViewControllerDelegate?
    
    private var client: RevClient!
    private var progress: Progress?
    private var progressObservation: NSKeyValueObservation?
    private var uploadTask: URLSessionUploadTask?
    
    @objc dynamic var fileURL: URL! {
        didSet {
            if isViewLoaded {
                startUpload(with: fileURL)
            }
        }
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if fileURL != nil {
            startUpload(with: fileURL)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func cancelClicked(_ sender: Any) {
        uploadTask?.cancel()
        dismiss(self)
    }
    
    private func startUpload(with fileURL: URL) {
        guard let creds = RevCredentials.current else {
            fatalError("Should have credentials")
        }
        
        titleLabel.stringValue = "Uploading \(fileURL.lastPathComponent)..."
        progressIndicator.startAnimation(self)
        client = RevClient(credentials: creds)
        let progress = Progress()
        progressObservation = progress.observe(\.fractionCompleted, changeHandler: { (p, change) in
            
            self.progressIndicator.doubleValue = p.fractionCompleted * 100
            let completedBytes = ByteCountFormatter.string(fromByteCount: p.completedUnitCount, countStyle: .file)
            let totalBytes = ByteCountFormatter.string(fromByteCount: p.totalUnitCount, countStyle: .file)
            
            if p.fractionCompleted == 1.0 {
                self.progressIndicator.isIndeterminate = true
            }
            
            self.statsLabel.stringValue = "\(completedBytes) out of \(totalBytes) uploaded."
        })
        uploadTask = client.uploadInput(file: fileURL, progress: progress) { result in
            switch result {
            case .success(let location):
                print("Location: \(location)")
                self.delegate?.uploadCompletedSuccessfully(file: fileURL, location: location)
                self.dismiss(self)
            case .failed(let error):
                self.presentError(error)
            }
        }
        self.progress = progress
    }
}
