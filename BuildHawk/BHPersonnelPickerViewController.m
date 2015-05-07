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
#import "Subcontractor+helper.h"
#import "ReportSub+helper.h"
#import "ReportUser+helper.h"
#import "Project+helper.h"
#import "BHChoosePersonnelCell.h"
#import "BHAddPersonnelViewController.h"
#import "BHSearchModalTransition.h"
#import "BHCompaniesViewController.h"

static NSString * const kAddPersonnelPlaceholder = @"    Add new personnel...";

// TO DO Rebuild this entire thing
@interface BHPersonnelPickerViewController () <UIAlertViewDelegate, UIViewControllerTransitioningDelegate, BHCompaniesDelegate> {
    AFHTTPRequestOperationManager *manager;
    BHAppDelegate *delegate;
    CGFloat width;
    CGFloat height;
    NSMutableArray *filteredUsers;
    NSMutableArray *filteredSubcontractors;
    UIAlertView *userAlertView;
    UIAlertView *companyAlertView;
    User *selectedUser;
    Company *selectedCompany;
    UIBarButtonItem *doneBarButtonItem;
    UIBarButtonItem *inviteBarButtonItem;
    NSArray *peopleArray;
    BOOL loading;
    BOOL searching;
    NSMutableOrderedSet *companySet;
    NSString *searchText;
    NSTimeInterval duration;
    UIViewAnimationOptions animationCurve;
    UIBarButtonItem *removeAllBarButton;
}
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) Task *task;
@property (strong, nonatomic) Report *report;
@property (strong, nonatomic) Company *company;
@end

@implementation BHPersonnelPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || SYSTEM_VERSION >= 8.f){
        width = screenWidth(); height = screenHeight();
    } else {
        width = screenHeight(); height = screenWidth();
    }
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.view setBackgroundColor:kDarkerGrayColor];
    self.tableView.rowHeight = 60;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    if (_companyMode){
        filteredSubcontractors = [NSMutableArray array];
    } else {
        filteredUsers = [NSMutableArray array];
    }
    
    self.company = [Company MR_findFirstByAttribute:@"identifier" withValue:_companyId inContext:[NSManagedObjectContext MR_defaultContext]];
    self.project = [Project MR_findFirstByAttribute:@"identifier" withValue:_projectId inContext:[NSManagedObjectContext MR_defaultContext]];
    if (_reportId) {
        self.report = [Report MR_findFirstByAttribute:@"identifier" withValue:_reportId inContext:[NSManagedObjectContext MR_defaultContext]];
    } else if (_taskId){
        self.task = [Task MR_findFirstByAttribute:@"identifier" withValue:_taskId inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    self.tableView.tableHeaderView = self.searchBar;
    
    inviteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(invite)];
    
    
    //set the search bar tint color so you can see the cursor
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setBackgroundColor:[UIColor clearColor]];
            [searchTextField setTextColor:[UIColor blackColor]];
            [searchTextField setTintColor:[UIColor blackColor]];
            [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kOpenSans] size:0]];
            [searchTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            break;
        }
    }
    
    self.searchBar.placeholder = _companyMode ? @"Search for companies..." : @"Search for personnel...";
    companySet = [NSMutableOrderedSet orderedSet];
    [self pinParentCompanyToTop];
    [self registerKeyboardNotifications];
    
    if (self.task && (self.task.assignees.count || self.task.assigneeName.length)) {
        removeAllBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Remove All" style:UIBarButtonItemStylePlain target:self action:@selector(removeAllAssignees)];
        self.navigationItem.rightBarButtonItems = @[inviteBarButtonItem,removeAllBarButton];
    } else {
        self.navigationItem.rightBarButtonItems = @[inviteBarButtonItem];
    }
    
    [self loadPersonnel];
}

- (void)pinParentCompanyToTop {
    for (Company *company in self.project.companies){
        [companySet addObject:company];
    }
    [companySet removeObject:self.project.company];
    [companySet insertObject:self.project.company atIndex:0];
    [self.project.company setExpanded:@YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self doneEditing];
    searching = NO;
    
}

- (void)loadPersonnel {
    if (delegate.connected){
        [ProgressHUD show:@"Fetching personnel..."];
        [manager GET:[NSString stringWithFormat:@"projects/%@/users",self.project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success loading project personnel: %@",responseObject);
            [self.project populateFromDictionary:responseObject];
            loading = NO;
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                [self processPersonnel];
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to load company information: %@",error.description);
            [ProgressHUD dismiss];
        }];
    } else {
        
    }
}

