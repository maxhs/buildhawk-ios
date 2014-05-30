//
//  BHPersonnelPickerViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPersonnelPickerViewController.h"
#import "BHPunchlistItemViewController.h"
#import "BHChecklistItemViewController.h"
#import "BHAppDelegate.h"
#import "Company+helper.h"
#import "Subcontractor.h"
#import "ReportSub.h"
#import "ReportUser.h"
#import "BHChoosePersonnelCell.h"

@interface BHPersonnelPickerViewController () <UIAlertViewDelegate> {
    NSMutableArray *filteredUsers;
    NSMutableArray *filteredSubcontractors;
    UIAlertView *userAlertView;
    UIAlertView *companyAlertView;
    AFHTTPRequestOperationManager *manager;
    User *selectedUser;
    Subcontractor *selectedSubcontractor;
    UIBarButtonItem *saveButton;
}

@end

@implementation BHPersonnelPickerViewController
@synthesize phone, email, countNotNeeded;
@synthesize users = _users;
@synthesize company = _company;
@synthesize orderedSubs = _orderedSubs;
@synthesize orderedUsers = _orderedUsers;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:kDarkerGrayColor];
    self.tableView.rowHeight = 54;
    if (_users.count){
        filteredUsers = [NSMutableArray array];
    } else {
        filteredSubcontractors = [NSMutableArray array];
        [self loadSubcontractors];
    }
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (void)loadSubcontractors {
    [ProgressHUD show:@"Getting company list..."];
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] GET:[NSString stringWithFormat:@"%@/companies/%@",kApiBaseUrl,_company.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [ProgressHUD dismiss];
        //NSLog(@"success loading company subcontractors: %@",responseObject);
        [_company populateWithDict:[responseObject objectForKey:@"company"]];
        [self.tableView reloadData];
        [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"%u success with saving company",success);
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed to load compoany stuff: %@",error.description);
        [ProgressHUD dismiss];
    }];
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
        if (_users.count) {
            return _users.count;
        } else {
            return _company.subcontractors.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_users.count){
        static NSString *CellIdentifier = @"ReportCell";
        BHChoosePersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChoosePersonnelCell" owner:self options:nil] lastObject];
        }
        User *user;
        if (tableView == self.searchDisplayController.searchResultsTableView){
            user = [filteredUsers objectAtIndex:indexPath.row];
            [cell.textLabel setText:user.fullname];
        } else {
            user = [_users objectAtIndex:indexPath.row];
            [cell.textLabel setText:user.fullname];
            [cell.detailTextLabel setText:user.company.name];
        }
        [cell.hoursTextField setText:@""];
        for (ReportUser *reportUser in _orderedUsers){
            if ([reportUser.identifier isEqualToNumber:user.identifier] && reportUser.hours.intValue > 0){
                [cell.hoursTextField setText:[NSString stringWithFormat:@"%@",reportUser.hours]];
                break;
            }
        }
        return cell;
    } else {
        static NSString *CellIdentifier = @"ReportCell";
        BHChoosePersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChoosePersonnelCell" owner:self options:nil] lastObject];
        }
        Subcontractor *subcontractor;
        if (tableView == self.searchDisplayController.searchResultsTableView){
            subcontractor = [filteredSubcontractors objectAtIndex:indexPath.row];
            [cell.textLabel setText:subcontractor.name];
        } else {
            subcontractor = [_company.subcontractors objectAtIndex:indexPath.row];
            [cell.textLabel setText:subcontractor.name];
            [cell.detailTextLabel setHidden:YES];
        }
        
        [cell.hoursTextField setText:@""];
        for (ReportSub *reportSub in _orderedSubs){
            if ([reportSub.identifier isEqualToNumber:subcontractor.identifier] && reportSub.count.intValue > 0){
                [cell.hoursTextField setText:[NSString stringWithFormat:@"%@",reportSub.count]];
                break;
            }
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (countNotNeeded){
        selectedUser = [_users objectAtIndex:indexPath.row];
        [self selectUserWithCount:nil];
    } else if (_users.count) {
        selectedUser = [_users objectAtIndex:indexPath.row];
        BOOL select = YES;
        for (ReportUser *reportUser in _orderedUsers) {
            if ([selectedUser.identifier isEqualToNumber:reportUser.identifier]){
                selectedUser.hours = nil;
                [_orderedUsers removeObject:reportUser];
                select = NO;
                break;
            }
        }
        if (select){
            userAlertView = [[UIAlertView alloc] initWithTitle:@"# of Hours Worked" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
            userAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [[userAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
            [userAlertView show];
        } else {
            [self.tableView reloadData];
        }
    } else {
        selectedSubcontractor = [_company.subcontractors objectAtIndex:indexPath.row];
        BOOL select = YES;
        for (ReportSub *reportSub in _orderedSubs) {
            if ([selectedSubcontractor.identifier isEqualToNumber:reportSub.identifier]){
                selectedSubcontractor.count = nil;
                [_orderedSubs removeObject:reportSub];
                select = NO;
                break;
            }
        }
        if (select){
            companyAlertView = [[UIAlertView alloc] initWithTitle:@"# of personnel onsite" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
            companyAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [[companyAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
            [companyAlertView show];
        }else {
            [self.tableView reloadData];
        }
        
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == userAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            [self selectUserWithCount:[f numberFromString:[[userAlertView textFieldAtIndex:0] text]]];
        }
    } else if (alertView == companyAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            [self selectCompany:nil andCount:[f numberFromString:[[companyAlertView textFieldAtIndex:0] text]]];
        }
    }
}

- (void)selectUserWithCount:(NSNumber*)count {
    
    ReportUser *reportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    reportUser.hours = count;
    reportUser.fullname = selectedUser.fullname;
    reportUser.identifier = selectedUser.identifier;
    
    NSDictionary *userInfo;
    if (self.phone) {
        if (selectedUser.phone) {
            userInfo = @{@"number":selectedUser.phone};
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlaceCall" object:nil userInfo:userInfo];
    } else if (self.email) {
        if (selectedUser.email) {
            userInfo = @{@"email":selectedUser.email};
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SendEmail" object:nil userInfo:userInfo];
    } else {
        [_orderedUsers addObject:reportUser];
    }
    [self.tableView reloadData];
    //[self.navigationController popViewControllerAnimated:YES];
}

- (void)selectCompany:(NSIndexPath*)indexPath andCount:(NSNumber*)count {
    ReportSub *reportSub = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    reportSub.count = count;
    reportSub.name = selectedSubcontractor.name;
    reportSub.identifier = selectedSubcontractor.identifier;
    [_orderedSubs addObject:reportSub];
    [self.tableView reloadData];
    //[self.navigationController popViewControllerAnimated:YES];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredUsers removeAllObjects];
    for (User *user in _users){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:user.fullname]) {
            [filteredUsers addObject:user];
        }
    }
}

- (void)save {
    NSDictionary *userInfo;
    if (_orderedUsers.count){
        userInfo = @{kpersonnel:_orderedUsers};
    } else if (_orderedSubs.count) {
        userInfo = @{kpersonnel:_orderedSubs};
    }
    
    id precedingVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
    if ([precedingVC isKindOfClass:[BHPunchlistItemViewController class]]){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PunchlistPersonnel" object:nil userInfo:userInfo];
    } else if ([precedingVC isKindOfClass:[BHChecklistItemViewController class]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChecklistPersonnel" object:nil userInfo:userInfo];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportPersonnel" object:nil userInfo:userInfo];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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
