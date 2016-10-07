//
//  Created by Admin on 9/8/16.
//

import WatchKit
import WatchConnectivity

enum WalletStatus {
    case unknown
    case hasSetup
    case notSetup
}

class BTCAWWatchDataManager: NSObject, WCSessionDelegate {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //none
    }

    static let sharedInstance = BTCAWWatchDataManager()
    static let ApplicationDataDidUpdateNotification = "ApplicationDataDidUpdateNotification"
    static let WalletStatusDidChangeNotification = "WalletStatusDidChangeNotification"
    static let WalletTxReceiveNotification = "WalletTxReceiveNotification"
    static let applicationContextDataFileName = "applicationContextData.txt"
    
    let session : WCSession =  WCSession.default()
    let timerFireInterval : TimeInterval = 7; // have iphone app sync with peer every 7 seconds
    
    var timer : Timer?
    
    fileprivate var appleWatchData : BTCAppleWatchData?

    var balance : String? { return appleWatchData?.balance }
    var balanceInLocalCurrency : String? { return appleWatchData?.balanceInLocalCurrency }
    var receiveMoneyAddress : String? { return appleWatchData?.receiveMoneyAddress }
    var receiveMoneyQRCodeImage : UIImage? { return appleWatchData?.receiveMoneyQRCodeImage }
    var lastestTransction : String? { return appleWatchData?.lastestTransction }
    var transactionHistory : [BTCAppleWatchTransactionData] {
        if let unwrappedAppleWatchData: BTCAppleWatchData = appleWatchData,
            let transactions :[BTCAppleWatchTransactionData] = unwrappedAppleWatchData.transactions{
            return  transactions
        } else {
            return [BTCAppleWatchTransactionData]()
        }
    }
    var walletStatus : WalletStatus  {
        if appleWatchData == nil {
            return WalletStatus.unknown
        } else if appleWatchData!.hasWallet {
            return WalletStatus.hasSetup
        } else {
            return WalletStatus.notSetup
        }
    }
    
    lazy var dataFilePath: URL = {
            let filemgr = FileManager.default
            let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)
            let docsDir = dirPaths[0] as String
            return URL(fileURLWithPath: docsDir).appendingPathComponent(applicationContextDataFileName)
        }()
    
    override init() {
        super.init()
        if appleWatchData == nil {
            unarchiveData()
        }
        session.delegate = self
        session.activate()
    }
    
    func requestAllData() {
        if self.session.isReachable {
            // WKInterfaceDevice.currentDevice().playHaptic(WKHapticType.Click)
            let messageToSend = [
                AW_SESSION_REQUEST_TYPE: NSNumber(value: AWSessionRquestTypeFetchData.rawValue as UInt32),
                AW_SESSION_REQUEST_DATA_TYPE_KEY:
                        NSNumber(value: AWSessionRquestDataTypeApplicationContextData.rawValue as UInt32)
            ]
            session.sendMessage(messageToSend, replyHandler: { [unowned self] replyMessage in
                    if let data = replyMessage[AW_SESSION_RESPONSE_KEY] as? Data {
                        if let unwrappedAppleWatchData
                                = NSKeyedUnarchiver.unarchiveObject(with: data) as? BTCAppleWatchData {
                            let previousAppleWatchData = self.appleWatchData
                            let previousWalletStatus = self.walletStatus
                            self.appleWatchData = unwrappedAppleWatchData
                            if previousAppleWatchData != self.appleWatchData {
                                self.archiveData(unwrappedAppleWatchData)
//                                WKInterfaceDevice.currentDevice().playHaptic(WKHapticType.Click)
                                NotificationCenter.default.post(
                                    name: Notification.Name(rawValue: BTCAWWatchDataManager.ApplicationDataDidUpdateNotification), object: nil)
                            }
                            if self.walletStatus != previousWalletStatus {
                                NotificationCenter.default.post(
                                    name: Notification.Name(rawValue: BTCAWWatchDataManager.WalletStatusDidChangeNotification), object: nil)
                            }
                        }
                    }
                }, errorHandler: {error in
//                    WKInterfaceDevice.currentDevice().playHaptic(WKHapticType.Failure)
                    print(error)
            })
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let applicationContextData = applicationContext[AW_APPLICATION_CONTEXT_KEY] as? Data {
            if let transferedAppleWatchData
                    = NSKeyedUnarchiver.unarchiveObject(with: applicationContextData) as? BTCAppleWatchData {
                let previousWalletStatus = self.walletStatus
                appleWatchData = transferedAppleWatchData
                archiveData(transferedAppleWatchData)
                if self.walletStatus != previousWalletStatus {
                    NotificationCenter.default.post(
                        name: Notification.Name(rawValue: BTCAWWatchDataManager.WalletStatusDidChangeNotification), object: nil)
                }
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: BTCAWWatchDataManager.ApplicationDataDidUpdateNotification), object: nil)
                
            }
        }
    }
    
    func session(
        _ session: WCSession, didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void) {
            print("Handle message from phone \(message)")
            if let noteV = message[AW_PHONE_NOTIFICATION_KEY],
                let noteStr = noteV as? String,
                let noteTypeV = message[AW_PHONE_NOTIFICATION_TYPE_KEY],
                let noteTypeN = noteTypeV as? NSNumber
                , noteTypeN.uint32Value == AWPhoneNotificationTypeTxReceive.rawValue {
                    let note = Notification(
                        name: Notification.Name(rawValue: BTCAWWatchDataManager.WalletTxReceiveNotification), object: nil, userInfo: [
                            NSLocalizedDescriptionKey: noteStr]);
                    NotificationCenter.default.post(note)
            }
    }
    
    func requestQRCodeForBalance(_ bits: String, responseHandler: @escaping (_ qrImage: UIImage?, _ error: NSError?) -> Void) {
       // /*
        if self.session.isReachable {
            let msg = [
                AW_SESSION_REQUEST_TYPE: NSNumber(value: AWSessionRquestTypeFetchData.rawValue as UInt32),
                AW_SESSION_REQUEST_DATA_TYPE_KEY: NSNumber(value: AWSessionRquestDataTypeQRCodeBits.rawValue as UInt32),
                AW_SESSION_QR_CODE_BITS_KEY: bits
            ] as [String : Any]
            session.sendMessage(msg,
                replyHandler: { (ctx) -> Void in
                    if let dat = ctx[AW_QR_CODE_BITS_KEY],
                        let datDat = dat as? Data,
                        let img = UIImage(data: datDat) {
                            responseHandler(img, nil)
                            return
                    }
                    responseHandler(nil, NSError(domain: "", code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "Unable to get new qr code"]))
                }, errorHandler: nil)
        }
