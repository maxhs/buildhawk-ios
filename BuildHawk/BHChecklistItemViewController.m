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
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import "Flurry.h"
#import <WSAssetPickerController/WSAssetPicker.h>
#import "BHPeoplePickerViewController.h"

@interface BHChecklistItemViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, WSAssetPickerControllerDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITextViewDelegate, UIScrollViewDelegate, MWPhotoBrowserDelegate> {
    NSMutableArray *photosArray;
    BOOL complete;
    BOOL emailBool;
    BOOL phoneBool;
    NSString *mainPhoneNumber;
    NSString *recipientEmail;
    UITextView *addCommentTextView;
    UIButton *doneButton;
    UIEdgeInsets tableViewInset;
    UIActionSheet *callActionSheet;
    UIActionSheet *emailActionSheet;
    AFHTTPRequestOperationManager *manager;
    UIScrollView *photoScrollView;
    NSDateFormatter *commentFormatter;
    UIBarButtonItem *saveButton;
    int removePhotoIdx;
    UIButton *takePhotoButton;
    NSMutableArray *browserPhotos;
    BOOL iPad;
    ALAssetsLibrary *library;
}
- (IBAction)updateChecklistItem;
@end

@implementation BHChecklistItemViewController

@synthesize item = _item;
@synthesize row = _row;
@synthesize savedUser = _savedUser;
@synthesize projectId = _projectId;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!photosArray) photosArray = [NSMutableArray array];
    if (_item.completed) complete = YES;
    else complete = NO;
    tableViewInset = self.tableView.contentInset;
    tableViewInset.top += 64;
    self.tableView.backgroundColor = kLightestGrayColor;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        iPad = YES;
    } else {
        iPad = NO;
    }
    library = [[ALAssetsLibrary alloc]init];
    if (!manager) manager = [AFHTTPRequestOperationManager manager];
    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateStyle:NSDateFormatterShortStyle];
    [commentFormatter setTimeStyle:NSDateFormatterShortStyle];
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(updateChecklistItem)];
    [[self navigationItem] setRightBarButtonItem:saveButton];
    [Flurry logEvent:@"Viewing checklist item"];
    [self loadItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(placeCall:) name:@"PlaceCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMail:) name:@"SendEmail" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"DeletePhoto" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadItem{
    [manager GET:[NSString stringWithFormat:@"%@/checklist_items/%@",kApiBaseUrl,_item.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting checklist item: %@",[responseObject objectForKey:@"checklist_item"]);
        [_item setComments:[BHUtilities commentsFromJSONArray:[[responseObject objectForKey:@"checklist_item"] objectForKey:@"comments"]]];
        [_item setPhotos:[BHUtilities photosFromJSONArray:[[responseObject objectForKey:@"checklist_item"] objectForKey:@"photos"]]];
        [_item setCategory:[[responseObject objectForKey:@"checklist_item"] objectForKey:@"category_name"]];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure getting checklist item: %@",error.description);
    }];
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
    else if (section == 4) return _item.comments.count;
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0){
        return _item.type;
    } else return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        BHChecklistMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell"];
        if (messageCell == nil) {
            messageCell = [[[NSBundle mainBundle] loadNibNamed:@"BHChecklistMessageCell" owner:self options:nil] lastObject];
        }
        [messageCell.messageTextView setText:_item.body];
        [messageCell.messageTextView setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];
        [messageCell.emailButton addTarget:self action:@selector(emailAction) forControlEvents:UIControlEventTouchUpInside];
        [messageCell.callButton addTarget:self action:@selector(callAction) forControlEvents:UIControlEventTouchUpInside];
        [messageCell.textButton addTarget:self action:@selector(sendText) forControlEvents:UIControlEventTouchUpInside];
        if (iPad) {
            [messageCell.callButton setHidden:YES];
            messageCell.emailButton.transform = CGAffineTransformMakeTranslation(275, 0);
            messageCell.textButton.transform = CGAffineTransformMakeTranslation(173, 0);
        }
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
                if ([_item.status isEqualToString:kCompleted]) {
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                [cell.textLabel setText:@"COMPLETED"];
                break;
            case 1:
                if ([_item.status isEqualToString:kInProgress]) {
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                [cell.textLabel setText:@"IN-PROGRESS"];
                break;
            case 2:
                if ([_item.status isEqualToString:kNotApplicable]) {
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
        takePhotoButton = photoCell.takePhotoButton;
        [photoCell.takePhotoButton addTarget:self action:@selector(photoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        return photoCell;
    } else if (indexPath.section == 3) {
        BHAddCommentCell *addCommentCell = [tableView dequeueReusableCellWithIdentifier:@"AddCommentCell"];
        if (addCommentCell == nil) {
            addCommentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddCommentCell" owner:self options:nil] lastObject];
        }
        [addCommentCell.messageTextView setText:kAddCommentPlaceholder];
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
        BHComment *comment = [_item.comments objectAtIndex:indexPath.row];
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
    if ([textView.text isEqualToString:kAddCommentPlaceholder]) {
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
        [textView setText:kAddCommentPlaceholder];
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
        [_item.comments addObject:comment];
        [self.tableView reloadData];
        NSDictionary *commentDict = @{@"checklist_item_id":_item.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"body":comment.body};
        [manager POST:[NSString stringWithFormat:@"%@/comments",kApiBaseUrl] parameters:@{@"comment":commentDict} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"failure creating a comment: %@",error.description);
        }];
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
    [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 49, 0)];
}

- (void)callAction{
    emailBool = NO;
    phoneBool = YES;
    callActionSheet = [[UIActionSheet alloc] initWithTitle:@"Place call:" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    [callActionSheet addButtonWithTitle:kCompanyUsers];
    [callActionSheet addButtonWithTitle:kSubcontractors];
    callActionSheet.cancelButtonIndex = [callActionSheet addButtonWithTitle:@"Cancel"];
    [callActionSheet showInView:self.view];
}

- (void)emailAction {
    emailBool = YES;
    phoneBool = NO;
    emailActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to email?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    [emailActionSheet addButtonWithTitle:kCompanyUsers];
    [emailActionSheet addButtonWithTitle:kSubcontractors];
    emailActionSheet.cancelButtonIndex = [emailActionSheet addButtonWithTitle:@"Cancel"];
    [emailActionSheet showInView:self.view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    BHPeoplePickerViewController *vc = [segue destinationViewController];
    if (phoneBool) {
        [vc setPhone:YES];
    } else if (emailBool) {
        [vc setEmail:YES];
    }
    if ([segue.identifier isEqualToString:@"SubPicker"]) {
        [vc setCountNotNeeded:YES];
        [vc setSubArray:_savedUser.subcontractors];
    } else if ([segue.identifier isEqualToString:@"PeoplePicker"]) {
        [vc setUserArray:_savedUser.coworkers];
    }
}

- (void)placeCall:(NSNotification*)notification {
    if (!iPad){
        NSString *number = [notification.userInfo objectForKey:@"number"];
        if (number != nil && number.length){
            NSString *phoneNumber = [@"tel://" stringByAppendingString:number];
            NSString *phoneString = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
            phoneString= [phoneString stringByReplacingOccurrencesOfString:@"(" withString:@""];
            phoneString= [phoneString stringByReplacingOccurrencesOfString:@")" withString:@""];
            phoneString= [phoneString stringByReplacingOccurrencesOfString:@"-" withString:@""];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneString]];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We don't have a phone number for this contact." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }
}

#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)sendMail:(NSNotification*)notification {
    NSString *destinationEmail = [notification.userInfo objectForKey:@"email"];
    if (destinationEmail && destinationEmail.length){
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.navigationBar.barStyle = UIBarStyleBlack;
            controller.mailComposeDelegate = self;
            [controller setSubject:[NSString stringWithFormat:@"%@",_item.body]];
            [controller setToRecipients:@[destinationEmail]];
            if (controller) [self presentViewController:controller animated:YES completion:nil];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send mail on this device." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
        }
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Sorry, we don't have an email address for this contact." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
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

- (void)existingPhotoButtonTapped:(UIButton*)button;
{
    [self showPhotoDetail:button.tag];
    removePhotoIdx = button.tag;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == callActionSheet || actionSheet == emailActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:@"Cancel"]) {
            [callActionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            return;
        } else if ([buttonTitle isEqualToString:kCompanyUsers]) {
            [self performSegueWithIdentifier:@"PeoplePicker" sender:nil];
        } else if ([buttonTitle isEqualToString:kSubcontractors]) {
            [self performSegueWithIdentifier:@"SubPicker" sender:nil];
        }
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove"]) {
        [self removeConfirm];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Photo Gallery"]) {
        [self showPhotoDetail:removePhotoIdx];
    }
}

- (void)choosePhoto {
    WSAssetPickerController *controller = [[WSAssetPickerController alloc] initWithAssetsLibrary:library];
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:NULL];
}

- (void)takePhoto {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [vc setDelegate:self];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    BHPhoto *newPhoto = [[BHPhoto alloc] init];
    [newPhoto setImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [self saveImage:[self fixOrientation:newPhoto.image]];
    [_item.photos addObject:newPhoto];
    [self.tableView reloadData];
}

- (void)assetPickerControllerDidCancel:(WSAssetPickerController *)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)assetPickerController:(WSAssetPickerController *)sender didFinishPickingMediaWithAssets:(NSArray *)assets
{
    [self dismissViewControllerAnimated:YES completion:^{
        for (id asset in assets) {
            if (asset != nil) {
                
                ALAssetRepresentation* representation = [asset defaultRepresentation];
                
                // Retrieve the image orientation from the ALAsset
                UIImageOrientation orientation = UIImageOrientationUp;
                NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
                if (orientationValue != nil) {
                    orientation = [orientationValue intValue];
                }
                
                CGFloat scale  = 1;
                UIImage* image = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                     scale:scale orientation:orientation];
                BHPhoto *newPhoto = [[BHPhoto alloc] init];
                [newPhoto setImage:[self fixOrientation:image]];
                [_item.photos addObject:newPhoto];
                [self saveImage:newPhoto.image];
            }
        }
        [self.tableView reloadData];
    }];
}

