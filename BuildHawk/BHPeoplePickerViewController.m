//
//  BHPeoplePickerViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPeoplePickerViewController.h"
#import "BHPunchlistItemViewController.h"
#import "BHChecklistItemViewController.h"

@interface BHPeoplePickerViewController () <UIAlertViewDelegate> {
    NSMutableArray *filteredUsers;
    UIAlertView *userAlertView;
    NSIndexPath *selectedIndexPath;
}

@end

@implementation BHPeoplePickerViewController
@synthesize userArray, phone, email, countNotNeeded;
@synthesize users = _users;
- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!filteredUsers) filteredUsers = [NSMutableArray array];
    [self.view setBackgroundColor:kDarkerGrayColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchDisplayController.searchBar setShowsCancelButton:YES animated:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView){
        return filteredUsers.count;
    } else {
        return self.userArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    User *user;
    if (tableView == self.searchDisplayController.searchResultsTableView){

            user = [filteredUsers objectAtIndex:indexPath.row];
            [cell.textLabel setText:user.fullname];
        
    } else {
        user = [self.userArray objectAtIndex:indexPath.row];
        [cell.textLabel setText:user.fullname];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.userArray.count) {
        selectedIndexPath = indexPath;
        userAlertView = [[UIAlertView alloc] initWithTitle:@"# of Hours Worked" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
        userAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[userAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
        [userAlertView show];
    } else if (countNotNeeded){
        [self selectUser:indexPath andCount:nil];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == userAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            [self selectUser:nil andCount:[f numberFromString:[[userAlertView textFieldAtIndex:0] text]]];
        }
    }
}

- (void)selectUser:(NSIndexPath*)indexPath andCount:(NSNumber*)count {
    User *user;
    if (self.userArray.count){
        user = [self.userArray objectAtIndex:selectedIndexPath.row];
        user.hours = count;
        [self addPersonnel:user];
    }
    id precedingVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
    NSDictionary *userInfo;
    if (self.phone) {
        if (user.phone) {
            userInfo = @{@"number":user.phone};
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlaceCall" object:nil userInfo:userInfo];
    } else if (self.email) {
        if (user.email) {
            userInfo = @{@"email":user.email};
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SendEmail" object:nil userInfo:userInfo];
    } else if ([precedingVC isKindOfClass:[BHPunchlistItemViewController class]]){
        userInfo = @{kpersonnel:_users};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PunchlistPersonnel" object:nil userInfo:userInfo];
    } else if ([precedingVC isKindOfClass:[BHChecklistItemViewController class]]) {
        userInfo = @{kpersonnel:_users};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChecklistPersonnel" object:nil userInfo:userInfo];
    } else {
        userInfo = @{kpersonnel:_users};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportPersonnel" object:nil userInfo:userInfo];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addPersonnel:(id)obj {
    if (![_users containsObject:obj]) {
        if (_users){
            [_users addObject:obj];
        } else {
            _users = [NSMutableOrderedSet orderedSet];
            [_users addObject:obj];
        }
    }
}
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredUsers removeAllObjects];
    for (User *user in self.userArray){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:user.fullname]) {
            [filteredUsers addObject:user];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.email = NO;
    self.phone = NO;
}

#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:nil];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    //[self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
    //[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return NO;
}

@end
