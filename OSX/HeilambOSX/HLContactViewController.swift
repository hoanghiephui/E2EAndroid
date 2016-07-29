//
//  HLContactViewController.swift
//  HeilambOSX
//
//  Created by Sinbad Flyce on 7/25/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import Cocoa

class HLContactViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var tableView: NSTableView!
    
    var contacts : [String : HLUser]!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        contacts = [String : HLUser]()
        HLConnectionManager.shared.onHandshakeMessage   = self.onHandshakeMessage
        HLConnectionManager.shared.onAgreedMessage      = self.onAgreedMessage
        HLConnectionManager.shared.onReceivedMessage    = self.onReceivedMessage
        HLConnectionManager.shared.onDeliveriedMessage  = self.OnDeliveriedMessage
        HLConnectionManager.shared.onReceivedDyMessage  = self.onReceivedDyMessage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.connectAWSIot()
    }
    
    @IBAction func logout(sender: AnyObject?) {
        HLConnectionManager.shared.disconnect()
        HLBleShareKey.shared.stop()
        self.parentViewController?.dismissController(self)
    }

    // MARK: - Connection
    
    func connectAWSIot() {
        self.title = "Connecting..."
        let chatUser = HLUser()
        chatUser.id = DyUser.currentUser?.userId
        chatUser.username =  DyUser.currentUser?.username
        chatUser.fullname =  DyUser.currentUser?.fullname
        
        HLConnectionManager.shared.connectWithUser(chatUser) { (success) in
            if (success) {
                self.title = "Ready"
                DyContact.fetchAll({ (items) in
                    if let arrayContact = items {
                        for ct in arrayContact {
                            let sct = ct as! DyContact
                            let chatUser = HLUser()
                            chatUser.id = sct.id
                            chatUser.username = sct.username
                            chatUser.fullname = sct.fullname
                            self.contacts[chatUser.id] = chatUser
                        }
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }
    
    func onHandshakeMessage(messagePackage: HLMessagePackage?) {
        if  let mpg = messagePackage {
            self.contacts[mpg.fromUser.id] = mpg.fromUser
            self.tableView.reloadData()
        }
    }
    
    func onAgreedMessage(messagePackage: HLMessagePackage?) {
        if  let mpg = messagePackage {
            self.contacts[mpg.fromUser.id] = mpg.fromUser
            self.tableView.reloadData()
        }
    }
    
    func onReceivedMessage(messagePackage: HLMessagePackage?) {
        NSNotificationCenter.defaultCenter().postNotificationName("CONTACT_INCOMING_MESSAGE", object: messagePackage)
    }
    
    func onReceivedDyMessage(dyMessage: DyMessage?)  {
        NSNotificationCenter.defaultCenter().postNotificationName("CONTACT_INCOMING_DYMESSAGE", object: dyMessage)
    }
    
    func OnDeliveriedMessage(messagePackage: HLMessagePackage?) {
    }
    
    // MARK: - TableView
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return contacts?.count ?? 0
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIdentifier: String = "ContactCell"
        let keys = Array(self.contacts.keys)
        let key = keys[row] as String
        let chatUser = self.contacts[key]
        if tableColumn == tableView.tableColumns[0] {
        }
        
        if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = (chatUser?.fullname)!
            return cell
        }
        return nil
    }
    
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let keys = Array(self.contacts.keys)
        let key = keys[row] as String
        let chatUser = self.contacts[key]
        NSNotificationCenter.defaultCenter().postNotificationName("CONTACT_SELECTED_USER", object: chatUser)
        return true
    }
}