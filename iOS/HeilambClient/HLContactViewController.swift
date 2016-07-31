//
//  HLContactViewController.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/18/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import UIKit

class HLContactViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, LGChatControllerDelegate {
    @IBOutlet weak var tableView : UITableView!
    
    var contacts : [String : HLUser]!
    var chatController : LGChatController!
    var opponentUser: HLUser!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        contacts = [String : HLUser]()
        HLConnectionManager.shared.onHandshakeMessage   = self.onHandshakeMessage
        HLConnectionManager.shared.onAgreedMessage      = self.onAgreedMessage
        HLConnectionManager.shared.onReceivedMessage    = self.onReceivedMessage
        HLConnectionManager.shared.onDeliveriedMessage  = self.OnDeliveriedMessage
    }
    
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
    
    func loadMessagesHistory() {
        HLDynamoDBManager.shared.fetchHistoryMessages(self.opponentUser.id) { (models) in
            
            if models != nil {
                let sortedMessages = models!.sort({
                    if let m0 = $0 as? DyMessage, let m1 = $1 as? DyMessage {
                        return m0.createdAtDate!.compare(m1.createdAtDate!) == NSComparisonResult.OrderedAscending
                    }
                    return false
                })
                
                for m in sortedMessages {
                    let dyMsg = m as! DyMessage
                    if (dyMsg.fromUserId == self.opponentUser.id ||
                        dyMsg.toUserId == self.opponentUser.id) {
                        var sentBy = LGChatMessage.SentBy.User
                        if (dyMsg.fromUserId != DyUser.currentUser?.userId) {
                            sentBy = LGChatMessage.SentBy.Opponent
                        }

                        let lgm = LGChatMessage(content: dyMsg.content!, sentBy: sentBy)
                        self.chatController.appendMessage(lgm)
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Contact-Cell")
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.connectAWSIot()
    }
    
    @IBAction func signOut(sender: AnyObject!) {
        HLConnectionManager.shared.disconnect()
        HLBleShareKey.shared.stop()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.keys.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Contact-Cell") as UITableViewCell!
        let keys = Array(self.contacts.keys)
        let key = keys[indexPath.row] as String
        let chatUser = self.contacts[key]
        cell.textLabel?.text  = chatUser?.fullname
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let keys = Array(self.contacts.keys)
        let key = keys[indexPath.row] as String
        let chatUser = self.contacts[key]
        self.opponentUser = chatUser
        self.chatController = LGChatController()
        chatController.opponentImage = UIImage(named: "opponent")
        chatController.title = "E2EE Chat"
        chatController.delegate = self
        self.loadMessagesHistory()
        self.navigationController?.pushViewController(chatController, animated: true)
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
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
        if  let mpg = messagePackage, let controller = self.chatController {
            let incomingMessage = LGChatMessage(content: mpg.content, sentBy: .Opponent)
            controller.appendMessage(incomingMessage)
        }
    }

    func OnDeliveriedMessage(messagePackage: HLMessagePackage?) {
    }
    
    func shouldChatController(chatController: LGChatController, addMessage message: LGChatMessage) -> Bool {
        HLConnectionManager.shared.sendChatOnUserChannel(self.opponentUser, textMessage: message.content);
        chatController.appendMessage(message)
        return false
    }
    
    func chatController(chatController: LGChatController, didAddNewMessage message: LGChatMessage) {
    }
}