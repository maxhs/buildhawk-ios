//
//  BHPunchlistItemViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/10/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPunchlistItemViewController.h"
#import "Constants.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHUser.h"
#import <MessageUI/MessageUI.h>
#import <SDWebImage/UIButton+WebCache.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import "Flurry.h"
#import "BHTabBarViewController.h"

static NSString *assigneePlaceholder = @"Assign";
static NSString *locationPlaceholder = @"Location";
static NSString *itemPlaceholder = @"Describe this item...";
typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHPunchlistItemViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIScrollViewDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, MWPhotoBrowserDelegate> {
    BOOL iPhone5;
    BOOL iPad;
    BOOL completed;
    BOOL shouldUpdateCompletion;
    UIActionSheet *assigneeActionSheet;
    UIActionSheet *locationActionSheet;
    AFHTTPRequestOperationManager *manager;
    UIActionSheet *emailActionSheet;
    UIActionSheet *callActionSheet;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *createButton;
    BHProject *project;
    UIAlertView *addOtherAlertView;
    UIButton *takePhotoButton;
    int photoIdx;
    NSMutableArray *browserPhotos;
}
- (IBAction)assigneeButtonTapped;
- (IBAction)locationButtonTapped;
- (IBAction)placeText:(id)sender;
- (IBAction)placeCall:(id)sender;
- (IBAction)sendEmail:(id)sender;
@end

@implementation BHPunchlistItemViewController

@synthesize punchlistItem, assignees, savedUser, locationSet;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        iPad = YES;
    } else if ([UIScreen mainScreen].bounds.size.height == 568) {
        iPhone5 = YES;
        [self.photoLabelButton setImage:[UIImage imageNamed:@"cameraButton"] forState:UIControlStateNormal];
    } else {
        iPhone5 = NO;
        self.emailButton.transform = CGAffineTransformMakeTranslation(0, -88);
        self.callButton.transform = CGAffineTransformMakeTranslation(0, -88);
        self.textButton.transform = CGAffineTransformMakeTranslation(0, -88);
        [self shrinkButton:self.photoButton withAmount:20];
        [self shrinkButton:self.photoLabelButton withAmount:20];
        [self shrinkButton:self.locationButton withAmount:20];
        [self shrinkButton:self.assigneeButton withAmount:20];
        [self shrinkButton:self.completionButton withAmount:30];
        CGRect textRect = self.itemTextView.frame;
        textRect.size.height -= 44;
        [self.itemTextView setFrame:textRect];
        self.photoButton.transform = CGAffineTransformMakeTranslation(0, -30);
        [self.photoLabelButton setTitle:@"Photos" forState:UIControlStateNormal];
        self.photoLabelButton.titleLabel.numberOfLines = 2;
        self.photoLabelButton.transform = CGAffineTransformMakeTranslation(0, -30);
        self.locationButton.transform = CGAffineTransformMakeTranslation(0, -50);
        self.assigneeButton.transform = CGAffineTransformMakeTranslation(0, -70);
        self.scrollView.transform = CGAffineTransformMakeTranslation(0, 56);
    }
    if (self.punchlistItem.photos.count > 0){
        [self redrawScrollView];
    } else {
        self.punchlistItem = [[BHPunchlistItem alloc] init];
        self.punchlistItem.photos = [NSMutableArray array];
    }
    if ([(BHTabBarViewController*)self.tabBarController project]){
        project = [(BHTabBarViewController*)self.tabBarController project];
    }
    if (!manager) {
        manager = [AFHTTPRequestOperationManager manager];
        [manager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    }
	[self.completionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self addBorderTreatement:self.photoButton];
    [self.photoButton addTarget:self action:@selector(photoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addBorderTreatement:self.locationButton];
    [self addBorderTreatement:self.assigneeButton];
    
    if (self.punchlistItem.identifier.length){
        saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(updateItem)];
        [[self navigationItem] setRightBarButtonItem:saveButton];
    } else {
        createButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(createItem)];
        [[self navigationItem] setRightBarButtonItem:createButton];
    }
    if (self.punchlistItem.completed) {
        completed = YES;
        [self.completionButton setBackgroundColor:kDarkGrayColor];
        [self.completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"Completed" forState:UIControlStateNormal];
    } else {
        completed = NO;
        [self.completionButton setBackgroundColor:kLightestGrayColor];
        [self.completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
    }
    shouldUpdateCompletion = NO;
    
    self.itemTextView.delegate = self;
    [self.itemTextView setText:itemPlaceholder];
    [Flurry logEvent:@"Viewing punchlist item"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.punchlistItem.location && self.punchlistItem.location.length) {
        [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",self.punchlistItem.location] forState:UIControlStateNormal];
    } else {
        [self.locationButton setTitle:locationPlaceholder forState:UIControlStateNormal];
    }
    
    if (self.punchlistItem.body) {
        [self.itemTextView setText:self.punchlistItem.body];
    } else {
        [self.itemTextView setTextColor:[UIColor lightGrayColor]];
    }
    
    if (self.punchlistItem.assignees.count) {
        BHUser *assignee = self.punchlistItem.assignees.firstObject;
        if ([assignee isKindOfClass:[BHUser class]] && assignee.fullname.length){
            [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",assignee.fullname] forState:UIControlStateNormal];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)save {
    [self updateItem];
    [SVProgressHUD showWithStatus:@"Saving..."];
}

- (void)addBorderTreatement:(UIButton*)button {
    button.layer.borderColor = [UIColor lightGrayColor].CGColor;
    button.layer.borderWidth = 0.5f;
    [button setBackgroundColor:kLightestGrayColor];
}

- (IBAction)completionTapped{
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (!completed){
            [self.completionButton setBackgroundColor:[UIColor colorWithWhite:.15 alpha:1]];
            [self.completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self.completionButton setTitle:@"Completed" forState:UIControlStateNormal];
        } else {
            [self.completionButton setBackgroundColor:kLightestGrayColor];
            [self.completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
        }
    } completion:^(BOOL finished) {
        completed = !completed;
        shouldUpdateCompletion = YES;
    }];
}

- (void)shrinkButton:(UIButton*)button withAmount:(int)amount {
    CGRect buttonRect = button.frame;
    buttonRect.size.height -= amount;
    [button setFrame:buttonRect];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    if (self.punchlistItem.identifier.length){
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem = createButton;
    }
}

- (IBAction)photoButtonTapped;
{
    UIActionSheet *actionSheet = nil;
    //[self doneEditing];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Choose Existing Photo", @"Take Photo", nil];
        [actionSheet showInView:self.view];
    } else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Choose Existing Photo", nil];
        [actionSheet showInView:self.view];
    }
}

- (void)existingPhotoButtonTapped:(UIButton*)button;
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Remove"
                                                    otherButtonTitles:@"Photo Gallery", nil];
    [actionSheet showInView:self.view];
    photoIdx = button.tag;
}

