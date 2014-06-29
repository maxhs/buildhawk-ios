//
//  BHSettingsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/12/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHSettingsViewController.h"
#import "BHAppDelegate.h"

@interface BHSettingsViewController () <UITextFieldDelegate> {
    UIBarButtonItem *backButton;
    User *currentUser;
    AFHTTPRequestOperationManager *manager;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *doneButton;
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
    
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    
    currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 4;
            break;
        case 1:
            return 3;
            break;
            
        default:
            break;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    if (indexPath.section == 0){
        UITextField *settingsTextField = [[UITextField alloc] init];
        [settingsTextField setFrame:CGRectMake(14, 2, cell.frame.size.width-28, cell.frame.size.height-4)];
        [cell addSubview:settingsTextField];
        [settingsTextField setTag:indexPath.row];
        
        switch (indexPath.row) {
            case 0:
            {
                if (currentUser.firstName.length){
                    [settingsTextField setText:currentUser.firstName];
                }
                [settingsTextField setPlaceholder:@"Your first name"];
                [settingsTextField setKeyboardType:UIKeyboardTypeDefault];
            }
                break;
            case 1:
            {
                if (currentUser.lastName.length){
                    [settingsTextField setText:currentUser.lastName];
                }
                [settingsTextField setKeyboardType:UIKeyboardTypeDefault];
                [settingsTextField setPlaceholder:@"Your last name"];
            }
                break;
            case 2:
            {
                [settingsTextField setText:currentUser.email];
                [settingsTextField setPlaceholder:@"Your email address"];
                [settingsTextField setKeyboardType:UIKeyboardTypeEmailAddress];
            }
                break;
            case 3:
            {
                if (currentUser.formattedPhone.length){
                    [settingsTextField setText:currentUser.formattedPhone];
                }
                [settingsTextField setKeyboardType:UIKeyboardTypePhonePad];
                [settingsTextField setPlaceholder:@"Your phone number"];
            }
                break;
                
            default:
                break;
        }
        
    } else {
        UISwitch *settingsSwitch = [[UISwitch alloc] init];
        cell.accessoryView = settingsSwitch;
        settingsSwitch.tag = indexPath.row;
        [settingsSwitch addTarget:self action:@selector(switchFlipped:) forControlEvents:UIControlEventValueChanged];
        
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
            return @"Notification Permissions";
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
        NSLog(@"Success updating user: %@",responseObject);
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD dismiss];
            [self back];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure updating user settings: %@",error.description);
    }];
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
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
