//
//  BHSettingsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/12/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHSettingsViewController.h"
#import "BHAppDelegate.h"
#import "Alternate+helper.h"
#import "BHSettingsCell.h"

@interface BHSettingsViewController () <UITextFieldDelegate, UIAlertViewDelegate> {
    UIBarButtonItem *backButton;
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *doneButton;
    NSIndexPath *alternateIndexPathForDeletion;
    UITextField *addAlternateTextField;
    UITextField *firstNameTextField;
    UITextField *lastNameTextField;
    UITextField *emailTextField;
    UITextField *phoneTextField;
    CGFloat width;
    CGFloat height;
}
@property (strong, nonatomic) User *currentUser;
@end

@implementation BHSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
    doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEditing)];
    
    self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    self.tableView.rowHeight = 60;

    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.navigationController.navigationBar.frame.size.height, 0);
    
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 88)];
    [footerLabel setText:[NSString stringWithFormat:@"VERSION: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
    [footerLabel setTextAlignment:NSTextAlignmentCenter];
    [footerLabel setBackgroundColor:[UIColor clearColor]];
    [footerLabel setTextColor:[UIColor lightGrayColor]];
    [footerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadPro] size:0]];
    self.tableView.tableFooterView = footerLabel;
    
    [self registerForKeyboardNotifications];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (delegate.connected) {
        
    } else {
        [BHAlert show:@"The ability to save settings is disabled while your device is offline." withTime:3.3f persist:NO];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 4;
            break;
        case 1:
            return self.currentUser.alternates.count + 1;
            break;
        case 2:
            return 3;
            break;
        default:
            break;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SettingsCell";
    BHSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
    [cell.textField setText:@""];
    [cell.textField setPlaceholder:@""];
    [cell.textLabel setText:@""];
    cell.accessoryView = nil;
    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    cell.textField.delegate = self;
    [cell.actionButton setHidden:YES];
    if (indexPath.section == 0){
        [cell.textField setTag:indexPath.row];
        [cell.textField setEnabled:YES];
        switch (indexPath.row) {
            case 0:
            {
                if (self.currentUser.firstName.length){
                    [cell.textField setText:self.currentUser.firstName];
                }
                [cell.textField setPlaceholder:@"Your first name"];
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                cell.textField.returnKeyType = UIReturnKeyNext;
                firstNameTextField = cell.textField;
            }
                break;
            case 1:
            {
                if (self.currentUser.lastName.length){
                    [cell.textField setText:self.currentUser.lastName];
                }
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                [cell.textField setPlaceholder:@"Your last name"];
                cell.textField.returnKeyType = UIReturnKeyNext;
                lastNameTextField = cell.textField;
            }
                break;
            case 2:
            {
                [cell.textField setText:self.currentUser.email];
                [cell.textField setPlaceholder:@"Your email address"];
                [cell.textField setKeyboardType:UIKeyboardTypeEmailAddress];
                cell.textField.returnKeyType = UIReturnKeyNext;
                emailTextField = cell.textField;
            }
                break;
            case 3:
            {
                if (self.currentUser.formattedPhone.length){
                    [cell.textField setText:self.currentUser.formattedPhone];
                }
                [cell.textField setKeyboardType:UIKeyboardTypePhonePad];
                [cell.textField setPlaceholder:@"Your phone number"];
                phoneTextField = cell.textField;
                cell.textField.returnKeyType = UIReturnKeyDone;
            }
                break;
                
            default:
                break;
        }
    } else if (indexPath.section == 1){
        [cell.textField setEnabled:YES];
        if (indexPath.row == self.currentUser.alternates.count){
            cell.textField.placeholder = @"Any alternate email addresses?";
            [cell.actionButton addTarget:self action:@selector(createAlternate) forControlEvents:UIControlEventTouchUpInside];;
            addAlternateTextField = cell.textField;
            addAlternateTextField.delegate = self;
            [cell.actionButton setHidden:NO];
            [cell.textLabel setText:@""];
        } else {
            Alternate *alternate = self.currentUser.alternates[indexPath.row];
            if (alternate.email.length){
                [cell.textLabel setText:alternate.email];
            }
            [cell.textField setHidden:YES];
        }
        
    } else {
        [cell.textField setEnabled:NO];
        UISwitch *settingsSwitch = [[UISwitch alloc] init];
        cell.accessoryView = settingsSwitch;
        settingsSwitch.tag = indexPath.row;
        [settingsSwitch addTarget:self action:@selector(switchFlipped:) forControlEvents:UIControlEventValueChanged];
        [cell.actionButton setHidden:YES];
        [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
        switch (indexPath.row) {
            case 0:
            {
                [cell.textLabel setText:@"Emails"];
                [settingsSwitch setOn:self.currentUser.emailPermissions.boolValue];
            }
                break;
            case 1:
            {
                [cell.textLabel setText:@"Push notifications"];
                [settingsSwitch setOn:self.currentUser.pushPermissions.boolValue];
            }
                break;
            case 2:
            {
                [cell.textLabel setText:@"Text notifications"];
                [settingsSwitch setOn:self.currentUser.textPermissions.boolValue];
            }
                break;
                
            default:
                break;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 34)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, width-10, 34)];
    [headerLabel setTextColor:[UIColor colorWithWhite:.77 alpha:1]];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kOpenSans] size:0]];
    switch (section) {
        case 0:
            headerLabel.text = @"Personal details".uppercaseString;
            break;
        case 1:
            headerLabel.text = @"Alternate contact information".uppercaseString;
            break;
        case 2:
            headerLabel.text = @"Notification permissions".uppercaseString;
            break;
            
        default:
            headerLabel.text = @"";
            break;
    }
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (void)switchFlipped:(UISwitch*)settingsSwitch {
    switch (settingsSwitch.tag) {
        case 0:
        {
            self.currentUser.emailPermissions = [NSNumber numberWithBool:settingsSwitch.isOn];
        }
            break;
        case 1:
        {
            self.currentUser.pushPermissions = [NSNumber numberWithBool:settingsSwitch.isOn];
        }
            break;
        case 2:
        {
            self.currentUser.textPermissions = [NSNumber numberWithBool:settingsSwitch.isOn];
        }
            break;
            
        default:
            break;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = doneButton;
    if (textField == addAlternateTextField){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentUser.alternates.count inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (void)doneEditing {
    self.navigationItem.rightBarButtonItem = saveButton;
    [self.view endEditing:YES];
}

- (void)save {
    [self.currentUser setSaved:@NO];
    if (delegate.connected){
        [ProgressHUD show:@"Updating your settings..."];
        [self.currentUser synchWithServer:^(BOOL completed) {
            if (completed){
                [ProgressHUD dismiss];
                [self back];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Error saving settings" message:@"Something went wrong while trying to save your settings. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                [ProgressHUD dismiss];
                [self back];
            }
        }];
    } else {
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        [[[UIAlertView alloc] initWithTitle:@"Offline" message:@"Saving settings is disabled while your device is offline." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)createAlternate{
    NSString *email = addAlternateTextField.text;
    
    if (email.length){
        [self doneEditing];
        [ProgressHUD show:@"Adding your alternate contact info..."];
        [manager POST:[NSString stringWithFormat:@"%@/users/%@/add_alternate",kApiBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:@{@"email":email} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success creating alternate: %@",responseObject);
            Alternate *alternate = [Alternate MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [alternate populateFromDictionary:[responseObject objectForKey:@"alternate"]];
            NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.currentUser.alternates];
            [set addObject:alternate];
            self.currentUser.alternates = set;
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                [ProgressHUD dismiss];
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            NSLog(@"Failed to create alternate");
        }];
    }
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row != self.currentUser.alternates.count){
        return YES;
    } else {
        return NO;
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        alternateIndexPathForDeletion = indexPath;
        [self confirmDeletion];
    }
}

- (void)confirmDeletion{
    [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to delete this? Messages will no longer be forwarded from this address." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self deleteAlternate];
    }
}

- (void)deleteAlternate {
    Alternate *alternate = self.currentUser.alternates[alternateIndexPathForDeletion.row];
    if (alternate){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (![alternate.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [parameters setObject:alternate.identifier forKey:@"alternate_id"];
        } else if (alternate.email.length) {
            [parameters setObject:alternate.email forKey:@"email"];
        }
        [manager POST:[NSString stringWithFormat:@"%@/users/%@/delete_alternate",kApiBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete alternate");
        }];
        
        NSMutableOrderedSet *alternates = [NSMutableOrderedSet orderedSetWithOrderedSet:self.currentUser.alternates];
        [alternates removeObject:alternate];
        self.currentUser.alternates = alternates;
        [alternate MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        
        if (self.currentUser.alternates.count > 1){
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[alternateIndexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        alternateIndexPathForDeletion = nil;
    } else {
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if (textField == firstNameTextField){
            [lastNameTextField becomeFirstResponder];
        } else if (textField == lastNameTextField){
            [emailTextField becomeFirstResponder];
        } else if (textField == emailTextField){
            [phoneTextField becomeFirstResponder];
        } else if (textField == phoneTextField){
            [self doneEditing];
        }
    }
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
    NSDictionary* info = [notification userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = keyboardValue.CGRectValue.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight+44, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight+44, 0);
                     }
                     completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)note {
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

@end