- (void)choosePhoto {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [vc setDelegate:self];
    [vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)takePhoto {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [vc setDelegate:self];
    [vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.scrollView setAlpha:0.0];
    [picker dismissViewControllerAnimated:YES completion:nil];
    BHPhoto *newPhoto = [[BHPhoto alloc] init];
    [newPhoto setImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [self.punchlistItem.photos addObject:newPhoto];
    [self redrawScrollView];
    [self saveImage:[self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]]];
}

- (UIImage *)fixOrientation:(UIImage*)image {
    
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (void)savePostToLibrary:(UIImage*)originalImage {
    NSString *albumName = @"BuildHawk";
    UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:0.5 orientation:UIImageOrientationUp];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
    [library addAssetsGroupAlbumWithName:albumName
                             resultBlock:^(ALAssetsGroup *group) {
                                 
                             }
                            failureBlock:^(NSError *error) {
                                NSLog(@"error adding album");
                            }];
    
    __block ALAssetsGroup* groupToAddTo;
    [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                   
                                   groupToAddTo = group;
                               }
                           }
                         failureBlock:^(NSError* error) {
                             NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                         }];
    
    [library writeImageToSavedPhotosAlbum:imageToSave.CGImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error.code == 0) {
            // try to get the asset
            [library assetForURL:assetURL
                     resultBlock:^(ALAsset *asset) {
                         // assign the photo to the album
                         [groupToAddTo addAsset:asset];
                     }
                    failureBlock:^(NSError* error) {
                        NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                    }];
        }
        else {
            NSLog(@"saved image failed.\nerror code %i\n%@", error.code, [error localizedDescription]);
        }
    }];
}

