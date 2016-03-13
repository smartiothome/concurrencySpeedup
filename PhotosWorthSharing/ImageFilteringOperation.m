//
//  ImageFilteringOperation.m
//  PhotosWorthSharing
//
//  Created by Smart Home on 3/12/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import "ImageFilteringOperation.h"

@interface ImageFilteringOperation()

@property (nonatomic) UIImage *imageData ;
@property BOOL cancelledBeforeFinished ;


@end

@implementation ImageFilteringOperation


- (instancetype) initWithImageData:(UIImage *)image
{
    self = [super init] ;
    
    if(self)
    {
        _imageData=image ;
        _cancelledBeforeFinished=NO ;
    }
    
    return self ;
}

-(void)main {
    
    @try {
        
        if (![self isCancelled]) {
            
            // Do some work and set isDone to YES when finished
            // Check if operation has been cancelled before 				// starting a lot of work to avoid doing a lot of work 		// that will be thrown away
            self.imageData = [self applySepiaFilter:self.imageData] ;
        }
        
        if ([self isCancelled]) {
            self.cancelledBeforeFinished=YES ;
        }
        
    }
    
    @catch(NSException *exception) {
        
        // Do not rethrow exceptions.
         NSLog(@"Exception %@ occured while applying Sepia Filter",[exception description]);
        
    }
    
}

- (UIImage *) applySepiaFilter:(UIImage*)image
{
    //let inputImage = CIImage(data:UIImagePNGRepresentation(image)!)
    CIImage *inputImage = [CIImage imageWithData:UIImagePNGRepresentation(image)] ;
    //let context = CIContext(options:nil)
    //let filter = CIFilter(name:"CISepiaTone")
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone" keysAndValues:kCIInputImageKey,inputImage,@"inputIntensity",@(0.8),nil] ;
    CIImage *outputImage = [filter outputImage];
    //CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone" keysAndValues: kCIInputImageKey, beginImage, @"inputIntensity", @0.8, nil];
    return [UIImage imageWithCIImage:outputImage];
}

@end
