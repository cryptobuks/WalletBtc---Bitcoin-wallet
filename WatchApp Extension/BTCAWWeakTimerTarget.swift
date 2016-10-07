//
//  Created by Admin on 9/8/16.
//

import WatchKit

class BTCAWWeakTimerTarget: NSObject {
    weak var target : AnyObject? = nil
    var selector : Selector? = nil
    
    init(initTarget: AnyObject , initSelector : Selector) {
        super.init()
        target = initTarget
        selector = initSelector
    }
    
    func timerDidFire() {
        if target != nil && selector != nil && target!.responds(to: selector!) {
            target!.perform(selector!)
        }
    }
}
