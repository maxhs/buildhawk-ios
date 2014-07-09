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
#import "Project+helper.h"
#import "BHChoosePersonnelCell.h"
#import "BHAddPersonnelViewController.h"

@interface BHPersonnelPickerViewController () <UIAlertViewDelegate> {
    NSMutableArray *filteredUsers;
    NSMutableArray *filteredSubcontractors;
    UIAlertView *userAlertView;
    UIAlertView *companyAlertView;
    User *selectedUser;
    Company *selectedCompany;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *doneButton;
    NSArray *peopleArray;
    BOOL loading;
    BOOL searching;
    NSMutableOrderedSet *companySet;
}
@end

static NSString * const kAddPersonnelPlaceholder = @"    Add new personnel...";

@implementation BHPersonnelPickerViewController
@synthesize phone, email;
@synthesize project = _project;
@synthesize company = _company;
@synthesize task = _task;
@synthesize report = _report;
//@synthesize orderedSubs = _orderedSubs;
//@synthesize orderedUsers = _orderedUsers;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:kDarkerGrayColor];
    self.tableView.rowHeight = 60;
    if (_project.users.count){
        filteredUsers = [NSMutableArray array];
    } else {
        filteredSubcontractors = [NSMutableArray array];
        loading = YES;
    }
    
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];

    self.tableView.tableHeaderView = self.searchBar;
    
    //set the search bar tint color so you can see the cursor
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setBackgroundColor:[UIColor clearColor]];
            [searchTextField setTextColor:[UIColor blackColor]];
            [searchTextField setTintColor:[UIColor blackColor]];
            [searchTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            break;
        }
    }
    self.searchBar.placeholder = @"Search for personnel...";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self doneEditing];
    searching = NO;
    [self loadPersonnel];
}

- (void)loadPersonnel {
    [ProgressHUD show:@"Getting personnel..."];
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] GET:[NSString stringWithFormat:@"%@/projects/%@",kApiBaseUrl,_project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success loading project personnel: %@",responseObject);
        [_project update:[responseObject objectForKey:@"project"]];
        loading = NO;
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"%u success with saving project subs",success);
            [ProgressHUD dismiss];
            [self processPersonnel];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load company information: %@",error.description);
        [ProgressHUD dismiss];
    }];
}

