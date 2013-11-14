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
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>
#import "Flurry.h"

static NSString *assigneePlaceholder = @"Assign this item";
typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHPunchlistItemViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIScrollViewDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
    BOOL iPhone5;
    BOOL iPad;
    BOOL completed;
    BOOL shouldUpdateCompletion;
    UIActionSheet *assigneeActionSheet;
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *updatePhotos;
    UIActionSheet *emailActionSheet;
    UIActionSheet *callActionSheet;
    UIBarButtonItem *saveButton;
}
- (IBAction)assigneeButtonTapped;
- (IBAction)locationButtonTapped;
- (IBAction)placeText:(id)sender;
- (IBAction)placeCall:(id)sender;
- (IBAction)sendEmail:(id)sender;
@end

@implementation BHPunchlistItemViewController

@synthesize punchlistItem, photos, assignees;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSLog(@"it's an ipad");
        iPad = YES;
    } else if ([UIScreen mainScreen].bounds.size.height == 568) {
        iPhone5 = YES;
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
        self.photoLabelButton.transform = CGAffineTransformMakeTranslation(0, -30);
        self.locationButton.transform = CGAffineTransformMakeTranslation(0, -50);
        self.assigneeButton.transform = CGAffineTransformMakeTranslation(0, -70);
        self.scrollView.transform = CGAffineTransformMakeTranslation(0, 56);
    }
    if (self.punchlistItem.createdPhotos.count > 0 || self.punchlistItem.completedPhotos.count > 0){
        self.photos = self.punchlistItem.createdPhotos;
        [self.photos addObjectsFromArray:self.punchlistItem.completedPhotos];
        [self redrawScrollView];
    } else {
        self.photos = [NSMutableArray array];
    }
    if (!updatePhotos) updatePhotos = [NSMutableArray array];
    [self dontDeletePhotos];
    if (!manager) {
        manager = [AFHTTPRequestOperationManager manager];
        [manager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    }
	[self.completionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self addBorderTreatement:self.photoButton];
    [self.photoButton addTarget:self action:@selector(photoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addBorderTreatement:self.locationButton];
    [self addBorderTreatement:self.assigneeButton];
    
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(updateItem)];
    [[self navigationItem] setRightBarButtonItem:saveButton];
    
    if (self.punchlistItem.completedOn) {
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
    [Flurry logEvent:@"Viewing punchlist item"];
}

- (void)dontDeletePhotos {
    for (BHPhoto *photo in self.punchlistItem.createdPhotos) {
        [updatePhotos addObject:@{@"_id":photo.identifier}];
    }
    for (BHPhoto *photo in self.punchlistItem.completedPhotos) {
        [updatePhotos addObject:@{@"_id":photo.identifier}];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.punchlistItem.location) {
        [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",self.punchlistItem.location] forState:UIControlStateNormal];
        [self.locationButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
    
    if (self.punchlistItem.name) {
        [self.itemTextView setText:self.punchlistItem.name];
    } else {
        [self.itemTextView setTextColor:[UIColor lightGrayColor]];
    }
    
    if (self.punchlistItem.assignees.count) {
        NSLog(@"There are assignees");
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
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (IBAction)photoButtonTapped;
{
    UIActionSheet *actionSheet = nil;
    //[self doneEditing];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:photos.count ? @"Remove Last Photo" : nil
                                         otherButtonTitles:@"Choose Existing Photo", @"Take Photo", nil];
        [actionSheet showInView:self.view];
    } else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:photos.count ? @"Remove Last Photo" : nil
                                         otherButtonTitles:@"Choose Existing Photo", nil];
        [actionSheet showInView:self.view];
    }
    
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
    [self saveImage:[self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]]];
    
    /*if (self.photos.count == 1){
         [self.photoLabelButton setTitle:@"1 photo added" forState:UIControlStateNormal];
    } else {
        [self.photoLabelButton setTitle:[NSString stringWithFormat:@"%i photos added", self.photos.count] forState:UIControlStateNormal];
    }*/
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
    NSDictionary *parameters = @{@"apikey":kFilepickerApiKey,@"filename":@"image.jpg",@"storePath":@"upload/"};
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    [manager POST:[NSString stringWithFormat:@"%@",kFilepickerBaseUrl] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"fileUpload" fileName:@"image.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BHPhoto *newPhoto = [[BHPhoto alloc] init];
        NSDictionary *tempDict = [[responseObject objectForKey:@"data"] firstObject];
        newPhoto.mimetype = [tempDict valueForKeyPath:@"data.type"];
        newPhoto.photoSize = [tempDict valueForKeyPath:@"data.size"];
        newPhoto.key = [tempDict valueForKeyPath:@"data.key"];
        newPhoto.url = [tempDict objectForKey:@"url"];
        newPhoto.filename =  [tempDict valueForKeyPath:@"data.filename"];
        [self.photos addObject:newPhoto];
        [self redrawScrollView];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure posting image to filepicker: %@",error.description);
    }];
}

