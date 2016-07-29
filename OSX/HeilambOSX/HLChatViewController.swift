//
//  HLChatViewController.swift
//  HeilambOSX
//
//  Created by Sinbad Flyce on 7/25/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import Cocoa

class HLChatViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var txtChatField: NSTextField!
    @IBOutlet weak var btnSend : NSButton!;
    
    var opponentUser : HLUser!
    var messages : [DyMessage]?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HLChatViewController.selectedContact(notification:)), name: "CONTACT_SELECTED_USER", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HLChatViewController.cameMessageContact(notification:)), name: "CONTACT_INCOMING_DYMESSAGE", object: nil)
        self.btnSend.enabled = false
        self.txtChatField.delegate = self
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Chatting
    
    func cameMessageContact(notification notif: NSNotification) -> Void {
        if let dyMessage = notif.object as? DyMessage {
            if  dyMessage.fromUserId == opponentUser.id || dyMessage.fromUserId == DyUser.currentUser?.userId {
                self.messages?.append(dyMessage)
                self.tableView.reloadData()
            }
        }
    }
    
    func selectedContact(notification notif: NSNotification) -> Void {
        if let changedUser = notif.object as? HLUser {
            if opponentUser == nil ||  opponentUser != changedUser {
                self.opponentUser = changedUser
                self.reloadChatUserMessage()
            }
        }
        self.btnSend.enabled = true
    }
    
    func reloadChatUserMessage() -> Void {
        HLDynamoDBManager.shared.fetchHistoryMessages(self.opponentUser.id) { (models) in
            
            if models != nil {
                let sortedMessages = models!.sort({
                    if let m0 = $0 as? DyMessage, let m1 = $1 as? DyMessage {
                        return m0.createdAtDate!.compare(m1.createdAtDate!) == NSComparisonResult.OrderedAscending
                    }
                    return false
                })
                self.messages = sortedMessages as? [DyMessage]
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - TableView
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return messages?.count ?? 0
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIdentifier: String = "MessageCell"
        let message = self.messages![row]
        var plainText = ""
        
        if (message.fromUserId != DyUser.currentUser?.userId) {
            plainText = "(\(self.opponentUser.fullname))" + ": \(message.content!)"
        } else {
            plainText = "(Me): \(message.content!)"
        }

        if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = plainText
            return cell
        }
        return nil
    }
    
    // MARK: - UI Control
    @IBAction func send(sender: AnyObject?) {
        if self.txtChatField.stringValue.characters.count > 0 && self.opponentUser != nil {
            HLConnectionManager.shared.sendChatOnUserChannel(self.opponentUser, textMessage: self.txtChatField.stringValue)
            let dyMessage = DyMessage()
            dyMessage.fromUserId = DyUser.currentUser?.userId
            dyMessage.toUserId = self.opponentUser.id
            dyMessage.content = self.txtChatField.stringValue
            dyMessage.status = DyMessageStatus.Sent
            self.messages?.append(dyMessage)
            self.txtChatField.stringValue = ""
            self.tableView.reloadData()
        }
    }
    
    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSControl.insertNewline) {
            self.send(nil)
            return true
        }
        return false
    }
}