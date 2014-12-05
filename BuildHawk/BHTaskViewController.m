//
//  BHTaskViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/10/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHTaskViewController.h"
#import "Constants.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "User+helper.h"
#import <MessageUI/MessageUI.h>
#import "UIButton+WebCache.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MWPhotoBrowser.h"
#import "BHTabBarViewController.h"
#import "BHPersonnelPickerViewController.h"
#import "BHAddCommentCell.h"
#import "BHCommentCell.h"
#import "BHTasksViewController.h"
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#import "Task+helper.h"
#import "Tasklist+helper.h"
#import "Comment+helper.h"
#import "BHAppDelegate.h"
#import "BHActivityCell.h"

static NSString *assigneePlaceholder = @"Assign task";
static NSString *locationPlaceholder = @"Select location";
static NSString *anotherLocationPlaceholder = @"Add Another Location...";
static NSString *itemPlaceholder = @"Describe this task...";
typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHTaskViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIScrollViewDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, MWPhotoBrowserDelegate, CTAssetsPickerControllerDelegate> {
    BOOL iPhone5;
    BOOL saveToLibrary;
    UIActionSheet *locationActionSheet;
    BHAppDelegate *appDelegate;
    AFHTTPRequestOperationManager *manager;
    UIActionSheet *emailActionSheet;
    UIActionSheet *callActionSheet;
    UIActionSheet *textActionSheet;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *createButton;
    UIBarButtonItem *doneEditingButton;
    UIAlertView *addOtherAlertView;
    NSInteger photoIdx;
    NSMutableArray *browserPhotos;
    UITextView *addCommentTextView;
    NSDateFormatter *commentFormatter;
    UIButton *doneCommentButton;
    ALAssetsLibrary *library;
    NSIndexPath *indexPathForDeletion;
    UIButton *activityButton;
    UIButton *commentsButton;
    BOOL activities;
    CGFloat width;
    CGFloat height;
    UIEdgeInsets originalInsets;
}

- (IBAction)assigneeButtonTapped;
- (IBAction)locationButtonTapped;
- (IBAction)placeText:(id)sender;
- (IBAction)placeCall:(id)sender;
- (IBAction)sendEmail:(id)sender;

@end

@implementation BHTaskViewController

@synthesize task = _task;
@synthesize locationSet;
@synthesize project = _project;

