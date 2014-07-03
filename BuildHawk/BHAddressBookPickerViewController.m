//
//  BHAddressBookPickerViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/18/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHAddressBookPickerViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBook/ABAddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "BHAddressBookCell.h"
#import "BHAppDelegate.h"
#import "BHTaskViewController.h"
#import "Company+helper.h"

@interface BHAddressBookPickerViewController () {
    NSMutableArray *_addressBookArray;
}

@end

@implementation BHAddressBookPickerViewController

@synthesize peopleArray = _peopleArray;
@synthesize task = _task;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _addressBookArray = [NSMutableArray array];
    self.tableView.rowHeight = 78;
    [self sortPeople];
}

- (void)sortPeople {
    for (int i = 0;i < _peopleArray.count;i++) {
        ABRecordRef person = (__bridge ABRecordRef)([_peopleArray objectAtIndex:i]);
        if (person) {
            NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonFirstNameProperty);
            NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonLastNameProperty);
            
            NSString *email;
            ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
            if (emails != nil){
                CFIndex ix = ABMultiValueGetIndexForIdentifier(emails, 0);
                if (ix >= 0){
                    CFStringRef emailRef = ABMultiValueCopyValueAtIndex(emails, ix);
                    if (emailRef != nil) email = (__bridge_transfer NSString*) (emailRef);
                }
                CFRelease(emails);
            }
            
            ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            NSString *phone1;
            if (phones != nil){
                CFIndex px = ABMultiValueGetIndexForIdentifier(phones, 0);
                if (px >= 0) {
                    CFStringRef phoneRef = ABMultiValueCopyValueAtIndex(phones, px);
                    phone1 = (__bridge_transfer NSString*) (phoneRef);
                }
                CFRelease(phones);
            }
            
            User *user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            
            NSData *imgData = (NSData*)CFBridgingRelease(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail));
            
            if (imgData != nil) user.image = [UIImage imageWithData:imgData];
            
            if (firstName) user.firstName = firstName;
            if (lastName) user.lastName = lastName;
            if (phone1) {
                phone1 = [phone1 stringByReplacingOccurrencesOfString:@"+" withString:@""];
                phone1 = [phone1 stringByReplacingOccurrencesOfString:@"-" withString:@""];
                phone1 = [phone1 stringByReplacingOccurrencesOfString:@"(" withString:@""];
                phone1 = [phone1 stringByReplacingOccurrencesOfString:@")" withString:@""];
                [user setPhone:[phone1 stringByReplacingOccurrencesOfString:@" " withString:@""]];
            
            }
            if (email) user.email = email;
            if (user.firstName.length || user.lastName.length || user.email.length)[_addressBookArray addObject:user];
        }
    }
    
    NSArray *newArray = [_addressBookArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        
        NSString *first = [(User*)a firstName];
        NSString *second = [(User*)b firstName];
        return [first compare:second];
    }];
    _addressBookArray = [newArray mutableCopy];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _addressBookArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BHAddressBookCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddressBookCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddressBookCell" owner:self options:nil] lastObject];
    }
    User *user = _addressBookArray[indexPath.row];
    [cell.firstNameLabel setText:user.firstName];
    [cell.firstNameLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:19]];
    [cell.lastNameLabel setText:user.lastName];
    [cell.lastNameLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:19]];
    [cell.emailLabel setText:user.email];
    [cell.emailLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
    [cell.phoneLabel setText:user.phone];
    [cell.phoneLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    User *selectedUser = _addressBookArray[indexPath.row];
    [self createUser:selectedUser];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)createUser:(User*)user {
    [ProgressHUD show:[NSString stringWithFormat:@"Adding user to \"%@\"...", _company.name]];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (user.lastName.length){
        [parameters setObject:user.lastName forKey:@"last_name"];
    }
    if (user.firstName.length){
        [parameters setObject:user.firstName forKey:@"first_name"];
    }
    if (user.email.length){
        [parameters setObject:user.email forKey:@"email"];
    }
    if (user.phone.length){
        [parameters setObject:user.phone forKey:@"phone"];
    }
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] POST:[NSString stringWithFormat:@"%@/project_subs/%@/add_user",kApiBaseUrl,_company.identifier] parameters:@{@"user":parameters,@"project_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId],@"task_id":_task.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"old user? %@",user);
        NSLog(@"Success creating new user from Address book: %@",responseObject);
        if ([responseObject objectForKey:@"user"]){
            [user populateFromDictionary:[responseObject objectForKey:@"user"]];
            [_company addUser:user];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AssignTask" object:nil userInfo:@{@"user":user}];
        }
        
        BHTaskViewController *taskVC = nil;
        for (UIViewController *vc in self.navigationController.viewControllers){
            if ([vc isKindOfClass:[BHTaskViewController class]]){
                taskVC = (BHTaskViewController*)vc;
                break;
            }
        }
        
        if (taskVC) {
            [self.navigationController popToViewController:taskVC animated:YES];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
        [ProgressHUD dismiss];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure creating new user from address book: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while adding this user. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        [ProgressHUD dismiss];
    }];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
}

@end
