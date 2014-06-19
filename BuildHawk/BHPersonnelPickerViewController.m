//
//  BHPersonnelPickerViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPersonnelPickerViewController.h"
#import "BHTaskViewController.h"
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
    NSMutableArray *_subcontractors;
}
@end

static NSString * const kAddPersonnelPlaceholder = @"    Add new personnel...";

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
    
    self.searchDisplayController.searchResultsTableView.rowHeight = 60;
    if (_users.count){
        filteredUsers = [NSMutableArray array];
    } else {
        filteredSubcontractors = [NSMutableArray array];
        loading = YES;
        _subcontractors = _company.subcontractors.array.mutableCopy;
        [self loadSubcontractors];
    }
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
    self.tableView.tableHeaderView = self.searchDisplayController.searchBar;
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
    } else {
        _subcontractors = _company.subcontractors.array.mutableCopy;
        [self.tableView reloadData];
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
        //NSLog(@"success loading company subcontractors: %@",responseObject);
        [_company populateWithDict:[responseObject objectForKey:@"company"]];
        loading = NO;
        [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
            _subcontractors = _company.subcontractors.array.mutableCopy;
            NSLog(@"%u success with saving company",success);
            [ProgressHUD dismiss];
            [self.tableView reloadData];
        }];
        
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
    if (_taskMode) {
        if (loading) {
            return 0;
        } else if (tableView == self.searchDisplayController.searchResultsTableView){
            return 1;
        }
        else {
            return _subcontractors.count;
        }
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
        if (_taskMode){
            Subcontractor *subcontractor = [_subcontractors objectAtIndex:section];
            return subcontractor.users.count + 2;
        } else if (_users.count) {
            return _users.count;
        } else {
            return _subcontractors.count;
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
            [cell.nameLabel setText:user.fullname];
        } else {
            user = [_users objectAtIndex:indexPath.row];
            [cell.nameLabel setText:user.fullname];
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
        [cell.nameLabel setText:@""];
        [cell.nameLabel setTextColor:[UIColor blackColor]];
        [cell.nameLabel setFont:[UIFont systemFontOfSize:16]];
        [cell.connectDetail setText:@""];
        [cell.connectNameLabel setText:@""];
        
        cell.userInteractionEnabled = YES;
        Subcontractor *subcontractor = nil;
        if (tableView == self.searchDisplayController.searchResultsTableView){
            if (indexPath.row == filteredSubcontractors.count) {
                [cell.nameLabel setText:[NSString stringWithFormat:@"Add \"%@\" to list",self.searchDisplayController.searchBar.text]];
                [cell.nameLabel setTextColor:[UIColor lightGrayColor]];
                [cell.nameLabel setFont:[UIFont italicSystemFontOfSize:16]];
            } else {
                subcontractor = [filteredSubcontractors objectAtIndex:indexPath.row];
                [cell.nameLabel setText:subcontractor.name];
                [cell.nameLabel setTextColor:[UIColor blackColor]];
                [cell.nameLabel setFont:[UIFont systemFontOfSize:16]];
            }
        } else {
            
            if (_taskMode){
                subcontractor = [_subcontractors objectAtIndex:indexPath.section];
                if (indexPath.row == 0){
                    //first row is the subcontractor name
                    [cell.nameLabel setText:subcontractor.name];
                    cell.userInteractionEnabled = NO;
                } else if (indexPath.row > 0 && indexPath.row <= subcontractor.users.count) {
                    //next rows are for actual personnel
                    User *user = subcontractor.users[indexPath.row-1];
                    [cell.connectNameLabel setText:user.fullname];
                    if (user.email.length){
                        [cell.connectDetail setText:user.email];
                    } else if (user.phone.length) {
                        [cell.connectDetail setText:user.phone];
                    }
                } else {
                    //the last row is for "adding new personnel"
                    [cell.nameLabel setText:kAddPersonnelPlaceholder];
                    [cell.nameLabel setFont:[UIFont italicSystemFontOfSize:15]];
                    [cell.nameLabel setTextColor:[UIColor lightGrayColor]];
                }
            } else {
                subcontractor = [_subcontractors objectAtIndex:indexPath.row];
                [cell.nameLabel setText:subcontractor.name];
            }
        }
        
        [cell.hoursTextField setText:@""];
        if (subcontractor){
            for (ReportSub *reportSub in _orderedSubs){
                if ([reportSub.companyId isEqualToNumber:subcontractor.identifier] && reportSub.count.intValue > 0){
                    [cell.hoursTextField setText:[NSString stringWithFormat:@"%@",reportSub.count]];
                    break;
                }
            }
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_taskMode){
        if (indexPath.row == 0){
            cell.backgroundColor = [UIColor colorWithWhite:.95 alpha:1];
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_taskMode){
        if (indexPath.row == 0) {
            return 34;
        } else {
            return 60;
        }
    } else {
        return 60;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"AddPersonnel"]){
        BHAddPersonnelViewController *vc = [segue destinationViewController];
        if (_users.count){
            [vc setCompanyMode:NO];
        } else {
            if (_taskMode){
                [vc setCompanyMode:NO];
            } else {
                [vc setCompanyMode:YES];
            }
            if ([sender isKindOfClass:[Subcontractor class]]){
                [vc setTitle:[NSString stringWithFormat:@"Add to: %@",[(Subcontractor*)sender name]]];
                [vc setSubcontractor:(Subcontractor*)sender];
            } else if (self.searchDisplayController.searchBar.text) {
                [vc setName:self.searchDisplayController.searchBar.text];
            }
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
        } else if ([precedingVC isKindOfClass:[BHTaskViewController class]]){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WorklistPersonnel" object:nil userInfo:@{kpersonnel:selectedUser}];
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
        //subcontractor select mode
        if (_taskMode){
            selectedSubcontractor = [_subcontractors objectAtIndex:indexPath.section];
            if (indexPath.row > 0 && indexPath.row <= selectedSubcontractor.users.count){
                //selecting an actual user
                User *user = selectedSubcontractor.users[indexPath.row-1];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AssignTask" object:nil userInfo:@{@"user":user}];
                NSLog(@"selected: %@", user.fullname);
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                //selecting "add new"
                [self performSegueWithIdentifier:@"AddPersonnel" sender:selectedSubcontractor];
            }
        } else {
            selectedSubcontractor = [_subcontractors objectAtIndex:indexPath.row];
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
    if ([precedingVC isKindOfClass:[BHTaskViewController class]]){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WorklistPersonnel" object:nil userInfo:userInfo];
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
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
            if([predicate evaluateWithObject:user.fullname]) {
                [filteredUsers addObject:user];
            }
        }
    } else {
        [filteredSubcontractors removeAllObjects];
        for (Subcontractor *subcontractor in _subcontractors){
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