- (void)viewDidLoad
{
    [super viewDidLoad];
    appDelegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [appDelegate manager];
    
    if ([UIScreen mainScreen].bounds.size.height == 568) {
        iPhone5 = YES;
    } else if (IDIOM != IPAD) {
        iPhone5 = NO;
        self.emailButton.transform = CGAffineTransformMakeTranslation(0, -88);
        self.callButton.transform = CGAffineTransformMakeTranslation(0, -88);
        self.textButton.transform = CGAffineTransformMakeTranslation(0, -88);
       
        [self shrinkButton:self.photoButton width:16 height:16];
        [self shrinkButton:self.libraryButton width:16 height:16];
        [self shrinkButton:self.locationButton width:0 height:20];
        [self shrinkButton:self.assigneeButton width:0 height:20];
        [self shrinkButton:self.completionButton width:0 height:30];
        CGRect itemTextRect = self.itemTextView.frame;
        itemTextRect.size.height = self.completionButton.frame.size.height;
        [_itemTextView setFrame:itemTextRect];
        
        self.photoButton.transform = CGAffineTransformMakeTranslation(0, -34);
        self.libraryButton.transform = CGAffineTransformMakeTranslation(0, -34);
        self.locationButton.transform = CGAffineTransformMakeTranslation(0, -50);
        self.assigneeButton.transform = CGAffineTransformMakeTranslation(0, -70);
        self.photosScrollView.transform = CGAffineTransformMakeTranslation(0, -32);
    }
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    //show activities for this task by default
    activities = YES;
    
    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateStyle:NSDateFormatterShortStyle];
    [commentFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    if (!_task || [_task.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        _task = [Task MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        createButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(sendItem)];
        [self.navigationItem setRightBarButtonItem:createButton];
    } else {
        //_task = [_task MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        [self redrawScrollView];
        [self loadItem];
        saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(sendItem)];
        [self.navigationItem setRightBarButtonItem:saveButton];
        
        if (IDIOM == IPAD && _task.user.fullname){
            if (_task.user.company.name.length){
                [self.navigationItem setTitle:[NSString stringWithFormat:@"Created By: %@ (%@) - %@",_task.user.fullname,_task.user.company.name,[commentFormatter stringFromDate:_task.createdAt]]];
            } else {
                [self.navigationItem setTitle:[NSString stringWithFormat:@"Created By: %@ - %@",_task.user.fullname,[commentFormatter stringFromDate:_task.createdAt]]];
            }
        } else {
            [self.navigationItem setTitle:[NSString stringWithFormat:@"%@",[commentFormatter stringFromDate:_task.createdAt]]];
        }
    }
    
    //override standard back navigation so we can ask the user if they want to save their changes
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    doneEditingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    
    self.tableView.tableHeaderView = _taskContainerView;
    originalInsets = UIEdgeInsetsMake(0, 0, self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height, 0);
    self.tableView.contentInset = originalInsets;
    
    //basic setup
    self.itemTextView.delegate = self;
    [self.itemTextView setText:itemPlaceholder];
    library = [[ALAssetsLibrary alloc] init];
    
    //notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assignTask:) name:@"AssignTask" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    [self registerForKeyboardNotifications];
}

