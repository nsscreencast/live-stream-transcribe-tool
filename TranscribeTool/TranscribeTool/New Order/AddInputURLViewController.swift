//
//  AddInputURLViewController.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 5/18/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation
import Cocoa

protocol AddInputURLViewControllerDelegate : AnyObject {
    func didSelect(url: URL, controller: AddInputURLViewController)
}

class AddInputURLViewController : NSViewController {
 
    weak var delegate: AddInputURLViewControllerDelegate?
    
    @objc dynamic var urlValue = "" {
        didSet {
            isURLValid = URL(string: urlValue) != nil
        }
    }
    @objc dynamic var isURLValid = false
    
    @objc dynamic var isFormEnabled = true
    
    func enableForm() {
        isFormEnabled = true
    }
    
    func disableForm() {
        isFormEnabled = false
    }
    
    @IBAction func addButtonClicked(_ sender: NSButton) {
        guard let url = URL(string: urlValue) else { return }
        delegate?.didSelect(url: url, controller: self)
    }
}
