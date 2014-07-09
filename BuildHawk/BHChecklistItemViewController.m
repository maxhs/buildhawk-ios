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
#import "BHItemContactCell.h"
#import "BHSetReminderCell.h"
#import "BHActivityCell.h"
#import "Activity+helper.h"
#import "Reminder+helper.h"

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
    UIView *overlayBackground;
    NSDateFormatter *formatter;
    BHDatePicker *_datePicker;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];

    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    _selectButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.5].CGColor;
    _selectButton.layer.borderWidth = .5f;
    _selectButton.layer.cornerRadius = 2.f;
    _selectButton.clipsToBounds = YES;
    _cancelButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.5].CGColor;
    _cancelButton.layer.borderWidth = .5f;
    _cancelButton.layer.cornerRadius = 2.f;
    _cancelButton.clipsToBounds = YES;
}

- (void)loadItem{
    [manager GET:[NSString stringWithFormat:@"%@/checklist_items/%@",kApiBaseUrl,_item.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success getting checklist item: %@",[responseObject objectForKey:@"checklist_item"]);
        [_item populateFromDictionary:[responseObject objectForKey:@"checklist_item"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":_item}];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure getting checklist item: %@",error.description);
    }];
}

- (IBAction)cancelDatePicker{
    [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _datePickerContainer.transform = CGAffineTransformIdentity;
        self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
        [overlayBackground setAlpha:0];
    } completion:^(BOOL finished) {
        overlayBackground = nil;
        [overlayBackground removeFromSuperview];
    }];
}

- (void)showDatePicker{
    if (_datePicker == nil) {
        _datePicker = [[BHDatePicker alloc] initWithFrame:CGRectMake(0, _cancelButton.frame.size.height + _cancelButton.frame.origin.y+24, _datePickerContainer.frame.size.width, 162)];
        [_datePickerContainer addSubview:_datePicker];
    }
    
    if (overlayBackground == nil){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlayUnderNav:NO];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelDatePicker)];
        tapGesture.numberOfTapsRequired = 1;
        [overlayBackground addGestureRecognizer:tapGesture];
        [self.view insertSubview:overlayBackground belowSubview:_datePickerContainer];
        [self.view bringSubviewToFront:_datePickerContainer];
        [UIView animateWithDuration:0.75 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _datePickerContainer.transform = CGAffineTransformMakeTranslation(0, -(_datePickerContainer.frame.size.height+_selectButton.frame.size.height));
            
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [self cancelDatePicker];
    }
}

- (IBAction)selectDate {
    [self cancelDatePicker];
    [self setReminder:_datePicker.date];
}

