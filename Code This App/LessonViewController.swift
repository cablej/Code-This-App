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
    
    let LINE_DELAY = 1
    let CHAR_DELAY = 0.05
    var lessonCode = ""
    
    let context = JSContext()
    
    var printingCompletion: (() -> Void) = { () in
        
    }
    var currentCompletion: Any?
    var actionEvent: (() -> Void) = { () in
        
    }
    var actionEventType = ""
    var verifyValue = ""
    var verifyErrorMessage = ""
    enum EVENT_TYPES: String {
        case READ_INPUT = "ReadInput"
        case VERIFY_OUTPUT = "VerifyOutput"
        case WAIT_EXECUTION = "WaitExecution"
    }
    
    var dataToStore = [
        "data": Dictionary<String, AnyObject>(),
        "code": Dictionary<String, AnyObject>()
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
            
            if self.actionEventType == LessonViewController.EVENT_TYPES.VERIFY_OUTPUT.rawValue {
                if message == self.verifyValue {
                    self.actionEventType = ""
                    self.actionEvent()
                } else {
                    self.console.text.appendContentsOf("\(self.verifyErrorMessage)")
                }
            }
        }
        context.setObject(unsafeBitCast(consoleLog, AnyObject.self), forKeyedSubscript: "_consoleLog")
        
        let readline: @convention(block) (String, JSValue) -> Void = { (message, callback) in
            self.console.text.appendContentsOf("[Input]: \(message)\n")
            self.console.becomeFirstResponder()
            let beforeText = self.console.text
            self.actionEventType = EVENT_TYPES.READ_INPUT.rawValue
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
        
        let verifyOutput: @convention(block) (String, String, JSValue) -> Void = { (value, errorMessage, callback) in
            self.actionEventType = EVENT_TYPES.VERIFY_OUTPUT.rawValue
            self.verifyValue = value;
            self.verifyErrorMessage = errorMessage
            
            self.actionEvent = { () in
                callback.callWithArguments([])
            }
        }
        context.setObject(unsafeBitCast(verifyOutput, AnyObject.self), forKeyedSubscript: "verifyOutput")
        
        let waitForExecution: @convention(block) (JSValue, JSValue, JSValue) -> Void = { (check, error, callback) in
            self.actionEventType = EVENT_TYPES.WAIT_EXECUTION.rawValue
            self.actionEvent = { () in
                if check.callWithArguments([]).toBool() {
                    callback.callWithArguments([])
                } else {
                    error.callWithArguments([])
                    self.actionEventType = EVENT_TYPES.WAIT_EXECUTION.rawValue
                }
            }
        }
        context.setObject(unsafeBitCast(waitForExecution, AnyObject.self), forKeyedSubscript: "waitForExecution")
        
        context.exceptionHandler = { (context, exception) in
            self.console.text.appendContentsOf("[Error]: \(exception)\n")
        }
    }

    
    @IBAction func onRunButtonTapped(sender: AnyObject) {
        context.evaluateScript(codeView.text)
        if actionEventType == EVENT_TYPES.WAIT_EXECUTION.rawValue {
            actionEventType = ""
            actionEvent()
        }
    }
    
    func printArray(array: [String], params: Dictionary<String, AnyObject>? = nil) {
        if array.count == 0 {
            printingCompletion()
            return
        }
        var delay = Double(CHAR_DELAY) * Double(array[0].characters.count)
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
    
    /*
     Manages detecting unput
     */
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if textView == console {
            if text == "\n" {
                textView.resignFirstResponder()
                if actionEventType == EVENT_TYPES.READ_INPUT.rawValue {
                    actionEventType = ""
                    actionEvent()
                }
                return false
            }
        }
        return true
    }

}
