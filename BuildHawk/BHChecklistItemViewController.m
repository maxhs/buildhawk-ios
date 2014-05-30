//
//  BHChecklistItemViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHChecklistItemViewController.h"
#import "ChecklistItem.h"
#import "ChecklistItem+helper.h"
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
#import "UIButton+WebCache.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MWPhotoBrowser.h"
#import "Flurry.h"
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#import "BHPersonnelPickerViewController.h"
#import "Project.h"
#import "BHAppDelegate.h"
#import "Comment+helper.h"

@interface BHChecklistItemViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, CTAssetsPickerControllerDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITextViewDelegate, UIScrollViewDelegate, MWPhotoBrowserDelegate> {
    NSMutableArray *photosArray;
    BOOL emailBool;
    BOOL phoneBool;
    BOOL saveToLibrary;
    BOOL shouldSave;
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
    UIView *photoButtonContainer;
    NSMutableArray *browserPhotos;
    BOOL iPad;
    ALAssetsLibrary *library;
    Project *savedProject;
    NSIndexPath *indexPathForDeletion;
}

@end

@implementation BHChecklistItemViewController

@synthesize item = _item;
@synthesize row = _row;
@synthesize project = _project;

- (void)viewDidLoad
{
    [super viewDidLoad];
    photosArray = [NSMutableArray array];
    tableViewInset = self.tableView.contentInset;
    tableViewInset.top += 64;
    self.tableView.backgroundColor = kLightestGrayColor;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        iPad = YES;
    } else {
        iPad = NO;
    }
    library = [[ALAssetsLibrary alloc]init];
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];

    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(updateChecklistItem:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [Flurry logEvent:@"Viewing checklist item"];
    [self loadItem];

    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateStyle:NSDateFormatterShortStyle];
    [commentFormatter setTimeStyle:NSDateFormatterShortStyle];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(placeCall:) name:@"PlaceCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMail:) name:@"SendEmail" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];

    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadItem{
    [manager GET:[NSString stringWithFormat:@"%@/checklist_items/%@",kApiBaseUrl,_item.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting checklist item: %@",[responseObject objectForKey:@"checklist_item"]);
        [_item populateFromDictionary:[responseObject objectForKey:@"checklist_item"]];
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
        [self redrawScrollView];
        photoButtonContainer = photoCell.buttonContainer;
        [photoCell.takePhotoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        [photoCell.choosePhotoButton addTarget:self action:@selector(choosePhoto) forControlEvents:UIControlEventTouchUpInside];
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
        Comment *comment = [_item.comments objectAtIndex:indexPath.row];
        [commentCell.messageTextView setText:comment.body];
        if (comment.createdOnString.length){
            [commentCell.timeLabel setText:comment.createdOnString];
        } else {
            [commentCell.timeLabel setText:[commentFormatter stringFromDate:comment.createdAt]];
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
    shouldSave = YES;
    UIEdgeInsets tempInset = tableViewInset;
    tempInset.bottom += 216;
    self.tableView.contentInset = tempInset;
    if ([textView.text isEqualToString:kAddCommentPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor blackColor]];
    }
    [UIView animateWithDuration:.25 animations:^{
        doneButton.alpha = 1.0;
    }];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
    [cancelButton setTitle:@"Cancel"];
    [[self navigationItem] setRightBarButtonItem:cancelButton];
    if (textView == addCommentTextView){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}


-(void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        [textView setText:@"hey"];
        [textView setTextColor:[UIColor colorWithWhite:.75 alpha:1.0]];
    } else {
        [textView setTextColor:[UIColor blackColor]];
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
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to add comments to a demo project checklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if (addCommentTextView.text.length) {
            Comment *comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            comment.body = addCommentTextView.text;
            comment.createdOnString = @"Just now";
            User *user = [(BHTabBarViewController*) self.tabBarController user];
            comment.user = user;
            [_item addComment:comment];
            
            [self.tableView reloadData];
            NSDictionary *commentDict = @{@"checklist_item_id":_item.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"body":comment.body};
            [manager POST:[NSString stringWithFormat:@"%@/comments",kApiBaseUrl] parameters:@{@"comment":commentDict} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
                //CLEAN UP COMMENTS//
                NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSet];
                //NSLog(@"checklist item comments %@",[dictionary objectForKey:@"comments"]);
                for (id commentDict in [responseObject objectForKey:@"comments"]){
                    NSPredicate *commentPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [commentDict objectForKey:@"id"]];
                    Comment *comment = [Comment MR_findFirstWithPredicate:commentPredicate];
                    if (!comment){
                        comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [comment populateFromDictionary:commentDict];
                    [orderedComments addObject:comment];
                }
                _item.comments = orderedComments;
                // *** //
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationFade];
                addCommentTextView.text = @"";
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"failure creating a comment: %@",error.description);
            }];
        }
    }
    
    [self doneEditing];
}

