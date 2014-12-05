//
//  BHAddPersonnelViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/5/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHAddPersonnelViewController.h"
#import "BHAddPersonnelCell.h"
#import "BHAppDelegate.h"
#import <AddressBook/AddressBook.h>
#import "BHAddressBookPickerViewController.h"
#import "BHReportViewController.h"
#import "BHTaskViewController.h"

@interface BHAddPersonnelViewController () <UITextFieldDelegate, UIAlertViewDelegate> {
    UIBarButtonItem *createButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *nextButton;
    UIBarButtonItem *previousButton;
    AFHTTPRequestOperationManager *manager;
    NSArray *peopleArray;
    UITextField *_firstNameTextField;
    UITextField *_lastNameTextField;
    UITextField *_companyNameTextField;
    UIAlertView *userAlertView;
    NSString *email;
    NSString *phone;
    ReportUser *selectedReportUser;
}

@end

@implementation BHAddPersonnelViewController

@synthesize task = _task;
@synthesize project = _project;
@synthesize report = _report;
@synthesize company = _company;
@synthesize firstName = _firstName;
@synthesize companyName = _companyName;
@synthesize lastName = _lastName;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 60.f;
    self.secondTableView.rowHeight = 60.f;
    previousButton = [[UIBarButtonItem alloc] initWithTitle:@"Previous" style:UIBarButtonItemStylePlain target:self action:@selector(previous)];
    nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(next)];
    createButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(create)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem = nextButton;
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [self registerForKeyboardNotifications];
    
    //[self.tableView setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
    [self.view setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
}

#pragma mark - Navigation

- (void)next {
    if (_emailTextField.text.length){
        email = _emailTextField.text;
    }
    if (_phoneTextField.text.length){
        phone = _phoneTextField.text;
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (phone.length){
        [parameters setObject:phone forKey:@"phone"];
    } else if (email.length) {
        [parameters setObject:email forKey:@"email"];
    }
    
    if (_firstStepComplete){
        [self moveForward];
    } else if (parameters){
        [ProgressHUD show:@"Searching..."];
        [manager POST:[NSString stringWithFormat:@"%@/projects/%@/find_user",kApiBaseUrl,_project.identifier] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success finding user: %@",responseObject);
            [ProgressHUD dismiss];
            
            if ([[responseObject objectForKey:@"success"] isEqualToNumber:@0]){
                //success => false means the API searched for, but could not find, a match
                [self moveForward];
            } else {
                NSDictionary *userDict = [responseObject objectForKey:@"user"];
                User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!user){
                    user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [user populateFromDictionary:userDict];
                } else {
                    [user updateFromDictionary:userDict];
                }
                
                if (_task){
                    NSMutableOrderedSet *assignees = [NSMutableOrderedSet orderedSet];
                    [assignees addObject:user];
                    _task.assignees = assignees;
                    [self saveAndExit];
                } else if (_report) {
                    selectedReportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    selectedReportUser.userId = user.identifier;
                    selectedReportUser.fullname = user.fullname;
                    [self getHours];
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            NSLog(@"Failed to find user: %@",error.description);
        }];
    }
}

- (void)getHours {
    userAlertView = [[UIAlertView alloc] initWithTitle:@"# of Hours Worked" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
    userAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[userAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
    [userAlertView show];
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == userAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *hours = [f numberFromString:[[userAlertView textFieldAtIndex:0] text]];
            if (hours.floatValue > 0.f){
                [self selectReportUserWithCount:hours];
            }
        }
    }
}

- (void)selectReportUserWithCount:(NSNumber*)count {
    if (selectedReportUser){
        selectedReportUser.hours = count;
        [_report addReportUser:selectedReportUser];
        [self saveAndExit];
    } else {
        
    }
}

- (void)moveForward {
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = previousButton;
    self.navigationItem.rightBarButtonItem = createButton;
    CGRect secondFrame = _secondTableView.frame;
    secondFrame.origin.x = 0;
    CGRect firstFrame = _tableView.frame;
    firstFrame.origin.x = -screenWidth();
    
    [self.secondTableView reloadData];
    
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [_secondTableView setFrame:secondFrame];
        [_tableView setFrame:firstFrame];
    } completion:^(BOOL finished) {
        [_tableView setHidden:YES];
        if (_firstStepComplete == NO){
            _firstStepComplete = YES;
        }
    }];
}

