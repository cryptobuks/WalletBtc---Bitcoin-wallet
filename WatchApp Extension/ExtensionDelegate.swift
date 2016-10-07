//
//  Created by Admin on 9/8/16.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }

    func applicationDidBecomeActive() {
        BTCAWWatchDataManager.sharedInstance.setupTimer()
        BTCAWWatchDataManager.sharedInstance.requestAllData()
    }

    func applicationWillResignActive() {
        BTCAWWatchDataManager.sharedInstance.destoryTimer()
    }
}
