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
    
    var contacts : [HLUser]!
    var chatController : LGChatController!
    var opponentUser: HLUser!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        contacts = []
        HLConnectionManager.sharedInstance.onHandshakeMessage   = self.onHandshakeMessage
        HLConnectionManager.sharedInstance.onAgreedMessage      = self.onAgreedMessage
        HLConnectionManager.sharedInstance.onReceivedMessage    = self.onReceivedMessage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Contact-Cell")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Contact-Cell") as UITableViewCell!
        cell.textLabel?.text  = self.contacts[indexPath.row].fullname
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.opponentUser = self.contacts[indexPath.row];
        self.chatController = LGChatController()
        chatController.opponentImage = UIImage(named: "opponent")
        chatController.title = "E2EE Chat"
        chatController.delegate = self
        self.navigationController?.pushViewController(chatController, animated: true)
    }
    
    func onHandshakeMessage(messagePackage: HLMessagePackage?) {
        if  let mpg = messagePackage {
            self.contacts.append(mpg.fromUser)
            self.tableView.reloadData()
        }
    }
    
    func onAgreedMessage(messagePackage: HLMessagePackage?) {
        if  let mpg = messagePackage {
            self.contacts.append(mpg.fromUser)
            self.tableView.reloadData()
        }
    }

    func onReceivedMessage(messagePackage: HLMessagePackage?) {
        if  let mpg = messagePackage {
            let incomingMessage = LGChatMessage(content: mpg.content, sentBy: .Opponent)
            self.chatController.appendMessage(incomingMessage)
        }
    }

    func shouldChatController(chatController: LGChatController, addMessage message: LGChatMessage) -> Bool {
        HLConnectionManager.sharedInstance.sendChatOnUserChannel(self.opponentUser, textMessage: message.content);
        chatController.appendMessage(message)
        return false
    }
    
    func chatController(chatController: LGChatController, didAddNewMessage message: LGChatMessage) {
    }
}