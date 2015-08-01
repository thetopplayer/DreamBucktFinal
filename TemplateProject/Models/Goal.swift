//
//  Goal.swift
//  TemplateProject
//
//  Created by Aarushi Shah on 7/17/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit
import Parse
import Bond

class Goal: PFObject, PFSubclassing{
    
    @NSManaged var title: String?
    @NSManaged var goalDescription: String?
    @NSManaged var externalLink: String?
    @NSManaged var starRating: Float
    @NSManaged var dateGoal: NSDate?
    @NSManaged var shareable: Bool
    @NSManaged var accomplished: Bool
    @NSManaged var ofUser: PFUser?
    @NSManaged var imageFile: PFFile?
    @NSManaged var imageFileArray: [PFFile]?
    
    var image:UIImage?
    var likes =  Dynamic<[PFUser]?>(nil)
    var photoUploadTask: UIBackgroundTaskIdentifier?

    
   
    static func parseClassName() -> String {
        return "Goal"
    }
    
    override init() {
        super.init()
    }
    
    override class func initialize() {
        var onceToken : dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            // inform Parse about this subclass
            self.registerSubclass()
        }
    }
    
    func uploadGoal () {
        ofUser = PFUser.currentUser()
        saveInBackgroundWithBlock{ (success: Bool, error: NSError?) -> Void in
            println("save succesfully")
        }
    }
    func updateAccomplish(completed: Bool) {
        self.accomplished = completed
        self.saveInBackground()
    }
    
    func uploadImages(images: [UIImage]) {
        
        for eachimage in images {
            let imageData = UIImageJPEGRepresentation(eachimage, 0.8)
            let imageFile = PFFile(data:imageData)
            imageFileArray!.append(imageFile)
            imageFile.saveInBackgroundWithBlock { (succes: Bool, error: NSError?) -> Void in
                UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
            }
        }
            
            //when the post uploads, we create this background task, and IOS stores the unique ID of the background task in photoUploadTask.
            //the API requires us to provide an ExpirationHandler in the form of a closure, so whenever the time is up, we can stop the background task and delete any temporary information we may have kept. We have none in this case
            photoUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler{ () -> Void in
                
                UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
                //if you dont do this ^ your app will be terminated
            }
            
        
    }
    func doesUserLikePost(user: PFUser) -> Bool {
        if let likes = likes.value {
            return contains(likes, user)
        } else {
            return false
        }
    }
    
    func toggleLikePost(user: PFUser) {
        if (doesUserLikePost(user)) {
            likes.value = likes.value?.filter { $0 != user }
            ParseHelper.removeLike(self)
        } else {
            likes.value?.append(user)
            ParseHelper.addLike(self)
        }
    }
    
    func fetchLikes() -> Int {

        if (likes.value == nil) {
        ParseHelper.likesForPost(self, completionBlock: { (var likes: [AnyObject]?, error: NSError?) -> Void in
            likes = likes?.filter { like in like[ParseHelper.ParseLikeFromUser] != nil }
            
            self.likes.value = likes?.map { like in
                let like = like as! PFObject
                let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser
                
                return fromUser
            }
        })
        }
        
        if let numLikes = likes.value?.count {
            return numLikes
        }
        else {
            return 0
        }
    }
}
