//
//  PhotoTableTableViewController.h
//  PhotosWorthSharing
//
//  Created by Smart Home on 3/5/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoTableTableViewController : UITableViewController

@property (nonatomic) NSMutableArray *photos ;
@property NSURLSessionConfiguration *defaultSessionConfig ;
@property NSURLSession *defaultSession ;

@end
