//
//  ImageDetailViewController.m
//  PhotosWorthSharing
//
//  Created by Smart Home on 3/6/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import "ImageDetailViewController.h"

@interface ImageDetailViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageDisplay;

@end

@implementation ImageDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"Received segue with test string = %@, image size = %.2f, %.2f and data set to %@",self.imageName,self.imageDisplay.image.size.width,self.imageDisplay.image.size.height,self.imageDisplay.image) ;
    //self.imageDisplay.frame = CGRectMake(0, 0, self.imageDisplay.image.size.width,self.imageDisplay.image.size.height) ;
    //NSURL *url = [NSURL URLWithString:self.url];
    //NSData *data = [NSData dataWithContentsOfURL:url];
    self.imageDisplay.image = self.imageToDisplay;
    
    //[self addImageView] ;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addImageView{
    UIImageView *imgview = [[UIImageView alloc]
                            initWithFrame:CGRectMake(10, 10, 300, 400)];
    [imgview setImage:self.imageDisplay.image];
    [imgview setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:imgview];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
