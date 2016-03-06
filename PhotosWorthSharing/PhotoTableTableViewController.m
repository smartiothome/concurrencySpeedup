//
//  PhotoTableTableViewController.m
//  PhotosWorthSharing
//
//  Created by Smart Home on 3/5/16.
//  Copyright © 2016 Smart Home. All rights reserved.
//

#import "PhotoTableTableViewController.h"
#import "ImageDetailViewController.h"

@interface PhotoTableTableViewController ()

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
    NSURL *photoPlist = [NSURL URLWithString:@"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist"] ;
    NSLog(@"loading from URL %@",photoPlist) ;
    NSURLSessionDataTask *dataTask = [self.defaultSession dataTaskWithURL:photoPlist completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error)
        {
            NSLog(@"Could not retrieve list of photo URLs due to error %@",error) ;
            [self.photos addObject:[[NSMutableDictionary alloc] initWithObjectsAndKeys:@"Failed to load Objects",@"Name",@"-1",@"URL",nil]] ;
            //[self.photos setObject:[[NSDictionary alloc] initWithObjectsAndKeys:@"-1",@"URL",nil] forKey:@"Failed to Load Photos"] ;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData] ;
            }) ;
        }
        else
        {
        //Convert received plist into list of objects to download
            //NSError *error ;
            NSDictionary *datasourceDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:&error] ;
            if(!error)
            {
                NSLog(@"Received dictionary of URLs %@",datasourceDictionary) ;
                NSString *key ;
                for(key in datasourceDictionary)
                {
                    NSString *value = [datasourceDictionary objectForKey:key];
                    [self.photos addObject:[[NSMutableDictionary alloc] initWithObjectsAndKeys:key,@"Name",value,@"URL",nil]] ;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData] ;
                }) ;
            }
            else
            {
                NSLog(@"Did not receive valid plist.  PList decoding resulted in error %@",error) ;
                [self.photos addObject:[[NSMutableDictionary alloc] initWithObjectsAndKeys:@"Failed to load Objects",@"Name",@"-1",@"URL",nil]] ;
                //[self.photos setObject:[[NSDictionary alloc] initWithObjectsAndKeys:@"-1",@"URL",nil] forKey:@"Failed to Load Photos"] ;
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CFTimeInterval startTime = CACurrentMediaTime();
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"photoDisplay" forIndexPath:indexPath];
    
    
    // Configure the cell...
    NSDictionary *rowDict=[NSDictionary dictionaryWithDictionary:self.photos[indexPath.row]] ;
    if(![rowDict[@"URL"] isEqualToString:@"-1"])
    {
        //Download image
        NSURL *imageURL = [NSURL URLWithString:rowDict[@"URL"]] ;
        if(!rowDict[@"Image"] && !rowDict[@"isDownloading"])
        {
            NSLog(@"Starting image download for URl %@ for row %ld",imageURL,(long)indexPath.row) ;
            self.photos[indexPath.row][@"isDownloading"]=@(YES) ;
            NSURLSessionDataTask *dataTask = [self.defaultSession dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if(error)
                {
                    NSLog(@"Could not retrieve image at row %ld due to error %@",(long)indexPath.row,error) ;
                    self.photos[indexPath.row][@"Name"] =@"Failed to load Objects" ;
                    self.photos[indexPath.row][@"URL"] =@"-1" ;
                }
                else
                {
                    //Convert received plist into list of objects to download
                    //NSPropertyListSerialization.propertyListWithData
                    //Create image object from retrieved data and apply sepia filter on it
                    self.photos[indexPath.row][@"Image"]=[self applySepiaFilter:[UIImage imageWithData:data]] ;
                    cell.imageView.image=self.photos[indexPath.row][@"Image"] ;
                }
                [self.tableView reloadData] ;
            }] ;
            [dataTask resume] ;
        }
        else
        {
            cell.imageView.image=rowDict[@"Image"] ;
            NSLog(@"Image for URl %@/row %ld alreday exists or is downloading.",imageURL,(long)indexPath.row) ;
        }
    }
    else
    {
        NSLog(@"Not retrieving image at row %ld since URL is -1",(long)indexPath.row) ;
        cell.imageView.image=nil ;
    }
    
    cell.textLabel.text=rowDict[@"Name"] ;
    
    CFTimeInterval endTime = CACurrentMediaTime();
    NSLog(@"Total Runtime for cellFOrIdnex: %g ms", (endTime - startTime)/1000.0);
    
    return cell;
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
    destVC.imageToDisplay = self.photos[indexPath.row][@"Image"] ;
    destVC.imageName=self.photos[indexPath.row][@"Name"] ;
    destVC.url=self.photos[indexPath.row][@"URL"] ;
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
