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

@interface BHPersonnelPickerViewController () <UIAlertViewDelegate> {
    NSMutableArray *filteredUsers;
    NSMutableArray *filteredSubcontractors;
    UIAlertView *userAlertView;
    UIAlertView *companyAlertView;
    NSIndexPath *selectedIndexPath;
    AFHTTPRequestOperationManager *manager;
}

@end

@implementation BHPersonnelPickerViewController
@synthesize phone, email, countNotNeeded;
@synthesize users = _users;
@synthesize company = _company;

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
}

- (void)loadSubcontractors {
    [ProgressHUD show:@"Getting company list..."];
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] GET:[NSString stringWithFormat:@"%@/companies/%@",kApiBaseUrl,_company.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [ProgressHUD dismiss];
        NSLog(@"success loading company subcontractors: %@",responseObject);
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
            NSLog(@"looking for companies: %d",_company.subcontractors.count);
            return _company.subcontractors.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (_users.count){
        static NSString *CellIdentifier = @"UserCell";
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        User *user;
        if (tableView == self.searchDisplayController.searchResultsTableView){
            user = [filteredUsers objectAtIndex:indexPath.row];
            [cell.textLabel setText:user.fullname];
        } else {
            user = [_users objectAtIndex:indexPath.row];
            [cell.textLabel setText:user.fullname];
            [cell.detailTextLabel setText:user.company.name];
            NSLog(@"user: %@",user);
        }
    } else {
        static NSString *CellIdentifier = @"UserCell";
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        Subcontractor *subcontractor;
        if (tableView == self.searchDisplayController.searchResultsTableView){
            subcontractor = [filteredSubcontractors objectAtIndex:indexPath.row];
            [cell.textLabel setText:subcontractor.name];
        } else {
            subcontractor = [_company.subcontractors objectAtIndex:indexPath.row];
            [cell.textLabel setText:subcontractor.name];
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@ personnel",subcontractor.usersCount]];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (countNotNeeded){
        [self selectUser:indexPath andCount:nil];
    } else if (_users.count) {
        selectedIndexPath = indexPath;
        userAlertView = [[UIAlertView alloc] initWithTitle:@"# of Hours Worked" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
        userAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[userAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
        [userAlertView show];
    } else {
        selectedIndexPath = indexPath;
        companyAlertView = [[UIAlertView alloc] initWithTitle:@"# of personnel onsite" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
        companyAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[companyAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
        [companyAlertView show];
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
    } else if (alertView == companyAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            [self selectCompany:nil andCount:[f numberFromString:[[companyAlertView textFieldAtIndex:0] text]]];
        }
    }
}

- (void)selectUser:(NSIndexPath*)indexPath andCount:(NSNumber*)count {
    User *user = [_users objectAtIndex:selectedIndexPath.row];
    user.hours = count;
    
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
        
        userInfo = @{kpersonnel:user};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PunchlistPersonnel" object:nil userInfo:userInfo];
        
    } else if ([precedingVC isKindOfClass:[BHChecklistItemViewController class]]) {
        
        userInfo = @{kpersonnel:user};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChecklistPersonnel" object:nil userInfo:userInfo];
    
    } else {
        userInfo = @{kpersonnel:user};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportPersonnel" object:nil userInfo:userInfo];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectCompany:(NSIndexPath*)indexPath andCount:(NSNumber*)count {
    Subcontractor *subcontractor = [_company.subcontractors objectAtIndex:selectedIndexPath.row];
    subcontractor.count = count;
    
    id precedingVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
    NSDictionary *userInfo;
    if ([precedingVC isKindOfClass:[BHPunchlistItemViewController class]]){
        userInfo = @{kpersonnel:subcontractor};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PunchlistPersonnel" object:nil userInfo:userInfo];
    } else if ([precedingVC isKindOfClass:[BHChecklistItemViewController class]]) {
        userInfo = @{kpersonnel:subcontractor};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChecklistPersonnel" object:nil userInfo:userInfo];
    } else {
        userInfo = @{kpersonnel:subcontractor};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportPersonnel" object:nil userInfo:userInfo];
    }
    [self.navigationController popViewControllerAnimated:YES];
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
