//
//  HLContactViewController.swift
//  HeilambOSX
//
//  Created by Sinbad Flyce on 7/25/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import Cocoa

class HLContactViewController: NSViewController {
    var contacts : [String : HLUser]!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        contacts = [String : HLUser]()
        HLConnectionManager.shared.onHandshakeMessage   = self.onHandshakeMessage
        HLConnectionManager.shared.onAgreedMessage      = self.onAgreedMessage
        HLConnectionManager.shared.onReceivedMessage    = self.onReceivedMessage
        HLConnectionManager.shared.onDeliveriedMessage  = self.OnDeliveriedMessage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.connectAWSIot()
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
                    }
                })
            }
        }
    }
    
    func onHandshakeMessage(messagePackage: HLMessagePackage?) {
        if  let mpg = messagePackage {
            self.contacts[mpg.fromUser.id] = mpg.fromUser
        }
    }
    
    func onAgreedMessage(messagePackage: HLMessagePackage?) {
        if  let mpg = messagePackage {
            self.contacts[mpg.fromUser.id] = mpg.fromUser
        }
    }
    
    func onReceivedMessage(messagePackage: HLMessagePackage?) {
    }
    
    func OnDeliveriedMessage(messagePackage: HLMessagePackage?) {
    }
}