- (void)saveImage:(UIImage*)image {
    [self savePostToLibrary:image];
    if (self.punchlistItem.identifier.length){
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        [manager POST:[NSString stringWithFormat:@"%@/punchlist_items/photo",kApiBaseUrl] parameters:@{@"id":self.punchlistItem.identifier, @"photo[user_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"photo[project_id]":project.identifier, @"photo[source]":kWorklist, @"photo[company_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"save punchlist item photo response object: %@",responseObject);
            self.punchlistItem = [responseObject objectForKey:@"punchlist_item"];
            //[self.tableView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"failure posting image to API: %@",error.description);
        }];
    }
}

-(void)removePhoto {
    NSLog(@"should be removing photo with id: %i",photoIdx);
    BHPhoto *photoToRemove = [self.punchlistItem.photos objectAtIndex:photoIdx];
    if (photoToRemove.identifier.length) {
        [manager DELETE:[NSString stringWithFormat:@"%@/photos/%@",kApiBaseUrl,photoToRemove.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success removing photo");
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    }
    [self.punchlistItem.photos removeObjectAtIndex:photoIdx];
    [self redrawScrollView];
}

- (void)redrawScrollView {
    self.scrollView.delegate = self;
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.showsHorizontalScrollIndicator=NO;

    float imageSize;
    float space;
    if (iPad) {
        imageSize = 80;
        space = 4;
    } else if (iPhone5){
        imageSize = 56.0;
        space = 4.0;
    } else {
        imageSize = 40;
        space = 3;
    }

    int index = 0;
    for (BHPhoto *photo in self.punchlistItem.photos) {
        __weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.scrollView addSubview:imageButton];
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),4,imageSize, imageSize)];
        
        if (photo.url200.length){
            [imageButton setAlpha:0.0];
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url200] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
            }];
        } else if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
            [UIView animateWithDuration:.25 animations:^{
                [imageButton setAlpha:1.0];
            }];
        }
        
        imageButton.imageView.layer.cornerRadius = 3.0;
        [imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        [imageButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        imageButton.imageView.layer.shouldRasterize = YES;
        imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton setTag:[self.punchlistItem.photos indexOfObject:photo]];
        [imageButton addTarget:self action:@selector(existingPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        index++;
    }
    
    [self.view bringSubviewToFront:self.scrollView];
    [self.scrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    if (self.scrollView.isHidden) [self.scrollView setHidden:NO];
    
    if (self.punchlistItem.photos.count > 0){
        [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (iPad) {
                self.photoLabelButton.transform = CGAffineTransformMakeTranslation(-288, 0);
            } else if (iPhone5) {
                self.photoLabelButton.transform = CGAffineTransformMakeTranslation(-120, 0);
            } else {
                self.photoLabelButton.transform = CGAffineTransformMakeTranslation(-120, -30);
            }
        } completion:^(BOOL finished) {
            
        }];
    }
    
    [UIView animateWithDuration:.3 delay:.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.scrollView setAlpha:1.0];
    } completion:^(BOOL finished) {
        self.scrollView.layer.shouldRasterize = YES;
        self.scrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }];

}

- (void)showPhotoDetail {
    browserPhotos = [NSMutableArray new];
    for (BHPhoto *photo in self.punchlistItem.photos) {
        MWPhoto *mwPhoto;
        //if (photo.mimetype && [photo.mimetype isEqualToString:kPdf]){
        mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        //} else {
        //    idmPhoto = [IDMPhoto photoWithURL:[NSURL URLWithString:photo.orig]];
        //}
        [browserPhotos addObject:mwPhoto];
    }

    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0){
        browser.wantsFullScreenLayout = YES; // iOS 5 & 6 only: Decide if you want the photo browser full screen, i.e. whether the status bar is affected (defaults to YES)
    }
    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:photoIdx];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}

-(IBAction)assigneeButtonTapped{
    assigneeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assign this worklist item" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (BHUser *user in savedUser.coworkers) {
        [assigneeActionSheet addButtonWithTitle:user.fullname];
    }
    if (![self.assigneeButton.titleLabel.text isEqualToString:assigneePlaceholder])assigneeActionSheet.destructiveButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Remove assignee"];
    assigneeActionSheet.cancelButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Cancel"];
    [assigneeActionSheet showFromTabBar:self.tabBarController.tabBar];
}

