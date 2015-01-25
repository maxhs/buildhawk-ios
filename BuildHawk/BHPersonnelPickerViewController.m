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
#import "BHSearchModalTransition.h"
#import "BHCompaniesViewController.h"

@interface BHPersonnelPickerViewController () <UIAlertViewDelegate, UIViewControllerTransitioningDelegate> {
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *filteredUsers;
    NSMutableArray *filteredSubcontractors;
    UIAlertView *userAlertView;
    UIAlertView *companyAlertView;
    User *selectedUser;
    Company *selectedCompany;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *cancelButton;
    NSArray *peopleArray;
    BOOL loading;
    BOOL searching;
    NSMutableOrderedSet *companySet;
    NSString *searchText;
    NSTimeInterval duration;
    UIViewAnimationOptions animationCurve;
    Project *_project;
    Report *_report;
    Task *_task;
    Company *_company;
}
@end

static NSString * const kAddPersonnelPlaceholder = @"    Add new personnel...";

@implementation BHPersonnelPickerViewController
@synthesize phone, email;
@synthesize projectId = _projectId;
@synthesize companyId = _companyId;
@synthesize taskId = _taskId;
@synthesize reportId = _reportId;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:kDarkerGrayColor];
    self.tableView.rowHeight = 60;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    if (_companyMode){
        filteredSubcontractors = [NSMutableArray array];
    } else {
        filteredUsers = [NSMutableArray array];
    }
    
    _project = [Project MR_findFirstByAttribute:@"identifier" withValue:_projectId inContext:[NSManagedObjectContext MR_defaultContext]];
    _report = [Report MR_findFirstByAttribute:@"identifier" withValue:_reportId inContext:[NSManagedObjectContext MR_defaultContext]];
    _company = [Company MR_findFirstByAttribute:@"identifier" withValue:_companyId inContext:[NSManagedObjectContext MR_defaultContext]];
    _task = [Task MR_findFirstByAttribute:@"identifier" withValue:_taskId inContext:[NSManagedObjectContext MR_defaultContext]];
    
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = doneButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];

    self.tableView.tableHeaderView = self.searchBar;
    
    //set the search bar tint color so you can see the cursor
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setBackgroundColor:[UIColor clearColor]];
            [searchTextField setTextColor:[UIColor blackColor]];
            [searchTextField setTintColor:[UIColor blackColor]];
            [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadProRegular] size:0]];
            [searchTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            break;
        }
    }
    if (_companyMode){
        self.searchBar.placeholder = @"Search for / add a new company...";
    } else {
        self.searchBar.placeholder = @"Search for / add personnel...";
    }
    companySet = [NSMutableOrderedSet orderedSet];
    [self pinParentCompanyToTop];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCompany:) name:@"AddCompany" object:nil];
    [self registerKeyboardNotifications];
}

- (void)pinParentCompanyToTop {
    for (Company *company in _project.companies){
        [companySet addObject:company];
    }
    [companySet removeObject:_project.company];
    [companySet insertObject:_project.company atIndex:0];
}

- (void)addCompany:(NSNotification*)notification {
    _companyMode = YES;
    Company *company = [notification.userInfo objectForKey:@"company"];
    if (company){
        [companySet addObject:company];
    }
    [self endSearch];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self doneEditing];
    searching = NO;
    [self loadPersonnel];
}

- (void)loadPersonnel {
    [ProgressHUD show:@"Fetching personnel..."];
    [manager GET:[NSString stringWithFormat:@"%@/projects/%@",kApiBaseUrl,_project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success loading project personnel: %@",responseObject);
        [_project updateFromDictionary:[responseObject objectForKey:@"project"]];
        loading = NO;
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            //NSLog(@"%u success with saving project subs",success);
            [ProgressHUD dismiss];
            [self processPersonnel];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load company information: %@",error.description);
        [ProgressHUD dismiss];
    }];
}

