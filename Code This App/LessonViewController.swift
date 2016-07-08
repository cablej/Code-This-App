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
    
    let LINE_DELAY = 1.5
    var items = []
    
    var dataToStore = [
        "data": Dictionary<String, AnyObject>(),
        "code": Dictionary<String, AnyObject>()
    ]
    
    var currentCompletion: Any?;
    
    let commands = [
        ".FOCUS": #selector(focusConsole:),
        ".PROMPT": #selector(focusConsole),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.hidesBarsOnTap = true
        self.navigationController?.hidesBarsOnSwipe = true
        
        printArray(items as! [String])
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
            print(response)
            var tempArray = array
            tempArray.removeFirst()
            self.printArray(tempArray, params: response)
        })
    }
    
    func printLine(text: String, delay: Double, completion: (Dictionary<String, AnyObject>?) -> Void) {
        let params = matchesForRegexInText(text)
        print(params)
        
        var shouldReturn = false;
        commands.forEach { (command) in
            if(text.containsString(command.0)) {
                currentCompletion = completion
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
    
    func focusConsole(params: [String]) {
        guard let completion = currentCompletion as? ((Dictionary<String, AnyObject>?) -> Void) else {
            return
        }
        completion(["text": "name"])
        console.becomeFirstResponder()
    }

    func inputString(prompt: String) {
        
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

