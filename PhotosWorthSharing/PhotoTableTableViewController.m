//
//  PhotoTableTableViewController.m
//  PhotosWorthSharing
//
//  Created by Smart Home on 3/5/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import "PhotoTableTableViewController.h"
#import "ImageDetailViewController.h"
#import "PhotoRecord.h"
#import <dispatch/dispatch.h>

@interface PhotoTableTableViewController ()

@property dispatch_queue_t serialQ ;
@property dispatch_queue_t concurrentQ ;

@end

@implementation PhotoTableTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //Start download of plist with Photo URLs
    self.defaultSessionConfig = 	[NSURLSessionConfiguration defaultSessionConfiguration];
    self.defaultSession = [NSURLSession sessionWithConfiguration:
    self.defaultSessionConfig delegate: nil delegateQueue: [NSOperationQueue mainQueue]] ;
    
    self.serialQ = dispatch_queue_create("com.smarthome.imagegrabber.serialbgqueue",DISPATCH_QUEUE_SERIAL) ;
    self.concurrentQ = dispatch_queue_create("com.smarthome.imagegrabber.concBgQ",DISPATCH_QUEUE_CONCURRENT) ;
    
    
    NSURL *photoPlist = [NSURL URLWithString:@"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist"] ;
    NSLog(@"loading from URL %@",photoPlist) ;
    NSURLSessionDataTask *dataTask = [self.defaultSession dataTaskWithURL:photoPlist completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error)
        {
            NSLog(@"Could not retrieve list of photo URLs due to error %@",error) ;
            PhotoRecord *photoObjToAdd=[[PhotoRecord alloc] init] ;
            photoObjToAdd.photoTitle=@"Failed to Load Photo, plist retrieve error" ;
            photoObjToAdd.currState=Failed ;
            [self.photos addObject:photoObjToAdd] ;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData] ;
            }) ;
        }
        else
        {
            //Convert received plist into list of objects to download
            NSDictionary *datasourceDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:&error] ;
            if(!error)
            {
                NSLog(@"Received dictionary of URLs %@",datasourceDictionary) ;
                NSString *key ;
                for(key in datasourceDictionary)
                {
                    NSString *value = [datasourceDictionary objectForKey:key];
                    PhotoRecord *photoObjToAdd=[[PhotoRecord alloc] init] ;
                    photoObjToAdd.photoTitle=key ;
                    photoObjToAdd.photoURL=value ;
                    photoObjToAdd.currState=New;
                    [self.photos addObject:photoObjToAdd] ;
                    
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData] ;
                }) ;
            }
            else
            {
                NSLog(@"Did not receive valid plist.  PList decoding resulted in error %@",error) ;
                PhotoRecord *photoObjToAdd=[[PhotoRecord alloc] init] ;
                photoObjToAdd.photoTitle=@"Failed to Load Photo, URL plist decode error" ;
                photoObjToAdd.currState=Failed ;
                [self.photos addObject:photoObjToAdd] ;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData] ;
                }) ;

            }
         //NSLog(@"received data %@",data) ;
            
        }

    }] ;
    [dataTask resume] ;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    
    self.tableView.rowHeight = 60.f ;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.photos count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    PhotoRecord *photoDetails=self.photos[indexPath.row] ;
    //NSLog(@"Photo details are %@",photoDetails) ;
    if(photoDetails.currState!=Failed)
    {
        //NSAssert(photoDetails.currState==Downloaded || photoDetails.currState==Downloading || photoDetails.currState==Filtered || photoDetails.currState==New, @"State is %d not failed, new, downloading, downlaoded or filtered.",photoDetails.currState) ;
        //Download image
        NSURL *imageURL = [NSURL URLWithString:photoDetails.photoURL] ;
        if(photoDetails.currState==Filtered)
        {
            cell.imageView.image=photoDetails.photoThumbnail ;
            //cell.imageView.image=photoDetails.imageData ;
            //NSLog(@"Have already downlaoded and filtered image for URL %@/row %ld. Just supllying image %@.",imageURL,(long)indexPath.row,photoDetails.photoThumbnail) ;
        }
//        else if(photoDetails.currState==Downloading)
//        {
//            //No op, since we just wait for download to complete
//            //NSLog(@"Have staretd downloading image for URL %@/row %ld. Nothing to supply at this point and nothing to start.",imageURL,(long)indexPath.row) ;
//        }
        else if(photoDetails.currState==Downloaded)
        {
            cell.imageView.image=photoDetails.photoThumbnail ;
            //cell.imageView.image=photoDetails.imageData ;
            //NSLog(@"Have already downlaoded but not filtered image for URL %@/row %ld. Just supplying pre-filtered version.",imageURL,(long)indexPath.row) ;
        }
        else if(photoDetails.currState==New)
        {
            //NSLog(@"Starting image download for URL %@/row %ld",imageURL,(long)indexPath.row) ;
            photoDetails.currState=Downloading ;
            self.photos[indexPath.row]=photoDetails ;
            dispatch_async(self.concurrentQ, ^(void) {
                NSURLSessionDataTask *dataTask = [self.defaultSession dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    if(error)
                    {
                        //NSLog(@"Could not retrieve image at row %ld due to error %@",(long)indexPath.row,error) ;
                        PhotoRecord *photoObjToAdd=[[PhotoRecord alloc] init] ;
                        photoObjToAdd.photoTitle=@"Failed to Load Photo, Downlaod error" ;
                        photoObjToAdd.currState=Failed ;
                        self.photos[indexPath.row]=photoObjToAdd;
                    }
                    else
                    {
                        //Convert received plist into list of objects to download
                        //NSPropertyListSerialization.propertyListWithData
                        //Create image object from retrieved data and apply sepia filter on it
                        ((PhotoRecord *)self.photos[indexPath.row]).imageData=[UIImage imageWithData:data] ;
                        //Downscale it for showing a smaller vesrion in tableview to speed things up
                        ((PhotoRecord *)self.photos[indexPath.row]).photoThumbnail=[self returnThumbnail:((PhotoRecord *)self.photos[indexPath.row]).imageData] ;
                        ((PhotoRecord *)self.photos[indexPath.row]).currState=Downloaded ;
                        
                        //Start filtering process in background
                        dispatch_async(self.concurrentQ, ^(void) {
                            ((PhotoRecord *)self.photos[indexPath.row]).imageData=[self applySepiaFilter:((PhotoRecord *)self.photos[indexPath.row]).imageData] ;
                            ((PhotoRecord *)self.photos[indexPath.row]).photoThumbnail=[self returnThumbnail:((PhotoRecord *)self.photos[indexPath.row]).imageData] ;
                            ((PhotoRecord *)self.photos[indexPath.row]).currState=Filtered ;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                            }) ;
                        }) ;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }) ;
                }] ;
                [dataTask resume] ;
            }) ;
        }
    }
    else
    {
        //NSLog(@"Not retrieving image at row %ld because of failure %@",(long)indexPath.row,photoDetails.photoTitle) ;
        cell.imageView.image=nil ;
    }
    
    cell.textLabel.text=photoDetails.photoTitle ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"photoDisplay" forIndexPath:indexPath];
    return cell;
}

- (UIImage *) returnThumbnail:(UIImage*)image
{
    CGSize itemSize = CGSizeMake(120, 90);
    UIGraphicsBeginImageContext(itemSize);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width,  itemSize.height);
    [image drawInRect:imageRect];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //NSLog(@"Returning scaled image %@",scaledImage) ;
    return scaledImage ;
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


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    ImageDetailViewController *destVC = (ImageDetailViewController *)[segue destinationViewController] ;
    PhotoRecord *photoObjSelected = self.photos[indexPath.row] ;
    destVC.imageToDisplay = photoObjSelected.imageData ;
    destVC.imageName=photoObjSelected.photoTitle ;
    destVC.url=photoObjSelected.photoURL ;
    //NSLog(@"doing a segue from row %ld with image of size = %f,%f and data = %@",(long)indexPath.row,destVC.imageDisplay.image.size.width,destVC.imageDisplay.image.size.height,self.photos[indexPath.row][@"Image"]);
}


- (NSMutableArray*) photos
{
    if (!_photos){
        _photos = [[NSMutableArray alloc] init];
    }
    return _photos;
}

@end