-(IBAction)locationButtonTapped{
    locationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Location" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString *location in locationSet.allObjects) {
        [locationActionSheet addButtonWithTitle:location];
    }
    [locationActionSheet addButtonWithTitle:kAddOther];
    if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder])locationActionSheet.destructiveButtonIndex = [locationActionSheet addButtonWithTitle:@"Remove location"];
    locationActionSheet.cancelButtonIndex = [locationActionSheet addButtonWithTitle:@"Cancel"];
    [locationActionSheet showFromTabBar:self.tabBarController.tabBar];
}

-(void)updateItem {
    [SVProgressHUD showWithStatus:@"Updating item..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSString *strippedLocationString;
    if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder]){
        strippedLocationString = [[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""] stringByTrimmingCharactersInSet:
                                        [NSCharacterSet whitespaceCharacterSet]];
            if (strippedLocationString.length) [parameters setObject:strippedLocationString forKey:@"location"];
    }
    
    NSString *strippedAssigneeString;
    if (![self.assigneeButton.titleLabel.text isEqualToString:assigneePlaceholder]){
        strippedAssigneeString = [[self.assigneeButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Assigned: " withString:@""] stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];
        if (strippedAssigneeString.length) [parameters setObject:strippedAssigneeString forKey:@"assignee"];
    }
    
    [parameters setObject:self.punchlistItem.identifier forKey:@"id"];
    if (self.itemTextView.text.length) [parameters setObject:self.itemTextView.text forKey:@"body"];
    if (completed){
        [parameters setObject:kCompleted forKey:@"status"];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"punchlist_item[completed_by_user_id]"];
    } else {
        [parameters setObject:@"Not Completed" forKey:@"status"];
    }
    
    NSLog(@"parameters for updating item: %@",parameters);
    [manager PUT:[NSString stringWithFormat:@"%@/punchlist_items/%@", kApiBaseUrl, self.punchlistItem.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.navigationController popViewControllerAnimated:YES];
        [SVProgressHUD dismiss];
        NSLog(@"Success updating punchlist item: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        NSLog(@"Failed to update punchlist item: %@",error.description);
    }];
}

-(void)createItem {
    [SVProgressHUD showWithStatus:@"Adding item..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        NSString *strippedLocationString;
    if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder]){
        strippedLocationString = [[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""] stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];
        if (strippedLocationString.length) [parameters setObject:strippedLocationString forKey:@"location"];
    }
    NSString *strippedAssigneeString;
    if (![self.assigneeButton.titleLabel.text isEqualToString:assigneePlaceholder]){
        strippedAssigneeString = [[self.assigneeButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Assigned: " withString:@""] stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];
        if (strippedAssigneeString.length) [parameters setObject:strippedAssigneeString forKey:@"assignee"];
    }
    
    if (self.itemTextView.text) [parameters setObject:self.itemTextView.text forKey:@"body"];

    NSLog(@"parameters for creating item: %@",parameters);
    [manager POST:[NSString stringWithFormat:@"%@/punchlist_items", kApiBaseUrl] parameters:@{@"punchlist_item":parameters,@"project_id":project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating punchlist item: %@",responseObject);
        [SVProgressHUD dismiss];
        BHPunchlistItem *newItem = [[BHPunchlistItem alloc] initWithDictionary:[responseObject objectForKey:@"punchlist_item"]];
        NSLog(@"punchlist item id: %@",newItem.identifier);
        if (newItem.identifier){
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            [parameters setObject:newItem.identifier forKey:@"id"];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"photo[user_id]"];
            if (project.identifier.length) [parameters setObject:project.identifier forKey:@"photo[project_id]"];
            [parameters setObject:kWorklist forKey:@"photo[source]"];
            if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId])[parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"photo[company_id]"];
            
            for (BHPhoto *photo in self.punchlistItem.photos){
                NSData *imageData = UIImageJPEGRepresentation(photo.image, 0.5);
                NSLog(@"new photo for new report parameters: %@",parameters);
                [manager POST:[NSString stringWithFormat:@"%@/punchlist_items/photo",kApiBaseUrl] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                    [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
                } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSLog(@"save punchlist item photo response object: %@",responseObject);
                    //self.punchlistItem = [responseObject objectForKey:@"punchlist_item"];
                    //[self.tableView reloadData];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"failure posting image to API: %@",error.description);
                }];
            }
        }
        [self.navigationController popViewControllerAnimated:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to update punchlist item: %@",error.description);
    }];
}

