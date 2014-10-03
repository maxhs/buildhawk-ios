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
    BOOL textBool;
    BOOL iPad;
    BOOL saveToLibrary;
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
    NSInteger removePhotoIdx;
    UIView *photoButtonContainer;
    NSMutableArray *browserPhotos;
    ALAssetsLibrary *library;
    Project *savedProject;
    NSIndexPath *indexPathForDeletion;
    UIView *overlayBackground;
    NSDateFormatter *formatter;
    BHDatePicker *_datePicker;
    Reminder *_reminder;
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
    self.tableView.backgroundColor = [UIColor whiteColor];

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

    [self loadItem:YES];

    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateStyle:NSDateFormatterShortStyle];
    [commentFormatter setTimeStyle:NSDateFormatterShortStyle];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(placeCall:) name:@"PlaceCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMail:) name:@"SendEmail" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendText:) name:@"SendText" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [self registerForKeyboardNotifications];
    
    _selectButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.7].CGColor;
    _selectButton.layer.borderWidth = 1.f;
    _selectButton.layer.cornerRadius = 3.f;
    _selectButton.clipsToBounds = YES;
    _cancelButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.7].CGColor;
    _cancelButton.layer.borderWidth = 1.f;
    _cancelButton.layer.cornerRadius = 3.f;
    _cancelButton.clipsToBounds = YES;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)loadItem:(BOOL)shouldReload{
    [manager GET:[NSString stringWithFormat:@"%@/checklist_items/%@",kApiBaseUrl,_item.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting checklist item: %@",[responseObject objectForKey:@"checklist_item"]);
        [_item populateFromDictionary:[responseObject objectForKey:@"checklist_item"]];
        [_item.reminders enumerateObjectsUsingBlock:^(Reminder *reminder, NSUInteger idx, BOOL *stop) {
            if ([reminder.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
                _reminder = reminder;
                *stop = YES;
            }
        }];
        if (shouldReload)[[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":_item}];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure getting checklist item: %@",error.description);
    }];
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

- (void)showDatePicker{
    if (_datePicker == nil) {
        _datePicker = [[BHDatePicker alloc] initWithFrame:CGRectMake(0, _cancelButton.frame.size.height + _cancelButton.frame.origin.y+24, _datePickerContainer.frame.size.width, 162)];
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
    [parameters setObject:_item.project.identifier forKey:@"project_id"];
    [manager POST:[NSString stringWithFormat:@"%@/reminders",kApiBaseUrl] parameters:@{@"reminder":parameters,@"date":[NSNumber numberWithDouble:[date timeIntervalSince1970]]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a reminder: %@",responseObject);
        if ([responseObject objectForKey:@"failure"]){
            NSLog(@"Failed to create checklist item: %@",responseObject);
        } else {
            if (!_reminder){
                _reminder = [Reminder MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [_reminder populateFromDictionary:[responseObject objectForKey:@"reminder"]];
            [_item addReminder:_reminder];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
            }];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error creating a checklist item reminder: %@",error.description);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) return 3;
    else if (section == 5) return _item.activities.count + 1;
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 40)];
    [headerView setBackgroundColor:[UIColor whiteColor]];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 40)];
    headerLabel.layer.cornerRadius = 3.f;
    headerLabel.clipsToBounds = YES;
    [headerLabel setBackgroundColor:kLightestGrayColor];
    [headerLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setTextColor:[UIColor darkGrayColor]];
    switch (section) {
        case 0:
            [headerLabel setText:_item.type];
            break;
        case 1:
            [headerLabel setText:@"STATUS"];
            break;
        case 2:
            [headerLabel setText:@"PHOTOS"];
            break;
        case 3:
            [headerLabel setText:@"REMINDERS"];
            break;
        case 4:
            [headerLabel setText:@"CONTACT"];
            break;
        case 5:
            [headerLabel setText:@"COMMENTS & ACTIVITY"];
            break;
        default:
            break;
    }
    [headerView addSubview:headerLabel];
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        BHChecklistItemBodyCell *bodyCell = [tableView dequeueReusableCellWithIdentifier:@"ChecklistItemBodyCell"];
        if (bodyCell == nil) {
            bodyCell = [[[NSBundle mainBundle] loadNibNamed:@"BHChecklistItemBodyCell" owner:self options:nil] lastObject];
        }
        [bodyCell.bodyTextView setText:_item.body];
        [bodyCell.bodyTextView setUserInteractionEnabled:NO];
        
        if (IDIOM == IPAD){
            [bodyCell.bodyTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProRegular] size:0]];
        } else {
            [bodyCell.bodyTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
        }
        
        return bodyCell;
    } else if (indexPath.section == 1) {
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
                if (_item.state && [_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
                    cell.backgroundColor = kBlueColor;
                    [cell.textLabel setTextColor:[UIColor whiteColor]];
                }
                [cell.textLabel setText:@"COMPLETED"];
                break;
            case 1:
                if (_item.state && [_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemInProgress]]){
                    cell.backgroundColor = kBlueColor;
                    [cell.textLabel setTextColor:[UIColor whiteColor]];
                }
                [cell.textLabel setText:@"IN-PROGRESS"];
                break;
            case 2:
                if (_item.state && [_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemNotApplicable]]){
                    cell.backgroundColor = kBlueColor;
                    [cell.textLabel setTextColor:[UIColor whiteColor]];
                }
                [cell.textLabel setText:@"NOT APPLICABLE"];
                break;
                
            default:
                break;
        }
        [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0]];
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
        
        if (_reminder){
            [reminderCell.reminderLabel setText:[NSString stringWithFormat:@"Reminder: %@",[formatter stringFromDate:_reminder.reminderDate]]];
        } else {
            [reminderCell.reminderLabel setText:@"Set a reminder"];
        }
        
        return reminderCell;
    } else if (indexPath.section == 4) {
        BHItemContactCell *contactCell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        if (contactCell == nil) {
            contactCell = [[[NSBundle mainBundle] loadNibNamed:@"BHItemContactCell" owner:self options:nil] lastObject];
        }
        [contactCell.emailButton addTarget:self action:@selector(emailAction) forControlEvents:UIControlEventTouchUpInside];
        [contactCell.callButton addTarget:self action:@selector(callAction) forControlEvents:UIControlEventTouchUpInside];
        [contactCell.textButton addTarget:self action:@selector(textAction) forControlEvents:UIControlEventTouchUpInside];
        
        if (iPad) {
            [contactCell.callButton setHidden:YES];
            contactCell.emailButton.transform = CGAffineTransformMakeTranslation(275, 0);
            contactCell.textButton.transform = CGAffineTransformMakeTranslation(173, 0);
        }
        return contactCell;
    } else {
        if (indexPath.row == 0){
            BHAddCommentCell *addCommentCell = [tableView dequeueReusableCellWithIdentifier:@"AddCommentCell"];
            if (addCommentCell == nil) {
                addCommentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddCommentCell" owner:self options:nil] lastObject];
            }
            [addCommentCell.messageTextView setText:kAddCommentPlaceholder];
            addCommentTextView = addCommentCell.messageTextView;
            addCommentTextView.delegate = self;
            [addCommentTextView setFont:[UIFont fontWithName:kMyriadProRegular size:17]];
            
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
            Activity *activity = _item.activities[indexPath.row-1];
            [activityCell configureForActivity:activity];
            [activityCell.timestampLabel setText:[formatter stringFromDate:activity.createdDate]];
            return activityCell;
        }
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
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:5] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
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
    [_item setSaved:@NO];
    return YES;
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
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                     }
                     completion:nil];
}

