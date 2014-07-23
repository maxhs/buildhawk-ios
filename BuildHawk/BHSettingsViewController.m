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
    User *currentUser;
    AFHTTPRequestOperationManager *manager;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *doneButton;
    NSIndexPath *alternateIndexPathForDeletion;
    UITextField *addAlternateTextField;
}

@end

@implementation BHSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
    
    currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    self.tableView.rowHeight = 60;
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 4;
            break;
        case 1:
            return currentUser.alternates.count + 1;
            break;
        case 2:
            return 3;
            break;
            
        default:
            break;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingsCell";
    BHSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHSettingsCell" owner:self options:nil] lastObject];
    }
    [cell.textLabel setFont:[UIFont systemFontOfSize:15]];
    [cell.textField setText:@""];
    [cell.textField setPlaceholder:@""];
    [cell.textLabel setText:@""];
    cell.accessoryView = nil;
    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    cell.textField.delegate = self;
    [cell.actionButton setHidden:YES];
    if (indexPath.section == 0){
        [cell.textField setTag:indexPath.row];
        switch (indexPath.row) {
            case 0:
            {
                if (currentUser.firstName.length){
                    [cell.textField setText:currentUser.firstName];
                }
                [cell.textField setPlaceholder:@"Your first name"];
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
            }
                break;
            case 1:
            {
                if (currentUser.lastName.length){
                    [cell.textField setText:currentUser.lastName];
                }
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                [cell.textField setPlaceholder:@"Your last name"];
            }
                break;
            case 2:
            {
                [cell.textField setText:currentUser.email];
                [cell.textField setPlaceholder:@"Your email address"];
                [cell.textField setKeyboardType:UIKeyboardTypeEmailAddress];
            }
                break;
            case 3:
            {
                if (currentUser.formattedPhone.length){
                    [cell.textField setText:currentUser.formattedPhone];
                }
                [cell.textField setKeyboardType:UIKeyboardTypePhonePad];
                [cell.textField setPlaceholder:@"Your phone number"];
            }
                break;
                
            default:
                break;
        }
    } else if (indexPath.section == 1){
        if (indexPath.row == currentUser.alternates.count){
            cell.textField.placeholder = @"Any alternate email addresses?";
            [cell.actionButton addTarget:self action:@selector(createAlternate) forControlEvents:UIControlEventTouchUpInside];;
            addAlternateTextField = cell.textField;
            [cell.actionButton setHidden:NO];
            cell.actionButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:.3].CGColor;
            cell.actionButton.layer.borderWidth = .5f;
            cell.actionButton.layer.cornerRadius = 5.f;
            cell.actionButton.clipsToBounds = YES;
            [cell.textLabel setText:@""];
        } else {
            Alternate *alternate = currentUser.alternates[indexPath.row];
            if (alternate.email.length){
                [cell.textLabel setText:alternate.email];
            }
            [cell.textField setHidden:YES];
        }
        
    } else {
        UISwitch *settingsSwitch = [[UISwitch alloc] init];
        cell.accessoryView = settingsSwitch;
        settingsSwitch.tag = indexPath.row;
        [settingsSwitch addTarget:self action:@selector(switchFlipped:) forControlEvents:UIControlEventValueChanged];
        [cell.actionButton setHidden:YES];
        switch (indexPath.row) {
            case 0:
            {
                [cell.textLabel setText:@"Emails"];
                [settingsSwitch setOn:currentUser.emailPermissions.boolValue];
            }
                break;
            case 1:
            {
                [cell.textLabel setText:@"Push notifications"];
                [settingsSwitch setOn:currentUser.pushPermissions.boolValue];
            }
                break;
            case 2:
            {
                [cell.textLabel setText:@"Text notifications"];
                [settingsSwitch setOn:currentUser.textPermissions.boolValue];
            }
                break;
                
            default:
                break;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Personal details";
            break;
        case 1:
            return @"Alternate contact information";
            break;
        case 2:
            return @"Notification permissions";
            break;
            
        default:
            return @"";
            break;
    }
}

- (void)switchFlipped:(UISwitch*)settingsSwitch {
    switch (settingsSwitch.tag) {
        case 0:
        {
            currentUser.emailPermissions = [NSNumber numberWithBool:settingsSwitch.isOn];
        }
            break;
        case 1:
        {
            currentUser.pushPermissions = [NSNumber numberWithBool:settingsSwitch.isOn];
        }
            break;
        case 2:
        {
            currentUser.textPermissions = [NSNumber numberWithBool:settingsSwitch.isOn];
        }
            break;
            
        default:
            break;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = doneButton;
    if (textField == addAlternateTextField){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:currentUser.alternates.count inSection:1] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (void)doneEditing {
    self.navigationItem.rightBarButtonItem = saveButton;
    [self.view endEditing:YES];
}

- (void)save {
    [ProgressHUD show:@"Updating your settings..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:currentUser.emailPermissions forKey:@"email_permissions"];
    [parameters setObject:currentUser.textPermissions forKey:@"text_permissions"];
    [parameters setObject:currentUser.pushPermissions forKey:@"push_permissions"];
    [manager PATCH:[NSString stringWithFormat:@"%@/users/%@",kApiBaseUrl,currentUser.identifier] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success updating user: %@",responseObject);
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD dismiss];
            [self back];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure updating user settings: %@",error.description);
    }];
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
            NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:currentUser.alternates];
            [set addObject:alternate];
            currentUser.alternates = set;
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
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row != currentUser.alternates.count){
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
    Alternate *alternate = currentUser.alternates[alternateIndexPathForDeletion.row];
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
        
        NSMutableOrderedSet *alternates = [NSMutableOrderedSet orderedSetWithOrderedSet:currentUser.alternates];
        [alternates removeObject:alternate];
        currentUser.alternates = alternates;
        [alternate MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        
        if (currentUser.alternates.count > 1){
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
