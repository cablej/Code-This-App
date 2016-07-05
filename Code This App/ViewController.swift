//
//  ViewController.swift
//  Code This App
//
//  Created by Jack Cable on 7/3/16.
//  Copyright © 2016 Jack Cable. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var console: UITextView!
    
    let LINE_DELAY = 0.5
    
    let commands = [
        ".FOCUS": #selector(ViewController.focusConsole(_:))
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        printArray([
            "*Yawwwwwn*",
            "What a lovely-- Ah, hi there!",
            "I almost didn't see you.",
            "So, anyways, what's your name?",
            ".FOCUS"
        ])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func printArray(array: [String], params: Dictionary<String, AnyObject>? = nil) {
        if array.count == 0 {
            return
        }
        var delay = 0.0
        delay += Double(LINE_DELAY)
        printLine(array[0], delay: delay, completion: { (response) in
            var tempArray = array
            tempArray.removeFirst()
            self.printArray(tempArray, params: response)
        })
    }
    
    func printLine(text: String, delay: Double, completion: (Dictionary<String, AnyObject>?) -> Void) {
        if (commands[text] != nil) {
//            self.performSelector(commands[text]!)
//            self.performSelector(commands[text]!, withObject: completion)
            return
        } else {
            console.text.appendContentsOf(text + "\n")
            
            let time = Double(NSEC_PER_SEC) * delay
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(time)), dispatch_get_main_queue()) {
                completion(nil)
            }
        }
    }
    
    func invokeCompletion() {
        
    }
    
    func focusConsole(completion: (Dictionary<String, AnyObject>?) -> Void) {
        console.becomeFirstResponder()
    }

}

