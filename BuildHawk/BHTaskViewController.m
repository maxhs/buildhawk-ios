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
#import "BHAssetGroupPickerViewController.h"
#import "BHImagePickerController.h"
#import "Task+helper.h"
#import "Tasklist+helper.h"
#import "Comment+helper.h"
#import "BHAppDelegate.h"
#import "BHActivityCell.h"
#import "BHLocationsViewController.h"
#import "BHUtilities.h"

static NSString *assigneePlaceholder = @"Assign task";
static NSString *locationPlaceholder = @"Select location";
static NSString *anotherLocationPlaceholder = @"Add Another Location...";
static NSString *itemPlaceholder = @"Describe this task...";
typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHTaskViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIScrollViewDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, MWPhotoBrowserDelegate, BHImagePickerControllerDelegate, BHLocationsDelegate, BHPersonnelPickerDelegate> {
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

@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) Task *task;

- (IBAction)assigneeButtonTapped;
- (IBAction)locationButtonTapped;
- (IBAction)placeText:(id)sender;
- (IBAction)placeCall:(id)sender;
- (IBAction)sendEmail:(id)sender;

@end

@implementation BHTaskViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    appDelegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [appDelegate manager];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth(); height = screenHeight();
    } else {
        width = screenHeight(); height = screenWidth();
    }
    activities = NO; //show comments for this task by default (by setting activities to NO)
    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateStyle:NSDateFormatterShortStyle];
    [commentFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    if (self.taskId) {
        self.task = (Task*)[[NSManagedObjectContext MR_defaultContext] objectWithID:self.taskId];
        [self redrawScrollView];
        [self loadItem];
        saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(postTask)];
        [self.navigationItem setRightBarButtonItem:saveButton];
        
        if (IDIOM == IPAD && self.task.user.fullname){
            if (self.task.user.company.name.length){
                [self.navigationItem setTitle:[NSString stringWithFormat:@"%@ (%@) - %@",self.task.user.fullname,self.task.user.company.name,[commentFormatter stringFromDate:self.task.createdAt]]];
            } else {
                [self.navigationItem setTitle:[NSString stringWithFormat:@"%@ - %@",self.task.user.fullname,[commentFormatter stringFromDate:self.task.createdAt]]];
            }
        } else {
            [self.navigationItem setTitle:[NSString stringWithFormat:@"%@",[commentFormatter stringFromDate:self.task.createdAt]]];
        }
    } else {
        self.task = [Task MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        createButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(postTask)];
        [self.navigationItem setRightBarButtonItem:createButton];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
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
    
    // set location and assignee titles and colors
    [_locationButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kLato] size:0]];
    [_locationButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_locationLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kLatoLight] size:0]];
    [_locationLabel setTextColor:[UIColor darkGrayColor]];
    [_locationLabel setText:@"LOCATION(S)"];
    [_assigneeButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kLato] size:0]];
    [_assigneeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_assigneeLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kLatoLight] size:0]];
    [_assigneeLabel setTextColor:[UIColor darkGrayColor]];
    [_assigneeLabel setText:@"ASSIGNEE(S)"];
    
    if (IDIOM != IPAD){
        [_locationButton setBackgroundColor:kLightestGrayColor];
        [_assigneeButton setBackgroundColor:kLightestGrayColor];
    }
    [_photoBackgroundView setBackgroundColor:kLightestGrayColor];
    
    //notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assignTask:) name:@"AssignTask" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    [self registerForKeyboardNotifications];
}

