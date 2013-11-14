//
//  BHChecklistItemViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHChecklistItemViewController.h"
#import "BHChecklistItem.h"
#import "Constants.h"
#import "BHCommentCell.h"
#import "BHAddCommentCell.h"
#import "BHChecklistMessageCell.h"
#import "BHListItemPhotoCell.h"
#import <MessageUI/MessageUI.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "BHTabBarViewController.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>
#import "Flurry.h"

static NSString *addCommentPlaceholder = @"Add comment...";
@interface BHChecklistItemViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITextViewDelegate, UIScrollViewDelegate> {
    NSMutableArray *photosArray;
    BOOL complete;
    NSString *mainPhoneNumber;
    NSString *recipientEmail;
    BOOL text;
    BOOL phone;
    UITextView *addCommentTextView;
    UIButton *doneButton;
    UIEdgeInsets tableViewInset;
    UIActionSheet *callActionSheet;
    UIActionSheet *emailActionSheet;
    BHProject *project;
    AFHTTPRequestOperationManager *manager;
    UIScrollView *photoScrollView;
    NSDateFormatter *commentFormatter;
    UIBarButtonItem *saveButton;
}
- (IBAction)updateChecklistItem;
@end

@implementation BHChecklistItemViewController

@synthesize item;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!photosArray) photosArray = [NSMutableArray array];
    if (self.item.completed) complete = YES;
    else complete = NO;
    tableViewInset = self.tableView.contentInset;
    self.tableView.backgroundColor = kLightestGrayColor;
    project = [(BHTabBarViewController*)self.tabBarController project];
    if (!manager) manager = [AFHTTPRequestOperationManager manager];
    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateStyle:NSDateFormatterShortStyle];
    [commentFormatter setTimeStyle:NSDateFormatterShortStyle];
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(updateChecklistItem)];
    [[self navigationItem] setRightBarButtonItem:saveButton];
    [Flurry logEvent:@"Viewing checklist item"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    else if (section == 1) return 3;
    else if (section == 2) return 1;
    else if (section == 3) return 1;
    else if (section == 4) return self.item.comments.count;
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0){
        return self.item.type;
    } else return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        BHChecklistMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell"];
        if (messageCell == nil) {
            messageCell = [[[NSBundle mainBundle] loadNibNamed:@"BHChecklistMessageCell" owner:self options:nil] lastObject];
        }
        [messageCell.messageTextView setText:self.item.name];
        [messageCell.messageTextView setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];
        [messageCell.emailButton addTarget:self action:@selector(emailAction) forControlEvents:UIControlEventTouchUpInside];
        [messageCell.callButton addTarget:self action:@selector(callAction) forControlEvents:UIControlEventTouchUpInside];
        [messageCell.textButton addTarget:self action:@selector(sendText) forControlEvents:UIControlEventTouchUpInside];
        return messageCell;
    } else if (indexPath.section == 1) {
        static NSString *CellIdentifier = @"ActionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        UIView *selectecBackgroundColor = [[UIView alloc] init];
        [selectecBackgroundColor setBackgroundColor:kDarkGrayColor];
        cell.selectedBackgroundView = selectecBackgroundColor;
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        switch (indexPath.row) {
            case 0:
                if ([self.item.status isEqualToString:kCompleted]) {
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                [cell.textLabel setText:@"COMPLETED"];
                break;
            case 1:
                if ([self.item.status isEqualToString:kInProgress]) {
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                [cell.textLabel setText:@"IN-PROGRESS"];
                break;
            case 2:
                if ([self.item.status isEqualToString:kNotApplicable]) {
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                [cell.textLabel setText:@"NOT APPLICABLE"];
                break;
                
            default:
                break;
        }
        [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:18]];
        return cell;
    } else if (indexPath.section == 2) {
        BHListItemPhotoCell *photoCell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        if (photoCell == nil) {
            photoCell = [[[NSBundle mainBundle] loadNibNamed:@"BHListItemPhotoCell" owner:self options:nil] lastObject];
        }
        photoScrollView = photoCell.scrollView;
        [self redrawScrollView:photoCell.takePhotoButton];
        [photoCell.takePhotoButton addTarget:self action:@selector(photoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        return photoCell;
    } else if (indexPath.section == 3) {
        BHAddCommentCell *addCommentCell = [tableView dequeueReusableCellWithIdentifier:@"AddCommentCell"];
        if (addCommentCell == nil) {
            addCommentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddCommentCell" owner:self options:nil] lastObject];
        }
        [addCommentCell.messageTextView setText:addCommentPlaceholder];
        addCommentTextView = addCommentCell.messageTextView;
        addCommentTextView.delegate = self;
        
        [addCommentCell.doneButton addTarget:self action:@selector(submitComment) forControlEvents:UIControlEventTouchUpInside];
        [addCommentCell.doneButton setBackgroundColor:kSelectBlueColor];
        addCommentCell.doneButton.layer.cornerRadius = 4.f;
        addCommentCell.doneButton.clipsToBounds = YES;
        doneButton = addCommentCell.doneButton;
        return addCommentCell;
    } else {
        BHCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
        if (commentCell == nil) {
            commentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHCommentCell" owner:self options:nil] lastObject];
        }
        BHComment *comment = [self.item.comments objectAtIndex:indexPath.row];
        [commentCell.messageTextView setText:comment.body];
        if (comment.createdOnString.length){
            [commentCell.timeLabel setText:comment.createdOnString];
        } else {
            [commentCell.timeLabel setText:[commentFormatter stringFromDate:comment.createdOn]];
        }
        [commentCell.nameLabel setText:comment.user.fullname];
        return commentCell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 180;
            break;
        case 1:
            return 54;
            break;
        case 2:
            return 100;
            break;
        default:
            return 80;
            break;
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    UIEdgeInsets tempInset = tableViewInset;
    tempInset.bottom += 216;
    self.tableView.contentInset = tempInset;
    if ([textView.text isEqualToString:addCommentPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor darkGrayColor]];
    }
    [UIView animateWithDuration:.25 animations:^{
        doneButton.alpha = 1.0;
    }];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
    [cancelButton setTitle:@"Cancel"];
    [[self navigationItem] setRightBarButtonItem:cancelButton];
}


-(void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length) {
        addCommentTextView = textView;
    } else {
        [textView setText:addCommentPlaceholder];
        [textView setTextColor:[UIColor colorWithWhite:.75 alpha:1.0]];
    }
    [self doneEditing];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)thisText {
    if ([thisText isEqualToString:@"\n"]) {
        if (textView.text.length) {
            [self submitComment];
            [self doneEditing];
        }
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)submitComment {
    if (addCommentTextView.text.length) {
        BHComment *comment = [[BHComment alloc] init];
        comment.body = addCommentTextView.text;
        comment.createdOnString = @"Just now";
        User *user = [(BHTabBarViewController*) self.tabBarController user];
        comment.user = [[BHUser alloc] init];
        comment.user.fullname = user.fullname;
        [self.item.comments addObject:comment];
        [self.tableView reloadData];
    }
    
    [self doneEditing];
}

- (void)doneEditing {
    [addCommentTextView resignFirstResponder];
    [addCommentTextView setText:@""];
    [self.view endEditing:YES];
    [UIView animateWithDuration:.25 animations:^{
        doneButton.alpha = 0.0;
    }];
    self.navigationItem.rightBarButtonItem = saveButton;
    //self.tableView.contentInset = tableViewInset;
}

- (void)callAction{
    callActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to call?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (BHUser *user in project.users) {
        [callActionSheet addButtonWithTitle:user.fullname];
    }
    callActionSheet.cancelButtonIndex = [callActionSheet addButtonWithTitle:@"Cancel"];
    [callActionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)emailAction {
    emailActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to email?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (BHUser *user in project.users) {
        [emailActionSheet addButtonWithTitle:user.fullname];
    }
    emailActionSheet.cancelButtonIndex = [emailActionSheet addButtonWithTitle:@"Cancel"];
    [emailActionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)placeCall:(NSString*)number {
    NSString *phoneNumber = [@"tel://" stringByAppendingString:number];
    NSString *phoneString = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    phoneString= [phoneString stringByReplacingOccurrencesOfString:@"(" withString:@""];
    phoneString= [phoneString stringByReplacingOccurrencesOfString:@")" withString:@""];
    phoneString= [phoneString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneString]];
}

#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)sendMail:(NSString*)destinationEmail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.navigationBar.barStyle = UIBarStyleBlack;
        controller.mailComposeDelegate = self;
        [controller setSubject:[NSString stringWithFormat:@"%@",self.item.type]];
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

- (void)sendText {
    MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
    if ([MFMessageComposeViewController canSendText]){
        viewController.messageComposeDelegate = self;
        [viewController setRecipients:nil];
        [self presentViewController:viewController animated:YES completion:^{
            
        }];
    }
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


- (void)photoButtonTapped;
{
    UIActionSheet *actionSheet = nil;

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

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == callActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:@"Cancel"]) {
            [callActionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            return;
        }
        for (BHUser *user in project.users){
            if ([user.fullname isEqualToString:buttonTitle] && user.phone1) {
                [self placeCall:user.phone1];
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
        for (BHUser *user in project.users){
            if ([user.fullname isEqualToString:buttonTitle]) {
                [self sendMail:user.email];
                return;
            }
        }
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user may not have an email address on file with BuildHawk" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove Photo"]) {
        [self removePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
    }
}

- (void)choosePhoto {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [vc setDelegate:self];
    //[vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)takePhoto {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [vc setDelegate:self];
    //[vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    BHPhoto *newPhoto = [[BHPhoto alloc] init];
    [newPhoto setImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [self saveImage:[self fixOrientation:newPhoto.image]];
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

-(void)removePhoto {
    [self.item.photos removeLastObject];
    /*if (self.item.photos.count == 0){
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
    }*/
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
        [self.item.photos addObject:newPhoto];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure posting image to filepicker: %@",error.description);
    }];
}

- (void)redrawScrollView:(UIButton*)photoButton {
    photoScrollView.delegate = self;
    [photoScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    photoScrollView.showsHorizontalScrollIndicator = NO;
    if (photoScrollView.isHidden) [photoScrollView setHidden:NO];
    float imageSize = 70.0;
    float space = 5.0;
    int index = 0;
    
    for (BHPhoto *photo in self.item.photos) {
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
        imageButton.imageView.layer.cornerRadius = 3.0;
        [imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        [imageButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        imageButton.layer.shouldRasterize = YES;
        imageButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton setFrame:CGRectMake((space+imageSize)*index,15,imageSize, imageSize)];
        [imageButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
        [photoScrollView addSubview:imageButton];
        index++;
    }

    [photoButton setFrame:CGRectMake((space+imageSize)*index,15,imageSize, imageSize)];
    [photoScrollView addSubview:photoButton];
    
    [photoScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    [photoScrollView setContentOffset:CGPointMake(-space, 0) animated:NO];
    [UIView animateWithDuration:.3 delay:.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [photoScrollView setAlpha:1.0];
    } completion:^(BOOL finished) {
        photoScrollView.layer.shouldRasterize = YES;
        photoScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }];
}

- (IBAction)updateChecklistItem {
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:self.item.identifier forKey:@"_id"];
    if (self.item.status) [parameters setObject:self.item.status forKey:@"status"];
    if (self.item.completed) [parameters setObject:@"true" forKey:@"completed"];
    if (self.item.photos.count) {
        NSMutableArray *photoArray = [NSMutableArray arrayWithCapacity:self.item.photos.count];
        for (BHPhoto *photo in self.item.photos) {
            NSMutableDictionary *photoDict = [NSMutableDictionary dictionary];
            if (photo.identifier) [photoDict setObject:photo.identifier forKey:@"_id"];
            if (photo.url) [photoDict setObject:photo.url forKey:@"url"];
            if (photo.photoSize) [photoDict setObject:photo.photoSize forKey:@"size"];
            if (photo.mimetype) [photoDict setObject:photo.mimetype forKey:@"type"];
            [photoArray addObject:photoDict];
        }
        [parameters setObject:photoArray forKey:@"photos"];
    }
    if (self.item.comments){
        NSMutableArray *commentArray = [NSMutableArray arrayWithCapacity:self.item.comments.count];
        for (BHComment *comment in self.item.comments) {
            NSMutableDictionary *commentDict = [NSMutableDictionary dictionary];
            if (comment.identifier) [commentDict setObject:comment.identifier forKey:@"_id"];
            if (comment.body) [commentDict setObject:comment.body forKey:@"body"];
            [commentArray addObject:commentDict];
        }
        [parameters setObject:commentArray forKey:@"comments"];
    }
    [manager PUT:[NSString stringWithFormat:@"%@/checklist", kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success updating checklist item %@",responseObject);
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure updating checklist item: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while updating this item. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)showPhotoDetail:(id)sender {
    NSMutableArray *tempPhotos = [NSMutableArray new];
    for (BHPhoto *photo in self.item.photos) {
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

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                [self.item setStatus:kCompleted];
                self.item.completed = YES;
                break;
            case 1:
                [self.item setStatus:kInProgress];
                break;
            case 2:
                [self.item setStatus:kNotApplicable];
                break;
            default:
                break;
        }
    }
}

@end
