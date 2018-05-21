//
//  ViewController.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 5/4/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Cocoa
import RevKit

class OrderListViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var ordersArrayController: NSArrayController!
    
    var hasCheckedPreferences = false
    var orders: [Order]?
    
    private lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(doubleClickRow(_:))
    }
    
    @objc
    private func doubleClickRow(_ sender: NSTableView) {
        let row = tableView.clickedRow
        guard row >= 0 else { return }

        let identifier = NSStoryboardSegue.Identifier("showOrderSegue")
        performSegue(withIdentifier: identifier, sender: self)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard !hasCheckedPreferences else { return }
        hasCheckedPreferences = true
        if hasCredentials() {
            loadOrders(self)
        } else {
            performSegue(withIdentifier: NSStoryboardSegue.Identifier("preferencesSegue"), sender: self)
        }
    }

    var windowController: OrderListWindowController! {
        return view.window?.windowController as? OrderListWindowController
    }
    
    @IBAction func loadOrders(_ sender: Any) {
        guard let credentials = RevCredentials.current else { fatalError() }
        let client = RevClient(clientKey: credentials.clientKey,
                               userKey: credentials.userKey,
                               environment: .sandbox)

        windowController.isLoading = true
        client.getAllOrders { (result) in
            self.windowController.isLoading = false
            switch result {
            case .success(let pagedOrders):
                print("Loaded \(pagedOrders.totalCount) orders")
                
                self.orders = pagedOrders.orders
                self.tableView.reloadData()
                
                break
            case .failed(let error):
                NSApp.presentError(error)
            }
        }
    }

    private func hasCredentials() -> Bool {
        return RevCredentials.current != nil
    }
}

extension OrderListViewController : NSTableViewDelegate {
    
}

extension OrderListViewController : NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return orders?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let orders = orders else { return nil }
        guard row >= 0 && row < orders.count else { return nil }
        let order = orders[row]
        let rowModel = OrderTableRow(order: order)
        return rowModel
    }
}

















