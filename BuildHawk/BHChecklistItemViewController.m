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
#import "BHChecklistItemBodyCell.h"
#import "BHListItemPhotoCell.h"
#import <MessageUI/MessageUI.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "BHTabBarViewController.h"
#import "UIButton+WebCache.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MWPhotoBrowser.h"
#import "BHImagePickerController.h"
#import "BHAssetGroupPickerViewController.h"
#import "BHPersonnelPickerViewController.h"
#import "Project.h"
#import "BHAppDelegate.h"
#import "Comment+helper.h"
#import "BHItemContactCell.h"
#import "BHSetReminderCell.h"
#import "BHActivityCell.h"
#import "Activity+helper.h"
#import "Reminder+helper.h"
#import "BHItemDeadlineCell.h"
#import "BHUtilities.h"

@interface BHChecklistItemViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, BHImagePickerControllerDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITextViewDelegate, UIScrollViewDelegate, MWPhotoBrowserDelegate> {
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *photosArray;
    BOOL emailBool;
    BOOL phoneBool;
    BOOL textBool;
    BOOL saveToLibrary;
    CGFloat width;
    CGFloat height;
    NSString *mainPhoneNumber;
    NSString *recipientEmail;
    UITextView *addCommentTextView;
    UIButton *doneButton;
    UIActionSheet *callActionSheet;
    UIActionSheet *emailActionSheet;
    
    UIScrollView *photoScrollView;
    NSDateFormatter *commentFormatter;
    UIBarButtonItem *saveButton;
    NSInteger removePhotoIdx;
    UIView *photoButtonContainer;
    NSMutableArray *browserPhotos;
    ALAssetsLibrary *library;
    Project *savedProject;
    NSIndexPath *indexPathForDeletion;
    UIView *overlayBackground;
    NSDateFormatter *formatter;
    NSDateFormatter *deadlineFormatter;
    BHDatePicker *_datePicker;
    BOOL activities; // for the activities/comments section to determine what to show
    UIButton *activityButton;
    UIButton *commentsButton;
    UIRefreshControl *refreshControl;
}
@property (strong, nonatomic) Reminder *reminder;
@property (strong, nonatomic) User *currentUser;
@end

@implementation BHChecklistItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    library = [[ALAssetsLibrary alloc]init];
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    self.currentUser = [delegate.currentUser MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    [self loadItem:YES]; // load the item!
    activities = NO; // show comments by default (instead of activities)

    //setup communication notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(placeCall:) name:@"PlaceCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMail:) name:@"SendEmail" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendText:) name:@"SendText" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    
    //hide the back button so we can override the popViewController method and implement a "do you want to save" thing
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    
    //basic setup
    [self registerForKeyboardNotifications];
    [self setUpTimeFormatters];
    [self setUpTimePicker];
    photosArray = [NSMutableArray array];
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    //set up date picker frame(s)
    CGRect datePickerContainerRect = _datePickerContainer.frame;
    datePickerContainerRect.origin.y = height;
    datePickerContainerRect.size.width = width;
    [_datePickerContainer setFrame:datePickerContainerRect];
}

- (void)setUpTimeFormatters {
    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateFormat:@"MM/dd/yy\nh:mm a"];
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    if (self.item.criticalDate){
        deadlineFormatter = [[NSDateFormatter alloc] init];
        [deadlineFormatter setDateStyle:NSDateFormatterFullStyle];
    }
}