/*-(void)sendComplete {
    NSDictionary *parameters = @{kcompleted:@{@"user":@{@"_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]}}};
    [manager PUT:[NSString stringWithFormat:@"%@/punchlist/complete/%@",kApiBaseUrl, self.punchlistItem.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        NSLog(@"success sending complete: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        NSLog(@"failure sending complete: %@",error.description);
    }];
}

-(void)uncomplete {
    NSDictionary *parameters = @{kcompleted:@{@"user":@{@"_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]}}};
    [manager PUT:[NSString stringWithFormat:@"%@/punchlist/uncomplete/%@",kApiBaseUrl, self.punchlistItem.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success sending incomplete: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure sending incomplete: %@",error.description);
    }];
}*/

- (void)textViewDidBeginEditing:(UITextView *)textView {
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
    [cancelButton setTitle:@"Cancel"];
    [[self navigationItem] setRightBarButtonItem:cancelButton];
    if ([textView.text isEqualToString:itemPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor darkGrayColor]];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length) {
        self.punchlistItem.body = textView.text;
    } else {
        [textView setText:itemPlaceholder];
        [textView setTextColor:[UIColor lightGrayColor]];
    }
    [self doneEditing];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (IBAction)placeCall:(id)sender{
    callActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to call?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (BHUser *user in savedUser.coworkers) {
        [callActionSheet addButtonWithTitle:user.fullname];
    }
    callActionSheet.cancelButtonIndex = [callActionSheet addButtonWithTitle:@"Cancel"];
    [callActionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (IBAction)placeText:(id)sender{
    MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
    if ([MFMessageComposeViewController canSendText]){
        viewController.messageComposeDelegate = self;
        [viewController setRecipients:nil];
        [self presentViewController:viewController animated:YES completion:^{
            
        }];
    }
}

- (IBAction)sendEmail:(id)sender {
    emailActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to email?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (BHUser *user in savedUser.coworkers) {
        [emailActionSheet addButtonWithTitle:user.fullname];
    }
    emailActionSheet.cancelButtonIndex = [emailActionSheet addButtonWithTitle:@"Cancel"];
    [emailActionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)call:(NSString*)phone {
    NSString *phoneNumber = [@"tel://" stringByAppendingString:phone];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
}


#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)sendMail:(NSString*)destinationEmail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.navigationBar.barStyle = UIBarStyleBlack;
        controller.mailComposeDelegate = self;
        //[controller setSubject:@""];
        [controller setToRecipients:@[destinationEmail]];
        if (controller) [self presentViewController:controller animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send mail on this device." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
    }
}
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {}
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent) {
        
    } else if (result == MessageComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your message. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == callActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:@"Cancel"]) {
            [callActionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            return;
        }
        for (BHUser *user in savedUser.coworkers){
            if ([user.fullname isEqualToString:buttonTitle] && user.phone1) {
                [self call:user.phone1];
                return;
            }
        }
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user may not have a phone number on file with BuildHawk" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else if (actionSheet == emailActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:@"Cancel"]) {
            [emailActionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            return;
        }
        for (BHUser *user in savedUser.coworkers){
            if ([user.fullname isEqualToString:buttonTitle]) {
                [self sendMail:user.email];
                return;
            }
        }
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user may not have an email address on file with BuildHawk" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove"]) {
        [self removePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Photo Gallery"]) {
        [self showPhotoDetail];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove assignee"]) {
        [self.assigneeButton setTitle:assigneePlaceholder forState:UIControlStateNormal];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove location"]) {
        [self.locationButton setTitle:locationPlaceholder forState:UIControlStateNormal];
    } else if (actionSheet == assigneeActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",[actionSheet buttonTitleAtIndex:buttonIndex]] forState:UIControlStateNormal];
    } else if (actionSheet == locationActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if (buttonTitle.length) {
            if ([buttonTitle isEqualToString:kAddOther]) {
                addOtherAlertView = [[UIAlertView alloc] initWithTitle:@"Add other personnel" message:@"Enter personnel name(s):" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
                addOtherAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [addOtherAlertView show];
            } else {
                [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",[actionSheet buttonTitleAtIndex:buttonIndex]] forState:UIControlStateNormal];
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addOtherAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            [self.locationButton setTitle:[[alertView textFieldAtIndex:0] text] forState:UIControlStateNormal];
            
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