- (UIImage *)fixOrientation:(UIImage*)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
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
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }

    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (void)savePostToLibrary:(UIImage*)originalImage {
    NSString *albumName = @"BuildHawk";
    UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:0.5 orientation:UIImageOrientationUp];
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

-(void)removeConfirm {
    [[[UIAlertView alloc] initWithTitle:@"Please Confirm" message:@"Are you sure you want to delete this photo?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil] show];
}

-(void)removePhoto:(NSNotification*)notification {

    NSString *photoIdentifier = [notification.userInfo objectForKey:@"photoId"];
    [SVProgressHUD showWithStatus:@"Deleting photo..."];
    [_item.photos enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[(BHPhoto*)obj identifier] isEqualToString:photoIdentifier]){
            NSLog(@"should be removing photo at index: %i",idx);
            BHPhoto *photoToRemove = [_item.photos objectAtIndex:idx];
            [manager DELETE:[NSString stringWithFormat:@"%@/photos/%@",kApiBaseUrl,[notification.userInfo objectForKey:@"photoId"]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [SVProgressHUD dismiss];
                [_item.photos removeObject:photoToRemove];
                [self redrawScrollView:takePhotoButton];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
            }];
            *stop = YES;
        }
    }];
}

- (void)saveImage:(UIImage*)image {
    [self savePostToLibrary:image];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    [manager POST:[NSString stringWithFormat:@"%@/checklist_items/photo/",kApiBaseUrl] parameters:@{@"id":_item.identifier, @"photo[user_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"photo[project_id]":_projectId, @"photo[source]":@"Checklist",@"photo[phase]":_item.category, @"photo[company_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"save image response object: %@",responseObject);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklist" object:nil userInfo:@{@"category":_item.category}];
        _item.photos = [BHUtilities photosFromJSONArray:[[responseObject objectForKey:@"checklist_item"] objectForKey:@"photos"]];
        [self redrawScrollView:takePhotoButton];
        //[self.tableView reloadData];
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
    
    for (BHPhoto *photo in _item.photos) {
        __weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.url200.length){
            [imageButton setAlpha:0.0];
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url200] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
                [imageButton setTitle:photo.identifier forState:UIControlStateNormal];
            }];
        } else if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        }
        [imageButton setTag:[_item.photos indexOfObject:photo]];
        [imageButton.titleLabel setHidden:YES];
        imageButton.imageView.layer.cornerRadius = 2.0;
        [imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        [imageButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        imageButton.layer.shouldRasterize = YES;
        imageButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton setFrame:CGRectMake((space+imageSize)*index,15,imageSize, imageSize)];
        [imageButton addTarget:self action:@selector(existingPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [photoScrollView addSubview:imageButton];
        index++;
    }

    [photoButton setFrame:CGRectMake((space+imageSize)*index,15,imageSize, imageSize)];
    [photoScrollView addSubview:photoButton];
    
    [photoScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    [photoScrollView setContentOffset:CGPointMake(-space*2, 0) animated:NO];
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
    [parameters setObject:_item.identifier forKey:@"id"];
    if (_item.status) [parameters setObject:_item.status forKey:@"status"];
    if (_item.completed) [parameters setObject:@"true" forKey:@"completed"];
    
        NSMutableArray *commentArray = [NSMutableArray arrayWithCapacity:_item.comments.count];
        for (BHComment *comment in _item.comments) {
            NSMutableDictionary *commentDict = [NSMutableDictionary dictionary];
            if (comment.identifier) [commentDict setObject:comment.identifier forKey:@"_id"];
            if (comment.body) [commentDict setObject:comment.body forKey:@"body"];
            [commentArray addObject:commentDict];
        }
        [parameters setObject:commentArray forKey:@"comments"];
    [SVProgressHUD showWithStatus:@"Updating item..."];
    [manager PUT:[NSString stringWithFormat:@"%@/checklist_items/%@", kApiBaseUrl,_item.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success updating checklist item %@",responseObject);
        BHChecklistItem *updatedItem = [[BHChecklistItem alloc] initWithDictionary:[responseObject objectForKey:@"checklist_item"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklist" object:nil userInfo:@{@"category":updatedItem.category}];
        [self.navigationController popViewControllerAnimated:YES];
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure updating checklist item: %@",error.description);
        [SVProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while updating this item. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)showPhotoDetail:(int)idx {
    browserPhotos = [NSMutableArray new];
    for (BHPhoto *photo in _item.photos) {
        MWPhoto *mwPhoto;
        mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setOriginalURL:[NSURL URLWithString:photo.orig]];
        [mwPhoto setPhotoId:photo.identifier];
        [browserPhotos addObject:mwPhoto];
    }
    
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
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

    [browser setCurrentPhotoIndex:idx];
    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                if ([_item.status isEqualToString:kCompleted]){
                    _item.status = nil;
                    _item.completed = NO;
                } else {
                    [_item setStatus:kCompleted];
                    _item.completed = YES;
                }
                break;
            case 1:
                if ([_item.status isEqualToString:kInProgress]){
                    [_item setStatus:nil];
                } else {
                    [_item setStatus:kInProgress];
                }
                
                break;
            case 2:
                if ([_item.status isEqualToString:kNotApplicable]){
                    [_item setStatus:nil];
                } else {
                    [_item setStatus:kNotApplicable];
                }
                break;
            default:
                break;
        }
        [self.tableView reloadData];
    }
}

- (void)back {
    
}

@end
