//
//  NewOrderViewController.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 5/18/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation
import Cocoa
import RevKit

class NewOrderViewController : NSViewController {
    @IBOutlet var addInputMenu: NSMenu!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet var removeItemButton: NSButton!
    
    @objc dynamic var selectionIndices: NSIndexSet? {
        didSet {
            removeItemButton.isEnabled = (selectionIndices?.count ?? 0) > 0
        }
    }
    
    private var inputItems: [OrderInputTableRow] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerForDraggedTypes([.fileURL])
    }
    
    // MARK: - Actions
    
    @IBAction func addInputClicked(_ sender: NSButton) {
        addInputMenu.popUp(positioning: nil, at: .zero, in: sender)
    }
    
    @IBAction func addInputFromFileClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Upload"
        openPanel.allowedFileTypes = [kUTTypeMovie] as [String]
        openPanel.runModal()
        
        if let selectedURL = openPanel.url {
            uploadFile(url: selectedURL)
        }
    }
    
    @IBAction func removeSelectedInput(_ sender: NSButton) {
        guard let selection = selectionIndices else { return }
        inputItems = inputItems.enumerated().filter { index, inputItem in
            return !selection.contains(index)
            }.map { $0.element }
    }
    
    @IBAction func urlClicked(_ sender: Any) {
        guard let storyboard = NSStoryboard.main else { return }
        let vc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "AddInputURLViewController")) as! AddInputURLViewController
        vc.delegate = self
        presentViewControllerAsSheet(vc)
    }
}

extension NewOrderViewController : NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return inputItems.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row >= 0 && row < inputItems.count else { return nil }
        return inputItems[row]
    }
}

extension NewOrderViewController {
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        print("Validate drop?")
        if movieURLs(in: info.draggingPasteboard()).isEmpty {
            return []
        } else {
            return NSDragOperation.copy
        }
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        let urls = movieURLs(in: info.draggingPasteboard())
        print("Accept drop: \(urls)")
        if let first = urls.first {
            uploadFile(url: first)
            NSApp.activate(ignoringOtherApps: false)
            return true
        }
        
        return false
    }
    
    private func uploadFile(url: URL) {
        guard let uploadVC = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("UploadFileViewController")) as? UploadFileViewController else { return }
            
        uploadVC.fileURL = url
        uploadVC.delegate = self
        presentViewControllerAsSheet(uploadVC)
    }
    
    private func movieURLs(in pasteboard: NSPasteboard) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey:Any] = [
            .urlReadingContentsConformToTypes: [kUTTypeMovie],
            .urlReadingFileURLsOnly: true
        ]
        let matchingObjects = pasteboard.readObjects(forClasses: [NSURL.self], options: options)
        return matchingObjects as? [URL] ?? []
    }
}

extension NewOrderViewController : AddInputURLViewControllerDelegate {
    func didSelect(url: URL, controller: AddInputURLViewController) {
        controller.disableForm()
        // do the API call
        progressIndicator.startAnimation(self)
        submitURLInput(url: url) { [unowned self] success in
            self.progressIndicator.stopAnimation(self)
            if success {
                self.dismissViewController(controller)
            } else {
                controller.enableForm()
            }
        }
    }
    
    private func submitURLInput(url: URL, completion: @escaping (Bool) -> Void) {
        guard let creds = RevCredentials.current else { return }
        let client = RevClient(credentials: creds)
        client.uploadInput(from: url) { [unowned self] result in
            switch result {
            case .success(let location):
                completion(true)
                let filename = url.lastPathComponent
                let inputItem = OrderInputTableRow(urn: location, filename: filename)
                self.inputItems.append(inputItem)
                
            case .failed(let error):
                self.presentError(error)
                completion(false)
            }
        }
    }
}

extension NewOrderViewController : UploadFileViewControllerDelegate {
    func uploadCompletedSuccessfully(file: URL, location: String) {
        let row = OrderInputTableRow(urn: location, filename: file.lastPathComponent)
        inputItems.append(row)
    }
}