- (void)submitComment {
    if ([_project.demo isEqualToNumber:@YES]){
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
                [set removeObjectAtIndex:set.count-1];
                [set insertObject:activity atIndex:0];
                [_item setActivities:set];
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:5];
                
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                
                
                addCommentTextView.text = kAddCommentPlaceholder;
                addCommentTextView.textColor = [UIColor lightGrayColor];
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
        [vc setProject:_project];
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
            [(BHAppDelegate*)[UIApplication sharedApplication].delegate setDefaultAppearances];
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
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
    [(BHAppDelegate*)[UIApplication sharedApplication].delegate setToBuildHawkAppearances];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendText:(NSString*)phone {
    [(BHAppDelegate*)[UIApplication sharedApplication].delegate setDefaultAppearances];
    MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
    if ([MFMessageComposeViewController canSendText]){
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
    [self dismissViewControllerAnimated:YES completion:NULL];
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
                NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
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
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && ![_project.demo isEqualToNumber:@YES]){
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
        [photoParameters setObject:@YES forKey:@"mobile"];
        
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
        }*/
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        } else if (photo.urlSmall.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal];
        } else if (photo.urlThumb.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlThumb] forState:UIControlStateNormal];
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
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to update checklist items on a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (_item.state){
            // if we don't send a state, this will erase the checklist item's current state via the API
            [parameters setObject:_item.state forKey:@"state"];
        }
        
        [ProgressHUD show:@"Updating item..."];
        [manager PATCH:[NSString stringWithFormat:@"%@/checklist_items/%@", kApiBaseUrl,_item.identifier] parameters:@{@"checklist_item":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success updating checklist item %@",responseObject);
            
            [_item setSaved:@YES];
            [_item populateFromDictionary:[responseObject objectForKey:@"checklist_item"]];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadChecklistItem" object:nil userInfo:@{@"item":_item}];
                
                if (stayHere){
                    [ProgressHUD showSuccess:@"Saved"];
                    [self.tableView reloadData];
                } else {
                    [self.navigationController popViewControllerAnimated:YES];
                    [ProgressHUD dismiss];
                }
                
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure updating checklist item: %@",error.description);
            [ProgressHUD dismiss];
            [_item setSaved:@NO];
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
    if (indexPath.section == 1) {
        [_item setSaved:@NO];
        switch (indexPath.row) {
            case 0:
                if ([_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
                    _item.state = nil;
                } else {
                    _item.state = [NSNumber numberWithInteger:kItemCompleted];
                }
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case 1:
                if ([_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemInProgress]]){
                    [_item setState:nil];
                } else {
                    [_item setState:[NSNumber numberWithInteger:kItemInProgress]];
                }
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case 2:
                if ([_item.state isEqualToNumber:[NSNumber numberWithInteger:kItemNotApplicable]]){
                    [_item setState:nil];
                } else {
                    [_item setState:[NSNumber numberWithInteger:kItemNotApplicable]];
                }
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                break;
            default:
                break;
        }
    } else if (indexPath.section == 3){
        if (_reminder){
            
        } else {
            [self showDatePicker];
        }
        
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) {
        if (_reminder){
            return YES;
        } else {
            return NO;
        }

    } else if (indexPath.section == 5 && _item.activities.count && indexPath.row > 0) {
        Activity *activity = _item.activities[indexPath.row - 1];
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
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete comments from a demo project checklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        Activity *activity = _item.activities[indexPathForDeletion.row-1];
        if ([activity.comment.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [_item removeActivity:activity];
            [activity MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kApiBaseUrl,activity.comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully deleted activity: %@",responseObject);
                [_item removeActivity:activity];
                [activity MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                //NSLog(@"Failed to delete comment: %@",error.description);
            }];
        }
    }
}

- (void)deleteReminder {
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete reminders from a demo project checklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if ([_reminder.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [_item removeReminder:_reminder];
            [_reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            _reminder = nil;
            
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            [manager DELETE:[NSString stringWithFormat:@"%@/reminders/%@",kApiBaseUrl,_reminder.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"successfully delete reminder: %@",responseObject);
                [_item removeReminder:_reminder];
                [_reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                _reminder = nil;
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to delete reminder: %@",error.description);
            }];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Save"]) {
        [self updateChecklistItem:NO];
    }  else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Discard"]) {
        [self loadItem:NO];
        [self.navigationController popViewControllerAnimated:YES];
    }  else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Delete"]) {
        [self deleteComment];
    }  else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Yes"]) {
        [self deleteReminder];
    }
}

- (void)back {
    if ([_item.saved isEqualToNumber:@NO] && [_project.demo isEqualToNumber:@NO]) {
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
