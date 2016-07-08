//
//  SelectViewController.swift
//  Code This App
//
//  Created by Jack Cable on 7/7/16.
//  Copyright © 2016 Jack Cable. All rights reserved.
//

import UIKit

class SelectViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet var collectionView: UICollectionView!
    var lessons = [];
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        loadLessons()
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return lessons.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LessonCell", forIndexPath: indexPath) as! LessonCell
        guard let lesson = lessons[indexPath.row] as? NSDictionary, let name = lesson["name"] as? String else {
            return cell
        }
        cell.nameLabel.text = name
        return cell
    }

    func loadLessons() {
        guard let path = NSBundle.mainBundle().pathForResource("original", ofType: "plist"), let lessonsArray = NSArray(contentsOfURL: NSURL(fileURLWithPath: path)) else {
            return
        }
        
        lessons = lessonsArray
        self.collectionView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? LessonViewController {
            let selectedRow = (collectionView.indexPathsForSelectedItems()?.first!.row)!
            guard let lesson = lessons[selectedRow] as? NSDictionary, let items = lesson["items"] as? [String] else {
                return
            }
            vc.items = items
        }
    }

}
