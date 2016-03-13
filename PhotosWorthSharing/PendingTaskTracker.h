//
//  PendingTaskTracker.h
//  PhotosWorthSharing
//
//  Created by Smart Home on 3/8/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface PendingTaskTracker : NSObject

@property NSMutableArray *pendingTasks ; //Array of Dictionaries.  Each index in array represnets particular kind of task being tracked.  E.g. in this project they are DL task and filtering task
@property NSMutableArray * pendingOperationQueue ; //Array of Operation queues used to execute each kind of task.  Index mapping to queue type same as above
- (instancetype) initOperationQueuesWithNamesInArray:(NSArray *)operationQueueNames ;

@end