-(void)removePhoto {
    [self.photos removeLastObject];
    if (self.photos.count == 0){
        [UIView animateWithDuration:.35 delay:.35 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.photoLabelButton.transform = CGAffineTransformIdentity;
            [self.scrollView setAlpha:0.0];
            [self.photoLabelButton setTitle:@"Add Photo" forState:UIControlStateNormal];
        } completion:^(BOOL finished) {
            [self.scrollView setHidden:YES];
        }];
    } else {
        [UIView animateWithDuration:.35 delay:.35 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (self.photos.count == 1){
                [self.photoLabelButton setTitle:@"1 photo added" forState:UIControlStateNormal];
            } else {
                [self.photoLabelButton setTitle:[NSString stringWithFormat:@"%i photos added", self.photos.count] forState:UIControlStateNormal];
            }
        } completion:^(BOOL finished) {
        }];
    }
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
    
    for (BHPhoto *photo in self.photos) {
        __weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.url200.length){
            [imageButton setAlpha:0.0];
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url200] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
            }];
        } else if (photo.url.length){
            [imageButton setAlpha:0.0];
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
            }];
        } else {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        }
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),4,imageSize, imageSize)];
        imageButton.imageView.layer.cornerRadius = 3.0;
        [imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        [imageButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        imageButton.imageView.layer.shouldRasterize = YES;
        imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:imageButton];
        index++;
    }
    
    [self.view bringSubviewToFront:self.scrollView];
    [self.scrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    if (self.scrollView.isHidden) [self.scrollView setHidden:NO];
    
    if (self.photos.count > 0){
        [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (iPad) {
                self.photoLabelButton.transform = CGAffineTransformMakeTranslation(-288, 0);
            } else if (iPhone5) {
                self.photoLabelButton.transform = CGAffineTransformMakeTranslation(-98, 0);
            } else {
                self.photoLabelButton.transform = CGAffineTransformMakeTranslation(-98, -30);
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

- (void)showPhotoDetail:(id)sender {
    NSMutableArray *tempPhotos = [NSMutableArray new];
    for (BHPhoto *photo in self.photos) {
        IDMPhoto *idmPhoto;
        if (photo.orig.length){
            idmPhoto = [IDMPhoto photoWithURL:[NSURL URLWithString:photo.orig]];
        } else {
            idmPhoto = [IDMPhoto photoWithURL:[NSURL URLWithString:photo.url]];
        }
        [tempPhotos addObject:idmPhoto];
    }
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:tempPhotos];
    [self presentViewController:browser animated:YES completion:^{
        
    }];
}

-(IBAction)assigneeButtonTapped{
    assigneeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assign this worklist item" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (BHUser *user in self.project.users) {
        [assigneeActionSheet addButtonWithTitle:user.fullname];
    }
    if (![self.assigneeButton.titleLabel.text isEqualToString:assigneePlaceholder])assigneeActionSheet.destructiveButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Remove assignee"];
    assigneeActionSheet.cancelButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Cancel"];
    [assigneeActionSheet showFromTabBar:self.tabBarController.tabBar];
    
}

-(IBAction)locationButtonTapped{
    NSLog(@"Location button tapped");
}

-(void)updateItem {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (completed && shouldUpdateCompletion) {
        parameters = [@{@"_id":self.punchlistItem.identifier, @"name":self.itemTextView.text,@"location":[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""], @"completed":@{@"photos":updatePhotos}} mutableCopy];
    } else {
        parameters = [@{@"_id":self.punchlistItem.identifier, @"name":self.itemTextView.text,@"location":[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""], @"created":@{@"photos":updatePhotos}} mutableCopy];
    }
    if (self.photos.count) {
        NSMutableArray *photoArray = [NSMutableArray arrayWithCapacity:self.photos.count];
        for (BHPhoto *photo in self.photos) {
            NSMutableDictionary *photoDict = [NSMutableDictionary dictionary];
            if (photo.identifier) [photoDict setObject:photo.identifier forKey:@"_id"];
            if (photo.url) [photoDict setObject:photo.url forKey:@"url"];
            if (photo.photoSize) [photoDict setObject:photo.photoSize forKey:@"size"];
            if (photo.mimetype) [photoDict setObject:photo.mimetype forKey:@"type"];
            [photoArray addObject:photoDict];
        }
        [parameters setObject:@{@"photos":photoArray} forKey:@"created"];
    }
    NSLog(@"Parameters for updating item: %@",parameters);
    [manager PUT:[NSString stringWithFormat:@"%@/punchlist/%@", kApiBaseUrl, self.punchlistItem.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completed && shouldUpdateCompletion) [self sendComplete];
        else if (shouldUpdateCompletion) [self uncomplete];
        else [SVProgressHUD dismiss];
        [self.navigationController popViewControllerAnimated:YES];
        NSLog(@"Success updating punchlist item: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to update punchlist item: %@",error.description);
    }];
}

-(void)sendComplete {
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
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
    [cancelButton setTitle:@"Cancel"];
    [[self navigationItem] setRightBarButtonItem:cancelButton];
}

-(void)textViewDidEndEditing:(UITextView *)textView {
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
    for (BHUser *user in self.project.users) {
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
    for (BHUser *user in self.project.users) {
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
        for (BHUser *user in self.project.users){
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
        for (BHUser *user in self.project.users){
            if ([user.fullname isEqualToString:buttonTitle]) {
                [self sendMail:user.email];
                return;
            }
        }
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user may not have an email address on file with BuildHawk" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove Last Photo"]) {
        [self removePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove assignee"]) {
        [self.assigneeButton setTitle:assigneePlaceholder forState:UIControlStateNormal];
    } else if (actionSheet == assigneeActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",[actionSheet buttonTitleAtIndex:buttonIndex]] forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