- (void)handleRefresh {
    [ProgressHUD show:@"Refreshing..."];
    [self loadItem:YES];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) return 0;
    else if (section == 2) return 3;
    else if (section == 6) {
        if (activities) return self.item.activities.count;
        else return self.item.comments.count + 1;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1 && !self.item.criticalDate)
        return 0;
    else
        return 40;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
    [headerView setBackgroundColor:kLightestGrayColor];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
    headerLabel.layer.cornerRadius = 3.f;
    headerLabel.clipsToBounds = YES;
    [headerLabel setBackgroundColor:[UIColor clearColor]];
    [headerLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setTextColor:[UIColor darkGrayColor]];
    switch (section) {
        case 0:
            [headerLabel setText:self.item.type];
            break;
        case 1:
            return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)]; //temporarily hide the deadline section and just return nothing
            break;
        case 2:
            [headerLabel setText:@"STATUS"];
            break;
        case 3:
            [headerLabel setText:@"PHOTOS"];
            break;
        case 4:
            [headerLabel setText:@"REMINDERS"];
            break;
        case 5:
            [headerLabel setText:@"CONTACT"];
            break;
        case 6:
        {
            [headerLabel setText:@""];
            commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [commentsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            [commentsButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadPro] size:0]];
            NSString *commentsTitle = self.item.comments.count == 1 ? @"1 COMMENT" : [NSString stringWithFormat:@"%lu COMMENTS",(unsigned long)self.item.comments.count];
            [commentsButton setTitle:commentsTitle forState:UIControlStateNormal];
            if (activities){
                [commentsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                [commentsButton setBackgroundColor:[UIColor whiteColor]];
            } else {
                [commentsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [commentsButton setBackgroundColor:kDarkGrayColor];
            }
            
            [commentsButton setFrame:CGRectMake(0, 1, width/2, 38)];
            [commentsButton addTarget:self action:@selector(showComments) forControlEvents:UIControlEventTouchUpInside];
            [headerView addSubview:commentsButton];
            
            activityButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [activityButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
            [activityButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadPro] size:0]];
            NSString *activitiesTitle = self.item.activities.count == 1 ? @"1 ACTIVITY" : [NSString stringWithFormat:@"%lu ACTIVITIES",(unsigned long)self.item.activities.count];
            [activityButton setTitle:activitiesTitle forState:UIControlStateNormal];
            if (activities){
                [activityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [activityButton setBackgroundColor:kDarkGrayColor];
            } else {
                [activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                [activityButton setBackgroundColor:[UIColor whiteColor]];
            }
            [activityButton setFrame:CGRectMake(width/2, 1, width/2, 38)];
            [activityButton addTarget:self action:@selector(showActivities) forControlEvents:UIControlEventTouchUpInside];
            [headerView addSubview:activityButton];
        }
            break;
        default:
            break;
    }
    [headerView addSubview:headerLabel];
    return headerView;
}

