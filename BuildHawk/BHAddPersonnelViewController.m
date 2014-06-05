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
}

@end

@implementation BHAddPersonnelViewController
@synthesize name = _name;
- (void)viewDidLoad
{
    [super viewDidLoad];
    createButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(create)];
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
    return 4;
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
    if (_companyMode){
        switch (indexPath.section) {
            case 0:
                cell.personnelTextField.placeholder = @"Company name";
                companyNameTextField = cell.personnelTextField;
                if (_name.length) [companyNameTextField setText:_name];
                [companyNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [companyNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                break;
            case 1:
                cell.personnelTextField.placeholder = @"Your contact at this company";
                contactTextField = cell.personnelTextField;
                [contactTextField setKeyboardType:UIKeyboardTypeDefault];
                [contactTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                break;
            case 2:
                cell.personnelTextField.placeholder = @"A contact email address";
                companyEmailTextField = cell.personnelTextField;
                [companyEmailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                [companyEmailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                break;
            case 3:
                cell.personnelTextField.placeholder = @"A contact phone number";
                companyPhoneTextField = cell.personnelTextField;
                [companyPhoneTextField setKeyboardType:UIKeyboardTypePhonePad];
                [companyPhoneTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                break;
                
            default:
                break;
        }
    } else {
        switch (indexPath.section) {
            case 0:
                cell.personnelTextField.placeholder = @"First name";
                firstNameTextField = cell.personnelTextField;
                if (_name.length) [firstNameTextField setText:_name];
                [firstNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [firstNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                break;
            case 1:
                cell.personnelTextField.placeholder = @"Last name";
                lastNameTextField = cell.personnelTextField;
                [lastNameTextField setKeyboardType:UIKeyboardTypeDefault];
                [lastNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                break;
            case 2:
                cell.personnelTextField.placeholder = @"Email address";
                emailTextField = cell.personnelTextField;
                [emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                [emailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                break;
            case 3:
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
            [parameters setObject:companyPhoneTextField.text forKey:@"phone_number"];
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
            [parameters setObject:phoneTextField.text forKey:@"phone_number"];
        }
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_companyMode){
        switch (section) {
            case 0:
                return @"Company Name";
                break;
            case 1:
                return @"Contact";
                break;
            case 2:
                return @"Email address";
                break;
            case 3:
                return @"Phone number";
                break;
            default:
                return @"";
                break;
        }
    } else {
        switch (section) {
            case 0:
                return @"First Name";
                break;
            case 1:
                return @"Last Name";
                break;
            case 2:
                return @"Email address";
                break;
            case 3:
                return @"Phone number";
                break;
            default:
                return @"";
                break;
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