- (void)doneEditing {
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
    callActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to call?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    [callActionSheet addButtonWithTitle:kUsers];
    [callActionSheet addButtonWithTitle:kSubcontractors];
    callActionSheet.cancelButtonIndex = [callActionSheet addButtonWithTitle:@"Cancel"];
    [callActionSheet showInView:self.view];
}

- (void)emailAction {
    emailBool = YES;
    phoneBool = NO;
    emailActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to email?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    [emailActionSheet addButtonWithTitle:kUsers];
    [emailActionSheet addButtonWithTitle:kSubcontractors];
    emailActionSheet.cancelButtonIndex = [emailActionSheet addButtonWithTitle:@"Cancel"];
    [emailActionSheet showInView:self.view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    BHPersonnelPickerViewController *vc = [segue destinationViewController];
    [vc setCountNotNeeded:YES];
    
    if (phoneBool) {
        [vc setPhone:YES];
    } else if (emailBool) {
        [vc setEmail:YES];
    }
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]) {
        [vc setUsers:_project.users.mutableCopy];
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
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We don't have a phone number for this contact." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send mail on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
        }
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Sorry, we don't have an email address for this contact." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your message. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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
        } else if ([buttonTitle isEqualToString:kUsers]) {
            [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
        } else if ([buttonTitle isEqualToString:kSubcontractors]) {
            [self performSegueWithIdentifier:@"SubPicker" sender:nil];
        }
    }/* else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
    }*/
}

- (void)choosePhoto {
    saveToLibrary = NO;
    CTAssetsPickerController *controller = [[CTAssetsPickerController alloc] init];
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:NULL];
}

- (void)takePhoto {
    saveToLibrary = YES;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *vc = [[UIImagePickerController alloc] init];
        [vc setModalPresentationStyle:UIModalPresentationFullScreen];
        [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
        [vc setDelegate:self];
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We're unable to access a camera on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [newPhoto setImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [self saveImage:[self fixOrientation:newPhoto.image]];
    [_item addPhoto:newPhoto];
    [self.tableView reloadData];
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
    if (picker.selectedAssets.count >= 10){
        [[[UIAlertView alloc] initWithTitle:nil message:@"We're unable to select more than 10 photos per batch." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
    // Allow 10 assets to be picked
    return (picker.selectedAssets.count < 10);
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
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
                Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [newPhoto setImage:[self fixOrientation:image]];
                [_item addPhoto:newPhoto];
                [self saveImage:newPhoto.image];
            }
        }
        [self redrawScrollView];
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
    if (saveToLibrary){
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
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    if (photoToRemove.identifier){
        for (Photo *photo in _item.photos){
            if ([photo.identifier isEqualToNumber:photoToRemove.identifier]) {
                [_item removePhoto:photo];
                [self redrawScrollView];
                break;
            }
        }
    } else {
        [_item removePhoto:photoToRemove];
        [self redrawScrollView];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":_item}];
    [self saveContext];
}

- (void)saveImage:(UIImage*)image {
    if (![_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [self savePostToLibrary:image];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        [manager POST:[NSString stringWithFormat:@"%@/checklist_items/photo/",kApiBaseUrl] parameters:@{@"photo":@{@"checklist_item_id":_item.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"project_id":_project.identifier, @"source":kChecklist,@"company_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]}} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"save image response object: %@",responseObject);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":_item}];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure posting image to API: %@",error.description);
        }];
    }
}

- (void)redrawScrollView {
    photoScrollView.delegate = self;
    [photoScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    photoScrollView.showsHorizontalScrollIndicator = NO;
    if (photoScrollView.isHidden) [photoScrollView setHidden:NO];
    float imageSize = 70.0;
    float space = 5.0;
    int index = 0;
    
    for (Photo *photo in _item.photos) {
        __weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.urlSmall.length){
            [imageButton setAlpha:0.0];
            [imageButton setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
                //[imageButton setTitle:photo.identifier forState:UIControlStateNormal];
            }];
        } else if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        }
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageButton.imageView.clipsToBounds = YES;
        [imageButton setTag:[_item.photos indexOfObject:photo]];
        [imageButton.titleLabel setHidden:YES];
        imageButton.imageView.layer.cornerRadius = 2.0;
        [imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        [imageButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        imageButton.layer.shouldRasterize = YES;
        imageButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton setFrame:CGRectMake(space + (space + imageSize)*index,15,imageSize, imageSize)];
        [imageButton addTarget:self action:@selector(existingPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [photoScrollView addSubview:imageButton];
        index++;
    }

    CGRect photoButtonRect = photoButtonContainer.frame;
    photoButtonRect.origin.x = (space+imageSize)*index;
    [photoButtonContainer setFrame:photoButtonRect];
    [photoScrollView addSubview:photoButtonContainer];
    
    [photoScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))+photoButtonContainer.frame.size.width),40)];
    //[photoScrollView setContentOffset:CGPointMake(-space*2, 0) animated:NO];
    [UIView animateWithDuration:.3 delay:.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [photoScrollView setAlpha:1.0];
    } completion:^(BOOL finished) {
        photoScrollView.layer.shouldRasterize = YES;
        photoScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }];
}

