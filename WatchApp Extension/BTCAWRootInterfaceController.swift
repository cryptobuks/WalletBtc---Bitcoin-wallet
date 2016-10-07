//
//  Created by Admin on 9/8/16.
//

import WatchKit

class BTCAWRootInterfaceController: WKInterfaceController {
    @IBOutlet var setupWalletMessageLabel: WKInterfaceLabel! {
        didSet{
            setupWalletMessageLabel.setHidden(true)
        }
    }
    @IBOutlet var loadingIndicator: WKInterfaceGroup!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        updateUI()
        NotificationCenter.default.addObserver(
            self, selector: #selector(BTCAWRootInterfaceController.updateUI), name: NSNotification.Name(rawValue: BTCAWWatchDataManager.WalletStatusDidChangeNotification), object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(BTCAWRootInterfaceController.txReceive(_:)), name: NSNotification.Name(rawValue: BTCAWWatchDataManager.WalletTxReceiveNotification), object: nil)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateUI() {
        switch BTCAWWatchDataManager.sharedInstance.walletStatus {
        case .unknown:
            loadingIndicator.setHidden(false)
            setupWalletMessageLabel.setHidden(true)
        case .notSetup:
            loadingIndicator.setHidden(true)
            setupWalletMessageLabel.setHidden(false)
        case .hasSetup:
            WKInterfaceController.reloadRootControllers(
                withNames: ["BTCAWBalanceInterfaceController","BTCAWReceiveMoneyInterfaceController"], contexts: [])
        }
    }
    
    @objc func txReceive(_ notification: Notification?) {
        print("root view controller received notification: \(notification)")
        if let userData = (notification as NSNotification?)?.userInfo,
            let noteString = userData[NSLocalizedDescriptionKey] as? String {
                self.presentAlert(
                    withTitle: noteString, message: nil, preferredStyle: .alert, actions: [
                        WKAlertAction(title: NSLocalizedString("OK", comment: ""),
                            style: .cancel, handler: { self.dismiss() })])
        }
    }
}
