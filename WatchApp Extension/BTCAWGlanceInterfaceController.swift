//
//  Created by Admin on 9/8/16.
//

import WatchKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class BTCAWGlanceInterfaceController: WKInterfaceController {
    
    @IBOutlet var setupWalletContainer: WKInterfaceGroup!
    @IBOutlet var balanceAmountLabel: WKInterfaceLabel!
    @IBOutlet var balanceInLocalCurrencyLabel: WKInterfaceLabel!
    @IBOutlet var lastTransactionLabel: WKInterfaceLabel!
    @IBOutlet var balanceInfoContainer: WKInterfaceGroup!
    @IBOutlet var loadingIndicator: WKInterfaceGroup!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        updateUI()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        BTCAWWatchDataManager.sharedInstance.setupTimer()
        updateUI()
        NotificationCenter.default.addObserver(
            self, selector: #selector(BTCAWGlanceInterfaceController.updateUI), name: NSNotification.Name(rawValue: BTCAWWatchDataManager.ApplicationDataDidUpdateNotification), object: nil)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        BTCAWWatchDataManager.sharedInstance.destoryTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateUI() {
        // when local currency rate is no avaliable, use empty string
        updateContainerVisibility()
        
        if (BTCAWWatchDataManager.sharedInstance.balanceInLocalCurrency?.characters.count <= 2) {
            balanceInLocalCurrencyLabel.setHidden(true)
        } else {
            balanceInLocalCurrencyLabel.setHidden(false)
        }
        balanceAmountLabel.setAttributedText(BTCAWWatchDataManager.sharedInstance.balanceAttributedString())
        balanceInLocalCurrencyLabel.setText(BTCAWWatchDataManager.sharedInstance.balanceInLocalCurrency)
        lastTransactionLabel.setText(BTCAWWatchDataManager.sharedInstance.lastestTransction)
    }
    
    func shouldShowSetupWalletInterface()->Bool {
        return false;
    }
    
    func updateContainerVisibility() {
        switch BTCAWWatchDataManager.sharedInstance.walletStatus {
            case .unknown:
                loadingIndicator.setHidden(false)
                balanceInfoContainer.setHidden(true)
                setupWalletContainer.setHidden(true)
            case .notSetup:
                loadingIndicator.setHidden(true)
                balanceInfoContainer.setHidden(true)
                setupWalletContainer.setHidden(false)
            case .hasSetup:
                loadingIndicator.setHidden(true)
                balanceInfoContainer.setHidden(false)
                setupWalletContainer.setHidden(true)
        }
    }
}
