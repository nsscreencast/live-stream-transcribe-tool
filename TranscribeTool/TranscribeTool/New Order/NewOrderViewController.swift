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
    
    @IBAction func addInputClicked(_ sender: NSButton) {
        addInputMenu.popUp(positioning: nil, at: .zero, in: sender)
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
