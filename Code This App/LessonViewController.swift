//
//  LessonViewController.swift
//  Code This App
//
//  Created by Jack Cable on 7/3/16.
//  Copyright © 2016 Jack Cable. All rights reserved.
//

import UIKit

class LessonViewController: UIViewController {

    @IBOutlet var console: UITextView!
    
    var items = []
    let LINE_DELAY = 0.5
    
    let commands = [
        ".FOCUS": #selector(focusConsole),
        ".PROMPT": #selector(focusConsole),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.hidesBarsOnTap = true
        self.navigationController?.hidesBarsOnSwipe = true
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
        var shouldReturn = false;
        commands.forEach { (command) in
            if(text.containsString(command.0)) {
                self.performSelector(command.1)
                shouldReturn = true
                return
            }
        }
        if(shouldReturn) { return }

        console.text.appendContentsOf(text + "\n")
        
        let time = Double(NSEC_PER_SEC) * delay
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(time)), dispatch_get_main_queue()) {
            completion(nil)
        }
    }
    
    func focusConsole() {
//        guard let completion = params["completion"] as? (Dictionary<String, AnyObject>?) -> Void) else {
//            return
//        }
        console.becomeFirstResponder()
    }

}