- (void)previous {
    [_tableView setHidden:NO];
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nextButton;
    CGRect secondFrame = _secondTableView.frame;
    secondFrame.origin.x = screenWidth();
    CGRect firstFrame = _tableView.frame;
    firstFrame.origin.x = 0;
    //[self.tableView reloadData];
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [_secondTableView setFrame:secondFrame];
        [_tableView setFrame:firstFrame];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)saveAndExit {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [ProgressHUD dismiss];
        if (_report){
            [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
                if ([vc isKindOfClass:[BHReportViewController class]]){
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportPersonnel" object:nil];
                    [self.navigationController popToViewController:vc animated:YES];
                    *stop = YES;
                }
            }];
        } else if (_task){
            [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
                if ([vc isKindOfClass:[BHTaskViewController class]]){
                    [(BHTaskViewController*)vc setTask:_task];
                    [(BHTaskViewController*)vc drawItem];
                    [self.navigationController popToViewController:vc animated:YES];
                    *stop = YES;
                }
            }];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AddPersonnel";
    BHAddPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddPersonnelCell" owner:self options:nil] lastObject];
    }
    cell.personnelTextField.delegate = self;
    [cell.personnelTextField setUserInteractionEnabled:YES];
    
    if (tableView == self.tableView){
    
        switch (indexPath.row) {
            case 0:
                [cell.textLabel setText:@"Pull from address book"];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
                [cell.imageView setImage:[UIImage imageNamed:@"contacts"]];
                [cell.personnelTextField setUserInteractionEnabled:NO];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
            case 1:
                cell.personnelTextField.placeholder = @"Or enter an email address";
                _emailTextField = cell.personnelTextField;
                [_emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [_emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                [_emailTextField setReturnKeyType:UIReturnKeyNext];
                [_emailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [cell.imageView setImage:[UIImage imageNamed:@"email"]];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
            case 2:
                cell.personnelTextField.placeholder = @"And/or a phone number";
                _phoneTextField = cell.personnelTextField;
                [_phoneTextField setKeyboardType:UIKeyboardTypePhonePad];
                [_phoneTextField setReturnKeyType:UIReturnKeyNext];
                [_phoneTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [cell.imageView setImage:[UIImage imageNamed:@"phone"]];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
            default:
                break;
        }
        
    } else {
        CGRect secondTableViewTextFieldFrame = cell.personnelTextField.frame;
        secondTableViewTextFieldFrame.origin.x = 14;
        secondTableViewTextFieldFrame.size.width = screenWidth()-20;
        switch (indexPath.row) {
            case 0:
                cell.personnelTextField.placeholder = @"Company name (required)";
                _companyNameTextField = cell.personnelTextField;
                if (_company && _company.name.length){
                    [_companyNameTextField setText:_company.name];
                } else if (_companyName.length){
                    [_companyNameTextField setText:_companyName];
                }
                [_companyNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [_companyNameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [_companyNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                [_companyNameTextField setFrame:secondTableViewTextFieldFrame];
                break;
            case 1:
            {
                cell.personnelTextField.placeholder = @"First name..";
                if (_firstName.length){
                    [_firstNameTextField setText:_firstName];
                }
                _firstNameTextField = cell.personnelTextField;
                [_firstNameTextField setReturnKeyType:UIReturnKeyNext];
                [_firstNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [_firstNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                [_firstNameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [_firstNameTextField setFrame:secondTableViewTextFieldFrame];
            }
                break;
            case 2:
                cell.personnelTextField.placeholder = @"Last name...";
                if (_lastName.length){
                    [_lastNameTextField setText:_lastName];
                }
                _lastNameTextField = cell.personnelTextField;
                [_lastNameTextField setReturnKeyType:UIReturnKeyNext];
                [_lastNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [_lastNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                [_lastNameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [_lastNameTextField setFrame:secondTableViewTextFieldFrame];
                break;
            
            case 3:
                if (phone.length > 0 && email.length == 0){
                    cell.personnelTextField.placeholder = @"Email address";
                    [_emailTextField setText:email];
                    _emailTextField = cell.personnelTextField;
                    [_emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                    [_emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                    [_emailTextField setReturnKeyType:UIReturnKeyNext];
                    [_emailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    [cell.imageView setImage:[UIImage imageNamed:@"email"]];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                } else {
                    cell.personnelTextField.placeholder = @"Phone number";
                    [_phoneTextField setText:phone];
                    _phoneTextField = cell.personnelTextField;
                    [_phoneTextField setKeyboardType:UIKeyboardTypePhonePad];
                    [_phoneTextField setReturnKeyType:UIReturnKeyNext];
                    [_phoneTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    [cell.imageView setImage:[UIImage imageNamed:@"phone"]];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                
                break;
                
            default:
                break;
        }
    }
    return cell;
}

- (void)create {
    if (_companyNameTextField.text.length && (_emailTextField.text.length > 0 || _phoneTextField.text.length > 0)){
    
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (_company && ![_company.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [parameters setObject:_company.identifier forKey:@"company_id"];
        }
        if (_task && ![_task.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [parameters setObject:_task.identifier forKey:@"task_id"];
        }
        
        NSMutableDictionary *userParameters = [NSMutableDictionary dictionary];
        [ProgressHUD show:@"Adding contact..."];

        if (_firstNameTextField.text.length){
            [userParameters setObject:_firstNameTextField.text forKey:@"first_name"];
        }
        if (_lastNameTextField.text.length){
            [userParameters setObject:_lastNameTextField.text forKey:@"last_name"];
        }
        if (_emailTextField.text.length){
            [userParameters setObject:_emailTextField.text forKey:@"email"];
        }
        if (_phoneTextField.text.length){
            NSString *cleanPhone = [_phoneTextField.text stringByReplacingOccurrencesOfString:@"+" withString:@""];
            cleanPhone = [cleanPhone stringByReplacingOccurrencesOfString:@"-" withString:@""];
            cleanPhone = [cleanPhone stringByReplacingOccurrencesOfString:@"(" withString:@""];
            cleanPhone = [cleanPhone stringByReplacingOccurrencesOfString:@")" withString:@""];
            cleanPhone = [cleanPhone stringByReplacingOccurrencesOfString:@" " withString:@""];
            [userParameters setObject:cleanPhone forKey:@"phone"];
        }
        if (_companyNameTextField.text.length){
            [userParameters setObject:_companyNameTextField.text forKey:@"company_name"];
        }
        [parameters setObject:userParameters forKey:@"user"];
        
        [manager POST:[NSString stringWithFormat:@"%@/projects/%@/add_user",kApiBaseUrl,_project.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success creating a new project sub user: %@",responseObject);
            if ([responseObject objectForKey:@"user"]){
                
                NSDictionary *userDict = [responseObject objectForKey:@"user"];
                User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!user){
                    user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [user populateFromDictionary:userDict];
                
                if (_task){
                    NSMutableOrderedSet *assignees = [NSMutableOrderedSet orderedSet];
                    [assignees addObject:user];
                    _task.assignees = assignees;
                    
                    //Check if the user is active or not. If not, then they're a "connect user"
                    if ([user.active isEqualToNumber:@NO]){
                        NSString *alertMessage;
                        if (user.email.length){
                            alertMessage = @"The person you've selected doesn't currently use BuildHawk, but we've emailed them this task.";
                        } else {
                            alertMessage = @"The person you've selected doesn't currently use BuildHawk, but we've notified them about this task.";
                        }
                        [[[UIAlertView alloc] initWithTitle:@"BuildHawk Connect" message:alertMessage delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    }
    
                } else if (_report) {
                    ReportUser *reportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    reportUser.userId = user.identifier;
                    reportUser.fullname = user.fullname;
                    [_report addReportUser:reportUser];
                }
            }
            
            [self saveAndExit];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating a company sub: %@",error.description);
            [ProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Unable to connect" message:@"Something went wrong while trying to add personnel." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Company Needed" message:@"Please make sure you've specified a company for this contact." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *emptyView = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
        return emptyView;
    } else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 4)];
        [headerView setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
        
        UILabel *contactInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, screenWidth()-40, 24)];
        [contactInfoLabel setTextColor:[UIColor darkGrayColor]];
        [contactInfoLabel setText:@"CONTACT INFO"];
        [contactInfoLabel setTextAlignment:NSTextAlignmentCenter];
        [contactInfoLabel setFont:[UIFont fontWithName:kMyriadProRegular size:16]];
        contactInfoLabel.numberOfLines = 0;
        [headerView addSubview:contactInfoLabel];
        
        return headerView;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        CFErrorRef error = nil;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
        if (!addressBook)
        {
            //some sort of error preventing us from grabbing the address book
            return;
        }
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted){
                CFArrayRef arrayOfPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
                peopleArray = (__bridge NSArray *)(arrayOfPeople);
                
                CFRelease(arrayOfPeople);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performSegueWithIdentifier:@"AddressBook" sender:nil];
                });
            }
        });
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AddressBook"]){
        BHAddressBookPickerViewController *vc = [segue destinationViewController];
        [vc setPeopleArray:peopleArray];
        [vc setCompany:_company];
        [vc setProject:_project];
        if (_company.name.length){
            [vc setTitle:[NSString stringWithFormat:@"%@",_company.name]];
        } else {
            [vc setTitle:@"Address Book"];
        }
        if (_task){
            [vc setTask:_task];
        }
    }
}

#pragma mark - UITextField Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if (textField == _emailTextField || textField == _phoneTextField){
            [textField resignFirstResponder];
            [self next];
        } else if (textField == _firstNameTextField) {
            [_lastNameTextField becomeFirstResponder];
        } else if (textField == _lastNameTextField) {
            if (_companyNameTextField.text.length == 0){
                [_companyNameTextField becomeFirstResponder];
            }
        } else if (textField == _companyNameTextField) {
            [self create];
        }
    }
    return YES;
}

- (void)doneEditing {
    if (_emailTextField.text.length || _phoneTextField.text.length){
        [self next];
        self.navigationItem.rightBarButtonItem = createButton;
    } else {
        self.navigationItem.rightBarButtonItem = nextButton;
    }
    [self.view endEditing:YES];
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
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
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
                         
                     }
                     completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