- (void)processPersonnel {
    if (companySet){
        [companySet removeAllObjects];
    }
    [self.project.companies enumerateObjectsUsingBlock:^(Company *company, NSUInteger idx, BOOL *stop) {
        [companySet addObject:company];
    }];
    
    [self pinParentCompanyToTop];
    
    [self.project.users enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
        if (!user.company.projectUsers){
            user.company.projectUsers = [NSMutableOrderedSet orderedSet];
        }
        [user.company.projectUsers addObject:user];
        
        if (user.company)
            [companySet addObject:user.company];
    }];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Dispose of any resources that can be recreated.
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
        [filteredUsers addObjectsFromArray:self.project.users.array];
    }
    if (shouldReload) [self.tableView reloadData];
    self.navigationItem.rightBarButtonItems = @[doneBarButtonItem];
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
    searching = NO;
    //have to manually resign the first responder here
    [self.searchBar resignFirstResponder];
    [self.view endEditing:YES];
    [self.searchBar setText:@""];
    [filteredSubcontractors removeAllObjects];
    [filteredUsers removeAllObjects];
    [self.tableView reloadData];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    searching = NO;
    [self.searchBar setText:@""];
    [self.tableView reloadData];
    self.navigationItem.rightBarButtonItems = removeAllBarButton ? @[inviteBarButtonItem, removeAllBarButton] : @[inviteBarButtonItem];
}

