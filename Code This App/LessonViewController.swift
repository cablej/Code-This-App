//
//  LessonViewController.swift
//  Code This App
//
//  Created by Jack Cable on 7/3/16.
//  Copyright © 2016 Jack Cable. All rights reserved.
//

import UIKit
import JavaScriptCore

class LessonViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var console: UITextView!
    @IBOutlet var codeView: UITextView!
    
    let LINE_DELAY = 0.5
    var lessonCode = ""
    
    let context = JSContext()
    
    var printingCompletion: Any?
    var currentCompletion: Any?
    var actionEvent: Any?
    var actionEventType = ""
    enum EVENT_TYPES: String {
        case READ_INPUT = "ReadInput"
        case VERIFY_CODE = "VerifyCode"
    }
    
    var dataToStore = [
        "data": Dictionary<String, AnyObject>(),
        "code": Dictionary<String, AnyObject>()
    ]
    
    let commands = [
        ".PROMPT": #selector(inputString(_:)),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationController?.hidesBarsOnTap = true
//        self.navigationController?.hidesBarsOnSwipe = true
        
        console.delegate = self
        
        initializeContext()
        
//        codeView.text.appendContentsOf(lessonCode)
        context.evaluateScript(lessonCode)
    }
    
    func initializeContext() {
        context.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
        let consoleLog: @convention(block) String -> Void = { message in
            self.console.text.appendContentsOf("\(message)\n")
        }
        context.setObject(unsafeBitCast(consoleLog, AnyObject.self), forKeyedSubscript: "_consoleLog")
        
        let readline: @convention(block) (String, JSValue) -> Void = { (message, callback) in
            self.console.text.appendContentsOf("[Input]: \(message)\n")
            self.console.becomeFirstResponder()
            let beforeText = self.console.text
            self.actionEvent = { () in
                let inputText = self.console.text.stringByReplacingOccurrencesOfString(beforeText, withString: "")
                self.console.text.appendContentsOf("\n")
                self.currentCompletion = nil
                callback.callWithArguments([inputText])
            }
        }
        context.setObject(unsafeBitCast(readline, AnyObject.self), forKeyedSubscript: "readline")
        
        let alert: @convention(block) (String, JSValue) -> Void = { (message, callback) in
            let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action) in
                if(!callback.isUndefined) {
                    callback.callWithArguments([])
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        context.setObject(unsafeBitCast(alert, AnyObject.self), forKeyedSubscript: "alert")
        
        let printArray: @convention(block) ([String], JSValue) -> Void = { (message, callback) in
            self.printArray(message);
            self.printingCompletion = { () in
                callback.callWithArguments([])
            }
        }
        context.setObject(unsafeBitCast(printArray, AnyObject.self), forKeyedSubscript: "printArray")
        
        context.exceptionHandler = { (context, exception) in
            self.console.text.appendContentsOf("[Error]: \(exception)\n")
        }
    }

    
    @IBAction func onRunButtonTapped(sender: AnyObject) {
        context.evaluateScript(codeView.text)
    }
    
    func printArray(array: [String], params: Dictionary<String, AnyObject>? = nil) {
        if array.count == 0 {
            if let comp = printingCompletion as? (() -> Void) {
                printingCompletion = nil
                comp()
            }
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
        console.text.appendContentsOf(text + "\n")
        
        let time = Double(NSEC_PER_SEC) * delay
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(time)), dispatch_get_main_queue()) {
            completion(nil)
        }
    }
    
    func inputString(params: [String]) {
        guard let completion = currentCompletion as? ((Dictionary<String, AnyObject>?) -> Void) else {
            return
        }
        console.text.appendContentsOf(params[0])
        console.becomeFirstResponder()
        let beforeText = console.text
        actionEvent = { () in
            let inputText = self.console.text.stringByReplacingOccurrencesOfString(beforeText, withString: "")
            self.console.text.appendContentsOf("\n")
            self.currentCompletion = nil
            completion([params[1]: inputText])
        }
    }
    
    /*
     Manages detecting unput
     */
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if textView == console {
            if text == "\n" {
                textView.resignFirstResponder()
                if let action = actionEvent as? (() -> Void) {
                    actionEvent = nil
                    action()
                }
                return false
            }
        }
        return true
    }

}
