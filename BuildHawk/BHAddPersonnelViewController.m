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
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    if (_companyMode){
        switch (indexPath.section) {
            case 0:
            {
                [cell.textLabel setText:@"Tap to pull from address book"];
                [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
                [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
                UIImageView *buttonBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wideButton"]];
                [buttonBackground setFrame:CGRectMake(40, 2, 240, 50)];
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
                break;
            case 2:
                cell.personnelTextField.placeholder = @"Your contact at this company";
                contactTextField = cell.personnelTextField;
                [contactTextField setKeyboardType:UIKeyboardTypeDefault];
                [contactTextField setReturnKeyType:UIReturnKeyNext];
                [contactTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                break;
            case 3:
                cell.personnelTextField.placeholder = @"A contact email address";
                companyEmailTextField = cell.personnelTextField;
                [companyEmailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                [companyEmailTextField setReturnKeyType:UIReturnKeyNext];
                [companyEmailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
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
                [firstNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [firstNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                break;
            case 2:
                cell.personnelTextField.placeholder = @"Last name";
                lastNameTextField = cell.personnelTextField;
                [lastNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [lastNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                break;
            case 3:
                cell.personnelTextField.placeholder = @"Email address";
                emailTextField = cell.personnelTextField;
                [emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                [emailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                break;
            case 4:
                cell.personnelTextField.placeholder = @"Phone number";
                phoneTextField = cell.personnelTextField;
                [phoneTextField setKeyboardType:UIKeyboardTypePhonePad];
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
    [ProgressHUD show:@"Adding to companies list..."];
    if (_companyMode){
        
        if (companyNameTextField.text.length){
            [parameters setObject:companyNameTextField.text forKey:@"name"];
        }
        if (contactTextField.text.length){
            [parameters setObject:contactTextField.text forKey:@"contact_name"];
        }
        if (companyEmailTextField.text.length){
            [parameters setObject:companyEmailTextField.text forKey:@"email"];
        }
        if (companyPhoneTextField.text.length){
            [parameters setObject:companyPhoneTextField.text forKey:@"phone"];
        }
        [manager POST:[NSString stringWithFormat:@"%@/company_subs",kApiBaseUrl] parameters:@{@"company_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId],@"subcontractor":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success creating a new company sub: %@",responseObject);
            [ProgressHUD dismiss];
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating a company sub: %@",error.description);
            [ProgressHUD dismiss];
        }];
    } else {
        if (firstNameTextField.text.length){
            [parameters setObject:firstNameTextField.text forKey:@"first_name"];
        }
        if (lastNameTextField.text.length){
            [parameters setObject:lastNameTextField.text forKey:@"last_name"];
        }
        if (emailTextField.text.length){
            [parameters setObject:emailTextField.text forKey:@"email"];
        }
        if (phoneTextField.text.length){
            [parameters setObject:phoneTextField.text forKey:@"phone"];
        }
        [manager POST:[NSString stringWithFormat:@"%@/company_subs/%@/add_user",kApiBaseUrl,_subcontractor.identifier] parameters:@{@"company_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId],@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success creating a new company sub user: %@",responseObject);
            User *user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [user populateFromDictionary:[responseObject objectForKey:@"user"]];
            [_subcontractor addUser:user];
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
        [vc setTitle:[NSString stringWithFormat:@"%@",_subcontractor.name]];
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