- (void)showActivities {
    activities = YES;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:6] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showComments {
    activities = NO;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:6] withRowAnimation:UITableViewRowAnimationFade];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        BHChecklistItemBodyCell *bodyCell = [tableView dequeueReusableCellWithIdentifier:@"ChecklistItemBodyCell"];
        bodyCell.clipsToBounds = YES;
        [bodyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [bodyCell.bodyTextView setText:self.item.body];
        [bodyCell.bodyTextView setUserInteractionEnabled:NO];
        [bodyCell.bodyTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
        CGSize size = [bodyCell.bodyTextView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
        
        CGRect textViewRect = bodyCell.bodyTextView.frame;
        textViewRect.size = size;
        [bodyCell.bodyTextView setFrame:textViewRect];
        
        return bodyCell;
    } else if (indexPath.section == 1) {
        BHItemDeadlineCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemDeadlineCell"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell.deadlineLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
        [cell.deadlineLabel setTextColor:[UIColor blackColor]];
    
        if (self.item.criticalDate){
            [cell.deadlineLabel setText:[deadlineFormatter stringFromDate:self.item.criticalDate]];
        } else {
            [cell.deadlineLabel setText:@"This item's critical date has been removed."];
        }
        
        return cell;
    } else if (indexPath.section == 2) {
        static NSString *CellIdentifier = @"ActionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        cell.backgroundColor = [UIColor whiteColor];
        [cell.textLabel setTextColor:[UIColor blackColor]];
        UIView *selectecBackgroundColor = [[UIView alloc] init];
        [selectecBackgroundColor setBackgroundColor:kBlueColor];
        cell.selectedBackgroundView = selectecBackgroundColor;
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        switch (indexPath.row) {
            case 0:
                if (self.item.state && [self.item.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
                    cell.backgroundColor = kBlueColor;
                    [cell.textLabel setTextColor:[UIColor whiteColor]];
                }
                [cell.textLabel setText:@"COMPLETED"];
                break;
            case 1:
                if (self.item.state && [self.item.state isEqualToNumber:[NSNumber numberWithInteger:kItemInProgress]]){
                    cell.backgroundColor = kBlueColor;
                    [cell.textLabel setTextColor:[UIColor whiteColor]];
                }
                [cell.textLabel setText:@"IN-PROGRESS"];
                break;
            case 2:
                if (self.item.state && [self.item.state isEqualToNumber:[NSNumber numberWithInteger:kItemNotApplicable]]){
                    cell.backgroundColor = kBlueColor;
                    [cell.textLabel setTextColor:[UIColor whiteColor]];
                }
                [cell.textLabel setText:@"NOT APPLICABLE"];
                break;
                
            default:
                break;
        }
        [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
        return cell;
    } else if (indexPath.section == 3) {
        
        BHListItemPhotoCell *photoCell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        [photoCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        photoScrollView = photoCell.scrollView;
        photoButtonContainer = photoCell.buttonContainer;
        [self redrawScrollView];
        
        [photoCell.takePhotoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        [photoCell.choosePhotoButton addTarget:self action:@selector(choosePhoto) forControlEvents:UIControlEventTouchUpInside];
        return photoCell;
        
    } else if (indexPath.section == 4) {
        BHSetReminderCell *reminderCell = [tableView dequeueReusableCellWithIdentifier:@"SetReminderCell"];
        if (reminderCell == nil) {
            reminderCell = [[[NSBundle mainBundle] loadNibNamed:@"BHSetReminderCell" owner:self options:nil] lastObject];
        }
        [reminderCell.reminderButton addTarget:self action:@selector(showDatePicker) forControlEvents:UIControlEventTouchUpInside];
        
        if (self.reminder){
            [reminderCell.reminderLabel setText:[NSString stringWithFormat:@"Reminder: %@",[formatter stringFromDate:self.reminder.reminderDate]]];
        } else {
            [reminderCell.reminderLabel setText:@"Set a reminder"];
        }
        
        return reminderCell;
    } else if (indexPath.section == 5) {
        BHItemContactCell *contactCell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        [contactCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [contactCell.emailButton addTarget:self action:@selector(emailAction) forControlEvents:UIControlEventTouchUpInside];
        [contactCell.callButton addTarget:self action:@selector(callAction) forControlEvents:UIControlEventTouchUpInside];
        [contactCell.textButton addTarget:self action:@selector(textAction) forControlEvents:UIControlEventTouchUpInside];
        
        if (IDIOM == IPAD) {
            [contactCell.callButton setHidden:YES];
        } else {
            CGFloat buttonWidth = contactCell.emailButton.frame.size.width;
            CGFloat originEmail = (width - ((buttonWidth+7) * 3))/2;
            
            CGRect emailFrame = contactCell.emailButton.frame;
            emailFrame.origin.x = originEmail;
            [contactCell.emailButton setFrame:emailFrame];
            CGRect callFrame = contactCell.callButton.frame;
            callFrame.origin.x = originEmail + (buttonWidth+7);
            [contactCell.callButton setFrame:callFrame];
            CGRect textFrame = contactCell.textButton.frame;
            textFrame.origin.x = originEmail + ((buttonWidth+7)*2);
            [contactCell.textButton setFrame:textFrame];
        }
        
        return contactCell;
    } else {
        if (!activities && indexPath.row == 0){
            BHAddCommentCell *addCommentCell = [tableView dequeueReusableCellWithIdentifier:@"AddCommentCell"];
            if (addCommentCell == nil) {
                addCommentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddCommentCell" owner:self options:nil] lastObject];
            }
            [addCommentCell.messageTextView setText:kAddCommentPlaceholder];
            addCommentTextView = addCommentCell.messageTextView;
            addCommentTextView.delegate = self;
            [addCommentTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
            
            [addCommentCell.doneButton addTarget:self action:@selector(submitComment) forControlEvents:UIControlEventTouchUpInside];
            [addCommentCell.doneButton setBackgroundColor:kSelectBlueColor];
            addCommentCell.doneButton.layer.cornerRadius = 4.f;
            addCommentCell.doneButton.clipsToBounds = YES;
            doneButton = addCommentCell.doneButton;
            return addCommentCell;
        } else {
            BHActivityCell *activityCell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
            if (activityCell == nil) {
                activityCell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
            }
            if (activities){
                Activity *activity = self.item.activities[indexPath.row];
                [activityCell.timestampLabel setText:[formatter stringFromDate:activity.createdDate]];
                [activityCell configureForActivity:activity];
            } else {
                Comment *comment = self.item.comments[indexPath.row-1]; //offset the index becuase the first row is going to be an add comment cell
                [activityCell.timestampLabel setText:[commentFormatter stringFromDate:comment.createdAt]];
                [activityCell configureForComment:comment];
            }
            return activityCell;
        }
    }
}

- (CGFloat)calculateHeightForItemBody {
    UITextView *sizingTextView = [[UITextView alloc] init];
    [sizingTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
    [sizingTextView setText:self.item.body];
    CGSize size = [sizingTextView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    return size.height + 10.f; // add a little buffer
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return [self calculateHeightForItemBody];
            break;
        case 1:
            return 60;
            break;
        case 2:
            return 54;
            break;
        case 3:
            return 100;
            break;
        case 5:
            return 88;
            break;
        default:
            return 80;
            break;
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
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
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:6] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        [textView setText:kAddCommentPlaceholder];
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
    [self.item setSaved:@NO];
    return YES;
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
        NSDictionary *info = [notification userInfo];
        NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
        NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
        CGFloat keyboardHeight = keyboardValue.CGRectValue.size.height;
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
        NSDictionary *info = [notification userInfo];
        NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
        [UIView animateWithDuration:duration
                              delay:0
                            options:curve | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                             self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                         }
                         completion:nil];
    }
}

- (void)submitComment {
    [self doneEditing];
    
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to add comments to a demo project checklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if (addCommentTextView.text.length) {
            Comment *comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [comment setBody:addCommentTextView.text];
            if (self.currentUser){
                [comment setUser:self.currentUser];
            }
            [comment setCreatedAt:[NSDate date]];
            [self.item addComment:comment];
            [comment setSaved:@NO];
            
            [self.tableView beginUpdates];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:6];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:6] withRowAnimation:UITableViewRowAnimationAutomatic];
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
                        [delegate.syncController update];
                    }];
                }
            }];
            addCommentTextView.text = kAddCommentPlaceholder;
            addCommentTextView.textColor = [UIColor lightGrayColor];
        }
    }
}