- (void)removeAll {
    if (_task) {
        if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(userRemoved:)]){
            [_task.assignees enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
                [self.personnelDelegate userRemoved:user];
            }];
        }
        
    } else if (_report){
        if (_companyMode){
            if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(reportSubRemoved:)]){
                NSLog(@"company mode remove all from report");
                [_report.reportSubs enumerateObjectsUsingBlock:^(ReportSub *reportSub, NSUInteger idx, BOOL *stop) {
                    [self.personnelDelegate reportSubRemoved:reportSub];
                }];
            }
        } else {
            if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(reportUserRemoved:)]){
                NSLog(@"report user mode remove all from report");
                [_report.reportUsers enumerateObjectsUsingBlock:^(ReportUser *reportUser, NSUInteger idx, BOOL *stop) {
                    [self.personnelDelegate reportUserRemoved:reportUser];
                }];
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
            [cell.connectNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
            [cell.connectDetailLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
            if (_companyMode){
                Company *company;
                if (filteredSubcontractors.count){
                    company = filteredSubcontractors[indexPath.row];
                    [cell.nameLabel setText:company.name];
                    if (_report){
                        [_report.reportSubs enumerateObjectsUsingBlock:^(ReportSub *reportSub, NSUInteger idx, BOOL *stop) {
                            if ([company.identifier isEqualToNumber:reportSub.companyId]){
                                [cell.connectNameLabel setText:company.name];
                                [cell.connectNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSansSemibold] size:0]];
                                [cell.connectDetailLabel setText:[NSString stringWithFormat:@"%@ personnel on-site",reportSub.count]];
                                [cell.connectNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
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
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
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

                if (reportSub.companyId && [company.identifier isEqualToNumber:reportSub.companyId]){
                    [cell.connectNameLabel setText:company.name];
                    [cell.connectNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
                    [cell.connectDetailLabel setText:[NSString stringWithFormat:@"%@ personnel on-site",reportSub.count]];
                    [cell.connectDetailLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
                    [cell.nameLabel setText:@""];
                    *stop = YES;
                }
            }];
            
            [cell.nameLabel setNumberOfLines:0];
            [cell.nameLabel setTextColor:[UIColor blackColor]];
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
            
        } else if (indexPath.row == 0){
            cell.backgroundColor = [UIColor whiteColor];
            [cell.connectNameLabel setText:@""];
            [cell.connectDetailLabel setText:@""];
            [cell.nameLabel setText:company.name];
            [cell.nameLabel setNumberOfLines:0];
            [cell.nameLabel setTextColor:[UIColor blackColor]];
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
        } else if (indexPath.row == company.projectUsers.count + 1){
            [cell.connectNameLabel setText:@""];
            [cell.connectDetailLabel setText:@""];
            [cell.hoursLabel setText:@""];
            [cell.nameLabel setText:[NSString stringWithFormat:@"\u2794 Add a contact to \"%@\"",company.name]];
            [cell.nameLabel setNumberOfLines:0];
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSansItalic] size:0]];
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
            [cell.connectNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
            [cell.connectNameLabel setTextColor:[UIColor whiteColor]];
            [cell.connectDetailLabel setTextColor:[UIColor whiteColor]];
            [cell.nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
            [cell.connectDetailLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
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

- (void)invite {
    [self addPersonnel:nil orCompany:nil];
}

- (void)addPersonnel:(User*)user orCompany:(Company*)company {
    BHAddPersonnelViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"AddPersonnel"];
    [vc setTask:self.task];
    [vc setReport:self.report];
    [vc setProject:self.project];
    if (company){
        [vc setTitle:[NSString stringWithFormat:@"Add to: %@",company.name]];
        [vc setCompany:company];
    } else if (user){
        [vc.emailTextField setText:user.email];
    }
    
    [self.navigationController pushViewController:vc animated:YES];
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
    vc.companiesDelegate = self;
    [vc setTitle:@"Did you mean?"];
    [vc setSearchTerm:searchText];
    [vc setSearchResults:array];
    [vc setProject:self.project];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)addedCompanyWithId:(NSNumber *)companyId {
    _companyMode = YES;
    Company *company = [Company MR_findFirstByAttribute:@"identifier" withValue:companyId inContext:[NSManagedObjectContext MR_defaultContext]];
        if (company && company.identifier){
            [companySet addObject:company];
        
        if (_report&& _report.identifier){
            ReportSub *reportSub = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            reportSub.companyId = company.identifier;
            reportSub.name = company.name;
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [_report addReportSubcontractor:reportSub];
            NSLog(@"new report sub: %@",reportSub);
        }
        [self endSearch];
        [self.tableView reloadData];
        [self selectCompany];
    }
}

- (void)addCompany {
    [ProgressHUD show:@"Creating company..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (searchText.length){
        [parameters setObject:searchText forKey:@"name"];
    }
    [parameters setObject:self.project.identifier forKey:@"project_id"];
    [manager POST:[NSString stringWithFormat:@"%@/companies/add",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success adding a company to project companies: %@",responseObject);
        Company *company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [company populateFromDictionary:[responseObject objectForKey:@"company"]];
        [self.project addCompany:company];
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [companySet insertObject:company atIndex:0];
            [self endSearch];
            [self.tableView reloadData];
        }];
        
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
                if (delegate.connected){
                    [self addPersonnel:nil orCompany:nil];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Offline" message:@"Sorry, but the ability to add new personnel is disabled while offline." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                }
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
                if (indexPath.row == filteredUsers.count){
                    if (delegate.connected){
                        [self addPersonnel:nil orCompany:nil];
                    } else {
                        [[[UIAlertView alloc] initWithTitle:@"Offline" message:@"Sorry, but the ability to add new personnel is disabled while offline." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    }
                } else if (self.text) {
                    if (selectedUser.phone.length) {
                        [self.navigationController popViewControllerAnimated:YES];
                        if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(sendText:)]){
                            [self.personnelDelegate sendText:selectedUser.phone];
                        }
                    } else {
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user does not have a phone number on file." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    }
                } else if (self.email) {
                    if (selectedUser.email.length) {
                        [self.navigationController popViewControllerAnimated:YES];
                        if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(sendEmail:)]){
                            [self.personnelDelegate sendEmail:selectedUser.email];
                        }
                    } else {
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user does not have an email address on file." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    }
                } else  {
                    if (selectedUser && _task){
                        if ([selectedUser isKindOfClass:[User class]]){
                            if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(userAdded:)]){
                                [self.personnelDelegate userAdded:selectedUser];
                            }
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
            if (delegate.connected){
                [self addPersonnel:nil orCompany:selectedCompany];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Offline" message:@"Sorry, but the ability to add new personnel is disabled while offline." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
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
                if (remove){
                    [_task removeAssignee:selectedUser];
                    if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(userRemoved:)]){
                        [self.personnelDelegate userRemoved:selectedUser];
                    }
                } else {
                    [_task addAssignee:selectedUser];
                    if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(userAdded:)]){
                        [self.personnelDelegate userAdded:selectedUser];
                    }
                }
            
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
                if (delegate.connected){
                    [self addPersonnel:nil orCompany:selectedCompany];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Offline" message:@"Sorry, but the ability to add new personnel is disabled while offline." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                }
            } else {
                selectedUser = [selectedCompany.projectUsers objectAtIndex:indexPath.row-1];
                [self selectUser];
            }
        }
        
    } else {
        selectedCompany = companySet[indexPath.section];
        if (indexPath.row == 0){
            [selectedCompany.expanded isEqualToNumber:@YES] ? [selectedCompany setExpanded:@NO] : [selectedCompany setExpanded:@YES];
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            //this is the "add a contact" row for each company
            if (indexPath.row == selectedCompany.projectUsers.count+1){
                if (delegate.connected){
                    [self addPersonnel:nil orCompany:selectedCompany];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Offline" message:@"Sorry, but the ability to add new personnel is disabled while offline." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                }
            } else {
                selectedUser = selectedCompany.projectUsers[indexPath.row-1];
                id precedingVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
                if (self.text) {
                    if (selectedUser.phone.length) {
                        [self.navigationController popViewControllerAnimated:YES];
                        if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(sendText:)]){
                            [self.personnelDelegate sendText:selectedUser.phone];
                        }
                    } else {
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user does not have a phone number on file." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    }
                } else if (self.email) {
                    if (selectedUser.email.length) {
                        [self.navigationController popViewControllerAnimated:YES];
                        if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(sendEmail:)]){
                            [self.personnelDelegate sendEmail:selectedUser.email];
                        }
                    } else {
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user does not have an email address on file." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    }
                } else if ([precedingVC isKindOfClass:[BHTaskViewController class]]){
                    if (selectedUser){
                        if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(userAdded:)]){
                            [self.personnelDelegate userAdded:selectedUser];
                        }
                    }
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)selectCompany {
    BOOL select = YES;
    for (ReportSub *reportSub in _report.reportSubs) {
        if (reportSub.companyId && [selectedCompany.identifier isEqualToNumber:reportSub.companyId]){
            [_report removeReportSubcontractor:reportSub];
            [reportSub MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(reportSubRemoved:)]){
                [self.personnelDelegate reportSubRemoved:reportSub];
            }
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
    __block BOOL select = YES;
    [_report.reportUsers enumerateObjectsUsingBlock:^(ReportUser *reportUser, NSUInteger idx, BOOL *stop) {
        if ([selectedUser.identifier isEqualToNumber:reportUser.userId]){
            [_report removeReportUser:reportUser];
            [reportUser MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(reportUserRemoved:)]){
                [self.personnelDelegate reportUserRemoved:reportUser];
            }
            select = NO;
            *stop = YES;
        }
    }];
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
    if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(reportUserAdded:)]){
        [self.personnelDelegate reportUserAdded:reportUser];
    }
    [self.tableView reloadData];
}

- (void)selectReportCompany:(NSIndexPath*)indexPath andCount:(NSNumber*)count {
    ReportSub *reportSub = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    reportSub.count = count;
    reportSub.name = selectedCompany.name;
    reportSub.companyId = selectedCompany.identifier;
    [_report addReportSubcontractor:reportSub];
    if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(reportSubAdded:)]){
        [self.personnelDelegate reportSubAdded:reportSub];
    }
    [self.tableView reloadData];
}

- (void)removeAllAssignees {
    if (self.personnelDelegate && [self.personnelDelegate respondsToSelector:@selector(removeAllTaskAssignees)]){
        [self.personnelDelegate removeAllTaskAssignees];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)willShowKeyboard:(NSNotification*)notification {
    if (notification) {
        NSDictionary* keyboardInfo = [notification userInfo];
        NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
        CGFloat keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
        duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
        [UIView animateWithDuration:duration
                              delay:0
                            options:(animationCurve << 16)
                         animations:^{
                             self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight + 27, 0);
                             self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight + 27, 0);
                         }
                         completion:^(BOOL finished) {
                             self.navigationItem.rightBarButtonItems = @[doneBarButtonItem];
                         }];
    }
}

- (void)willHideKeyboard:(NSNotification *)notification {
    if (notification) {
        duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
        [UIView animateWithDuration:duration
                              delay:0
                            options:(animationCurve << 16)
                         animations:^{
                             self.tableView.contentInset = UIEdgeInsetsZero;
                             self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
    [self endSearch];
    self.email = NO;
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
        for (User *user in self.project.users){
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