- (void)drawItem {
    [_locationButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0]];
    [_assigneeButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0]];
    [_completionButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:19]];
    [_itemTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
    
    if (_task.body.length) {
        [self.itemTextView setText:_task.body];
    } else {
        [self.itemTextView setTextColor:[UIColor lightGrayColor]];
    }
    [self.completionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    if ([_task.completed isEqualToNumber:@YES]) {
        [self.completionButton setBackgroundColor:kDarkGrayColor];
        [self.completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"Completed" forState:UIControlStateNormal];
    } else {
        [self.completionButton setBackgroundColor:[UIColor whiteColor]];
        [self.completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
    }
    
    if (_task.location && _task.location.length) {
        [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",_task.location] forState:UIControlStateNormal];
    } else {
        [self.locationButton setTitle:locationPlaceholder forState:UIControlStateNormal];
    }
    if (_task.assignees.count) {
        if (_task.assignees.count == 1){
            [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",[(User*)[_task.assignees firstObject] fullname]] forState:UIControlStateNormal];
        } else {
            [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned to %lu personnel",(unsigned long)_task.assignees.count] forState:UIControlStateNormal];
        }
    } else {
        [self.assigneeButton setTitle:@"Assign" forState:UIControlStateNormal];
    }
}

- (void)shrinkButton:(UIButton*)button width:(int)buttonWidth height:(int)buttonHeight {
    CGRect buttonRect = button.frame;
    buttonRect.size.height -= buttonHeight;
    buttonRect.size.width -= buttonWidth;
    [button setFrame:buttonRect];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self drawItem];
}

- (void)loadItem {
    if ([(BHAppDelegate*)[UIApplication sharedApplication].delegate connected]){
        [manager GET:[NSString stringWithFormat:@"%@/tasks/%@",kApiBaseUrl,_task.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success getting task: %@",responseObject);
            [_task populateFromDictionary:[responseObject objectForKey:@"task"]];
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //NSLog(@"Failed to load task: %@",error.description);
        }];
    } else {
        
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([_task.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        return 0;
    }
    else return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (activities) return _task.activities.count;
    else return _task.comments.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!activities && indexPath.row == 0) {
        BHAddCommentCell *addCommentCell = [tableView dequeueReusableCellWithIdentifier:@"AddCommentCell"];
        if (addCommentCell == nil) {
            addCommentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddCommentCell" owner:self options:nil] lastObject];
        }
        [addCommentCell configure];
        
        addCommentTextView = addCommentCell.messageTextView;
        addCommentTextView.delegate = self;
        [addCommentTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
        [addCommentCell.doneButton addTarget:self action:@selector(submitComment) forControlEvents:UIControlEventTouchUpInside];
        doneCommentButton = addCommentCell.doneButton;
        return addCommentCell;
    } else if (activities){
        BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
        }
        Activity *activity = [_task.activities objectAtIndex:indexPath.row];
        [cell configureForActivity:activity];
        [cell.timestampLabel setText:[commentFormatter stringFromDate:activity.createdDate]];
        return cell;
    } else {
        BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
        }
        Comment *comment = [_task.comments objectAtIndex:indexPath.row - 1];
        [cell configureForComment:comment];
        [cell.timestampLabel setText:[commentFormatter stringFromDate:comment.createdAt]];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

#pragma mark - UITextView delegate methods
- (void)textViewDidBeginEditing:(UITextView *)textView {
    [_task setSaved:@NO];
    if ([textView.text isEqualToString:kAddCommentPlaceholder] || [textView.text isEqualToString:itemPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor blackColor]];
    }
    
    [UIView animateWithDuration:.25 animations:^{
        doneCommentButton.alpha = 1.0;
    }];
    
    [[self navigationItem] setRightBarButtonItem:doneEditingButton];

    if (textView == addCommentTextView){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == addCommentTextView){
        if (textView.text.length) {
            addCommentTextView = textView;
        } else {
            [_task setSaved:@YES];
            [textView setText:kAddCommentPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
        }
    } else {
        if (textView.text.length) {
            _task.body = textView.text;
        } else {
            [_task setSaved:@YES];
            [textView setText:itemPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
        }
    }
    [self doneEditing];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)thisText {
    if ([thisText isEqualToString:@"\n"]) {
        if (textView == addCommentTextView && textView.text.length) {
            [self submitComment];
            [self doneEditing];
        }
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark - Header & Comments Section

- (void)submitComment {
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to submit comments for a demo project task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if (addCommentTextView.text.length) {
            [ProgressHUD show:@"Adding comment..."];
            NSDictionary *commentDict = @{@"task_id":_task.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"body":addCommentTextView.text};
            [manager POST:[NSString stringWithFormat:@"%@/comments",kApiBaseUrl] parameters:@{@"comment":commentDict} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"success creating a comment for task: %@",responseObject);

                Comment *comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [comment populateFromDictionary:[responseObject objectForKey:@"comment"]];
                NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:_task.comments];
                [set insertObject:comment atIndex:0];
                [_task setComments:set];
                
                //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
                
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                //[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                
                addCommentTextView.text = kAddCommentPlaceholder;
                addCommentTextView.textColor = [UIColor lightGrayColor];
                
                [ProgressHUD dismiss];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [ProgressHUD dismiss];
                NSLog(@"Failure creating a comment for task: %@",error.description);
            }];
        }
    }
    [self doneEditing];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
    [headerView setBackgroundColor:kDarkerGrayColor];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
    headerLabel.layer.cornerRadius = 3.f;
    headerLabel.clipsToBounds = YES;
    [headerLabel setBackgroundColor:[UIColor clearColor]];
    [headerLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setTextColor:[UIColor darkGrayColor]];
    
    [headerLabel setText:@""];
    
    activityButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [activityButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
    [activityButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
    
    NSString *activitiesTitle = _task.activities.count == 1 ? @"1 ACTIVITY" : [NSString stringWithFormat:@"%lu ACTIVITIES",(unsigned long)_task.activities.count];
    [activityButton setTitle:activitiesTitle forState:UIControlStateNormal];
    
    if (activities){
        [activityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [activityButton setBackgroundColor:[UIColor clearColor]];
    } else {
        [activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [activityButton setBackgroundColor:[UIColor whiteColor]];
    }
    [activityButton setFrame:CGRectMake(0, 0, width/2, 40)];
    [activityButton addTarget:self action:@selector(showActivities) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:activityButton];
    
    commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [commentsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [commentsButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];

    NSString *commentsTitle = _task.comments.count == 1 ? @"1 COMMENT" : [NSString stringWithFormat:@"%lu COMMENTS",(unsigned long)_task.comments.count];
    [commentsButton setTitle:commentsTitle forState:UIControlStateNormal];
    if (activities){
        [commentsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [commentsButton setBackgroundColor:[UIColor whiteColor]];
    } else {
        [commentsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [commentsButton setBackgroundColor:[UIColor clearColor]];
    }
    
    [commentsButton setFrame:CGRectMake(width/2, 0, width/2, 40)];
    [commentsButton addTarget:self action:@selector(showComments) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:commentsButton];

    [headerView addSubview:headerLabel];
    return headerView;
}

- (void)showActivities {
    activities = YES;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showComments {   
    activities = NO;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

/*- (void)assignTask:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    if ([info objectForKey:@"user"]){
        User *user = [info objectForKey:@"user"];
        NSOrderedSet *assigneeSet = [NSOrderedSet orderedSetWithObject:user];
        _task.assignees = assigneeSet;
        if (user.fullname.length){
            [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",user.fullname] forState:UIControlStateNormal];
        } else if (user.firstName.length){
            [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",user.firstName] forState:UIControlStateNormal];
        }
    }
}*/

- (IBAction)completionTapped{
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if ([_task.completed isEqualToNumber:@NO]){
            [_completionButton setBackgroundColor:kDarkGrayColor];
            [_completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_completionButton setTitle:@"Completed" forState:UIControlStateNormal];
            _task.completed = @YES;
        } else {
            [_completionButton setBackgroundColor:[UIColor whiteColor]];
            [_completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
            _task.completed = @NO;
        }
    } completion:^(BOOL finished) {
        if ([_task.completed isEqualToNumber:@YES]){
            [[[UIAlertView alloc] initWithTitle:@"Completion Photo" message:@"Can you take a photo of the completed task?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
        }
        [_task setSaved:@NO];
    }];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    if ([_task.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        self.navigationItem.rightBarButtonItem = createButton;
    } else {
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    [UIView animateWithDuration:.25 animations:^{
        doneCommentButton.alpha = 0.0;
    }];
}

- (void)existingPhotoButtonTapped:(UIButton*)button;
{
    photoIdx = button.tag;
    [self showPhotoDetail];
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
    if (picker.selectedAssets.count >= 10){
        [[[UIAlertView alloc] initWithTitle:nil message:@"We're unable to select more than 10 photos per batch." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
    // Allow 10 assets to be picked
    return (picker.selectedAssets.count < 10);
}


- (IBAction)choosePhoto {
    saveToLibrary = NO;
    CTAssetsPickerController *controller = [[CTAssetsPickerController alloc] init];
    controller.delegate = self;
    //controller.maximumNumberOfSelections = 4;
    [self presentViewController:controller animated:YES completion:NULL];
}

- (IBAction)takePhoto {
    saveToLibrary = YES;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *vc = [[UIImagePickerController alloc] init];
        [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
        [vc setDelegate:self];
        [vc setModalPresentationStyle:UIModalPresentationCurrentContext];
        [self presentViewController:vc animated:YES completion:NULL];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We're unable to find a camera on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.photosScrollView setAlpha:0.0];
    [self dismissViewControllerAnimated:YES completion:nil];
    Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    UIImage *image = [self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [newPhoto setImage:image];
    [_task addPhoto:newPhoto];
    [self redrawScrollView];
    [self saveImage:image forPhoto:newPhoto];
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
                
                UIImage* image = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                     scale:[UIScreen mainScreen].scale orientation:orientation];
                Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [newPhoto setImage:[self fixOrientation:image]];
                
                [_task addPhoto:newPhoto];
                [self saveImage:newPhoto.image forPhoto:newPhoto];
            }
        }
        [self redrawScrollView];
    }];
}

- (UIImage *)fixOrientation:(UIImage*)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *correctedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return correctedImage;
}

- (void)saveToLibrary:(UIImage*)originalImage {
    if (saveToLibrary){
        NSString *albumName = @"BuildHawk";
        UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        library = [[ALAssetsLibrary alloc]init];
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
                NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
            }
        }];
    }
}

- (void)saveImage:(UIImage*)image forPhoto:(Photo*)photo {
    if ([_project.demo isEqualToNumber:@YES]){
        
    } else {
        [self saveToLibrary:image];
        if (![_task.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            NSData *imageData = UIImageJPEGRepresentation(image,1);
            NSMutableDictionary *photoParameters = [NSMutableDictionary dictionary];
            if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]){
                [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"company_id"];
            }
            if (_project && _project.identifier){
                [photoParameters setObject:_project.identifier forKey:@"project_id"];
                [photo setProject:_project];
            }
            [photoParameters setObject:_task.identifier forKey:@"task_id"];
            [photo setTask:_task];
            [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
            [photoParameters setObject:kTasklist forKey:@"source"];
            [photo setSource:kTasklist];
            [photoParameters setObject:@YES forKey:@"mobile"];
            
            //NSLog(@"photo parameters: %@",photoParameters);
            [manager POST:[NSString stringWithFormat:@"%@/photos",kApiBaseUrl] parameters:@{@"photo":photoParameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
            } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"save task photo response object: %@",responseObject);
                if ([responseObject objectForKey:@"task"]){
                    [_task populateFromDictionary:[responseObject objectForKey:@"task"]];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        
                    }];
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"failure posting image to API: %@",error.description);
            }];
        }
    }
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    if (photoToRemove.identifier){
        for (Photo *photo in _task.photos){
            if ([photo.identifier isEqualToNumber:photoToRemove.identifier]) {
                [_task removePhoto:photo];
                [self redrawScrollView];
                break;
            }
        }
    } else {
        [_task removePhoto:photoToRemove];
        [self redrawScrollView];
    }
}

- (void)redrawScrollView {
    _photosScrollView.delegate = self;
    [_photosScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _photosScrollView.showsHorizontalScrollIndicator=NO;

    float imageSize;
    float space;
    if (IDIOM == IPAD) {
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
    for (Photo *photo in _task.photos) {
        /*__weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.urlSmall.length){
            [imageButton setAlpha:0.0];
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
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
        */
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        } else if (photo.urlSmall.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        } else if (photo.urlThumb.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlThumb] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        }
        
        [_photosScrollView addSubview:imageButton];
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),4,imageSize, imageSize)];
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageButton.imageView.clipsToBounds = YES;
        imageButton.imageView.layer.cornerRadius = 2.0;
        [imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        [imageButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        imageButton.imageView.layer.shouldRasterize = YES;
        imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton setTag:[_task.photos indexOfObject:photo]];
        [imageButton addTarget:self action:@selector(existingPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        index++;
    }
    
    if (_task.photos.count > 0){
        [self.view bringSubviewToFront:self.photosScrollView];
        [self.photosScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
        if (self.photosScrollView.isHidden) [self.photosScrollView setHidden:NO];
        [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (IDIOM == IPAD) {
                self.photoButton.transform = CGAffineTransformMakeTranslation(-302, 0);
                self.libraryButton.transform = CGAffineTransformMakeTranslation(-302, 0);
            } else if (iPhone5) {
                self.photoButton.transform = CGAffineTransformMakeTranslation(-96, 0);
                self.libraryButton.transform = CGAffineTransformMakeTranslation(-96, 0);
            } else {
                self.photoButton.transform = CGAffineTransformMakeTranslation(-96, -32);
                self.libraryButton.transform = CGAffineTransformMakeTranslation(-86, -32);
            }
        } completion:^(BOOL finished) {
            
        }];
    }
    
    [UIView animateWithDuration:.3 delay:.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.photosScrollView setAlpha:1.0];
    } completion:^(BOOL finished) {
        self.photosScrollView.layer.shouldRasterize = YES;
        self.photosScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }];

}

- (void)showPhotoDetail {
    browserPhotos = [NSMutableArray new];
    for (Photo *photo in _task.photos) {
        MWPhoto *mwPhoto;
        if (photo.image){
            mwPhoto = [MWPhoto photoWithImage:photo.image];
        } else {
            mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        }
        [mwPhoto setPhoto:photo];
        if (photo.caption.length){
            mwPhoto.caption = photo.caption;
        }
        [browserPhotos addObject:mwPhoto];
    }

    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    if ([_project.demo isEqualToNumber:@YES]) {
        browser.displayTrashButton = NO;
    }
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = NO;

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
    if (_connectMode){
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"You don't have permission to change this task's assignees." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        [_task setSaved:@NO];
        [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
    }
}

-(IBAction)locationButtonTapped{
    if (_connectMode){
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"You don't have permission to change this task's location." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        [_task setSaved:@NO];
        locationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Location" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        for (NSString *location in locationSet.allObjects) {
            [locationActionSheet addButtonWithTitle:location];
        }
        [locationActionSheet addButtonWithTitle:kAddOther];
        if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder])locationActionSheet.destructiveButtonIndex = [locationActionSheet addButtonWithTitle:@"Remove location"];
        locationActionSheet.cancelButtonIndex = [locationActionSheet addButtonWithTitle:@"Cancel"];
        [locationActionSheet showInView:self.view];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    BHPersonnelPickerViewController *vc = [segue destinationViewController];
    [vc setProject:_project];
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]){
        [vc setTask:_task];
    }
}

-(void)sendItem {
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else if (!appDelegate.connected){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadTask" object:nil userInfo:@{@"task":_task}];
        [_task setSaved:@NO];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD showSuccess:@"Saved"];
            [appDelegate.syncController update];
        }];
    } else if ([_itemTextView.text isEqualToString:itemPlaceholder] || _itemTextView.text.length == 0){
        [[[UIAlertView alloc] initWithTitle:nil message:@"Please describe your task before continuing." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        
        if (appDelegate.currentUser){
            [_task setUser:appDelegate.currentUser];
        }
        if (_connectMode){
            [_task setApproved:@NO];
        }
        
        NSString *strippedLocationString;
        if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder]){
            strippedLocationString = [[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""] stringByTrimmingCharactersInSet:
                                      [NSCharacterSet whitespaceCharacterSet]];
            if (strippedLocationString.length) {
                [parameters setObject:strippedLocationString forKey:@"location"];
                _task.location = strippedLocationString;
            }
        } else {
            _task.location = nil;
        }
        
        BOOL isNew;
        if ([_task.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            isNew = YES;
            [ProgressHUD show:@"Adding task..."];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        } else {
            isNew = NO;
            [ProgressHUD show:@"Updating task..."];
        }
        
        if (_itemTextView.text && ![_itemTextView.text isEqualToString:itemPlaceholder]) {
            [parameters setObject:_itemTextView.text forKey:@"body"];
            [_task setBody:_itemTextView.text];
        }
        
        if (_task.assignees.count){
            NSMutableArray *assigneeIds = [NSMutableArray arrayWithCapacity:_task.assignees.count];
            [_task.assignees enumerateObjectsUsingBlock:^(User *assignee, NSUInteger idx, BOOL *stop) {
                [assigneeIds addObject:assignee.identifier];
            }];
            [parameters setObject:[assigneeIds componentsJoinedByString:@","] forKey:@"assignee_ids"];
        }
        
        if ([_task.completed isEqualToNumber:@YES]){
            [parameters setObject:@YES forKey:@"completed"];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"completed_by_user_id"];
        } else {
            [parameters setObject:@NO forKey:@"completed"];
        }
        NSOrderedSet *photoSet = [NSOrderedSet orderedSetWithOrderedSet:_task.photos];
        
        if (isNew){
            [manager POST:[NSString stringWithFormat:@"%@/tasks", kApiBaseUrl] parameters:@{@"task":parameters,@"project_id":_project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                //NSLog(@"Success creating a task: %@",responseObject);
                [_task populateFromDictionary:[responseObject objectForKey:@"task"]];
                [_task setSaved:@YES];
                for (Photo *photo in photoSet){
                    photo.task = _task;
                }
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(newTaskCreated:)]) {
                    [self.delegate newTaskCreated:_task];
                }
                
                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                [parameters setObject:_task.identifier forKey:@"task_id"];
                [parameters setObject:@YES forKey:@"mobile"];
                [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
                if (_project.identifier)
                    [parameters setObject:_project.identifier forKey:@"project_id"];
                [parameters setObject:kTasklist forKey:@"source"];
                
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId])
                    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"company_id"];
                
                for (Photo *photo in _task.photos){
                    NSData *imageData = UIImageJPEGRepresentation(photo.image, 1);
                    [manager POST:[NSString stringWithFormat:@"%@/photos",kApiBaseUrl] parameters:@{@"photo":parameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                        [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
                    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        //NSLog(@"Success posting photo for new task: %@",responseObject);
                        [_task populateFromDictionary:[responseObject objectForKey:@"task"]];
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"Failure posting new task image to API: %@",error.description);
                    }];
                }
                
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    [ProgressHUD showSuccess:@"Task created"];
                    [self dismiss];
                }];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to create a task: %@",error.description);
                [_task setSaved:@NO];
                [ProgressHUD dismiss];
            }];
        } else {
            [_task synchWithServer:^(BOOL completed) {
                if (completed) {
                    [_task setSaved:@YES];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        [ProgressHUD showSuccess:@"Task Saved"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadTask" object:nil userInfo:@{@"task":_task}];
                        //[self dismiss];
                    }];
                } else {
                    [_task setSaved:@NO];
                    [ProgressHUD dismiss];
                }
            }];
            
        }
    }
}

