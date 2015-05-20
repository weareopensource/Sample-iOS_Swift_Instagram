//
//  ViewController.swift
//  Sample-Swift_instagram
//
//  Created by RYPE on 12/05/2015.
//  Copyright (c) 2015 weareopensource. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, APIControllerProtocol {
    
    
    /*************************************************/
    // Main
    /*************************************************/
    
    // Var
    /*************************/
    var posts = [Post]()
    var imageCache = [String:UIImage]()
    var api : APIController!
    var refreshControl:UIRefreshControl!
    
    // Boulet
    /*************************/
    @IBOutlet weak var tableView: UITableView!
    
    // Base
    /*************************/
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // custom
        // ---------------------
        self.tableView.backgroundView = UIImageView(image: UIImage(named: "test.jpg"))
        // ---------------------
        
        
        // get data
        api = APIController(delegate: self)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        api.instagram()
        
        //Pull to refresh
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = UIColor.whiteColor()
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // TableView
    /*************************/
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! Cell
        let post = posts[indexPath.row]
        cell.myLabel.text = "✍ " + String(post.comments)
        cell.myLabel2.text = String(post.likes) + " ♥︎"

        // Start by setting the cell's image to a static file
        // Without this, we will end up without an image view!
        //cell.imageView?.image = UIImage(named: "test")
        
        let imgURLString = post.img
        let imgURL = NSURL(string: imgURLString)!
        
        // If this image is already cached, don't re-download
        if let img = imageCache[imgURLString] {
            cell.myImageView.image = img
        }
        else {
            // The image isn't cached, download the img data
            // We should perform this in a background thread
            let request: NSURLRequest = NSURLRequest(URL: imgURL)
            let mainQueue = NSOperationQueue.mainQueue()
            NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                if error == nil {
                    // Convert the downloaded data in to a UIImage object
                    let image = UIImage(data: data)
                    // Store the image in to our cache
                    self.imageCache[imgURLString] = image
                    // Update the cell
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath) as? Cell {
                            cellToUpdate.myImageView.image = image
                            // animation
                            // ---------------------
                            cellToUpdate.myImageView?.alpha = 0
                            UIView.animateWithDuration(0.5, delay: 0,
                                options: nil, animations: {
                                    cellToUpdate.myImageView?.alpha = 1
                                }, completion: nil)
                            // ---------------------
                        }
                    })
                }
                else {
                    println("Error: \(error.localizedDescription)")
                }
            })
        }
        
        // animation
        // ---------------------
        cell.myLabel?.alpha = 0.3
        cell.myLabel?.center.x -= view.bounds.width
        UIView.animateWithDuration(0.5, delay: 0.1,
            options: nil, animations: {
                cell.myLabel?.center.x += self.view.bounds.width
            }, completion: { _ in
                UIView.animateWithDuration(0.4, delay: 0,
                    options: nil, animations: {
                        cell.myLabel?.alpha = 1
                    }, completion: nil)
        })

        cell.myLabel2?.alpha = 0.3
        cell.myLabel2?.center.x += view.bounds.width
        UIView.animateWithDuration(0.5, delay: 0.1,
            options: nil, animations: {
                cell.myLabel2?.center.x -= self.view.bounds.width
            }, completion: { _ in
                UIView.animateWithDuration(0.4, delay: 0,
                    options: nil, animations: {
                        cell.myLabel2?.alpha = 1
                    }, completion: nil)
        })
        
        cell.myView?.alpha = 0
        UIView.animateWithDuration(0.5, delay: 0,
            options: nil, animations: {
                cell.myView?.alpha = 1
            }, completion: nil)
        // ---------------------
        self.tableView.rowHeight =  self.view.bounds.width

        
        return cell
    }
    
    /*
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
       cell.layer.transform = CATransform3DMakeScale(0.1,0.1,1)
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1,1,1)
        })
    }*/
    
    
    // Segue
    /*************************/
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let postViewController: PostController = segue.destinationViewController as? PostController {
            var postIndex = tableView!.indexPathForSelectedRow()!.row
            var selectedPost = self.posts[postIndex]
            postViewController.post = selectedPost
        }
    }
    
    /*************************************************/
    // Functions
    /*************************************************/
    
    // Other
    /*************************/
    func refresh(sender:AnyObject)
    {
        // get data
        api = APIController(delegate: self)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        api.instagram()
    }
    
    func didReceiveAPIResults(results: NSArray) {
        dispatch_async(dispatch_get_main_queue(), {
            self.posts = Post.postsWithJSON(results)
            self.tableView!.reloadData()
            self.refreshControl.endRefreshing()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }

}
