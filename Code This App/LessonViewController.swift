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
    var items = []
    
    let context = JSContext()
    
    var currentCompletion: Any?
    var actionEvent: Any?
    
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
        
        printArray(items as! [String])
    }
    
    func initializeContext() {
        context.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
        let consoleLog: @convention(block) String -> Void = { message in
            self.console.text.appendContentsOf("[Log]: \(message)\n")
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
        
        context.exceptionHandler = { (context, exception) in
            self.console.text.appendContentsOf("[Error]: \(exception)\n")
        }
    }

    
    @IBAction func onRunButtonTapped(sender: AnyObject) {
        context.evaluateScript(codeView.text)
    }
    
    func printArray(array: [String], params: Dictionary<String, AnyObject>? = nil) {
        if array.count == 0 {
            return
        }
        var delay = 0.0
        delay += Double(LINE_DELAY)
        printLine(array[0], delay: delay, completion: { (response) in
            if let response = response {
                self.dataToStore["data"]! += response
            }
            print(self.dataToStore)
            var tempArray = array
            tempArray.removeFirst()
            self.printArray(tempArray, params: response)
        })
    }
    
    func printLine(text: String, delay: Double, completion: (Dictionary<String, AnyObject>?) -> Void) {
        var text = text
        var shouldReturn = false;
        commands.forEach { (command) in
            if(text.containsString(command.0)) {
                let params = matchesForRegexInText(text)
                currentCompletion = completion
                self.performSelector(command.1, withObject: params)
                shouldReturn = true
                return
            }
        }
        if(shouldReturn) { return }
        
        for (key, value) in dataToStore["data"]! {
            text = text.stringByReplacingOccurrencesOfString("{\(key)}", withString: value as! String)
        }
        
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
    
    func matchesForRegexInText(text: String!) -> [String] {
        let regex = "\\{(.*?)\\}"
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            
            let results = regex.matchesInString(text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range).stringByReplacingOccurrencesOfString("{", withString: "").stringByReplacingOccurrencesOfString("}", withString: "")}
            
        } catch let error as NSError {
            
            print("invalid regex: \(error.localizedDescription)")
            
            return []
        }
    }

}

func += <KeyType, ValueType> (inout left: [KeyType:ValueType], right: [KeyType:ValueType]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}
