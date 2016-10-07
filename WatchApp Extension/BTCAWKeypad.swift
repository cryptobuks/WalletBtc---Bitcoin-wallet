import Foundation
import WatchKit

protocol BTCAWKeypadDelegate {
    func keypadDidFinish(_ stringValueBits: String)
}

class BTCAWKeypadModel {
    var delegate: BTCAWKeypadDelegate? = nil
    var valueInBits: String = "0"
    
    init(delegate d: BTCAWKeypadDelegate?) {
        delegate = d
    }
}

class BTCAWKeypad: WKInterfaceController {
    var digits: [String] = [String]()
    var ctx: BTCAWKeypadModel?
    
    override func awake(withContext context: Any?) {
        ctx = context as? BTCAWKeypadModel
        digits = [String]()
        if let c = ctx {
            for s in c.valueInBits.components(separatedBy: "") {
                digits.append(s)
            }
        }
    }
    
    override func willDisappear() {
        ctx = nil
    }

    @IBOutlet var display: WKInterfaceLabel!
    
    @IBAction func one(_ sender: AnyObject?) { append("1") }
    
    @IBAction func two(_ sender: AnyObject?) { append("2") }
    
    @IBAction func three(_ sender: AnyObject?) { append("3") }
    
    @IBAction func four(_ sender: AnyObject?) { append("4") }
    
    @IBAction func five(_ sender: AnyObject?) { append("5") }
    
    @IBAction func six(_ sender: AnyObject?) { append("6") }
    
    @IBAction func seven(_ sender: AnyObject?) { append("7") }
    
    @IBAction func eight(_ sender: AnyObject?) { append("8") }
    
    @IBAction func nine(_ sender: AnyObject?) { append("9") }
    
    @IBAction func zero(_ sender: AnyObject?) { append("0") }
    
    @IBAction func del(_ sender: AnyObject?) {
        if digits.count > 0 {
            digits.removeLast()
            fmt()
        }
    }
    
    @IBAction func ok(_ sender: AnyObject?) {
        ctx?.delegate?.keypadDidFinish(ctx!.valueInBits)
    }
    
    func append(_ digit: String) {
        digits.append(digit)
        fmt()
    }
    
    func fmt() {
        var s = "ƀ"
        var d = digits
        while d.count > 0 && d[0] == "0" { d.removeFirst() } // remove remove forward zero padding
        while d.count < 3 { d.insert("0", at: 0) } // add it back correctly
        for i in 0...(d.count - 1) {
            if i == d.count - 2 {
                s.append(".")
            }
            s.append(d[i])
        }
        display.setText(s)
        ctx?.valueInBits = s
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "ƀ", with: "")
    }
}
