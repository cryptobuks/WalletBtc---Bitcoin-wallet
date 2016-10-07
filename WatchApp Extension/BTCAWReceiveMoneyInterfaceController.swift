//
//  Created by Admin on 9/8/16.
//

import WatchKit
import WatchConnectivity

class BTCAWReceiveMoneyInterfaceController: WKInterfaceController, WCSessionDelegate, BTCAWKeypadDelegate {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //None
    }


    @IBOutlet var loadingIndicator: WKInterfaceGroup!
    @IBOutlet var imageContainer: WKInterfaceGroup!
    @IBOutlet var qrCodeImage: WKInterfaceImage!
    @IBOutlet var qrCodeButton: WKInterfaceButton!
    var customQR: UIImage?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        super.willActivate()
        customQR = nil
        updateReceiveUI()
        NotificationCenter.default.addObserver(
            self, selector: #selector(BTCAWReceiveMoneyInterfaceController.updateReceiveUI),
            name: NSNotification.Name(rawValue: BTCAWWatchDataManager.ApplicationDataDidUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(BTCAWReceiveMoneyInterfaceController.txReceive(_:)), name: NSNotification.Name(rawValue: BTCAWWatchDataManager.WalletTxReceiveNotification), object: nil)
    }

    override func didDeactivate() {
        super.didDeactivate()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func txReceive(_ notification: Notification?) {
        print("receive view controller received notification: \(notification)")
        if let userData = (notification as NSNotification?)?.userInfo,
            let noteString = userData[NSLocalizedDescriptionKey] as? String {
                self.presentAlert(
                    withTitle: noteString, message: nil, preferredStyle: .alert, actions: [
                        WKAlertAction(title: NSLocalizedString("OK", comment: ""),
                            style: .cancel, handler: { self.dismiss() })])
        }
    }
    
    func updateReceiveUI() {
        if BTCAWWatchDataManager.sharedInstance.receiveMoneyQRCodeImage == nil {
            loadingIndicator.setHidden(false)
            qrCodeButton.setHidden(true)
        } else {
            loadingIndicator.setHidden(true)
            qrCodeButton.setHidden(false)
            var qrImg = BTCAWWatchDataManager.sharedInstance.receiveMoneyQRCodeImage
            if customQR != nil {
                print("Using custom qr image")
                qrImg = customQR
            }
            qrCodeButton.setBackgroundImage(qrImg)
        }
    }
    
    @IBAction func qrCodeTap(_ sender: AnyObject?) {
        let ctx = BTCAWKeypadModel(delegate: self)
        self.presentController(withName: "Keypad", context: ctx)
    }
    
    // - MARK: Keypad delegate
    
    func keypadDidFinish(_ stringValueBits: String) {
        qrCodeButton.setHidden(true)
        loadingIndicator.setHidden(false)
        BTCAWWatchDataManager.sharedInstance.requestQRCodeForBalance(stringValueBits) { (qrImage, error) -> Void in
            if let qrImage = qrImage {
                self.customQR = qrImage
            }
            self.updateReceiveUI()
            print("Got new qr image: \(qrImage) error: \(error)")
        }
        self.dismiss()
    }
    
    
}