- (void)doneEditing {
    [self.view endEditing:YES];
    [UIView animateWithDuration:.25 animations:^{
        doneButton.alpha = 0.0;
    }];
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (void)callAction{
    emailBool = NO;
    textBool = NO;
    phoneBool = YES;
    [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
}

- (void)textAction{
    emailBool = NO;
    phoneBool = NO;
    textBool = YES;
    [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
}

- (void)emailAction {
    emailBool = YES;
    phoneBool = NO;
    textBool = NO;
    [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]) {
        BHPersonnelPickerViewController *vc = [segue destinationViewController];
        [vc setProjectId:_project.identifier];
        if (phoneBool) {
            [vc setPhone:YES];
        } else if (emailBool) {
            [vc setEmail:YES];
        } else if (textBool) {
            [vc setText:YES];
        }
        //[vc setUsers:_project.users.mutableCopy];
    }
}

- (void)placeCall:(NSNotification*)notification {
    if (IDIOM != IPAD){
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
            MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            [controller setSubject:[NSString stringWithFormat:@"%@",self.item.body]];
            [controller setToRecipients:@[destinationEmail]];
            if (controller) {
                [self presentViewController:controller animated:YES completion:^{
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                }];
            }
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we aren't able to send mail on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
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
    //if (result == MFMailComposeResultSent) {}
    //if (IDIOM != IPAD) [(BHAppDelegate*)[UIApplication sharedApplication].delegate setToBuildHawkAppearances];
    [self dismissViewControllerAnimated:YES completion:^{
        //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }];
}

- (void)sendText:(NSNotification*)notification {
    NSString *phone = [notification.userInfo objectForKey:@"number"];
    [(BHAppDelegate*)[UIApplication sharedApplication].delegate setDefaultAppearances];
    MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
    if ([MFMessageComposeViewController canSendText] && phone && phone.length){
        viewController.messageComposeDelegate = self;
        [viewController setRecipients:@[phone]];
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
    [(BHAppDelegate*)[UIApplication sharedApplication].delegate setToBuildHawkAppearances];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)existingPhotoButtonTapped:(UIButton*)button;
{
    [self showPhotoDetail:button.tag];
    removePhotoIdx = button.tag;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == callActionSheet || actionSheet == emailActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:kUsers]) {
            
        }
    }/* else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
    }*/
}

- (void)takePhoto {
    saveToLibrary = YES;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *vc = [[UIImagePickerController alloc] init];
        [vc setModalPresentationStyle:UIModalPresentationCurrentContext];
        [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
        [vc setDelegate:self];
        [self presentViewController:vc animated:YES completion:NULL];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We're unable to access a camera on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:NULL];
    Photo *photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [photo setFileName:@"photo.jpg"];
    [photo setImage:[BHUtilities fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]]];
    [self savePhoto:photo];
    [self.item addPhoto:photo];
    [self.tableView reloadData];
}

- (IBAction)choosePhoto {
    saveToLibrary = NO;
    [self performSegueWithIdentifier:@"AssetGroupPicker" sender:nil];
}

- (void)didFinishPickingPhotos:(NSOrderedSet *)selectedPhotos {
    for (Photo *p in selectedPhotos){
        Photo *photo = [p MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        [self.item addPhoto:photo];
        [self savePhoto:photo];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self redrawScrollView];
    [self.navigationController popToViewController:self animated:YES];
    [ProgressHUD dismiss];
}

- (void)saveToCameraLibrary:(UIImage*)originalImage {
    if (saveToLibrary){
        NSString *albumName = @"BuildHawk";
        UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
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
            } else {
                NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
            }
        }];
    }
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    if (photoToRemove.identifier){
        for (Photo *photo in self.item.photos){
            if ([photo.identifier isEqualToNumber:photoToRemove.identifier]) {
                [self.item removePhoto:photo];
                [self redrawScrollView];
                break;
            }
        }
    } else {
        [self.item removePhoto:photoToRemove];
        [self redrawScrollView];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":self.item}];
}

- (void)savePhoto:(Photo*)photo {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && ![_project.demo isEqualToNumber:@YES]){
        if (self.project && self.project.identifier){
            [photo setProject:self.project];
        }
        if (self.currentUser){
            [photo setUserName:self.currentUser.fullname];
        }
        [photo setChecklistItem:self.item];
        [photo setSource:kChecklist];
        [photo setSaved:@NO];
        [self saveToCameraLibrary:photo.image];
        [photo synchWithServer:^(BOOL completed) {
            if (completed){
                if (self.itemDelegate && [self.itemDelegate respondsToSelector:@selector(itemUpdated:)]){
                    [self.itemDelegate itemUpdated:self.item.identifier];
                }
            }
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
    
    for (Photo *photo in self.item.photos) {
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        } else if (photo.urlSmall.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        } else {
            [imageButton setImage:[UIImage imageNamed:@"whiteIcon"] forState:UIControlStateNormal];
        }
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageButton.imageView.clipsToBounds = YES;
        [imageButton setTag:[self.item.photos indexOfObject:photo]];
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
    
    [UIView animateWithDuration:.3 delay:.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [photoScrollView setAlpha:1.0];
    } completion:^(BOOL finished) {
        //photoScrollView.layer.shouldRasterize = YES;
        //photoScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }];
}

#pragma mark - API GET & PATCH item

- (void)loadItem:(BOOL)shouldReload{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [manager GET:[NSString stringWithFormat:@"%@/checklist_items/%@",kApiBaseUrl,self.item.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success getting checklist item: %@",[responseObject objectForKey:@"checklist_item"]);
            [self.item populateFromDictionary:[responseObject objectForKey:@"checklist_item"]];
            [self.item.reminders enumerateObjectsUsingBlock:^(Reminder *reminder, NSUInteger idx, BOOL *stop) {
                if ([reminder.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
                    self.reminder = reminder;
                    *stop = YES;
                }
            }];
            if (shouldReload)[[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":self.item}];
            [ProgressHUD dismiss];
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            [self.tableView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            if (delegate.connected){
                NSLog(@"failure getting checklist item: %@",error.description);
            }
        }];
    }
}

//This method adds a NO boolean flag to the update checklist method
- (void)save {
    [self updateChecklistItem:NO];
}

- (void)updateChecklistItem:(BOOL)dismiss {
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to update checklist items on a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else if (!delegate.connected) {
        [self.item setSaved:@NO];
        [delegate.syncController update];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":self.item}];
        [ProgressHUD showSuccess:@"Saved"];
    } else {
        [ProgressHUD show:@"Updating item..."];
        [self.item synchWithServer:^(BOOL completed) {
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":self.item}];
            }];
            
            if (completed){
                [delegate.syncController update];
                
                if (dismiss){
                    [self.navigationController popViewControllerAnimated:YES];
                    [ProgressHUD dismiss];
                } else {
                    [ProgressHUD showSuccess:@"Saved"];
                    [self.tableView reloadData];
                }
                
            } else {
                [ProgressHUD dismiss];
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while updating this item. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                [self.item setSaved:@NO];
            }
        }];
    }
}

- (void)showPhotoDetail:(NSInteger)idx {
    browserPhotos = [NSMutableArray new];
    for (Photo *photo in self.item.photos) {
        MWPhoto *mwPhoto;
        if (photo.image){
            mwPhoto = [MWPhoto photoWithImage:photo.image];
        } else {
            mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        }
        if (photo.caption.length){
            mwPhoto.caption = photo.caption;
        }
        [mwPhoto setPhoto:photo];
        [browserPhotos addObject:mwPhoto];
    }
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    if ([_project.demo  isEqualToNumber:@YES]) {
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
    if (indexPath.section == 2) {
        [self.item setSaved:@NO];
        switch (indexPath.row) {
            case 0:
                if ([self.item.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
                    self.item.state = nil;
                } else {
                    self.item.state = [NSNumber numberWithInteger:kItemCompleted];
                }
                break;
            case 1:
                if ([self.item.state isEqualToNumber:[NSNumber numberWithInteger:kItemInProgress]]){
                    [self.item setState:nil];
                } else {
                    [self.item setState:[NSNumber numberWithInteger:kItemInProgress]];
                }
                break;
            case 2:
                if ([self.item.state isEqualToNumber:[NSNumber numberWithInteger:kItemNotApplicable]]){
                    [self.item setState:nil];
                } else {
                    [self.item setState:[NSNumber numberWithInteger:kItemNotApplicable]];
                }
                break;
            default:
                break;
        }
        [UIView setAnimationsEnabled:NO];
        [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2],[NSIndexPath indexPathForRow:1 inSection:2],[NSIndexPath indexPathForRow:2 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
        [UIView setAnimationsEnabled:YES];
    } else if (indexPath.section == 4){
        if (self.reminder){
            
        } else {
            [self showDatePicker];
        }
        
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 4) {
        if (self.reminder){
            return YES;
        } else {
            return NO;
        }

    } else if (indexPath.section == 6 && self.item.comments.count && indexPath.row > 0 && !activities) {
        
        Comment *comment = self.item.comments[indexPath.row-1];
        if ([comment.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] || (self.currentUser && self.currentUser.uberAdmin)){
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
        if (indexPath.section == 4){
            [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to cancel this reminder?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
        } else if (!activities) {
            indexPathForDeletion = indexPath;
            [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to delete this comment?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil] show];
        }
    }
}

- (void)deleteComment {
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete comments from a demo project checklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        Comment *comment = self.item.comments[indexPathForDeletion.row-1];
        if ([comment.identifier isEqualToNumber:@0]){
            [self.item removeComment:comment];
            [comment MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPathForDeletion.section] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        
        } else if (delegate.connected) {
            [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kApiBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully deleted activity: %@",responseObject);
                [self.item removeComment:comment];
                [comment MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPathForDeletion.section] withRowAnimation:UITableViewRowAnimationFade];
                //[self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                //NSLog(@"Failed to delete comment: %@",error.description);
            }];
        }else {
            [[[UIAlertView alloc] initWithTitle:@"Offline" message:@"Deleting comments is disabled while offline." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }
}

#pragma mark - Date Picker and Reminder Logic

- (void)setUpTimePicker {
    _selectButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.7].CGColor;
    _selectButton.layer.borderWidth = 1.f;
    _selectButton.layer.cornerRadius = 3.f;
    _selectButton.clipsToBounds = YES;
    [_selectButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
    _cancelButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.7].CGColor;
    _cancelButton.layer.borderWidth = 1.f;
    _cancelButton.layer.cornerRadius = 3.f;
    _cancelButton.clipsToBounds = YES;
    [_cancelButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
}

- (void)showDatePicker {
    if (_datePicker == nil) {
        _datePicker = [[BHDatePicker alloc] initWithFrame:CGRectMake(0, _cancelButton.frame.size.height + _cancelButton.frame.origin.y+7, _datePickerContainer.frame.size.width, 162)];
        [_datePickerContainer addSubview:_datePicker];
    }
    
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    
    if (overlayBackground == nil){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlayUnderNav:NO];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelDatePicker)];
        tapGesture.numberOfTapsRequired = 1;
        [overlayBackground addGestureRecognizer:tapGesture];
        [self.view insertSubview:overlayBackground belowSubview:_datePickerContainer];
        [self.view bringSubviewToFront:_datePickerContainer];
        [UIView animateWithDuration:0.75 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _datePickerContainer.transform = CGAffineTransformMakeTranslation(0, -(_datePickerContainer.frame.size.height+_selectButton.frame.size.height*2));
            
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [self cancelDatePicker];
    }
}

- (IBAction)selectDate {
    [self cancelDatePicker];
    [self setReminderDate:_datePicker.date];
}

- (IBAction)cancelDatePicker{
    self.navigationItem.rightBarButtonItem = saveButton;
    self.navigationItem.hidesBackButton = NO;
    
    [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _datePickerContainer.transform = CGAffineTransformIdentity;
        self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
        [overlayBackground setAlpha:0];
    } completion:^(BOOL finished) {
        overlayBackground = nil;
        [overlayBackground removeFromSuperview];
    }];
}

- (void)setReminderDate:(NSDate*)date {
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"Sorry, but we're unable to create reminders from demo checklist items." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if (self.item.reminders.count){
            self.reminder = self.item.reminders.firstObject;
        } else {
            self.reminder = [Reminder MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [self.item addReminder:self.reminder];
        }
        [self.reminder setSaved:@NO];
        [self.reminder setReminderDate:date];
        if (self.currentUser){
            [self.reminder setUser:self.currentUser];
        }
        
        [self.reminder setProject:self.project];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:4]] withRowAnimation:UITableViewRowAnimationFade];
        [self.reminder synchWithServer:^(BOOL completed) {
            if (completed){
                [self.reminder setSaved:@YES];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            } else {
                if (delegate.connected){
                    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to create a reminder." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                } else {
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait]; //offline
                }
            }
        }];
    }
}

- (void)deleteReminder {
    if ([self.project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"Sorry, but we're unable to delete reminders from demo checklist items." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if ([self.reminder.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [self.item removeReminder:self.reminder];
            [self.reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            self.reminder = nil;
            
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            [manager DELETE:[NSString stringWithFormat:@"%@/reminders/%@",kApiBaseUrl,self.reminder.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully delete reminder: %@",responseObject);
                [self.item removeReminder:self.reminder];
                [self.reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                self.reminder = nil;
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to delete reminder: %@",error.description);
            }];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Save"]) {
        [self updateChecklistItem:YES];
    }  else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Discard"]) {
        [self.item setSaved:@YES];
        [self loadItem:NO];
        [self.navigationController popViewControllerAnimated:YES];
    }  else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Delete"]) {
        [self deleteComment];
    }  else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Yes"]) {
        [self deleteReminder];
    }
}

#pragma mark - Back Navigation and Cleanup

- (void)back {
    if ([self.item.saved isEqualToNumber:@NO] && [_project.demo isEqualToNumber:@NO] && delegate.connected) {
        [[[UIAlertView alloc] initWithTitle:@"Unsaved Changes" message:@"Do you want to save your unsaved changes?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Save", nil] show];
    } else {
        [self dismiss];
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
    [ProgressHUD dismiss];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