- (void)processPersonnel {
    if (companySet){
        [companySet removeAllObjects];
    }
    [_project.companies enumerateObjectsUsingBlock:^(Company *company, NSUInteger idx, BOOL *stop) {
        [companySet addObject:company];
    }];
    
    [self pinParentCompanyToTop];
    
    [_project.users enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
        if (!user.company.projectUsers){
            user.company.projectUsers = [NSMutableOrderedSet orderedSet];
        }
        [user.company.projectUsers addObject:user];
        
        if (user.company)
            [companySet addObject:user.company];
    }];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    BOOL shouldReload = NO;
    if (!searching){
        shouldReload = YES;
    }
    searching = YES;
    if (_companyMode){
        [filteredSubcontractors removeAllObjects];
        [filteredSubcontractors addObjectsFromArray:companySet.array];
    } else {
        [filteredUsers removeAllObjects];
        [filteredUsers addObjectsFromArray:_project.users.array];
    }
    if (shouldReload) [self.tableView reloadData];
    
    self.navigationItem.rightBarButtonItem = cancelButton;
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
    [filteredSubcontractors removeAllObjects];
    [filteredUsers removeAllObjects];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    searching = NO;
    [self.searchBar setText:@""];
    [self.tableView reloadData];
    self.navigationItem.rightBarButtonItem = doneButton;
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
                if (companySet.count){
                    return 1;
                } else {
                    return 0;
                }
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
            if (_companyMode){
                return filteredSubcontractors.count;
            } else {
                return filteredUsers.count;
            }
        } else {
            return 1;
        }
        
    } else {
        Company *company = companySet[section];
        if (_report){
            if (_companyMode){
                return companySet.count;
            } else {
                if ([company.expanded isEqualToNumber:@YES]){
                    return company.projectUsers.count + 2;
                } else {
                    return 1;
                }
            }
        } else {
            if ([company.expanded isEqualToNumber:@YES]){
                return company.projectUsers.count + 2;
            } else {
                return 1;
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    User *user;
    if (searching){
        if (indexPath.section == 0){
            static NSString *CellIdentifier = @"ReportCell";
            BHChoosePersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChoosePersonnelCell" owner:self options:nil] lastObject];
            }
            
            [cell.connectNameLabel setText:@""];
            [cell.connectDetailLabel setText:@""];
            [cell.hoursLabel setText:@""];
            [cell.nameLabel setText:@""];
            [cell.nameLabel setTextColor:[UIColor blackColor]];
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
            [cell.connectNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
            [cell.connectDetailLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
            if (_companyMode){
                Company *company;
                if (filteredSubcontractors.count){
                    company = filteredSubcontractors[indexPath.row];
                    [cell.nameLabel setText:company.name];
                    if (_report){
                        [_report.reportSubs enumerateObjectsUsingBlock:^(ReportSub *reportSub, NSUInteger idx, BOOL *stop) {
                            if ([company.identifier isEqualToNumber:reportSub.companyId]){
                                [cell.connectNameLabel setText:company.name];
                                [cell.connectNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProSemibold] size:0]];
                                [cell.connectDetailLabel setText:[NSString stringWithFormat:@"%@ personnel on-site",reportSub.count]];
                                [cell.connectNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
                                [cell.nameLabel setText:@""];
                                *stop = YES;
                            }
                        }];
                    }
                    
                    [cell.nameLabel setNumberOfLines:0];
                    [cell.nameLabel setTextColor:[UIColor blackColor]];
                }
            
                return cell;
            } else {
                
                if (filteredUsers.count){
                    user = filteredUsers[indexPath.row];
                    [cell.connectNameLabel setText:user.fullname];
                    [cell.connectNameLabel setTextColor:[UIColor blackColor]];
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
                    [cell.connectDetailLabel setTextColor:[UIColor lightGrayColor]];
                }
                //clear out the plain old boring name label
                [cell.nameLabel setText:@""];
                [cell.hoursLabel setText:@""];
                
                return cell;
            }
        } else {
            BHChoosePersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReportCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChoosePersonnelCell" owner:self options:nil] lastObject];
            }
            [cell.connectNameLabel setText:@""];
            [cell.connectDetailLabel setText:@""];
            if (searchText && searchText.length){
                [cell.nameLabel setText:[NSString stringWithFormat:@"Add \"%@\"",searchText]];
            } else {
                [cell.nameLabel setText:@"Add \"\""];
            }
            
            [cell.nameLabel setTextColor:[UIColor lightGrayColor]];
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
            return cell;
        }
    } else {
        //not searching
        static NSString *CellIdentifier = @"ReportCell";
        BHChoosePersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChoosePersonnelCell" owner:self options:nil] lastObject];
        }
        CGRect cellFrame = cell.frame;
        cellFrame.origin.x -= 1;
        cellFrame.size.width += 2;
        UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        cell.backgroundView = backgroundView;
        
        Company *company;
        if (_companyMode){
            company = companySet[indexPath.row];
        } else {
            company = companySet[indexPath.section];
        }
        
        //clear out the labels
        [cell.hoursLabel setText:@""];
        [cell.connectNameLabel setText:@""];
        [cell.connectDetailLabel setText:@""];
        [cell.nameLabel setText:@""];
        
        if (_companyMode){
            [cell.nameLabel setText:company.name];
            [_report.reportSubs enumerateObjectsUsingBlock:^(ReportSub *reportSub, NSUInteger idx, BOOL *stop) {
                if ([company.identifier isEqualToNumber:reportSub.companyId]){
                    [cell.connectNameLabel setText:company.name];
                    [cell.connectNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProRegular] size:0]];
                    [cell.connectDetailLabel setText:[NSString stringWithFormat:@"%@ personnel on-site",reportSub.count]];
                    [cell.connectDetailLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
                    [cell.nameLabel setText:@""];
                    *stop = YES;
                }
            }];
            
            [cell.nameLabel setNumberOfLines:0];
            [cell.nameLabel setTextColor:[UIColor blackColor]];
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
            
        } else if (indexPath.row == 0){
            cell.backgroundColor = [UIColor whiteColor];
            [cell.connectNameLabel setText:@""];
            [cell.connectDetailLabel setText:@""];
            [cell.nameLabel setText:company.name];
            [cell.nameLabel setNumberOfLines:0];
            [cell.nameLabel setTextColor:[UIColor blackColor]];
            [cell.nameLabel setTextAlignment:NSTextAlignmentLeft];
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProRegular] size:0]];
        } else if (indexPath.row == company.projectUsers.count + 1){
            [cell.connectNameLabel setText:@""];
            [cell.connectDetailLabel setText:@""];
            [cell.hoursLabel setText:@""];
            [cell.nameLabel setText:[NSString stringWithFormat:@"\u2794 Add a contact to \"%@\"",company.name]];
            [cell.nameLabel setNumberOfLines:0];
            [cell.nameLabel setTextAlignment:NSTextAlignmentCenter];
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProIt] size:0]];
            [cell.nameLabel setTextColor:[UIColor whiteColor]];
            cell.backgroundColor = kBlueColor;
            //add a border
            cell.layer.borderWidth = .5f;
            cell.layer.borderColor = [UIColor colorWithWhite:1 alpha:.2].CGColor;
        } else {
            //add a border
            cell.layer.borderWidth = .5f;
            cell.layer.borderColor = [UIColor colorWithWhite:1 alpha:.2].CGColor;
            
            //this could be a user, or it could be a connect user
            user = company.projectUsers[indexPath.row-1];
            [cell.connectNameLabel setText:user.fullname];
            [cell.connectNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
            [cell.connectNameLabel setTextColor:[UIColor whiteColor]];
            [cell.connectDetailLabel setTextColor:[UIColor whiteColor]];
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
            [cell.connectDetailLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
            [cell.hoursLabel setTextColor:[UIColor whiteColor]];
            cell.backgroundColor = kLightBlueColor;
            if (user.company.name.length){
                NSAttributedString *companyString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"   (%@)",user.company.name] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
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
                        if ([reportUser.hours isEqualToNumber:[NSNumber numberWithFloat:1.f]]){
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
        
        //set up the checkmark
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (_task){
            [_task.assignees enumerateObjectsUsingBlock:^(User *assignee, NSUInteger idx, BOOL *stop) {
                if ([user.identifier isEqualToNumber:assignee.identifier]){
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    [cell setTintColor:[UIColor whiteColor]];
                    *stop = YES;
                }
            }];
        }
        return cell;
    }
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
        } else if ([sender isKindOfClass:[User class]]){
            User *user = (User*)sender;
            [vc.emailTextField setText:user.email];
            [vc.phoneTextField setText:user.phone];
        }
    }
}

