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
#import "BHAddPersonnelViewController.h"

@interface BHAddressBookPickerViewController () {
    NSMutableArray *_addressBookArray;
    NSMutableArray *_filteredArray;
    NSString *searchText;
    BOOL searching;
    NSTimeInterval duration;
    UIViewAnimationOptions animationCurve;
}

@end

@implementation BHAddressBookPickerViewController

@synthesize peopleArray = _peopleArray;
@synthesize task = _task;
@synthesize project = _project;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _addressBookArray = [NSMutableArray array];
    self.tableView.rowHeight = 78;
    _filteredArray = [NSMutableArray array];
    [self sortPeople];
    [self.searchBar setPlaceholder:@"Search..."];
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    self.tableView.tableHeaderView = self.searchBar;
    //reset the search bar font
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
            break;
        }
    }
    [self registerKeyboardNotifications];
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
    if (searching){
        return _filteredArray.count;
    } else {
        return _addressBookArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BHAddressBookCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddressBookCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddressBookCell" owner:self options:nil] lastObject];
    }
    User *user;
    if (searching){
        user = _filteredArray[indexPath.row];
    } else {
        user = _addressBookArray[indexPath.row];
    }
    
    if (user.firstName.length){
        if (user.lastName.length){
            [cell.nameLabel setText:[NSString stringWithFormat:@"%@ %@",user.firstName,user.lastName]];
        } else {
            [cell.nameLabel setText:user.firstName];
        }
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProRegular] size:0]];
    [cell.emailLabel setText:user.email];
    [cell.emailLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProLight] size:0]];
    [cell.phoneLabel setText:user.phone];
    [cell.phoneLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProLight] size:0]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    User *selectedUser = _addressBookArray[indexPath.row];
    [self createUser:selectedUser];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)createUser:(User*)user {
    UIViewController *previousVC = [self.navigationController.viewControllers objectAtIndex:(self.navigationController.viewControllers.count-2)];
    
    if ([previousVC isKindOfClass:[BHAddPersonnelViewController class]]){
        BHAddPersonnelViewController *vc = (BHAddPersonnelViewController*)previousVC;
        [vc setFirstStepComplete:YES];
        [vc.tableView reloadData];
        
        if (user.lastName.length){
            vc.lastName = user.lastName;
        }
        if (user.firstName.length){
            vc.firstName = user.firstName;
        }
        if (user.email.length){
            [vc.emailTextField setText:user.email];
        }
        if (user.phone.length){
            [vc.phoneTextField setText:user.phone];
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Search Section
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    BOOL shouldReload = NO;
    if (!searching){
        shouldReload = YES;
    }
    searching = YES;
    
    [_filteredArray removeAllObjects];
    [_filteredArray addObjectsFromArray:_addressBookArray];
    
    if (shouldReload) [self.tableView reloadData];
    [self.searchBar setShowsCancelButton:YES animated:YES];
    
    //self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    searchText = searchBar.text;
    [self filterContentForSearchText:searchText scope:nil];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self endSearch];
    [self.tableView reloadData];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    searchText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self filterContentForSearchText:searchText scope:nil];
    return YES;
}

- (void)endSearch {
    //have to manually resign the first responder here
    [self.searchBar resignFirstResponder];
    [self.searchBar setText:@""];
    [self.view endEditing:YES];
    searching = NO;
     [self.searchBar setShowsCancelButton:NO animated:YES];
    [_filteredArray removeAllObjects];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    searching = NO;
    [self.searchBar setText:@""];
    [self.tableView reloadData];
}

-(void)willShowKeyboard:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
    duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight+27, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight+27, 0);
                     }
                     completion:NULL];
}

- (void)willHideKeyboard:(NSNotification *)notification
{
    duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsZero;
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
                     }
                     completion:NULL];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    NSLog(@"search text: %@",text);
    if (text.length) {
        [_filteredArray removeAllObjects];
        for (User *user in _addressBookArray){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if([predicate evaluateWithObject:user.fullname]) {
                [_filteredArray addObject:user];
            } else if ([predicate evaluateWithObject:user.phone]){
                [_filteredArray addObject:user];
            } else if ([predicate evaluateWithObject:user.email]){
                [_filteredArray addObject:user];
            }
        }
    } else {
        _filteredArray = [NSMutableArray arrayWithArray:_addressBookArray];
    }
    [self.tableView reloadData];
}


- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
}

@end
