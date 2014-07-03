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

@interface BHAddPersonnelViewController () <UITextFieldDelegate> {
    UIBarButtonItem *createButton;
    UIBarButtonItem *doneButton;
    AFHTTPRequestOperationManager *manager;
    UITextField *companyNameTextField;
    UITextField *contactTextField;
    UITextField *companyEmailTextField;
    UITextField *companyPhoneTextField;
    UITextField *firstNameTextField;
    UITextField *lastNameTextField;
    UITextField *emailTextField;
    UITextField *phoneTextField;
    NSArray *peopleArray;
}

@end

@implementation BHAddPersonnelViewController
@synthesize name = _name;
@synthesize task = _task;
@synthesize project = _project;
@synthesize company = _company;

- (void)viewDidLoad
{
    [super viewDidLoad];
    createButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(create)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem = createButton;
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [self registerForKeyboardNotifications];
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
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
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

    if (_companyMode){
        switch (indexPath.section) {
            case 0:
            {
                [cell.textLabel setText:@"Pull info from address book"];
                [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
                [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
                UIImageView *buttonBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wideButton"]];
                [buttonBackground setFrame:CGRectMake(30, 2, 260, 50)];
                [cell addSubview:buttonBackground];
                [cell sendSubviewToBack:buttonBackground];
                [cell.personnelTextField setUserInteractionEnabled:NO];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
                break;
            case 1:
                cell.personnelTextField.placeholder = @"Company name";
                companyNameTextField = cell.personnelTextField;
                if (_name.length) [companyNameTextField setText:_name];
                [companyNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [companyNameTextField setReturnKeyType:UIReturnKeyNext];
                [companyNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                break;
            case 2:
                cell.personnelTextField.placeholder = @"Your contact at this company";
                contactTextField = cell.personnelTextField;
                [contactTextField setKeyboardType:UIKeyboardTypeDefault];
                [contactTextField setReturnKeyType:UIReturnKeyNext];
                [contactTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                break;
            case 3:
                cell.personnelTextField.placeholder = @"A contact email address";
                companyEmailTextField = cell.personnelTextField;
                [companyEmailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                [companyEmailTextField setReturnKeyType:UIReturnKeyNext];
                [companyEmailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                break;
            case 4:
                cell.personnelTextField.placeholder = @"A contact phone number";
                companyPhoneTextField = cell.personnelTextField;
                [companyPhoneTextField setKeyboardType:UIKeyboardTypePhonePad];
                [companyPhoneTextField setReturnKeyType:UIReturnKeyDone];
                [companyPhoneTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                break;
                
            default:
                break;
        }
    } else {
        switch (indexPath.section) {
            case 0:
            {
                [cell.textLabel setText:@"Tap to pull from address book"];
                [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
                [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
                UIImageView *buttonBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wideButton"]];
                [buttonBackground setFrame:CGRectMake(40, 5, 240, 50)];
                [cell addSubview:buttonBackground];
                [cell sendSubviewToBack:buttonBackground];
                [cell.personnelTextField setUserInteractionEnabled:NO];
            }
                break;
            case 1:
                cell.personnelTextField.placeholder = @"First name";
                firstNameTextField = cell.personnelTextField;
                if (_name.length){
                    [firstNameTextField setText:_name];
                }
                [firstNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [firstNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                break;
            case 2:
                cell.personnelTextField.placeholder = @"Last name";
                lastNameTextField = cell.personnelTextField;
                [lastNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [lastNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                break;
            case 3:
                cell.personnelTextField.placeholder = @"Email address";
                emailTextField = cell.personnelTextField;
                [emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                [emailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                break;
            case 4:
                cell.personnelTextField.placeholder = @"Phone number";
                phoneTextField = cell.personnelTextField;
                [phoneTextField setKeyboardType:UIKeyboardTypePhonePad];
                [emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [phoneTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                break;
                
            default:
                break;
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 60;
    } else {
        return 50;
    }
}

- (void)create {
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (_company && ![_company.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        [parameters setObject:_project.identifier forKey:@"company_id"];
    }
    if (_task && ![_task.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        [parameters setObject:_task.identifier forKey:@"task_id"];
    }
    
    NSMutableDictionary *userParameters = [NSMutableDictionary dictionary];
    [ProgressHUD show:@"Adding to companies list..."];
    if (_companyMode){
        
        if (companyNameTextField.text.length){
            [userParameters setObject:companyNameTextField.text forKey:@"name"];
        }
        if (contactTextField.text.length){
            [userParameters setObject:contactTextField.text forKey:@"contact_name"];
        }
        if (companyEmailTextField.text.length){
            [userParameters setObject:companyEmailTextField.text forKey:@"email"];
        }
        if (companyPhoneTextField.text.length){
            [userParameters setObject:companyPhoneTextField.text forKey:@"phone"];
        }
        [parameters setObject:userParameters forKey:@"user"];
        [manager POST:[NSString stringWithFormat:@"%@/project_subs",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success creating a new project sub: %@",responseObject);
            [ProgressHUD dismiss];
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating a company sub: %@",error.description);
            [ProgressHUD dismiss];
        }];
    } else {
        if (firstNameTextField.text.length){
            [userParameters setObject:firstNameTextField.text forKey:@"first_name"];
        }
        if (lastNameTextField.text.length){
            [userParameters setObject:lastNameTextField.text forKey:@"last_name"];
        }
        if (emailTextField.text.length){
            [userParameters setObject:emailTextField.text forKey:@"email"];
        }
        if (phoneTextField.text.length){
            [userParameters setObject:phoneTextField.text forKey:@"phone"];
        }
        
        [parameters setObject:userParameters forKey:@"user"];
        
        [manager POST:[NSString stringWithFormat:@"%@/project_subs/%@/add_user",kApiBaseUrl,_project.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success creating a new project sub user: %@",responseObject);
            if ([responseObject objectForKey:@"connect_user"]){
                NSString *alertMessage;
                if ([[responseObject objectForKey:@"connect_user"] objectForKey:@"email"] != [NSNull null]){
                    alertMessage = @"The person you've selected doesn't currently use BuildHawk, but we've emailed them this task.";
                } else {
                    alertMessage = @"The person you've selected doesn't currently use BuildHawk, but we've texted them this task.";
                }
                [[[UIAlertView alloc] initWithTitle:@"BuildHawk Connect" message:alertMessage delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
            User *user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [user populateFromDictionary:[responseObject objectForKey:@"user"]];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                [self.navigationController popViewControllerAnimated:YES];
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating a company sub: %@",error.description);
            [ProgressHUD dismiss];
        }];
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_companyMode){
        switch (section) {
            case 0:
                return @"";
                break;
            case 1:
                return @"Company Name";
                break;
            case 2:
                return @"Contact";
                break;
            case 3:
                return @"Email address";
                break;
            case 4:
                return @"Phone number";
                break;
            default:
                return @"";
                break;
        }
    } else {
        switch (section) {
            case 0:
                return @"";
                break;
            case 1:
                return @"First Name";
                break;
            case 2:
                return @"Last Name";
                break;
            case 3:
                return @"Email address";
                break;
            case 4:
                return @"Phone number";
                break;
            default:
                return @"";
                break;
        }
    }
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
        [vc setTitle:[NSString stringWithFormat:@"%@",_company.name]];
        if (_task){
            [vc setTask:_task];
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = doneButton;
    
    if (textField == companyEmailTextField || textField == emailTextField){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    } else if (textField == phoneTextField || textField == companyPhoneTextField){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (void)doneEditing {
    self.navigationItem.rightBarButtonItem = createButton;
    [self.view endEditing:YES];
}


@end
