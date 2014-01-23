//
//  BHPeoplePickerViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPeoplePickerViewController.h"
#import "BHUser.h"
#import "BHSub.h"
#import "BHPersonnel.h"
#import "BHPunchlistItemViewController.h"
#import "BHChecklistItemViewController.h"

@interface BHPeoplePickerViewController () <UIAlertViewDelegate> {
    NSMutableArray *filteredUsers;
    NSMutableArray *filteredSubs;
    UIAlertView *subAlertView;
    NSIndexPath *selectedIndexPath;
}

@end

@implementation BHPeoplePickerViewController
@synthesize userArray, personnelArray, subArray, phone, email;
- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!filteredUsers) filteredUsers = [NSMutableArray array];
    if (!filteredSubs) filteredSubs = [NSMutableArray array];
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
    } else if (self.subArray.count) {
        return self.subArray.count;
    } else {
        return self.userArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    BHUser *user;
    BHSub *sub;
    if (tableView == self.searchDisplayController.searchResultsTableView){
        if (self.subArray.count){
            sub = [filteredSubs objectAtIndex:indexPath.row];
            [cell.textLabel setText:sub.name];
        } else {
            user = [filteredUsers objectAtIndex:indexPath.row];
            [cell.textLabel setText:user.fullname];
        }
    } else if (self.subArray.count) {
        sub = [self.subArray objectAtIndex:indexPath.row];
        [cell.textLabel setText:sub.name];
    } else {
        user = [self.userArray objectAtIndex:indexPath.row];
        [cell.textLabel setText:user.fullname];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.userArray.count) {
        [self selectUser:indexPath andCount:@"1"];
    } else if (self.subArray.count) {
        selectedIndexPath = indexPath;
        subAlertView = [[UIAlertView alloc] initWithTitle:@"# of Subcontractor Personnel" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
        subAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[subAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
        [subAlertView show];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
        [self selectUser:nil andCount:[[subAlertView textFieldAtIndex:0] text]];
    }
}

- (void)selectUser:(NSIndexPath*)indexPath andCount:(NSString*)count {
    BHUser *user;
    BHSub *sub;
    if (self.userArray.count){
        user = [self.userArray objectAtIndex:indexPath.row];
        [self addPersonnel:user];
    } else if (self.subArray.count){
        sub = [self.subArray objectAtIndex:selectedIndexPath.row];
        sub.count = count;
        [self addPersonnel:sub];
    }
    id precedingVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
    NSDictionary *userInfo;
    if (self.phone) {
        if (sub.phone){
            userInfo = @{@"number":sub.phone};
        } else if (user.phone) {
            userInfo = @{@"number":user.phone};
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlaceCall" object:nil userInfo:userInfo];
    } else if (self.email) {
        if (sub.email){
            userInfo = @{@"email":sub.email};
        } else if (user.email) {
            userInfo = @{@"email":user.email};
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SendEmail" object:nil userInfo:userInfo];
    } else if ([precedingVC isKindOfClass:[BHPunchlistItemViewController class]]){
        userInfo = @{kpersonnel:self.personnelArray};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PunchlistPersonnel" object:nil userInfo:userInfo];
    } else if ([precedingVC isKindOfClass:[BHChecklistItemViewController class]]) {
        userInfo = @{kpersonnel:self.personnelArray};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChecklistPersonnel" object:nil userInfo:userInfo];
    } else {
        userInfo = @{kpersonnel:self.personnelArray};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportPersonnel" object:nil userInfo:userInfo];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addPersonnel:(id)obj {
    if (![self.personnelArray containsObject:obj]) {
        if (self.personnelArray){
            [self.personnelArray addObject:obj];
        } else {
            self.personnelArray = [NSMutableArray array];
            [self.personnelArray addObject:obj];
        }
    } else {
        //[[[UIAlertView alloc] initWithTitle:@"Already added!" message:@"Personnel already included" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredUsers removeAllObjects];
    [filteredSubs removeAllObjects];
    if (self.subArray.count){
        for (BHSub *sub in self.subArray){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
            if([predicate evaluateWithObject:sub.name]) {
                [filteredSubs addObject:sub];
            }
        }
    } else {
        for (BHUser *user in self.userArray){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
            if([predicate evaluateWithObject:user.fullname]) {
                [filteredUsers addObject:user];
            }
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