- (IBAction)placeCall:(id)sender{
    callActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to call?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (User *user in _project.users) {
        [callActionSheet addButtonWithTitle:user.fullname];
    }
    callActionSheet.cancelButtonIndex = [callActionSheet addButtonWithTitle:@"Cancel"];
    [callActionSheet showInView:self.view];
}

- (IBAction)placeText:(id)sender{
    textActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to text?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (User *user in _project.users) {
        [textActionSheet addButtonWithTitle:user.fullname];
    }
    textActionSheet.cancelButtonIndex = [textActionSheet addButtonWithTitle:@"Cancel"];
    [textActionSheet showInView:self.view];
}

- (void)text:(NSString*)phone {
    [(BHAppDelegate*)[UIApplication sharedApplication].delegate setDefaultAppearances];
    MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
    if ([MFMessageComposeViewController canSendText]){
        viewController.messageComposeDelegate = self;
        [viewController setRecipients:@[phone]];
        [self presentViewController:viewController animated:YES completion:^{
            
        }];
    }
}


- (IBAction)sendEmail:(id)sender {
    emailActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to email?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (User *user in _project.users) {
        [emailActionSheet addButtonWithTitle:user.fullname];
    }
    emailActionSheet.cancelButtonIndex = [emailActionSheet addButtonWithTitle:@"Cancel"];
    [emailActionSheet showInView:self.view];
}

