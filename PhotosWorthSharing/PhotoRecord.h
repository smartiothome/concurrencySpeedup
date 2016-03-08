//
//  PhotoRecord.h
//  PhotosWorthSharing
//
//  Created by Smart Home on 3/6/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

@import UIKit;
#import <Foundation/Foundation.h>


typedef NS_ENUM(char,PhotoState)
{
    New=0,
    Downloading,
    Downloaded,
    Failed,
    Filtered
} ;

@interface PhotoRecord : NSObject

@property  (nonatomic) NSString *photoTitle ;
@property  (nonatomic) NSString *photoURL ;
@property  (nonatomic) PhotoState currState ;
@property  (nonatomic) UIImage *imageData ;
@property  (nonatomic) UIImage *photoThumbnail ;

@end