// */
    }
    
    func balanceAttributedString() -> NSAttributedString? {
       if let originalBalanceString = BTCAWWatchDataManager.sharedInstance.balance {
            var balanceString = originalBalanceString.replacingOccurrences(of: "ƀ", with: "")
            balanceString = balanceString.trimmingCharacters(in: CharacterSet.whitespaces)
            return attributedStringForBalance(balanceString)
        }
        return nil
    }
    
    fileprivate func attributedStringForBalance(_ balance: String?)-> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        attributedString.append(
            NSAttributedString(string: "ƀ", attributes: [NSForegroundColorAttributeName : UIColor.gray]))
        
        attributedString.append(
            NSAttributedString(string: balance ?? "0", attributes:
                [NSForegroundColorAttributeName : UIColor.white]))
        
        return attributedString
    }
    
    func archiveData(_ appleWatchData: BTCAppleWatchData){
        try? NSKeyedArchiver.archivedData(withRootObject: appleWatchData).write(to: dataFilePath, options: [.atomic])
    }
    
    func unarchiveData() {
        if let data = try? Data(contentsOf: dataFilePath) {
            appleWatchData = NSKeyedUnarchiver.unarchiveObject(with: data) as? BTCAppleWatchData
        }
    }
    
    func setupTimer() {
        destoryTimer()
        let weakTimerTarget = BTCAWWeakTimerTarget(initTarget: self,
                                                  initSelector: #selector(BTCAWWatchDataManager.requestAllData))
        timer = Timer.scheduledTimer(timeInterval: timerFireInterval, target: weakTimerTarget,
                                                       selector: #selector(BTCAWWeakTimerTarget.timerDidFire),
                                                       userInfo: nil, repeats: true)
    }
    
    func destoryTimer() {
        if let currentTimer : Timer = timer {
            currentTimer.invalidate();
            timer = nil
        }
    }
}