- (void)drawItem {
    if (IDIOM == IPAD){
        
    } else {
        CGFloat originX = width/2 - _locationButton.frame.size.width/2;
        // reset action buttons, if necessary
        CGFloat differential = _emailButton.frame.origin.x - originX;
        if (differential > 0){
            _emailButton.transform = CGAffineTransformMakeTranslation(-differential, 0);
            _callButton.transform = CGAffineTransformMakeTranslation(-differential, 0);
            _textButton.transform = CGAffineTransformMakeTranslation(-differential, 0);
        }
    }
    
    CGFloat completionButtonWidth = _completionButton.frame.size.width;
    CGRect itemTextViewRect = _itemTextView.frame;
    itemTextViewRect.size.width = width - completionButtonWidth;
    [_itemTextView setFrame:itemTextViewRect];
    
    CGRect completionButtonFrame = _completionButton.frame;
    completionButtonFrame.origin.x = itemTextViewRect.size.width;
    [_completionButton setFrame:completionButtonFrame];
    
    [_completionButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kLato] size:0]];
    [_itemTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
    
    if (self.task.body.length) {
        [self.itemTextView setText:self.task.body];
    } else {
        [self.itemTextView setTextColor:[UIColor lightGrayColor]];
    }
    [self.completionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    if ([self.task.completed isEqualToNumber:@YES]) {
        [self.completionButton setBackgroundColor:kDarkGrayColor];
        [self.completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"COMPLETED" forState:UIControlStateNormal];
    } else {
        [self.completionButton setBackgroundColor:[UIColor whiteColor]];
        [self.completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"MARK COMPLETE" forState:UIControlStateNormal];
    }
    
    [self setLocationString];
    [self setAssigneeString];
    
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
        [manager GET:[NSString stringWithFormat:@"%@/tasks/%@",kApiBaseUrl,self.task.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success getting task: %@",responseObject);
            [self.task populateFromDictionary:[responseObject objectForKey:@"task"]];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.task.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        return 0;
    } else return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (activities) return self.task.activities.count;
    else return self.task.comments.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!activities && indexPath.row == 0) {
        BHAddCommentCell *addCommentCell = [tableView dequeueReusableCellWithIdentifier:@"AddCommentCell"];
        if (addCommentCell == nil) {
            addCommentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddCommentCell" owner:self options:nil] lastObject];
        }
        [addCommentCell configure];
        
        addCommentTextView = addCommentCell.messageTextView;
        addCommentTextView.delegate = self;
        [addCommentTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
        [addCommentCell.doneButton addTarget:self action:@selector(submitComment) forControlEvents:UIControlEventTouchUpInside];
        doneCommentButton = addCommentCell.doneButton;
        return addCommentCell;
    } else if (activities){
        BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
        }
        Activity *activity = [self.task.activities objectAtIndex:indexPath.row];
        [cell configureForActivity:activity];
        [cell.timestampLabel setText:[commentFormatter stringFromDate:activity.createdDate]];
        return cell;
    } else {
        BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
        }
        Comment *comment = [self.task.comments objectAtIndex:indexPath.row - 1];
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
    [self.task setSaved:@NO];
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
            [self.task setSaved:@YES];
            [textView setText:kAddCommentPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
        }
    } else {
        if (textView.text.length) {
            self.task.body = textView.text;
        } else {
            [self.task setSaved:@YES];
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
    [self doneEditing];
    
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to submit comments for a demo project task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if (addCommentTextView.text.length) {
            Comment *comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [comment setBody:addCommentTextView.text];
            if (self.currentUser){
                [comment setUser:self.currentUser];
            }
            [comment setCreatedAt:[NSDate date]];
            [self.task addComment:comment];
            [comment setSaved:@NO];
            
            [self.tableView beginUpdates];
            //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
            //[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            
            [comment synchWithServer:^(BOOL completed) {
                if (completed){
                    [comment setSaved:@YES];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        NSLog(@"Success synching comment with server");
                    }];
                } else {
                    [comment setSaved:@NO];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        NSLog(@"Couldn't synch comment with server");
                        [appDelegate.syncController update];
                    }];
                }
            }];
            addCommentTextView.text = kAddCommentPlaceholder;
            addCommentTextView.textColor = [UIColor lightGrayColor];
        }
    }
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
    [headerLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setTextColor:[UIColor darkGrayColor]];
    [headerLabel setText:@""];
    
    commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [commentsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [commentsButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
    
    NSString *commentsTitle = self.task.comments.count == 1 ? @"1 COMMENT" : [NSString stringWithFormat:@"%lu COMMENTS",(unsigned long)self.task.comments.count];
    [commentsButton setTitle:commentsTitle forState:UIControlStateNormal];
    if (activities){
        [commentsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [commentsButton setBackgroundColor:[UIColor whiteColor]];
    } else {
        [commentsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [commentsButton setBackgroundColor:[UIColor clearColor]];
    }
    
    [commentsButton setFrame:CGRectMake(0, 0, width/2, 40)];
    [commentsButton addTarget:self action:@selector(showComments) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:commentsButton];
    
    activityButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [activityButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
    [activityButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
    
    NSString *activitiesTitle = self.task.activities.count == 1 ? @"1 ACTIVITY" : [NSString stringWithFormat:@"%lu ACTIVITIES",(unsigned long)self.task.activities.count];
    [activityButton setTitle:activitiesTitle forState:UIControlStateNormal];
    
    if (activities){
        [activityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [activityButton setBackgroundColor:[UIColor clearColor]];
    } else {
        [activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [activityButton setBackgroundColor:[UIColor whiteColor]];
    }
    [activityButton setFrame:CGRectMake(width/2, 0, width/2, 40)];
    [activityButton addTarget:self action:@selector(showActivities) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:activityButton];

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

- (IBAction)completionTapped{
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if ([self.task.completed isEqualToNumber:@NO]){
            [_completionButton setBackgroundColor:kDarkGrayColor];
            [_completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_completionButton setTitle:@"Completed" forState:UIControlStateNormal];
            self.task.completed = @YES;
        } else {
            [_completionButton setBackgroundColor:[UIColor whiteColor]];
            [_completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
            self.task.completed = @NO;
        }
    } completion:^(BOOL finished) {
        if ([self.task.completed isEqualToNumber:@YES]){
            [[[UIAlertView alloc] initWithTitle:@"Completion Photo" message:@"Can you take a photo of the completed task?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
        }
        [self.task setSaved:@NO];
    }];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    if ([self.task.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
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
    NSString *fileName = [NSString stringWithFormat:@"%ld.jpg",(long)NSDate.date.timeIntervalSince1970];
    [newPhoto setFileName:fileName];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [newPhoto setImage:image];
    [self.task addPhoto:newPhoto];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self redrawScrollView];
    [self saveImage:image forPhoto:newPhoto];
}

- (IBAction)choosePhoto {
    saveToLibrary = NO;
    [self performSegueWithIdentifier:@"AssetGroupPicker" sender:nil];
}

- (void)didFinishPickingPhotos:(NSOrderedSet *)selectedPhotos {
    for (Photo *p in selectedPhotos){
        Photo *photo = [p MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        [self.task addPhoto:photo];
        [self saveImage:photo.image forPhoto:photo];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self redrawScrollView];
    [self.navigationController popToViewController:self animated:YES];
    [ProgressHUD dismiss];
}

- (void)saveToLibrary:(UIImage*)originalImage {
    if (saveToLibrary){
        NSString *albumName = @"BuildHawk";
        UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        library = [[ALAssetsLibrary alloc]init];
        [library addAssetsGroupAlbumWithName:albumName
                                 resultBlock:^(ALAssetsGroup *group) { }
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
                [library assetForURL:assetURL // try to get the asset
                         resultBlock:^(ALAsset *asset) {
                             [groupToAddTo addAsset:asset]; // assign the photo to the album
                         }
                        failureBlock:^(NSError* error) {
                            NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                        }];
            } else {
                NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
            }
        }];
    }
}

- (void)saveImage:(UIImage*)image forPhoto:(Photo*)photo {
    if (![_project.demo isEqualToNumber:@YES]){
        [self saveToLibrary:image];
        if (![self.task.identifier isEqualToNumber:@0]){
            [photo setTask:self.task];
            [photo setSource:kTasklist];
            [photo setProject:self.project];
            [photo setSaved:@NO];
            [photo synchWithServer:^(BOOL completed) {
                if (completed){
                    [photo setSaved:@YES];
                    [appDelegate.syncController update];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                } else {
                    [appDelegate.syncController update];
                }
            }];
        }
    }
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    if (photoToRemove.identifier){
        for (Photo *photo in self.task.photos){
            if ([photo.identifier isEqualToNumber:photoToRemove.identifier]) {
                [self.task removePhoto:photo];
                [self redrawScrollView];
                break;
            }
        }
    } else {
        [self.task removePhoto:photoToRemove];
        [self redrawScrollView];
    }
}

- (void)redrawScrollView {
    // ensure the library and photo buttons are properly oriented on the iPad
    CGRect libraryRect = _libraryButton.frame;
    CGRect photoRect = _photoButton.frame;
    if (IDIOM == IPAD && libraryRect.origin.x > _photosScrollView.frame.origin.x){
        libraryRect.origin.x = 6;
        photoRect.origin.x = 6 + photoRect.size.width + 6;
    }
    _photosScrollView.delegate = self;
    [_photosScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _photosScrollView.showsHorizontalScrollIndicator=NO;

    float imageSize = _photosScrollView.frame.size.height;
    float space = 2.f;

    int index = 0;
    for (Photo *photo in self.task.photos) {
 
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        } else if (photo.urlSmall.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        }
        
        [_photosScrollView addSubview:imageButton];
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),4,imageSize, imageSize)];
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageButton.imageView.layer.cornerRadius = 2.f;
        imageButton.imageView.clipsToBounds = YES;
        imageButton.imageView.layer.shouldRasterize = YES;
        imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton setTag:[self.task.photos indexOfObject:photo]];
        [imageButton addTarget:self action:@selector(existingPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        index++;
    }
    
    [self.view bringSubviewToFront:self.photosScrollView];
    [self.photosScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    if (self.photosScrollView.isHidden) [self.photosScrollView setHidden:NO];
    
    [UIView animateWithDuration:.3 delay:.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.photosScrollView setAlpha:1.0];
        [_libraryButton setFrame:libraryRect];
        [_photoButton setFrame:photoRect];
    } completion:^(BOOL finished) {
        //self.photosScrollView.layer.shouldRasterize = YES;
        //self.photosScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }];
}

- (void)showPhotoDetail {
    browserPhotos = [NSMutableArray new];
    for (Photo *photo in self.task.photos) {
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
    [browser setProject:_project];
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
        [self.task setSaved:@NO];
        [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
    }
}

-(IBAction)locationButtonTapped{
    if (_connectMode){
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"You don't have permission to change this task's location." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        [self.task setSaved:@NO];
        [self performSegueWithIdentifier:@"SelectLocation" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]){
        BHPersonnelPickerViewController *vc = [segue destinationViewController];
        vc.personnelDelegate = self;
        [vc setProjectId:_project.identifier];
        [vc setTaskId:self.task.identifier];
    } else if ([segue.identifier isEqualToString:@"SelectLocation"]){
        BHLocationsViewController *vc = [segue destinationViewController];
        vc.locationsDelegate = self;
        [vc setProjectId:_project.identifier];
        [vc setTaskId:self.task.identifier];
    }
}

- (void)locationAdded:(Location *)location {
    [self.task addLocation:location];
    [self setLocationString];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
}

- (void)locationRemoved:(Location *)location {
    [self.task removeLocation:location];
    [self setLocationString];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
}

- (void)setLocationString {
    if (self.task.locations.count == 1) {
        [_locationButton setTitle:[(Location*)self.task.locations.firstObject name] forState:UIControlStateNormal];
    } else if (self.task.locations.count) {
        [_locationButton setTitle:self.task.locationsToSentence forState:UIControlStateNormal];
    } else {
        [_locationButton setTitle:locationPlaceholder forState:UIControlStateNormal];
    }
}

- (void)userAdded:(User *)user {
    [self.task addAssignee:user];
    [self setLocationString];
}

- (void)userRemoved:(User *)user {
    [self.task removeAssignee:user];
    [self setAssigneeString];
}

- (void)setAssigneeString {
    if (self.task.assignees.count == 1) {
        [_assigneeButton setTitle:[(User*)self.task.assignees.firstObject fullname] forState:UIControlStateNormal];
    } else if (self.task.assignees.count) {
        [_assigneeButton setTitle:self.task.assigneesToSentence forState:UIControlStateNormal];
    } else {
        [_assigneeButton setTitle:assigneePlaceholder forState:UIControlStateNormal];
    }
}

-(void)postTask {
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else if ([_itemTextView.text isEqualToString:itemPlaceholder] || _itemTextView.text.length == 0){
        [[[UIAlertView alloc] initWithTitle:nil message:@"Please describe your task before continuing." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (_connectMode){
            [self.task setApproved:@NO];
        }
        BOOL isNew;
        if ([self.task.identifier isEqualToNumber:@0]){
            isNew = YES;
            [self.task setUser:self.currentUser];
        } else {
            isNew = NO;
        }
        
        if (_itemTextView.text && ![_itemTextView.text isEqualToString:itemPlaceholder]) {
            [parameters setObject:_itemTextView.text forKey:@"body"];
            [self.task setBody:_itemTextView.text];
        }
        
        if (self.task.assignees){
            NSMutableArray *assigneeIds = [NSMutableArray arrayWithCapacity:self.task.assignees.count];
            [self.task.assignees enumerateObjectsUsingBlock:^(User *assignee, NSUInteger idx, BOOL *stop) {
                [assigneeIds addObject:assignee.identifier];
            }];
            [parameters setObject:assigneeIds forKey:@"assignee_ids"];
        }
        
        if (self.task.locations){
            NSMutableArray *locationIds = [NSMutableArray arrayWithCapacity:self.task.locations.count];
            [self.task.locations enumerateObjectsUsingBlock:^(Location *location, NSUInteger idx, BOOL *stop) {
                [locationIds addObject:location.identifier];
            }];
            [parameters setObject:locationIds forKey:@"location_ids"];
        }
        
        if ([self.task.completed isEqualToNumber:@YES]){
            [parameters setObject:@YES forKey:@"completed"];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"completed_by_user_id"];
        } else {
            [parameters setObject:@NO forKey:@"completed"];
        }
        [self.task setProject:self.project];
        
        if (appDelegate.connected){
            if (isNew){
                [ProgressHUD show:@"Adding task..."];
                [self.task synchWithServer:^(BOOL completed) {
                    if (completed) {
                        [self.task setSaved:@YES];
                        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                            [ProgressHUD showSuccess:@"Task Saved"];
                            if (self.delegate && [self.delegate respondsToSelector:@selector(taskCreated:)]) {
                                [self.delegate taskCreated:self.task];
                            }
                        }];
                    } else {
                        [self.task setSaved:@NO];
                        [ProgressHUD dismiss];
                    }
                    [self dismiss]; // finally dismiss the task
                }];
            } else {
                [ProgressHUD show:@"Updating task..."];
                [self.task synchWithServer:^(BOOL completed) {
                    if (completed) {
                        [self.task setSaved:@YES];
                        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                            [ProgressHUD showSuccess:@"Task Saved"];
                            if (self.delegate && [self.delegate respondsToSelector:@selector(taskUpdated:)]) {
                                [self.delegate taskUpdated:self.task];
                            }
                        }];
                    } else {
                        [self.task setSaved:@NO];
                        [ProgressHUD dismiss];
                    }
                }];
            }
        } else {
            [self.task setSaved:@NO];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            if (isNew){
                if (self.delegate && [self.delegate respondsToSelector:@selector(taskCreated:)]) {
                    [self.delegate taskCreated:self.task];
                }
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(taskUpdated:)]) {
                    [self.delegate taskUpdated:self.task];
                }
            }
            [self dismiss];
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
        [controller setSubject:[NSString stringWithFormat:@"%@ Task: \"%@\"",_project.name,self.task.body]];
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
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Reassign"]) {
        [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //only allow editing if the cell represents a comment and IS NOT the add comment row (i.e. the first row)
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && indexPath.section == 0 && !activities && indexPath.row != 0){
        Comment *comment = self.task.comments[indexPath.row - 1];
        if ([comment.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] || [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUberAdmin]){
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
        Comment *comment = [self.task.comments objectAtIndex:indexPathForDeletion.row - 1];
        if (![comment.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kApiBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully deleted comment: %@",responseObject);
                [self.task removeComment:comment];
                
                [comment MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                
                [self.tableView beginUpdates];
                //[self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPathForDeletion.section] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to delete activity: %@",error.description);
            }];
        } else {
            [self.task removeComment:comment];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Save"]) {
        [self postTask];
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Discard"]) {
        // only get rid of it if it's a new task
        if ([self.task.identifier isEqualToNumber:@0]){
            [self.task MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [self dismiss];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self takePhoto];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
        [self deleteComment];
    }
}

- (void)back {
    if ([self.task.saved isEqualToNumber:@NO] && [_project.demo isEqualToNumber:@NO] && appDelegate.connected) {
        [[[UIAlertView alloc] initWithTitle:@"Unsaved Changes" message:@"Do you want to save your unsaved changes?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Save", nil] show];
    } else {
        [self dismiss];
    }
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (notification) {
        NSDictionary* info = [notification userInfo];
        NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
        NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
        CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
        CGFloat keyboardHeight = convertedKeyboardFrame.size.height;
        if (!activities && self.task.comments.count == 0){
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
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (notification) {
        NSDictionary* info = [notification userInfo];
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
}

- (void)dismiss {
    if (self.navigationController.viewControllers.firstObject == self){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
