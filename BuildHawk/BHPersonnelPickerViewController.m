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
#import "BHAddPersonnelViewController.h"

@interface BHPersonnelPickerViewController () <UIAlertViewDelegate> {
    NSMutableArray *filteredUsers;
    NSMutableArray *filteredSubcontractors;
    UIAlertView *userAlertView;
    UIAlertView *companyAlertView;
    AFHTTPRequestOperationManager *manager;
    User *selectedUser;
    Subcontractor *selectedSubcontractor;
    UIBarButtonItem *saveButton;
    BOOL loading;
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
    self.searchDisplayController.searchResultsTableView.rowHeight = 54;
    if (_users.count){
        filteredUsers = [NSMutableArray array];
    } else {
        filteredSubcontractors = [NSMutableArray array];
        loading = YES;
        [self loadSubcontractors];
    }
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    //set the search bar tint color so you can see the cursor
    for (id subview in [self.searchDisplayController.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setBackgroundColor:[UIColor clearColor]];
            [searchTextField setTextColor:[UIColor blackColor]];
            [searchTextField setTintColor:[UIColor blackColor]];
            [searchTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            break;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.searchDisplayController.isActive){
        [self loadSubcontractors];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.searchDisplayController.isActive){
        [self.searchDisplayController setActive:NO animated:YES];
        [self.view endEditing:YES];
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
        loading = NO;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load company information: %@",error.description);
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
    if (_worklistMode) {
        if (loading) return 0;
        else return _company.subcontractors.count;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView){
        if (_users.count){
            return filteredUsers.count;
        } else {
            if (self.searchDisplayController.searchBar.text.length){
                return filteredSubcontractors.count + 1;
            } else {
                return filteredSubcontractors.count;
            }
        }
    } else {
        if (_worklistMode){
            Subcontractor *subcontractor = [_company.subcontractors objectAtIndex:section];
            return subcontractor.users.count;
        } else if (_users.count) {
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
            if ([reportUser.userId isEqualToNumber:user.identifier] && reportUser.hours.intValue > 0){
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
            if (indexPath.row == filteredSubcontractors.count) {
                [cell.textLabel setText:[NSString stringWithFormat:@"Add \"%@\" to list",self.searchDisplayController.searchBar.text]];
                [cell.textLabel setTextColor:[UIColor lightGrayColor]];
                [cell.textLabel setFont:[UIFont italicSystemFontOfSize:16]];
            } else {
                subcontractor = [filteredSubcontractors objectAtIndex:indexPath.row];
                [cell.textLabel setText:subcontractor.name];
                [cell.textLabel setTextColor:[UIColor blackColor]];
                [cell.textLabel setFont:[UIFont systemFontOfSize:16]];
            }
        } else {
            subcontractor = [_company.subcontractors objectAtIndex:indexPath.row];
            [cell.textLabel setText:subcontractor.name];
            [cell.detailTextLabel setHidden:YES];
        }
        
        [cell.hoursTextField setText:@""];
        for (ReportSub *reportSub in _orderedSubs){
            if ([reportSub.companyId isEqualToNumber:subcontractor.identifier] && reportSub.count.intValue > 0){
                [cell.hoursTextField setText:[NSString stringWithFormat:@"%@",reportSub.count]];
                break;
            }
        }
        return cell;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"AddPersonnel"]){
        BHAddPersonnelViewController *vc = [segue destinationViewController];
        if (_users.count){
            [vc setCompanyMode:NO];
        } else {
            [vc setName:self.searchDisplayController.searchBar.text];
            [vc setCompanyMode:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView && indexPath.row == filteredSubcontractors.count){
        [self performSegueWithIdentifier:@"AddPersonnel" sender:nil];
    } else if (countNotNeeded){
        selectedUser = [_users objectAtIndex:indexPath.row];
        id precedingVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        
        if (self.phone) {
            if (selectedUser.phone.length) {
                [self.navigationController popViewControllerAnimated:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PlaceCall" object:nil userInfo:@{@"number":selectedUser.phone}];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user does not have a phone number on file." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        } else if (self.email) {
            if (selectedUser.email.length) {
                [self.navigationController popViewControllerAnimated:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SendEmail" object:nil userInfo:@{@"email":selectedUser.email}];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user does not have an email address on file." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        } else if ([precedingVC isKindOfClass:[BHPunchlistItemViewController class]]){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PunchlistPersonnel" object:nil userInfo:@{kpersonnel:selectedUser}];
            [self.navigationController popViewControllerAnimated:YES];
        } else if ([precedingVC isKindOfClass:[BHChecklistItemViewController class]]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChecklistPersonnel" object:nil userInfo:@{kpersonnel:selectedUser}];
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    } else if (_users.count) {
        selectedUser = [_users objectAtIndex:indexPath.row];
        BOOL select = YES;
        for (ReportUser *reportUser in _orderedUsers) {
            if ([selectedUser.identifier isEqualToNumber:reportUser.userId]){
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
            if ([selectedSubcontractor.identifier isEqualToNumber:reportSub.companyId]){
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
        } else {
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
            [self selectReportUserWithCount:[f numberFromString:[[userAlertView textFieldAtIndex:0] text]]];
        }
    } else if (alertView == companyAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            [self selectReportCompany:nil andCount:[f numberFromString:[[companyAlertView textFieldAtIndex:0] text]]];
        }
    }
}

- (void)selectReportUserWithCount:(NSNumber*)count {
    ReportUser *reportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    reportUser.hours = count;
    reportUser.fullname = selectedUser.fullname;
    reportUser.userId = selectedUser.identifier;
    [_orderedUsers addObject:reportUser];
    [self.tableView reloadData];
}

- (void)selectReportCompany:(NSIndexPath*)indexPath andCount:(NSNumber*)count {
    ReportSub *reportSub = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    reportSub.count = count;
    reportSub.name = selectedSubcontractor.name;
    reportSub.companyId = selectedSubcontractor.identifier;
    [_orderedSubs addObject:reportSub];
    [self.tableView reloadData];
}

- (void)save {
    NSDictionary *userInfo;
    if (_users.count){
        userInfo = @{kUsers:_orderedUsers};
    } else {
        userInfo = @{kSubcontractors:_orderedSubs};
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


- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    if (_users.count){
        [filteredUsers removeAllObjects];
        for (User *user in _users){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
            if([predicate evaluateWithObject:user.fullname]) {
                [filteredUsers addObject:user];
            }
        }
    } else {
        [filteredSubcontractors removeAllObjects];
        for (Subcontractor *subcontractor in _company.subcontractors){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
            if([predicate evaluateWithObject:subcontractor.name]) {
                [filteredSubcontractors addObject:subcontractor];
            }
        }
    }
}

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
