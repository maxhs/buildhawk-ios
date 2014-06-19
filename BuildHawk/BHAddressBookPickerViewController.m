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

@interface BHAddressBookPickerViewController () {
    NSMutableArray *_addressBookArray;
}

@end

@implementation BHAddressBookPickerViewController

@synthesize peopleArray = _peopleArray;

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
            }
            
            ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            NSString *phone1;
            if (phones != nil){
                CFIndex px = ABMultiValueGetIndexForIdentifier(phones, 0);
                if (px >= 0) {
                    CFStringRef phoneRef = ABMultiValueCopyValueAtIndex(phones, px);
                    phone1 = (__bridge_transfer NSString*) (phoneRef);
                }
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
    [cell.phoneLabel setText:user.formattedPhone];
    [cell.phoneLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
    
    return cell;
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