- (void)setReminder:(NSDate*)date {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [parameters setObject:_item.identifier forKey:@"checklist_item_id"];
    if (_item.project && ![_item.project.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        [parameters setObject:_item.project.identifier forKey:@"project_id"];
    }
    [manager POST:[NSString stringWithFormat:@"%@/reminders",kApiBaseUrl] parameters:@{@"reminder":parameters,@"date":[NSNumber numberWithDouble:[date timeIntervalSince1970]]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success creating a reminder: %@",responseObject);
        Reminder *reminder = [Reminder MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"reminder"] objectForKey:@"id"]];
        if (!reminder){
            reminder = [Reminder MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [reminder populateFromDictionary:[responseObject objectForKey:@"reminder"]];
        [_item addReminder:reminder];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Error creating a checklist item reminder: %@",error.description);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) return 3;
    else if (section == 6) return _item.activities.count;
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 30;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return _item.type;
            break;
        case 1:
            return @"Status";
            break;
        case 2:
            return @"Photos";
            break;
        case 3:
            return @"Reminders";
            break;
        case 4:
            return @"Contact";
            break;
        case 5:
            return @"Comments";
            break;
        case 6:
            return @"Activity";
            break;
        default:
            return @"";
            break;
    }
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
                if (_item.state && [_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                [cell.textLabel setText:@"COMPLETED"];
                break;
            case 1:
                if (_item.state && [_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemInProgress]]){
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                [cell.textLabel setText:@"IN-PROGRESS"];
                break;
            case 2:
                if (_item.state && [_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemNotApplicable]]){
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
        BHSetReminderCell *reminderCell = [tableView dequeueReusableCellWithIdentifier:@"SetReminderCell"];
        if (reminderCell == nil) {
            reminderCell = [[[NSBundle mainBundle] loadNibNamed:@"BHSetReminderCell" owner:self options:nil] lastObject];
        }
        [reminderCell.reminderButton addTarget:self action:@selector(showDatePicker) forControlEvents:UIControlEventTouchUpInside];
        
        [reminderCell.reminderLabel setText:@"Set a reminder"];
        for (Reminder *r in _item.reminders){
            if ([r.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
                NSLog(@"Found a checklist item reminder for the current user");
                Reminder *reminder = _item.reminders.lastObject;
                [reminderCell.reminderLabel setText:[NSString stringWithFormat:@"Reminder: %@",[formatter stringFromDate:reminder.reminderDate]]];
                break;
            }
        }
        return reminderCell;
    } else if (indexPath.section == 4) {
        BHItemContactCell *contactCell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        if (contactCell == nil) {
            contactCell = [[[NSBundle mainBundle] loadNibNamed:@"BHItemContactCell" owner:self options:nil] lastObject];
        }
        [contactCell.emailButton addTarget:self action:@selector(emailAction) forControlEvents:UIControlEventTouchUpInside];
        [contactCell.callButton addTarget:self action:@selector(callAction) forControlEvents:UIControlEventTouchUpInside];
        [contactCell.textButton addTarget:self action:@selector(sendText) forControlEvents:UIControlEventTouchUpInside];
        if (iPad) {
            [contactCell.callButton setHidden:YES];
            contactCell.emailButton.transform = CGAffineTransformMakeTranslation(275, 0);
            contactCell.textButton.transform = CGAffineTransformMakeTranslation(173, 0);
        }
        return contactCell;
    } else if (indexPath.section == 5) {
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
    }/* else  if (indexPath.section == 6){
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
    }*/ else {
        BHActivityCell *activityCell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
        if (activityCell == nil) {
            activityCell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
        }
        Activity *activity = _item.activities[indexPath.row];
        [activityCell configureForActivity:activity];
        [activityCell.timestampLabel setText:[formatter stringFromDate:activity.createdDate]];
        return activityCell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 120;
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

-(void)willShowKeyboard:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
}

-(void)willHideKeyboard:(NSNotification*)notification {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    shouldSave = YES;
    UIEdgeInsets tempInset = self.tableView.contentInset;
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
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:5] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
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
            [self.tableView reloadData];
            NSDictionary *commentDict = @{@"checklist_item_id":_item.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"body":addCommentTextView.text};
            [manager POST:[NSString stringWithFormat:@"%@/comments",kApiBaseUrl] parameters:@{@"comment":commentDict} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"success posting a new comment %@",responseObject);
                Activity *activity = [Activity MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [activity populateFromDictionary:[responseObject objectForKey:@"activity"]];
                NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:_item.activities];
                [set insertObject:activity atIndex:0];
                _item.activities = set;
                
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:6] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                
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
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]) {
        BHPersonnelPickerViewController *vc = [segue destinationViewController];
        if (phoneBool) {
            [vc setPhone:YES];
        } else if (emailBool) {
            [vc setEmail:YES];
        }
        //[vc setUsers:_project.users.mutableCopy];
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
                
                UIImage* image = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                     scale:[UIScreen mainScreen].scale orientation:orientation];
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
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *correctedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return correctedImage;
}

- (void)savePostToLibrary:(UIImage*)originalImage {
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
}

- (void)saveImage:(UIImage*)image {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && ![_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [self savePostToLibrary:image];
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        NSMutableDictionary *photoParameters = [NSMutableDictionary dictionary];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]){
            [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"company_id"];
        }
        if (_project && _project.identifier){
            [photoParameters setObject:_project.identifier forKey:@"project_id"];
        }
        [photoParameters setObject:_item.identifier forKey:@"checklist_item_id"];
        [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [photoParameters setObject:kChecklist forKey:@"source"];
        [photoParameters setObject:[NSNumber numberWithBool:YES] forKey:@"mobile"];
        
        [manager POST:[NSString stringWithFormat:@"%@/checklist_items/photo/",kApiBaseUrl] parameters:@{@"photo":photoParameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
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
        
        if (_item.state){
            [parameters setObject:_item.state forKey:@"state"];
        }
    
        [ProgressHUD show:@"Updating item..."];
        [manager PATCH:[NSString stringWithFormat:@"%@/checklist_items/%@", kApiBaseUrl,_item.identifier] parameters:@{@"checklist_item":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success updating checklist item %@",responseObject);
            [_item populateFromDictionary:[responseObject objectForKey:@"checklist_item"]];
            NSLog(@"item expanded? %@ %@",_item.category.expanded, _item.category.phase.expanded);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":_item}];
            [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
                NSLog(@"item expanded? %@ %@",_item.category.expanded, _item.category.phase.expanded);
                NSLog(@"What happened during checklist item save? %hhd %@",success, error);
                [self.navigationController popViewControllerAnimated:YES];
                [ProgressHUD dismiss];
            }];
            
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
        if (photo.caption.length){
            mwPhoto.caption = photo.caption;
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
                if ([_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
                    _item.state = nil;
                } else {
                    _item.state = [NSNumber numberWithInteger:kItemCompleted];
                }
                [tableView reloadData];
                break;
            case 1:
                if ([_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemInProgress]]){
                    [_item setState:nil];
                } else {
                    [_item setState:[NSNumber numberWithInteger:kItemInProgress]];
                }
                [tableView reloadData];
                break;
            case 2:
                if ([_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemNotApplicable]]){
                    [_item setState:nil];
                } else {
                    [_item setState:[NSNumber numberWithInteger:kItemNotApplicable]];
                }
                [tableView reloadData];
                break;
            default:
                break;
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) {
        if (_item.reminders.count){
            return YES;
        } else {
            return NO;
        }

    } else if (indexPath.section == 6) {
        Activity *activity = [_item.activities objectAtIndex:indexPath.row];
        if ([activity.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] && [activity.activityType isEqualToString:kComment]){
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
        if (indexPath.section == 3){
            [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to cancel this reminder?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
        } else {
            indexPathForDeletion = indexPath;
            [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to delete this comment?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil] show];
        }
    }
}

- (void)deleteComment {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete comments from a demo project checklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        Comment *comment = [_item.comments objectAtIndex:indexPathForDeletion.row];
        if (![comment.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kApiBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully deleted comment: %@",responseObject);
                [_item removeComment:comment];
                
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                //NSLog(@"Failed to delete comment: %@",error.description);
            }];
        } else {
            [_item removeComment:comment];
            
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void)deleteReminder {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete reminders from a demo project checklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        Reminder *reminder = _item.reminders.lastObject;
        if (![reminder.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [manager DELETE:[NSString stringWithFormat:@"%@/reminders/%@",kApiBaseUrl,reminder.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"successfully delete reminder: %@",responseObject);
                [_item removeReminder:reminder];
                
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to delete reminder: %@",error.description);
            }];
        } else {
            [_item removeReminder:reminder];
            
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
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
    }  else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Yes"]) {
        [self deleteReminder];
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
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
