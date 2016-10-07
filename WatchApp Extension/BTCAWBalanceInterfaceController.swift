//
//  Created by Admin on 9/8/16.
//

import WatchKit

class BTCAWBalanceInterfaceController: WKInterfaceController {
    @IBOutlet var table: WKInterfaceTable!
    var transactionList = [BTCAppleWatchTransactionData]()

    @IBOutlet var balanceTextContainer: WKInterfaceGroup!
    @IBOutlet var balanceLoadingIndicator: WKInterfaceGroup!
    @IBOutlet var balanceLabel: WKInterfaceLabel!
    @IBOutlet var balanceInLocalCurrencyLabel: WKInterfaceLabel!
    @IBOutlet var transactionHeaderContainer: WKInterfaceGroup! {
        didSet {
            transactionHeaderContainer.setHidden(true) // hide header as default
        }
    }
    
    var showBalanceLoadingIndicator = false {
        didSet{
            self.balanceTextContainer.setHidden(showBalanceLoadingIndicator)
            self.balanceLoadingIndicator.setHidden(!showBalanceLoadingIndicator)
        }
    }
    
    // MARK: View life cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        updateBalance()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        updateBalance()
        updateTransactionList()
        NotificationCenter.default.addObserver(
            self, selector: #selector(BTCAWBalanceInterfaceController.updateUI), name: NSNotification.Name(rawValue: BTCAWWatchDataManager.ApplicationDataDidUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(BTCAWBalanceInterfaceController.txReceive(_:)), name: NSNotification.Name(rawValue: BTCAWWatchDataManager.WalletTxReceiveNotification), object: nil)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func txReceive(_ notification: Notification?) {
        print("balance view controller received notification: \(notification)")
        if let userData = (notification as NSNotification?)?.userInfo,
            let noteString = userData[NSLocalizedDescriptionKey] as? String {
                self.presentAlert(
                    withTitle: noteString, message: nil, preferredStyle: .alert, actions: [
                         WKAlertAction(title: NSLocalizedString("OK", comment: ""),
                            style: .cancel, handler: { self.dismiss() })])
        }
    }
    
    // MARK: UI update
    func updateUI() {
        updateBalance()
        updateTransactionList()
    }
    
    func updateBalance() {
        if let balanceInLocalizationString = BTCAWWatchDataManager.sharedInstance.balanceInLocalCurrency as String? {
            if (BTCAWWatchDataManager.sharedInstance.balanceAttributedString() != nil){
                balanceLabel.setAttributedText(BTCAWWatchDataManager.sharedInstance.balanceAttributedString())
            }
            balanceInLocalCurrencyLabel.setText(balanceInLocalizationString)
            showBalanceLoadingIndicator = false;
        } else {
            showBalanceLoadingIndicator = true;
        }
    }
    
    func updateTransactionList() {
        transactionList = BTCAWWatchDataManager.sharedInstance.transactionHistory
        let currentTableRowCount = table.numberOfRows
        let newTransactionCount = transactionList.count
        let numberRowsToInsertOrDelete = newTransactionCount - currentTableRowCount
        self.transactionHeaderContainer.setHidden(newTransactionCount == 0)
        // insert or delete rows to match number of transactions
        if (numberRowsToInsertOrDelete > 0) {
            let ixs = IndexSet(integersIn: NSMakeRange(currentTableRowCount, numberRowsToInsertOrDelete).toRange() ?? 0..<0)
            table.insertRows(at: ixs, withRowType: "BTCAWTransactionRowControl")
        } else {
            let ixs = IndexSet(integersIn: NSMakeRange(newTransactionCount, abs(numberRowsToInsertOrDelete)).toRange() ?? 0..<0)
            table.removeRows(at: ixs)
        }
        // update row content
        for index in 0 ..< newTransactionCount  {
            if let rowControl = table.rowController(at: index) as? BTCAWTransactionRowControl {
                updateRow(rowControl, transaction: self.transactionList[index])
            }
        }
    }
    
    func updateRow(_ rowControl: BTCAWTransactionRowControl, transaction: BTCAppleWatchTransactionData) {
        let localCurrencyAmount
            = (transaction.amountTextInLocalCurrency.characters.count > 2) ? transaction.amountTextInLocalCurrency : " "
        rowControl.amountLabel.setText(transaction.amountText)
        rowControl.localCurrencyAmount.setText(localCurrencyAmount)
        rowControl.dateLabel.setText(transaction.dateText)
        rowControl.type = transaction.type
        rowControl.seperatorGroup.setHeight(0.5)
    }
}
