//
//  PendingTaskTracker.m
//  PhotosWorthSharing
//
//  Created by Smart Home on 3/8/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import "PendingTaskTracker.h"

@implementation PendingTaskTracker

- (instancetype) initOperationQueuesWithNamesInArray:(NSArray *)operationQueueNames
{
    self = [super init] ;
    
    if(self)
    {
        _pendingOperationQueue = [[NSMutableArray alloc] init] ;
        NSString *nextQueue ;
        for (nextQueue in operationQueueNames)
        {
            NSOperationQueue * queue = [[NSOperationQueue alloc] init];
            queue.name=nextQueue ;
            [self.pendingOperationQueue addObject:queue] ;
        }
    }
    
    //Create queues with names listed in the operationQueNames array
    
    return self ;
    
}

@end
