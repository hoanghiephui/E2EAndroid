//
//  ViewController.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/11/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import UIKit
import AWSCore
import AWSLambda
import AWSCognito
import AWSIoT
import Heimdall

let kIoTTopic = "Heilamb"
let kProtocolMessage = "message:"
let kProtocolHandshake = "handshake:"
let kPrefixTag = "com.sinbadflyce.aws.e2ecc"


class ViewController: UIViewController, LGChatControllerDelegate {
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var connectButton: UIButton!
    
    let credentialProvider : AWSCognitoCredentialsProvider
    
    var connected = false
    var iotDataManager: AWSIoTDataManager!
    var iotData: AWSIoTData!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    var stringResult : String!
    var chatController : LGChatController!
    var userId : String!
    var receivers : NSMutableDictionary!
    
    // E2EE
    var heimdall : Heimdall!
    
    required init(coder aDecoder: NSCoder) {
        credentialProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: CognitoIdentityPoolId)
        let configuration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: credentialProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        iotManager = AWSIoTManager.defaultIoTManager()
        iot = AWSIoT.defaultIoT()
        
        iotDataManager = AWSIoTDataManager.defaultIoTDataManager()
        iotData = AWSIoTData.defaultIoTData()
        userId = NSUUID().UUIDString
        self.heimdall = Heimdall(tagPrefix: kPrefixTag, keySize: 1024)
        receivers = NSMutableDictionary()

        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func send(sender: AnyObject?) {
        self.connectButton.enabled = false
        self.validateCertAndConnectToIoT();
    }
    
    
    func mqttEventCallback( status: AWSIoTMQTTStatus ) {
        dispatch_async( dispatch_get_main_queue()) {
            print("connection status = \(status.rawValue)")
            switch(status)
            {
            case .Connecting:
                self.connectButton.enabled = false
                break
                
            case .Connected:
                self.connected = true
                self.suceededToConnectIoT();
                self.activityIndicatorView.stopAnimating()
                self.connectButton.enabled = true
                
            case .Disconnected:
                self.activityIndicatorView.stopAnimating()
                self.connectButton.enabled = true
                break
                
            case .ConnectionRefused:
                self.activityIndicatorView.stopAnimating()
                self.connectButton.enabled = true
                break
                
            case .ConnectionError:
                self.activityIndicatorView.stopAnimating()
                self.connectButton.enabled = true
                break
                
            case .ProtocolError:
                self.activityIndicatorView.stopAnimating()
                self.connectButton.enabled = true
                break
                
            default:
                self.activityIndicatorView.stopAnimating()
                self.connectButton.enabled = true
                break
                
            }
        }
    }
    
