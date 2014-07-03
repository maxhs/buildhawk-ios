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
//#import <AddressBook/AddressBook.h>
//#import "BHAddressBookPickerViewController.h"

@interface BHPersonnelPickerViewController () <UIAlertViewDelegate> {
    NSMutableArray *filteredUsers;
    NSMutableArray *filteredSubcontractors;
    UIAlertView *userAlertView;
    UIAlertView *companyAlertView;
    User *selectedUser;
    Subcontractor *selectedSubcontractor;
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
@synthesize orderedSubs = _orderedSubs;
@synthesize orderedUsers = _orderedUsers;

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
    
    /*UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 44)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    [headerView addSubview:self.searchBar];
    [self.searchBar setFrame:CGRectMake(0, 0, screenWidth()/2, 44)];
    self.searchBar.delegate = self;

    [headerView addSubview:_addressBookButton];
    [_addressBookButton setTitle:@"Address Book" forState:UIControlStateNormal];
    [_addressBookButton setFrame:CGRectMake(screenWidth()/2, 0, screenWidth()/2, 44)];
    [_addressBookButton addTarget:self action:@selector(goToAddressBook) forControlEvents:UIControlEventTouchUpInside];*/
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
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] GET:[NSString stringWithFormat:@"%@/project_subs/%@",kApiBaseUrl,_project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    [_project.users enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
        if (!user.company.projectUsers){
            user.company.projectUsers = [NSMutableOrderedSet orderedSet];
        }
        [user.company.projectUsers addObject:user];
        [companySet addObject:user.company];
        NSLog(@"inside block");
    }];
    
    NSLog(@"what finishes first? company set: %d",companySet.count);
    [self.tableView reloadData];
}
/*- (void)goToAddressBook {
    CFErrorRef error = nil;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (!addressBook)
    {
        //some sort of error preventing us from grabbing the address book
        return;
    }
    if (!peopleArray){
        peopleArray = [NSArray array];
    }
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (granted){
            CFArrayRef arrayOfPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
            peopleArray = (__bridge NSArray *)(arrayOfPeople);
            
            CFRelease(arrayOfPeople);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"AddressBook" sender:nil];
            });
        }
    });
}*/

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
            return companySet.count;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (searching){
        if (section == 0) {
            if (_companyMode) {
                return filteredSubcontractors.count;
            } else {
                return filteredUsers.count;
            }
        } else {
            return 1;
        }
        
    } else {
        Company *company = companySet[section];
        NSLog(@"returning %d users",company.projectUsers.count);
        return company.projectUsers.count + 1;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (searching){
        return @"";
    } else {
        Company *company = companySet[section];
        return company.name;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_companyMode){
        BHChoosePersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReportCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChoosePersonnelCell" owner:self options:nil] lastObject];
        }
        [cell.nameLabel setText:@""];
        [cell.nameLabel setTextColor:[UIColor blackColor]];
        [cell.nameLabel setFont:[UIFont systemFontOfSize:16]];
        [cell.connectDetailLabel setText:@""];
        [cell.connectNameLabel setText:@""];
        
        cell.userInteractionEnabled = YES;
        Subcontractor *subcontractor = nil;
        if (searching){
            if (indexPath.row == filteredSubcontractors.count) {
                [cell.nameLabel setText:[NSString stringWithFormat:@"Add \"%@\" to list",self.searchBar.text]];
                [cell.nameLabel setTextColor:[UIColor lightGrayColor]];
                [cell.nameLabel setFont:[UIFont italicSystemFontOfSize:16]];
            } else {
                subcontractor = [filteredSubcontractors objectAtIndex:indexPath.row];
                [cell.nameLabel setText:subcontractor.name];
                [cell.nameLabel setTextColor:[UIColor blackColor]];
                [cell.nameLabel setFont:[UIFont systemFontOfSize:16]];
            }
        }
        /*
         for (ReportUser *reportUser in _orderedUsers){
         if ([reportUser.userId isEqualToNumber:user.identifier] && reportUser.hours.intValue > 0){
         [cell.hoursTextField setText:[NSString stringWithFormat:@"%@",reportUser.hours]];
         break;
         }
         }
         */
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

    } else {
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
                [cell.hoursTextField setText:@""];
                
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
            Company *company = companySet[indexPath.section];
            if (indexPath.row == company.projectUsers.count){
                [cell.connectNameLabel setText:@""];
                [cell.connectDetailLabel setText:@""];
                [cell.nameLabel setText:[NSString stringWithFormat:@"Add a contact to\"%@\"",company.name]];
                [cell.nameLabel setNumberOfLines:0];
                [cell.nameLabel setTextColor:[UIColor lightGrayColor]];
                [cell.nameLabel setTextAlignment:NSTextAlignmentCenter];
                [cell.nameLabel setFont:[UIFont italicSystemFontOfSize:16]];
            } else {
                User *user = company.projectUsers[indexPath.row];
            
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
                [cell.hoursTextField setText:@""];
            }
        
            return cell;
        }
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
        [vc setProject:_project];
        
        if (_companyMode){
            [vc setCompanyMode:YES];
        } else {
            [vc setCompanyMode:NO];
        }
        if ([sender isKindOfClass:[Company class]]){
            [vc setTitle:[NSString stringWithFormat:@"Add to: %@",[(Company*)sender name]]];
            [vc setCompany:(Company*)sender];
        } else if (self.searchBar.text) {
            [vc setName:self.searchBar.text];
        }
    }/* else if ([segue.identifier isEqualToString:@"AddressBook"]){
        BHAddressBookPickerViewController *vc = [segue destinationViewController];
        [vc setPeopleArray:peopleArray];
        if (_task){
            [vc setTask:_task];
        }
    }*/
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searching && indexPath.row == filteredSubcontractors.count){
        [self performSegueWithIdentifier:@"AddPersonnel" sender:nil];
    } else if (_task){
        NSLog(@"did select durign task mode");
        Company *company = companySet[indexPath.section];
        if (indexPath.row == company.projectUsers.count){
            [self performSegueWithIdentifier:@"AddPersonnel" sender:company];
        } else {
            selectedUser = [company.projectUsers objectAtIndex:indexPath.row];
        }
        
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AssignTask" object:nil userInfo:@{@"user":selectedUser}];
            [self.navigationController popViewControllerAnimated:YES];
        } else if ([precedingVC isKindOfClass:[BHChecklistItemViewController class]]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChecklistPersonnel" object:nil userInfo:@{kpersonnel:selectedUser}];
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    } else if (_companyMode) {
        NSLog(@"did select durign company mode");
        //subcontractor select mode
        if (_companyMode){
            selectedSubcontractor = [_project.companies objectAtIndex:indexPath.row];
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
        } else {
            selectedSubcontractor = [_project.companies objectAtIndex:indexPath.section];
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
        }
    } else {
        selectedUser = [_project.users objectAtIndex:indexPath.row];
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
    /*NSDictionary *userInfo;
    if (_project.users.count){
        userInfo = @{kUsers:_orderedUsers};
    } else if (_orderedSubs.count) {
        userInfo = @{kSubcontractors:_orderedSubs};
    }
    
    id precedingVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
    if ([precedingVC isKindOfClass:[BHTaskViewController class]]){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WorklistPersonnel" object:nil userInfo:userInfo];
    } else if ([precedingVC isKindOfClass:[BHChecklistItemViewController class]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChecklistPersonnel" object:nil userInfo:userInfo];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportPersonnel" object:nil userInfo:userInfo];
    }*/
    [self.navigationController popViewControllerAnimated:YES];
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
    NSLog(@"new text: %@",newText);
    [self filterContentForSearchText:newText scope:nil];
    return YES;
}


@end