- (void)processPersonnel {
    companySet = [NSMutableOrderedSet orderedSet];
    [_project.companies enumerateObjectsUsingBlock:^(Company *company, NSUInteger idx, BOOL *stop) {
        [companySet addObject:company];
    }];
    if (!_companyMode){
    [_project.users enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
        if (!user.company.projectUsers){
            user.company.projectUsers = [NSMutableOrderedSet orderedSet];
        }
        [user.company.projectUsers addObject:user];
        [companySet addObject:user.company];
    }];
    }
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searching = YES;
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)doneEditing {
    [self.view endEditing:YES];
    searching = NO;
    [self.searchBar setText:@""];
    [self.tableView reloadData];
    self.navigationItem.rightBarButtonItem = saveButton;
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (searching){
        return 2;
    } else {
        if (loading) {
            return 0;
        } else {
            if (_companyMode){
                return 1;
            } else {
                return companySet.count;
            }
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (searching){
        if (section == 0) {
            return filteredUsers.count;
        } else {
            return 1;
        }
        
    } else {
        Company *company = companySet[section];
        if (_report){
            if (_companyMode){
                return companySet.count;
            } else {
                if ([company.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    return company.projectUsers.count + 2;
                } else {
                    return 1;
                }
            }
        } else {
            if ([company.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                return company.projectUsers.count + 2;
            } else {
                return 1;
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (searching){
        if (indexPath.section == 0){
            static NSString *CellIdentifier = @"ReportCell";
            BHChoosePersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChoosePersonnelCell" owner:self options:nil] lastObject];
            }
            User *user;
            if (filteredUsers.count){
                user = [filteredUsers objectAtIndex:indexPath.row];
                [cell.connectNameLabel setText:user.fullname];
                if (user.company.name.length){
                    NSAttributedString *companyString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"   (%@)",user.company.name] attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
                    NSMutableAttributedString *userString = [[NSMutableAttributedString alloc] initWithString:user.fullname];
                    [userString appendAttributedString:companyString];
                    [cell.connectNameLabel setAttributedText:userString];
                }
                
                if (user.email.length){
                    [cell.connectDetailLabel setText:user.email];
                } else if (user.phone.length) {
                    [cell.connectDetailLabel setText:user.phone];
                }
            }
            //clear out the plain old boring name label
            [cell.nameLabel setText:@""];
            [cell.hoursLabel setText:@""];
            
            return cell;
        } else {
            BHChoosePersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReportCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChoosePersonnelCell" owner:self options:nil] lastObject];
            }
            [cell.connectNameLabel setText:@""];
            [cell.connectDetailLabel setText:@""];
            [cell.nameLabel setText:[NSString stringWithFormat:@"Add \"%@\"",self.searchBar.text]];
            [cell.nameLabel setTextColor:[UIColor lightGrayColor]];
            [cell.nameLabel setFont:[UIFont italicSystemFontOfSize:16]];
            return cell;
        }
    } else {
        static NSString *CellIdentifier = @"ReportCell";
        BHChoosePersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChoosePersonnelCell" owner:self options:nil] lastObject];
        }
        Company *company;
        if (_companyMode){
            company = companySet[indexPath.row];
        } else {
            company = companySet[indexPath.section];
        }
        
        if (_companyMode){
            [cell.connectNameLabel setText:@""];
            [cell.connectDetailLabel setText:@""];
            [cell.nameLabel setText:company.name];
            [_report.reportSubs enumerateObjectsUsingBlock:^(ReportSub *reportSub, NSUInteger idx, BOOL *stop) {
                if ([company.identifier isEqualToNumber:reportSub.companyId]){
                    [cell.connectNameLabel setText:company.name];
                    [cell.connectNameLabel setFont:[UIFont boldSystemFontOfSize:16]];
                    [cell.connectDetailLabel setText:[NSString stringWithFormat:@"%@ personnel onsite",reportSub.count]];
                    [cell.nameLabel setText:@""];
                    *stop = YES;
                }
            }];
            
            [cell.nameLabel setNumberOfLines:0];
            [cell.nameLabel setTextColor:[UIColor blackColor]];
            
        } else if (indexPath.row == 0){
            [cell.connectNameLabel setText:@""];
            [cell.connectDetailLabel setText:@""];
            [cell.nameLabel setText:company.name];
            [cell.nameLabel setNumberOfLines:0];
            [cell.nameLabel setTextColor:[UIColor blackColor]];
            [cell.nameLabel setTextAlignment:NSTextAlignmentLeft];
            [cell.nameLabel setFont:[UIFont boldSystemFontOfSize:16]];
        } else if (indexPath.row == company.projectUsers.count + 1){
            [cell.connectNameLabel setText:@""];
            [cell.connectDetailLabel setText:@""];
            [cell.nameLabel setText:[NSString stringWithFormat:@"+ new contact to \"%@\"",company.name]];
            [cell.nameLabel setNumberOfLines:0];
            [cell.nameLabel setTextColor:[UIColor lightGrayColor]];
            [cell.nameLabel setTextAlignment:NSTextAlignmentCenter];
            [cell.nameLabel setFont:[UIFont italicSystemFontOfSize:16]];
        } else {
            User *user = company.projectUsers[indexPath.row-1];
            [cell.connectNameLabel setText:user.fullname];
            if (user.company.name.length){
                NSAttributedString *companyString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"   (%@)",user.company.name] attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
                NSMutableAttributedString *userString = [[NSMutableAttributedString alloc] initWithString:user.fullname];
                [userString appendAttributedString:companyString];
                [cell.connectNameLabel setAttributedText:userString];
            }
            
            if (user.email.length){
                [cell.connectDetailLabel setText:user.email];
            } else if (user.phone.length) {
                [cell.connectDetailLabel setText:user.phone];
            }
            //clear out the plain old boring name label
            [cell.nameLabel setText:@""];
            if (_report){
                [cell.hoursLabel setText:@""];
                [_report.reportUsers enumerateObjectsUsingBlock:^(ReportUser *reportUser, NSUInteger idx, BOOL *stop) {
                    if ([user.identifier isEqualToNumber:reportUser.userId]){
                        if (reportUser.hours.intValue == 1){
                            [cell.hoursLabel setText:@"1 hour"];
                        } else {
                            [cell.hoursLabel setText:[NSString stringWithFormat:@"%@\nhours",reportUser.hours]];
                        }
                        
                        *stop = YES;
                    }
                }];
            } else {
                [cell.hoursLabel setText:@""];
            }
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"AddPersonnel"]){
        BHAddPersonnelViewController *vc = [segue destinationViewController];
        [vc setTask:_task];
        [vc setReport:_report];
        [vc setProject:_project];

        if ([sender isKindOfClass:[Company class]]){
            [vc setTitle:[NSString stringWithFormat:@"Add to: %@",[(Company*)sender name]]];
            [vc setCompany:(Company*)sender];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searching && indexPath.row == filteredSubcontractors.count){
        [self performSegueWithIdentifier:@"AddPersonnel" sender:nil];
    } else if (_task){
        selectedCompany = companySet[indexPath.section];
        if (indexPath.row == 0){
            if ([selectedCompany.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                [selectedCompany setExpanded:[NSNumber numberWithBool:NO]];
            } else {
                [selectedCompany setExpanded:[NSNumber numberWithBool:YES]];
            }
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else if (indexPath.row == selectedCompany.projectUsers.count+1){
            [self performSegueWithIdentifier:@"AddPersonnel" sender:selectedCompany];
        } else {
            selectedUser = [selectedCompany.projectUsers objectAtIndex:indexPath.row-1];
            if (selectedUser){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AssignTask" object:nil userInfo:@{@"user":selectedUser}];
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
        
    } else if (_report) {

        if (_companyMode){
            //selecting a company
            selectedCompany = companySet[indexPath.row];
            BOOL select = YES;
            for (ReportSub *reportSub in _report.reportSubs) {
                if ([selectedCompany.identifier isEqualToNumber:reportSub.companyId]){
                    [_report removeReportSubcontractor:reportSub];
                    [reportSub MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                    NSLog(@"should be removing a report sub");
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

        } else {
            //not in company mode, but this tableview still focuses on companies with a tap to expand to see individual users
            selectedCompany = companySet[indexPath.section];
            if (indexPath.row == 0){
                if ([selectedCompany.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    [selectedCompany setExpanded:[NSNumber numberWithBool:NO]];
                } else {
                    [selectedCompany setExpanded:[NSNumber numberWithBool:YES]];
                }
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            } else if (indexPath.row == selectedCompany.projectUsers.count+1){
                
                [self performSegueWithIdentifier:@"AddPersonnel" sender:selectedCompany];
                
            } else {
                selectedUser = [selectedCompany.projectUsers objectAtIndex:indexPath.row-1];
                BOOL select = YES;
                for (ReportUser *reportUser in _report.reportUsers) {
                    if ([selectedUser.identifier isEqualToNumber:reportUser.userId]){
                        [_report removeReportUser:reportUser];
                        [reportUser MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
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
            }
        }
        
    } else {
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
            if (selectedUser){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AssignTask" object:nil userInfo:@{@"user":selectedUser}];
            }
            [self.navigationController popViewControllerAnimated:YES];
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
    [_report addReportUser:reportUser];
    [self.tableView reloadData];
}

- (void)selectReportCompany:(NSIndexPath*)indexPath andCount:(NSNumber*)count {
    ReportSub *reportSub = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    reportSub.count = count;
    reportSub.name = selectedCompany.name;
    reportSub.companyId = selectedCompany.identifier;
    [_report addReportSubcontractor:reportSub];
    [self.tableView reloadData];
}

- (void)save {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportPersonnel" object:nil];
        [self.navigationController popViewControllerAnimated:YES];
    }];
    /*id precedingVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
    if ([precedingVC isKindOfClass:[BHTaskViewController class]]){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WorklistPersonnel" object:nil userInfo:userInfo];
    } else if ([precedingVC isKindOfClass:[BHChecklistItemViewController class]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChecklistPersonnel" object:nil userInfo:userInfo];
    } else {
     
    }*/
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.email = NO;
    self.phone = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self doneEditing];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredUsers removeAllObjects];
    if (_project.users.count){
        for (User *user in _project.users){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
            if([predicate evaluateWithObject:user.fullname]) {
                [filteredUsers addObject:user];
            } else if ([predicate evaluateWithObject:user.company.name]){
                [filteredUsers addObject:user];
            } else if ([predicate evaluateWithObject:user.email]){
                [filteredUsers addObject:user];
            }
        }
    } else {
        [filteredSubcontractors removeAllObjects];
        for (Company *company in _project.companies){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
            if([predicate evaluateWithObject:company.name]) {
                [filteredSubcontractors addObject:company];
            }
        }
    }
    [self.tableView reloadData];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString* newText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self filterContentForSearchText:newText scope:nil];
    return YES;
}


@end
