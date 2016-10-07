//
//  Created by Admin on 9/8/16.
//

import WatchKit

class BTCAWTransactionRowControl: NSObject {
    
    @IBOutlet var statusIcon: WKInterfaceImage! {
        didSet {
            statusIcon.setImage(nil)
        }
    }
    @IBOutlet var amountLabel: WKInterfaceLabel!
    @IBOutlet var dateLabel: WKInterfaceLabel!
    @IBOutlet var seperatorGroup: WKInterfaceGroup!
    @IBOutlet var localCurrencyAmount: WKInterfaceLabel!
    var type = BTCAWTransactionTypeReceive {
        didSet {
            switch type {
                case BTCAWTransactionTypeReceive:
                    statusIcon.setImageNamed("ReceiveMoneyIcon")
                    break;
                case BTCAWTransactionTypeSent:
                    statusIcon.setImageNamed("SentMoneyIcon")
                    break;
                case BTCAWTransactionTypeMove:
                    statusIcon.setImageNamed("MoveMoneyIcon")
                    break;
                case BTCAWTransactionTypeInvalid:
                    statusIcon.setImageNamed("InvalidTransactionIcon")
                    break;
                default:
                    statusIcon.setImage(nil)
            }
        }
    }
}