    func validateCertAndConnectToIoT() {
        
        if (connected == false)
        {
            activityIndicatorView.startAnimating()
            
            let defaults = NSUserDefaults.standardUserDefaults()
            var certificateId = defaults.stringForKey( "certificateId")
            
            if (certificateId == nil)
            {
                dispatch_async( dispatch_get_main_queue()) {
                    self.stringResult = "No identity available, searching bundle..."
                }
                
                // No certificate ID has been stored in the user defaults; check to see if any .p12 files
                // exist in the bundle.
                let myBundle = NSBundle.mainBundle()
                let myImages = myBundle.pathsForResourcesOfType("p12" as String, inDirectory:nil)
                let uuid = NSUUID().UUIDString;
                
                if (myImages.count > 0) {
                    
                    // At least one PKCS12 file exists in the bundle.  Attempt to load the first one
                    // into the keychain (the others are ignored), and set the certificate ID in the
                    // user defaults as the filename.  If the PKCS12 file requires a passphrase,
                    // you'll need to provide that here; this code is written to expect that the
                    // PKCS12 file will not have a passphrase.
                    if let data = NSData(contentsOfFile:myImages[0]) {
                        dispatch_async( dispatch_get_main_queue()) {
                            self.stringResult = "found identity \(myImages[0]), importing..."
                        }
                        if AWSIoTManager.importIdentityFromPKCS12Data( data, passPhrase:"", certificateId:myImages[0]) {
                            
                            // Set the certificate ID and ARN values to indicate that we have imported
                            // our identity from the PKCS12 file in the bundle.
                            defaults.setObject(myImages[0], forKey:"certificateId")
                            defaults.setObject("from-bundle", forKey:"certificateArn")
                            dispatch_async( dispatch_get_main_queue()) {
                                self.stringResult = "Using certificate: \(myImages[0]))"
                                self.iotDataManager.connectWithClientId( uuid, cleanSession:true, certificateId:myImages[0], statusCallback: self.mqttEventCallback)
                            }
                        }
                    }
                }
                certificateId = defaults.stringForKey( "certificateId")
                if (certificateId == nil) {
                    dispatch_async( dispatch_get_main_queue()) {
                        self.stringResult = "No identity found in bundle, creating one..."
                    }

                    // Now create and store the certificate ID in NSUserDefaults
                    let csrDictionary = [ "commonName":CertificateSigningRequestCommonName, "countryName":CertificateSigningRequestCountryName, "organizationName":CertificateSigningRequestOrganizationName, "organizationalUnitName":CertificateSigningRequestOrganizationalUnitName ]
                    
                    self.iotManager.createKeysAndCertificateFromCsr(csrDictionary, callback: {  (response ) -> Void in
                        if (response != nil)
                        {
                            defaults.setObject(response.certificateId, forKey:"certificateId")
                            defaults.setObject(response.certificateArn, forKey:"certificateArn")
                            certificateId = response.certificateId
                            print("response: [\(response)]")
                            
                            let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
                            attachPrincipalPolicyRequest.policyName = PolicyName
                            attachPrincipalPolicyRequest.principal = response.certificateArn
                            
                            // Attach the policy to the certificate
                            self.iot.attachPrincipalPolicy(attachPrincipalPolicyRequest).continueWithBlock { (task) -> AnyObject? in
                                if let error = task.error {
                                    print("failed: [\(error)]")
                                }
                                if let exception = task.exception {
                                    print("failed: [\(exception)]")
                                }
                                print("result: [\(task.result)]")
                                
                                // Connect to the AWS IoT platform
                                if (task.exception == nil && task.error == nil)
                                {
                                    let delayTime = dispatch_time( DISPATCH_TIME_NOW, Int64(2*Double(NSEC_PER_SEC)))
                                    dispatch_after( delayTime, dispatch_get_main_queue()) {
                                        self.stringResult = "Using certificate: \(certificateId!)"
                                        self.iotDataManager.connectWithClientId( uuid, cleanSession:true, certificateId:certificateId, statusCallback: self.mqttEventCallback)
                                    }
                                }
                                return nil
                            }
                        }
                        else
                        {
                            dispatch_async( dispatch_get_main_queue()) {
                                self.connectButton.enabled = true
                                self.activityIndicatorView.stopAnimating()
                                self.stringResult = "Unable to create keys and/or certificate, check values in Constants.swift"
                            }
                        }
                    } )
                }
            }
            else
            {
                let uuid = NSUUID().UUIDString;
                
                // Connect to the AWS IoT service
                iotDataManager.connectWithClientId( uuid, cleanSession:true, certificateId:certificateId, statusCallback: mqttEventCallback)
            }
        }
        else
        {
            self.stringResult = "Disconnecting..."
            
            dispatch_async( dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0) ){
                self.iotDataManager.disconnect();
                dispatch_async( dispatch_get_main_queue() ) {
                    self.connected = false
                    self.connectButton.enabled = true
                    self.activityIndicatorView.stopAnimating()
                }
            }
        }
    }
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }
    
    func suceededToConnectIoT() {
        
        self.chatController = LGChatController()
        chatController.opponentImage = UIImage(named: "opponent")
        chatController.title = "E2EE Chat"
        chatController.delegate = self
        self.subcribeIoT();
        dispatch_async(dispatch_get_main_queue()) {
            self.broadcastHandshake()
        }
        self.navigationController?.pushViewController(chatController, animated: true)
    }
    
    func broadcastHandshake() {
        if let publicKeyData = self.heimdall.publicKeyDataX509() {
            let publicKeyString = publicKeyData.base64EncodedStringWithOptions([])
            let jsonObject: [String: AnyObject] = [
                "action": kProtocolHandshake,
                "user_id": userId,
                "public_key":publicKeyString
            ]
            let jsonString = JSON(jsonObject).toString()
            iotDataManager.publishString(jsonString, onTopic:kIoTTopic, qoS:.MessageDeliveryAttemptedAtMostOnce)
        }
    }
    
    func parseIncomingMessage(dataString: String!) {
        if let dict = self.convertStringToDictionary(dataString) {
            if let action = dict["action"] where action as! String == kProtocolHandshake {
                 self.handleHandshakeMessage(dataString)
            }
            else if let action = dict["action"] where action as! String == kProtocolMessage {
                self.handleContentMessage(dataString);
            }
        }
    }
    
    func handleContentMessage(dataString: String!) {
        if let dict = self.convertStringToDictionary(dataString) {
            if let user_id = dict["user_id"] as? String, let encrypedMessage = dict["content"] as? String {
                if let receiver = self.receivers.objectForKey(user_id) as? Heimdall {
                    let dencrypedString = receiver.decrypt(encrypedMessage, urlEncoded: false)
                    var sentBy  = LGChatMessage.SentBy.Opponent
                    if (user_id == self.userId) {
                        sentBy = LGChatMessage.SentBy.User;
                    }
                    let incomingMessage = LGChatMessage(content: dencrypedString! as String, sentBy: sentBy)
                    self.chatController.appendMessage(incomingMessage)
                }
            }
        }
    }
    
    func handleHandshakeMessage(dataString: String!) {
        if let dict = self.convertStringToDictionary(dataString) {
            if let user_id = dict["user_id"] as? String, let publicKey = dict["public_key"] as? String {
                let heimadallS = Heimdall(publicTag: kPrefixTag, publicKeyData: publicKey.dataUsingEncoding(NSUTF8StringEncoding))
                receivers.setValue(heimadallS, forKey: user_id)
            }
        }
    }
    
    func subcribeIoT() {
        iotDataManager.subscribeToTopic(kIoTTopic, qoS: .MessageDeliveryAttemptedAtMostOnce, messageCallback: {
            (payload) ->Void in
            
            dispatch_async(dispatch_get_main_queue()) {
                let stringValue = NSString(data: payload, encoding: NSUTF8StringEncoding)! as String
                self.parseIncomingMessage(stringValue)
            }
        } )
    }
    
    func publishIoT(message:LGChatMessage) {
        let partner = self.receivers.objectForKey(self.userId) as! Heimdall
        let encryptedContent = partner.encrypt(message.content)!
        let jsonObject: [String: AnyObject] = [
            "action": kProtocolMessage,
            "user_id": userId,
            "content": encryptedContent
        ]
        
        let jsonString = JSON(jsonObject).toString()
        iotDataManager.publishString(jsonString, onTopic:kIoTTopic, qoS:.MessageDeliveryAttemptedAtMostOnce)
    }
    
    func shouldChatController(chatController: LGChatController, addMessage message: LGChatMessage) -> Bool {
        self.publishIoT(message);
        return false
    }
    
    func chatController(chatController: LGChatController, didAddNewMessage message: LGChatMessage) {
    }
}

