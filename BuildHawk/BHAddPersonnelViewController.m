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
#import "ConnectUser+helper.h"
#import "BHTaskViewController.h"

@interface BHAddPersonnelViewController () <UITextFieldDelegate> {
    UIBarButtonItem *createButton;
    UIBarButtonItem *doneButton;
    AFHTTPRequestOperationManager *manager;
    NSArray *peopleArray;
    UITextField *_firstNameTextField;
    UITextField *_lastNameTextField;
    UITextField *_companyNameTextField;
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
    createButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(create)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem = createButton;
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [self registerForKeyboardNotifications];
    
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 0)];
    [headerView setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
    UILabel *explanatoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, screenWidth()-40, 70)];
    [explanatoryLabel setTextColor:[UIColor darkGrayColor]];
    [explanatoryLabel setText:@"Please enter the email/phone number of the person you'd like to add, or simply pull their info from your address book."];
    [explanatoryLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:16]];
    explanatoryLabel.numberOfLines = 0;
    [headerView addSubview:explanatoryLabel];
    self.tableView.tableHeaderView = headerView;
    
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
    [self.view setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_firstStepComplete){
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0){
        return 3;
    } else {
        return 3;
    }
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
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                [cell.textLabel setText:@"Pull from address book"];
                [cell.textLabel setFont:[UIFont systemFontOfSize:16]];
                [cell.imageView setImage:[UIImage imageNamed:@"contacts"]];
                [cell.personnelTextField setUserInteractionEnabled:NO];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
            case 1:
                cell.personnelTextField.placeholder = @"Email address";
                _emailTextField = cell.personnelTextField;
                [_emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [_emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                [_emailTextField setReturnKeyType:UIReturnKeyNext];
                [_emailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [cell.imageView setImage:[UIImage imageNamed:@"email"]];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
            case 2:
                cell.personnelTextField.placeholder = @"Phone number";
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
        
        switch (indexPath.row) {
            case 0:
            {
                cell.personnelTextField.placeholder = @"First name..";
                _firstNameTextField = cell.personnelTextField;
                if (_firstName.length){
                    [_firstNameTextField setText:_firstName];
                }
                [_firstNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [_firstNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                [_firstNameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
            }
                break;
            case 1:
                cell.personnelTextField.placeholder = @"Last name...";
                if (_lastName.length){
                    [_lastNameTextField setText:_lastName];
                }
                _lastNameTextField = cell.personnelTextField;
                [_lastNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [_lastNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                [_lastNameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                break;
            case 2:
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
                break;
                
            default:
                break;
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0){
        return 100;
    } else return 24;
}

- (void)create {
    if (_companyNameTextField.text.length){
    
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (_company && ![_company.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [parameters setObject:_project.identifier forKey:@"company_id"];
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
            [userParameters setObject:_phoneTextField.text forKey:@"phone"];
        }
        if (_companyNameTextField.text.length){
            [userParameters setObject:_companyNameTextField.text forKey:@"company_name"];
        }
        [parameters setObject:userParameters forKey:@"user"];
        
        [manager POST:[NSString stringWithFormat:@"%@/projects/%@/add_user",kApiBaseUrl,_project.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success creating a new project sub user: %@",responseObject);
            if ([responseObject objectForKey:@"connect_user"]){
                
                ConnectUser *connectUser = [ConnectUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [connectUser populateFromDictionary:[responseObject objectForKey:@"connect_user"]];
                
                if (_task){
                    NSString *alertMessage;
                    if ([[responseObject objectForKey:@"connect_user"] objectForKey:@"email"] != [NSNull null]){
                        alertMessage = @"The person you've selected doesn't currently use BuildHawk, but we've emailed them this task.";
                    } else {
                        alertMessage = @"The person you've selected doesn't currently use BuildHawk, but we've texted them this task.";
                    }
                    
                    NSMutableOrderedSet *assignees = [NSMutableOrderedSet orderedSet];
                    [assignees addObject:connectUser];
                    _task.connectAssignees = assignees;
                    
                    [[[UIAlertView alloc] initWithTitle:@"BuildHawk Connect" message:alertMessage delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                } else if (_report){
                    ReportUser *reportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    reportUser.connectUserId = connectUser.identifier;
                    reportUser.fullname = connectUser.fullname;
                    [_report addReportUser:reportUser];
                }
                
            } else {
                NSDictionary *userDict = [responseObject objectForKey:@"user"];
                User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"]];
                if (!user){
                    user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [user populateFromDictionary:userDict];
                }
                
                if (_task){
                    NSMutableOrderedSet *assignees = [NSMutableOrderedSet orderedSet];
                    [assignees addObject:user];
                    _task.assignees = assignees;
                } else if (_report) {
                    ReportUser *reportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    reportUser.userId = user.identifier;
                    reportUser.fullname = user.fullname;
                    [_report addReportUser:reportUser];
                }
            }
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                if (_report){
                    [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
                        if ([vc isKindOfClass:[BHReportViewController class]]){
                            [[(BHReportViewController*)vc reportTableView] reloadData];
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
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating a company sub: %@",error.description);
            [ProgressHUD dismiss];
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
        [contactInfoLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
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
        [vc setTitle:[NSString stringWithFormat:@"%@",_company.name]];
        if (_task){
            [vc setTask:_task];
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = doneButton;
    
    if (textField == _companyNameTextField){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    } else if (textField == _firstNameTextField){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    } else if (textField == _lastNameTextField){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == _emailTextField || textField == _phoneTextField){
        if (textField.text.length && !_firstStepComplete){
            _firstStepComplete = YES;
            [self.tableView reloadData];
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if (textField == _emailTextField || textField == _phoneTextField){
            [textField resignFirstResponder];
            [_firstNameTextField becomeFirstResponder];
        }
    }
    return YES;
}

- (void)doneEditing {
    self.navigationItem.rightBarButtonItem = createButton;
    [self.view endEditing:YES];
}

@end