- (void)performSearch{
    [ProgressHUD show:@"Searching..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (searchText.length){
        [parameters setObject:searchText forKey:@"search"];
    }
    [manager GET:[NSString stringWithFormat:@"%@/companies/search",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success searching for companies: %@",responseObject);
        if ([(NSArray*)[responseObject objectForKey:@"companies"] count]){
            [self searchCompany:[responseObject objectForKey:@"companies"]];
        } else {
            [self addCompany];
        }
        [ProgressHUD dismiss];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        NSLog(@"Failed to get company: %@",error.description);
    }];
}

- (void)searchCompany:(NSArray*)array {
    BHCompaniesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Companies"];
    [vc setTitle:@"Did you mean?"];
    [vc setSearchTerm:searchText];
    [vc setSearchResults:array];
    [vc setProject:_project];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)addCompany {
    [ProgressHUD show:@"Creating company..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (searchText.length){
        [parameters setObject:searchText forKey:@"name"];
    }
    [parameters setObject:_project.identifier forKey:@"project_id"];
    [manager POST:[NSString stringWithFormat:@"%@/companies/add",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success adding a company to project companies: %@",responseObject);
        
        Company *company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [company populateFromDictionary:[responseObject objectForKey:@"company"]];
        [_project addCompany:company];
        [companySet insertObject:company atIndex:0];
        [self endSearch];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Something went wrong while trying to add this company. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to add company to project companies: %@",error.description);
    }];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    BHSearchModalTransition *animator = [BHSearchModalTransition new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    BHSearchModalTransition *animator = [BHSearchModalTransition new];
    return animator;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searching){
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searching){
        if (indexPath.section == 1){
            if (_companyMode){
                [self performSearch];
            } else {
                [self performSegueWithIdentifier:@"AddPersonnel" sender:nil];
            }
        } else {
            if (_companyMode){
                if (indexPath.row == filteredSubcontractors.count){
                    [self performSearch];
                } else {
                    selectedCompany = filteredSubcontractors[indexPath.row];
                    [self selectCompany];
                }
            } else {
                selectedUser = filteredUsers[indexPath.row];
                NSLog(@"selectedUser: %@",selectedUser);
                
                if (indexPath.row == filteredUsers.count){
                    
                   [self performSegueWithIdentifier:@"AddPersonnel" sender:nil];

                } else if (self.phone) {
                    
                    if (selectedUser.phone.length) {
                        [self.navigationController popViewControllerAnimated:YES];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlaceCall" object:nil userInfo:@{@"number":selectedUser.phone}];
                    } else {
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user does not have a phone number on file." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    }
                } else if (self.text) {
                    if (selectedUser.phone.length) {
                        [self.navigationController popViewControllerAnimated:YES];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"SendText" object:nil userInfo:@{@"number":selectedUser.phone}];
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
                } else  {
                    
                    if (selectedUser && _task){
                        if ([selectedUser isKindOfClass:[User class]]){
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"AssignTask" object:nil userInfo:@{@"user":selectedUser}];
                        }
                        [self.navigationController popViewControllerAnimated:YES];
                    } else {
                        [self selectUser];
                    }
                }
            }
        }
        
    } else if (_task){
        selectedCompany = companySet[indexPath.section];
        if (indexPath.row == 0){
            if ([selectedCompany.expanded isEqualToNumber:@YES]){
                [selectedCompany setExpanded:@NO];
            } else {
                [selectedCompany setExpanded:@YES];
            }
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else if (indexPath.row == selectedCompany.projectUsers.count+1){
            [self performSegueWithIdentifier:@"AddPersonnel" sender:selectedCompany];
        } else {
            selectedUser = [selectedCompany.projectUsers objectAtIndex:indexPath.row-1];
            if (selectedUser){
                __block BOOL remove = NO;
                [_task.assignees enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
                    if ([user.identifier isEqualToNumber:selectedUser.identifier]){
                        remove = YES;
                        *stop = YES;
                    }
                }];
                remove ? [_task removeAssignee:selectedUser] : [_task addAssignee:selectedUser];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
        
    } else if (_report) {
        if (_companyMode){
            //selecting a company
            selectedCompany = companySet[indexPath.row];
            [self selectCompany];

        } else {
            //not in company mode, but this tableview still focuses on companies with a tap to expand to see individual users
            selectedCompany = companySet[indexPath.section];
            if (indexPath.row == 0){
                if ([selectedCompany.expanded isEqualToNumber:@YES]){
                    [selectedCompany setExpanded:@NO];
                } else {
                    [selectedCompany setExpanded:@YES];
                }
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            } else if (indexPath.row == selectedCompany.projectUsers.count+1){
                //"add a contact" row for this company
                [self performSegueWithIdentifier:@"AddPersonnel" sender:selectedCompany];
            } else {
                selectedUser = [selectedCompany.projectUsers objectAtIndex:indexPath.row-1];
                [self selectUser];
            }
        }
        
    } else {
        selectedCompany = companySet[indexPath.section];
        if (indexPath.row == 0){

            if ([selectedCompany.expanded isEqualToNumber:@YES]){
                [selectedCompany setExpanded:@NO];
            } else {
                [selectedCompany setExpanded:@YES];
            }
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            //this is the "add a contact" row for each company
            if (indexPath.row == selectedCompany.projectUsers.count+1){
                [self performSegueWithIdentifier:@"AddPersonnel" sender:selectedCompany];
            } else {
                selectedUser = selectedCompany.projectUsers[indexPath.row-1];
                id precedingVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
                if (self.phone) {
                    if (selectedUser.phone.length) {
                        [self.navigationController popViewControllerAnimated:YES];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlaceCall" object:nil userInfo:@{@"number":selectedUser.phone}];
                    } else {
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user does not have a phone number on file." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    }
                } else if (self.text) {
                    if (selectedUser.phone.length) {
                        [self.navigationController popViewControllerAnimated:YES];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"SendText" object:nil userInfo:@{@"number":selectedUser.phone}];
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
                        //NSLog(@"selected user: %@",selectedUser);
                        if ([selectedUser isKindOfClass:[User class]]){
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"AssignTask" object:nil userInfo:@{@"user":selectedUser}];
                        }
                    }
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)selectCompany{
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
        companyAlertView = [[UIAlertView alloc] initWithTitle:@"# of personnel on-site" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
        companyAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[companyAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
        [companyAlertView show];
    } else {
        [self.tableView reloadData];
    }
}

- (void)selectUser {
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
        if (userAlertView == nil){
            userAlertView = [[UIAlertView alloc] initWithTitle:@"# of Hours Worked" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
        }
        
        //resign all other first responders, otherwise the keyboard may not come up properly because something else is mysteriously the first responder
        [self.view endEditing:YES];
        
        userAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[userAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
        [userAlertView show];
    } else {
        [self.tableView reloadData];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == userAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            [self endSearch];
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *hours = [f numberFromString:[[userAlertView textFieldAtIndex:0] text]];
            if (hours.floatValue > 0.f){
                [self selectReportUserWithCount:hours];
            }
        }
    } else if (alertView == companyAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            [self endSearch];
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *count = [f numberFromString:[[companyAlertView textFieldAtIndex:0] text]];
            if (count.intValue > 0){
                [self selectReportCompany:nil andCount:count];
            }
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
}

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)willShowKeyboard:(NSNotification*)notification {
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.email = NO;
    self.phone = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self doneEditing];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    if (_companyMode){
        if (text.length) [filteredSubcontractors removeAllObjects];
        for (Company *company in companySet){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if([predicate evaluateWithObject:company.name]) {
                [filteredSubcontractors addObject:company];
            }
        }
    } else {
        if (text.length) [filteredUsers removeAllObjects];
        for (User *user in _project.users){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if([predicate evaluateWithObject:user.fullname]) {
                [filteredUsers addObject:user];
            } else if ([predicate evaluateWithObject:user.company.name]){
                [filteredUsers addObject:user];
            } else if ([predicate evaluateWithObject:user.email]){
                [filteredUsers addObject:user];
            }
        }
    }
    [self.tableView reloadData];
}

@end