- (void)call:(NSString*)phone {
    if (IDIOM != IPAD){
        NSString *phoneNumber = [@"tel://" stringByAppendingString:phone];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)sendMail:(NSString*)destinationEmail {
    if ([MFMailComposeViewController canSendMail]) {
        //[(BHAppDelegate*)[UIApplication sharedApplication].delegate setDefaultAppearances];
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        [controller setSubject:[NSString stringWithFormat:@"%@ Task: \"%@\"",_project.name,_task.body]];
        [controller setToRecipients:@[destinationEmail]];
        if (controller) {
            [self presentViewController:controller animated:YES completion:^{
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
            }];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send mail on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
    }
}
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    //if (result == MFMailComposeResultSent) {}
    //[(BHAppDelegate*)[UIApplication sharedApplication].delegate setToBuildHawkAppearances];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent) {
        
    } else if (result == MessageComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your message. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [(BHAppDelegate*)[UIApplication sharedApplication].delegate setToBuildHawkAppearances];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{

    if (actionSheet == callActionSheet || actionSheet == textActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if (![buttonTitle isEqualToString:@"Cancel"]) {
            for (User *user in _project.users){
                if ([user.fullname isEqualToString:buttonTitle] && user.phone) {
                    if (actionSheet == callActionSheet){
                        [self call:user.phone];
                    } else {
                        [self text:user.phone];
                    }
                    return;
                }
            }
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user may not have a phone number on file with BuildHawk" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        
    } else if (actionSheet == emailActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:@"Cancel"]) {
            [emailActionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            return;
        }
        for (User *user in _project.users){
            if ([user.fullname isEqualToString:buttonTitle]) {
                [self sendMail:user.email];
                return;
            }
        }
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user may not have an email address on file with BuildHawk" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove location"]) {
        [self.locationButton setTitle:locationPlaceholder forState:UIControlStateNormal];
        _task.location = nil;
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Reassign"]) {
        [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
    } else if (actionSheet == locationActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if (buttonTitle.length) {
            if ([buttonTitle isEqualToString:kAddOther]) {
                addOtherAlertView = [[UIAlertView alloc] initWithTitle:@"Add another location" message:@"Enter location name(s):" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
                addOtherAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [addOtherAlertView show];
            } else {
                [_task setLocation:buttonTitle];
                [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",buttonTitle] forState:UIControlStateNormal];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //only allow editing if the cell represents a comment and IS NOT the add comment row (i.e. the first row)
    if (indexPath.section == 0 && !activities && indexPath.row != 0){
        Comment *comment = _task.comments[indexPath.row - 1];
        if ([comment.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] || [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsUberAdmin]){
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
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete comments on a demo project task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        // the first row is actually the add comment text view, so make sure to take the correct one
        Comment *comment = [_task.comments objectAtIndex:indexPathForDeletion.row - 1];
        if (![comment.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kApiBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully deleted comment: %@",responseObject);
                [_task removeComment:comment];
                
                [comment MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                
                [self.tableView beginUpdates];
                //[self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPathForDeletion.section] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to delete activity: %@",error.description);
            }];
        } else {
            [_task removeComment:comment];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addOtherAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            [self.locationButton setTitle:[[alertView textFieldAtIndex:0] text] forState:UIControlStateNormal];
        }
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Save"]) {
        [self sendItem];
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Discard"]) {
        [self loadItem];
        [self drawItem];
        [self dismiss];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self takePhoto];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
        [self deleteComment];
    }
}

- (void)back {
    if ([_task.saved isEqualToNumber:@NO] && [_project.demo isEqualToNumber:@NO] && appDelegate.connected) {
        [[[UIAlertView alloc] initWithTitle:@"Unsaved Changes" message:@"Do you want to save your unsaved changes?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Save", nil] show];
    } else {
        [self dismiss];
    }
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = keyboardValue.CGRectValue.size.height;
    if (!activities && _task.comments.count == 0){
        keyboardHeight += 66.f;
    }
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = originalInsets;
                         self.tableView.scrollIndicatorInsets = originalInsets;
                     }
                     completion:nil];
}

- (void)dismiss {
    if (self.navigationController.viewControllers.firstObject == self){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
