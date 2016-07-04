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
    
    var textCounter = 0
    var timer:NSTimer?
    
    let INTERVAL = 0.1
    let LINE_DELAY = 0.5
    
    let commands = [
        ".FOCUS": #selector(ViewController.focusConsole)
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
    
    func printArray(array: [String]) {
        var delay = 0.0
        for string in array {
            delay += Double(LINE_DELAY)
            printLine(string, delay: delay)
            delay += Double(string.characters.count) * INTERVAL
        }
    }
    
    func printLine(text: String, delay: Double) {
        NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(ViewController.typeLetter), userInfo: ["text": text + "\n"], repeats: false)
    }
    
    func typeLetter(timer: NSTimer) {
        let text: String = timer.userInfo!["text"] as! String
        var textArray = text.characters.map { String($0) }
        if(commands[text.stringByReplacingOccurrencesOfString("\n", withString: "")] != nil) {
            self.performSelector(commands[text.stringByReplacingOccurrencesOfString("\n", withString: "")]!)
            return
        }
        
        if(textArray.count == 0) {
            timer.invalidate()
            return
        }
        console.text = console.text! + String(textArray[0])
        let randomInterval = 0.1//Double((arc4random_uniform(8)+1))/20
        timer.invalidate()
        textArray.removeFirst()
        NSTimer.scheduledTimerWithTimeInterval(randomInterval, target: self, selector: #selector(ViewController.typeLetter), userInfo: ["text": textArray.joinWithSeparator("")], repeats: false)
    }
    
    func focusConsole() {
        console.becomeFirstResponder()
    }

}