- (void)updateChecklistItem:(BOOL)stayHere {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to update checklist items on a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:_item.identifier forKey:@"id"];
        if (_item.status) [parameters setObject:_item.status forKey:@"status"];
        if ([_item.completed isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"completed_by_user_id"];
            [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"completed"];
        }
    
        [ProgressHUD show:@"Updating item..."];
        [manager PATCH:[NSString stringWithFormat:@"%@/checklist_items/%@", kApiBaseUrl,_item.identifier] parameters:@{@"checklist_item":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success updating checklist item %@",responseObject);
            [_item populateFromDictionary:[responseObject objectForKey:@"checklist_item"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":_item}];
            [self.navigationController popViewControllerAnimated:YES];
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure updating checklist item: %@",error.description);
            [ProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while updating this item. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    }
}

- (void)showPhotoDetail:(NSInteger)idx {
    browserPhotos = [NSMutableArray new];
    for (Photo *photo in _item.photos) {
        MWPhoto *mwPhoto;
        if (photo.image){
            mwPhoto = [MWPhoto photoWithImage:photo.image];
        } else {
            mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        }
        [mwPhoto setPhoto:photo];
        [browserPhotos addObject:mwPhoto];
    }
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    if (_project.demo == [NSNumber numberWithBool:YES]) {
        browser.displayTrashButton = NO;
    }
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = NO;
    
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    shouldSave = YES;
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                if ([_item.status isEqualToString:kCompleted]){
                    _item.status = nil;
                    _item.completed = NO;
                } else {
                    [_item setStatus:kCompleted];
                    _item.completed = @YES;
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 4) {
        Comment *comment = [_item.comments objectAtIndex:indexPath.row];
        if ([comment.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = indexPath;
        [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to delete this comment?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil] show];
    }
}

- (void)deleteComment {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete comments from a demo project checklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        Comment *comment = [_item.comments objectAtIndex:indexPathForDeletion.row];
        if (comment.identifier){
            [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kApiBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully deleted comment: %@",responseObject);
                [_item removeComment:comment];
                [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                //NSLog(@"Failed to delete comment: %@",error.description);
            }];
        } else {
            [_item removeComment:comment];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Save"]) {
        [self updateChecklistItem:NO];
    }  else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Discard"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }  else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Delete"]) {
        [self deleteComment];
    }
}

- (void)back {
    if (shouldSave && [_project.demo isEqualToNumber:[NSNumber numberWithBool:NO]]) {
        [[[UIAlertView alloc] initWithTitle:@"Unsaved Changes" message:@"Do you want to save your unsaved changes?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Save", nil] show];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [ProgressHUD dismiss];
    if (shouldSave)[self saveContext];
    [super viewWillDisappear:animated];
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"What happened during checklist item save? %hhd %@",success, error);
    }];
}

@end
