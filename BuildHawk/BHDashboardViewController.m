//
//  BHDashboardViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHDashboardViewController.h"
#import "BHDashboardProjectCell.h"
#import "BHDashboardGroupCell.h"
#import "BHProjectSynopsisViewController.h"
#import "BHTabBarViewController.h"
#import "Checklist+helper.h"
#import "Company+helper.h"
#import "Project+helper.h"
#import "Tasklist+helper.h"
#import "Address.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"
#import "BHGroupViewController.h"
#import "BHHiddenProjectsViewController.h"
#import "BHOverlayView.h"
#import "BHTasksViewController.h"
#import "BHTasklistConnectCell.h"
#import "BHDemoProjectsViewController.h"
#import "BHSafetyTopicTransition.h"
#import "BHWebViewController.h"
#import "BHDashboardButtonCell.h"

@interface BHDashboardViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIAlertViewDelegate, UIViewControllerTransitioningDelegate> {
    CGRect searchContainerRect;
    BOOL iPhone5;
    BOOL loading;
    BOOL searching;
    NSMutableArray *filteredProjects;
    AFHTTPRequestOperationManager *manager;
    BHAppDelegate *delegate;
    User *_currentUser;
    NSMutableArray *recentChecklistItems;
    NSMutableArray *recentlyCompletedTasks;
    NSMutableArray *upcomingChecklistItems;
    
    CGRect screen;
    Project *hiddenProject;
    UIBarButtonItem *refreshButton;
    UIView *overlayBackground;
    UIImageView *dashboardScreenshot;
    NSManagedObjectContext *defaultContext;
    
    NSMutableOrderedSet *connectItems;
    NSMutableOrderedSet *connectProjects;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftMenuButton;

@end

@implementation BHDashboardViewController
@synthesize projects = _projects;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    //only ask for push notifications when a user has successfully logged in
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
    
    [self.view setBackgroundColor:kDarkerGrayColor];
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    
    if (delegate.currentUser){
        _currentUser = delegate.currentUser;
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    loading = YES;
    self.leftMenuButton.imageInsets = UIEdgeInsetsMake(0, -8, 0, 0);
    self.tableView.rowHeight = 88;
    
    screen = [UIScreen mainScreen].bounds;
    filteredProjects = [NSMutableArray array];

    if (IDIOM == IPAD){
        
    } else {
        if (screen.size.height == 568) iPhone5 = YES;
        else iPhone5 = NO;
    }
    
    NSDate *now = [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    self.navigationItem.title = [dateFormatter stringFromDate:now];

    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView setContentOffset:CGPointMake(0, 44)];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    if (_currentUser.projects.count == 0){
        [ProgressHUD show:@"Fetching projects..."];
    }
    [self loadProjects];

    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(handleRefresh)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    //reset the search bar font
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
            break;
        }
    }
    
    [self.searchBar setPlaceholder:@"Search for projects..."];
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    [self registerForKeyboardNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [self loadConnectItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenDashboard]){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlayUnderNav:NO];
        [self slide1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenDashboard];
    }
}

- (IBAction)revealMenu {
    [self.sideMenuViewController presentLeftMenuViewController];
    if ([self.sideMenuViewController.leftMenuViewController isKindOfClass:[BHMenuViewController class]]){
        [(BHMenuViewController*)self.sideMenuViewController.leftMenuViewController loadNotifications];
    }
}

- (void)handleRefresh {
    [ProgressHUD show:@"Refreshing..."];
    [self loadProjects];
    [self loadConnectItems];
}

- (void)loadProjects {
    [manager GET:[NSString stringWithFormat:@"%@/projects",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"load projects response object: %@",responseObject);
        [self updateProjects:[responseObject objectForKey:@"projects"]];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error while loading projects: %@",error.description);
        loading = NO;
        //[[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your projects. Please try again soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        [ProgressHUD dismiss];
    }];
}

- (void)updateProjects:(NSArray*)projectsArray {
    if (projectsArray.count == 0){
        loading = NO;
        [self.tableView reloadData];
        [ProgressHUD dismiss];
    } else {
        NSMutableOrderedSet *projectSet = [NSMutableOrderedSet orderedSet];
        NSMutableOrderedSet *groupSet = [NSMutableOrderedSet orderedSet];
        NSMutableOrderedSet *hiddenSet = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *projectDict in projectsArray) {
            Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:(NSNumber*)[projectDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (project){
                [project updateFromDictionary:projectDict];
            } else {
                project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [project populateFromDictionary:projectDict];
            if ([project.active isEqualToNumber:@NO]) [hiddenSet addObject:project];
            else if (project.group)[groupSet addObject:project];
            else [projectSet addObject:project];
        }
    
        for (Project *p in _currentUser.projects){
            if (![projectSet containsObject:p] && ![hiddenSet containsObject:p] && ![groupSet containsObject:p]){
                NSLog(@"Deleting a project that no longer exists: %@",p.name);
                [p MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        
        _currentUser.projects = projectSet;
        _currentUser.hiddenProjects = hiddenSet;
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            //NSLog(@"What happened during dashboard save? %u",success);
            loading = NO;
            if (self.isViewLoaded && self.view.window){
                
                _projects = [_currentUser.projects.array sortedArrayUsingComparator:^NSComparisonResult(Project *a, Project *b) {
                    NSNumber *first = a.orderIndex;
                    NSNumber *second = b.orderIndex;
                    return [first compare:second];
                }].mutableCopy;
                //_projects = [NSMutableArray arrayWithArray:_currentUser.projects.array];
                [self.tableView reloadData];
                [ProgressHUD dismiss];
            }
        }];
    }
}

- (void)loadConnectItems {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"%@/connect",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success loading connect items: %@",responseObject);
            if (!connectItems){
                connectItems = [NSMutableOrderedSet orderedSet];
            } else {
                [connectItems removeAllObjects];
            }
            if (!connectProjects){
                connectProjects = [NSMutableOrderedSet orderedSet];
            } else {
                [connectProjects removeAllObjects];
            }
            
            for (id taskDict in [responseObject objectForKey:@"tasks"]){
                //NSLog(@"task dict: %@",taskDict);
                Task *task = [Task MR_findFirstByAttribute:@"identifier" withValue:[taskDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!task) {
                    task = [Task MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [task populateFromDictionary:taskDict];
                [connectItems addObject:task];
                if (task.project){
                    [connectProjects addObject:task.project];
                }
            }
            
            [connectItems enumerateObjectsUsingBlock:^(Task *item, NSUInteger idx, BOOL *stop) {
                for (Project *project in connectProjects){
                    if ([project.identifier isEqualToNumber:item.project.identifier]){
                        if (!project.userConnectItems) project.userConnectItems = [NSMutableOrderedSet orderedSet];
                        [project.userConnectItems addObject:item];
                    }
                }
            }];
            
            if (connectProjects.count){
                [self.tableView reloadData];
                /*if ([self.tableView numberOfRowsInSection:2]){
                    [self.tableView beginUpdates];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                    [self.tableView reloadData];
                } else {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:2];
                    [self.tableView beginUpdates];
                    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                }*/
            }
            [self loadGroups];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            loading = NO;
            NSLog(@"Failure loading connect items: %@",error.description);
        }];
    }
}

- (void)loadGroups {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/groups",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"load groups response object: %@",responseObject);
        if ([responseObject objectForKey:@"groups"]){
            NSMutableOrderedSet *groups = [NSMutableOrderedSet orderedSet];
            for (NSDictionary *groupDict in [responseObject objectForKey:@"groups"]) {
                Group *group = [Group MR_findFirstByAttribute:@"identifier" withValue:[groupDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (group){
                    [group updateWithDictionary:groupDict];
                } else {
                    group = [Group MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [group populateWithDictionary:groupDict];
                }
                
                [groups addObject:group];
            }
            for (Group *group in _currentUser.company.groups) {
                if (![groups containsObject:group]) {
                    NSLog(@"Deleting a group that no longer exists: %@",group.name);
                    [group MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                }
            }
            _currentUser.company.groups = groups;
        } else {
            _currentUser.company.groups = nil;
        }
        
        loading = NO;
        //reloading the entire tableView here. No fancy section- or row-specific animations.
        [self.tableView reloadData];
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        loading = NO;
        NSLog(@"Error while loading groups: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your project groups. Please try again soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        
    }];
}

- (void)hideProjects:(NSArray*)projectsArray {
    NSMutableOrderedSet *projectSet = [NSMutableOrderedSet orderedSet];
    for (id obj in projectsArray) {
        //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [obj objectForKey:@"id"]];
        Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:(NSNumber*)[obj objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [project populateFromDictionary:obj];
        NSLog(@"hidden project: %@",project.name);
        [projectSet addObject:project];
    }

    /*for (Project *p in _currentUser.company.hiddenProjects){
        if (![projectSet containsObject:p] && ![currentUser.projects containsObject:p]){
            NSLog(@"deleting hidden project %@ because it no longer exists",p.name);
            [p MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }*/
    _currentUser.company.hiddenProjects = projectSet;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (searching) {
        return 1;
    } else {
        return 5;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (searching) {
        return filteredProjects.count;
    } else if (section == 0){
        if (_projects.count == 0 && !loading){
            return 1;
        } else {
            return _projects.count;
        }
    } else if (section == 1) {
        return _currentUser.company.groups.count;
    } else if (section == 2) {
        return connectProjects.count;
    } else if (section == 3 && !loading) {
        return 1;
    } else if (section == 4 && !loading) {
        return 1;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        static NSString *CellIdentifier = @"ProjectCell";
        BHDashboardProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardProjectCell" owner:self options:nil] lastObject];
        }

        if (_projects.count == 0 && !loading){
            //cell.scrollView.scrollEnabled = NO;
            [cell.scrollView setUserInteractionEnabled:NO];
            [cell.projectButton setUserInteractionEnabled:NO];
            [cell.progressButton setHidden:YES];
            [cell.textLabel setText:@"No live projects. Please Log on to BuildHawk.com to add one."];
            [cell.textLabel setFont:[UIFont fontWithName:kMyriadProLight size:19]];
            [cell.textLabel setNumberOfLines:0];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        } else {
            Project *project;
            if (searching && filteredProjects.count){
                project = [filteredProjects objectAtIndex:indexPath.row];
            } else {
                project = [_projects objectAtIndex:indexPath.row];
            }
            [cell configureForProject:project andUser:_currentUser];
            [cell.textLabel setText:@""];
            [cell.progressButton setTitle:project.progressPercentage forState:UIControlStateNormal];
            [cell.progressButton setTag:indexPath.row];
            [cell.progressButton addTarget:self action:@selector(goToProjectDetail:) forControlEvents:UIControlEventTouchUpInside];
            
            [cell.projectButton setTag:indexPath.row];
            [cell.projectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
            
            [cell.nameLabel setTextColor:kDarkGrayColor];
            if ([_currentUser.admin isEqualToNumber:@YES] || [_currentUser.companyAdmin isEqualToNumber:@YES] || [_currentUser.uberAdmin isEqualToNumber:@YES]){
                [cell.hideButton setTag:indexPath.row];
                [cell.hideButton addTarget:self action:@selector(confirmHide:) forControlEvents:UIControlEventTouchUpInside];
                cell.scrollView.scrollEnabled = YES;
            } else {
                cell.scrollView.scrollEnabled = YES;
            }
        }
        return cell;
    } else if (indexPath.section == 1) {
        static NSString *CellIdentifier = @"GroupCell";
        BHDashboardGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardGroupCell" owner:self options:nil] lastObject];
        }
        Group *group = [_currentUser.company.groups objectAtIndex:indexPath.row];
        [cell.nameLabel setText:group.name];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        [cell.groupCountLabel setHidden:NO];
        [cell.groupCountLabel setText:[NSString stringWithFormat:@"Projects: %@",group.projectsCount]];
        
        [cell.nameLabel setTextAlignment:NSTextAlignmentLeft];
        [cell.nameLabel setTextColor:kDarkGrayColor];
        return cell;
    } else if (indexPath.section == 2) {
        static NSString *CellIdentifier = @"ConnectCell";
        BHTasklistConnectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHTasklistConnectCell" owner:self options:nil] lastObject];
        }
        
        if (connectProjects.count > indexPath.row){
            Project *project = [connectProjects objectAtIndex:indexPath.row];
            [cell.companyNameLabel setText:project.name];
            
            __block int activeCount = 0;
            [project.userConnectItems enumerateObjectsUsingBlock:^(Task *item, NSUInteger idx, BOOL *stop) {
                if ([item.completed isEqualToNumber:@NO]){
                    activeCount ++;
                }
            }];
            
            if (activeCount == 1){
                [cell.projectsLabel setText:[NSString stringWithFormat:@"%@  \u2022  1 item",project.company.name]];
            } else {
                [cell.projectsLabel setText:[NSString stringWithFormat:@"%@  \u2022  %d items",project.company.name,activeCount]];
            }
        }
    
        return cell;
    } else if (indexPath.section == 3) {
        
        BHDashboardButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
        [cell.button removeTarget:nil
                           action:NULL
                 forControlEvents:UIControlEventAllEvents];
        
        [cell.button.titleLabel setFont:[UIFont fontWithName:kMyriadProLight size:18]];
        [cell.button setTitle:@"VIEW DEMO PROJECT(S)" forState:UIControlStateNormal];
        [cell.button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [cell.button setFrame:CGRectMake(screenWidth()/2-150, cell.frame.size.height/2-35, 300, 70)];
        [cell.button addTarget:self action:@selector(showDemoProjects) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    } else {
        
        BHDashboardButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell.button removeTarget:nil
                           action:NULL
                 forControlEvents:UIControlEventAllEvents];
        
        [cell.button.titleLabel setFont:[UIFont fontWithName:kMyriadProLight size:18]];
        [cell.button setTitle:@"HIDDEN PROJECTS" forState:UIControlStateNormal];
        [cell.button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [cell.button setFrame:CGRectMake(screenWidth()/2-150, cell.frame.size.height/2-35, 300, 70)];
        [cell.button addTarget:self action:@selector(showHiddenProjects) forControlEvents:UIControlEventTouchUpInside];
    
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1 && _currentUser.company.groups.count == 0) return 0;
    else if (section == 2 && connectProjects.count == 0) return 0;
    else if (section == 3 || section == 4) return 0;
    else return 40;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 40)];
    [headerView setBackgroundColor:kDarkerGrayColor];

    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, screenWidth()-7, 40)];
    headerLabel.backgroundColor = [UIColor clearColor];
    [headerLabel setFont:[UIFont fontWithName:kMyriadProRegular size:18]];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.numberOfLines = 0;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    switch (section) {
        case 0:
            if (_currentUser.company.name.length){
                [headerLabel setText:[NSString stringWithFormat:@"%@ Projects",_currentUser.company.name]];
            } else {
                [headerLabel setText:@"Projects"];
            }
            break;
        case 1:
            if (_currentUser.company.groups.count){
                [headerLabel setText:[NSString stringWithFormat:@"%@ Project Groups",_currentUser.company.name]];
            } else {
                return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            }
            break;
        case 2:
            //if (connectProjects.count){
                [headerLabel setText:@"BuildHawk Connect"];
            /*} else {
                return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            }*/
            break;
        default:
            return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            break;
    }
    [headerView addSubview:headerLabel];
    return headerView;
}
    
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        //[ProgressHUD dismiss];
    }
}

- (void)confirmHide:(UIButton*)button{
    [[[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Once hidden, a project will no longer be visible on your dashboard." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Hide", nil] show];
    hiddenProject = [_projects objectAtIndex:button.tag];
    BHDashboardProjectCell *cell = (BHDashboardProjectCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:button.tag inSection:0]];
    [cell.scrollView setContentOffset:CGPointZero animated:YES];
}

- (void)hideProject{
    [manager POST:[NSString stringWithFormat:@"%@/projects/%@/archive",kApiBaseUrl,hiddenProject.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully hid the project: %@",responseObject);

        NSIndexPath *indexPathToHide = [NSIndexPath indexPathForRow:[_projects indexOfObject:hiddenProject] inSection:0];
        [_projects removeObject:hiddenProject];
        [_currentUser hideProject:hiddenProject];
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfAndWait];
        
        loading = NO;
        [self.tableView beginUpdates];
        if ([self.tableView cellForRowAtIndexPath:indexPathToHide] != nil){
            [self.tableView deleteRowsAtIndexPaths:@[indexPathToHide] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to hide this project. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to hide project: %@",error.description);
    }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Hide"]){
        [self hideProject];
    }
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searching = YES;
    [self.searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self doneEditing];
    [self.tableView reloadData];
}

- (void)doneEditing {
    searching = NO;
    [self.view endEditing:YES];
    [self.searchBar setShowsCancelButton:NO animated:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searching && filteredProjects.count){
        Project *selectedProject = [filteredProjects objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ProjectSynopsis" sender:selectedProject];
    } else if (indexPath.section == 0) {
        if (_projects.count){
            Project *selectedProject = [_projects objectAtIndex:indexPath.row];
            [self performSegueWithIdentifier:@"ProjectSynopsis" sender:selectedProject];
        } else {
            NSURL *projectsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/projects",kBaseUrl]];
            BHWebViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"WebView"];
            [vc setUrl:projectsUrl];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:NULL];
        }
    } else if (indexPath.section == 1) {
        Group *group = [_currentUser.company.groups objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"Group" sender:group];
    } else if (indexPath.section == 2) {
        [self performSegueWithIdentifier:@"TasklistConnect" sender:indexPath];
    } else if (indexPath.section == 3) {
        // Demo row selected
    } else {
        // Hide selected
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    BHSafetyTopicTransition *animator = [BHSafetyTopicTransition new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    BHSafetyTopicTransition *animator = [BHSafetyTopicTransition new];
    return animator;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Project"]) {
        Project *project = (Project*)sender;
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
    } else if ([segue.identifier isEqualToString:@"ProjectSynopsis"]) {
        Project *project = (Project*)sender;
        BHProjectSynopsisViewController *vc = [segue destinationViewController];
        [vc setProject:project];
    } else if ([segue.identifier isEqualToString:@"Group"]){
        Group *group = (Group *)sender;
        BHGroupViewController *vc = [segue destinationViewController];
        [vc setTitle:group.name];
        [vc setGroup:group];
    } else if ([segue.identifier isEqualToString:@"Demos"]){
        BHDemoProjectsViewController *vc = [segue destinationViewController];
        [vc setCurrentUser:_currentUser];
    } else if ([segue.identifier isEqualToString:@"Hidden"]){
        BHHiddenProjectsViewController *vc = [segue destinationViewController];
        [vc setTitle:@"Hidden Projects"];
    } else if ([segue.identifier isEqualToString:@"TasklistConnect"]){
        BHTasksViewController *vc = [segue destinationViewController];
        NSIndexPath *indexPath = (NSIndexPath*)sender;
        Project *project = [connectProjects objectAtIndex:indexPath.row];
        [vc setProject:project];
        [vc setConnectMode:YES];
    }
}

- (void)goToProject:(UIButton*)button {
    Project *selectedProject;
    if (searching && filteredProjects.count > button.tag){
        selectedProject = [filteredProjects objectAtIndex:button.tag];
    } else if (_projects.count > button.tag) {
        selectedProject = [_projects objectAtIndex:button.tag];
    }
    
    //make sure there's a project
    if (![selectedProject.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        [self performSegueWithIdentifier:@"Project" sender:selectedProject];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch this project. Please try again." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        [self handleRefresh];
    }
}

- (void)goToProjectDetail:(UIButton*)button {
    Project *selectedProject = [_projects objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"ProjectSynopsis" sender:selectedProject];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredProjects removeAllObjects]; // First clear the filtered array.
    for (Project *project in _projects){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:project.name]) {
            [filteredProjects addObject:project];
        }
    }
    [self.tableView reloadData];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString* newText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self filterContentForSearchText:newText scope:nil];
    return YES;
}

#pragma mark Intro Stuff
- (void)slide1 {
    BHOverlayView *welcomeLabel = [[BHOverlayView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), screenHeight())];
    UIImageView *welcomeImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"welcome"]];
    [welcomeLabel addSubview:welcomeImage];
    [welcomeImage setAlpha:0.0];
    [welcomeImage setFrame:CGRectMake(screenWidth()/2-150, screenHeight()/2-70, 300, 100)];
    [welcomeLabel configureText:@"(Tap anywhere to continue)" atFrame:CGRectMake(screenWidth()/2-150, screenHeight()-70, 300, 50)];
    [welcomeLabel.label setFont:[UIFont fontWithName:kMyriadProLight size:18]];
    welcomeLabel.label.layer.shadowColor = [UIColor blackColor].CGColor;
    [welcomeLabel.label setTextAlignment:NSTextAlignmentCenter];
    welcomeLabel.label.layer.shadowOffset = CGSizeMake(1, 1);
    welcomeLabel.label.layer.shadowRadius = .5f;
    welcomeLabel.label.layer.shadowOpacity    =   .5f;

    [welcomeLabel.tapGesture addTarget:self action:@selector(slide2:)];
    [overlayBackground addSubview:welcomeLabel];
    [UIView animateWithDuration:.25 animations:^{
        [welcomeLabel setAlpha:1.0];
        [welcomeImage setAlpha:1.0];
    }];
}

- (void)slide2:(UITapGestureRecognizer*)sender {
    BHOverlayView *dashboard = [[BHOverlayView alloc] initWithFrame:screen];
    if (IDIOM == IPAD){
        dashboardScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dashboardiPad"]];
        [dashboardScreenshot setFrame:CGRectMake(29, 30, 710, 700)];
    } else {
        dashboardScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dashboardScreenshot"]];
        [dashboardScreenshot setFrame:CGRectMake(20, 20, 280, 330)];
    }
    [dashboardScreenshot setAlpha:0.0];
    [overlayBackground addSubview:dashboardScreenshot];
    
    NSString *text =@"This is your project dashboard. All your active projects will be listed here.";
    if (IDIOM == IPAD){
        [dashboard configureText:text atFrame:CGRectMake(screenWidth()/4, dashboardScreenshot.frame.origin.y + dashboardScreenshot.frame.size.height + 10, screenWidth()/2, 100)];
    } else {
        [dashboard configureText:text atFrame:CGRectMake(20, dashboardScreenshot.frame.origin.y + dashboardScreenshot.frame.size.height + 10, screenWidth()-40, 100)];
    }
    
    [dashboard.tapGesture addTarget:self action:@selector(slide3:)];
    
    [UIView animateWithDuration:.25 animations:^{
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        [overlayBackground addSubview:dashboard];
        [UIView animateWithDuration:.25 animations:^{
            [dashboard setAlpha:1.0];
            [dashboardScreenshot setAlpha:1.0];
        }];
    }];
}

- (void)slide3:(UITapGestureRecognizer*)sender {
    BHOverlayView *dashboard = [[BHOverlayView alloc] initWithFrame:screen];
    NSString *text = @"\"View Demo Project\" will show you some examples of how you can use the app.";
    if (IDIOM == IPAD){
        [dashboard configureText:text atFrame:CGRectMake(screenWidth()/4, dashboardScreenshot.frame.origin.y + dashboardScreenshot.frame.size.height + 10, screenWidth()/2, 100)];
    } else {
        [dashboard configureText:text atFrame:CGRectMake(20, dashboardScreenshot.frame.origin.y + dashboardScreenshot.frame.size.height + 10, screenWidth()-40, 100)];
    }
    
    [dashboard.tapGesture addTarget:self action:@selector(slide4:)];
    
    [UIView animateWithDuration:.25 animations:^{
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        [overlayBackground addSubview:dashboard];
        [UIView animateWithDuration:.25 animations:^{
            [dashboard setAlpha:1.0];
            [dashboardScreenshot setAlpha:1.0];
        }];
    }];
}

- (void)slide4:(UITapGestureRecognizer*)sender {
    BHOverlayView *progress = [[BHOverlayView alloc] initWithFrame:screen];
    NSString *text = @"See detailed project overviews by tapping the % on the right side of each project.";
    if (IDIOM == IPAD){
        [progress configureText:text atFrame:CGRectMake(screenWidth()/4, dashboardScreenshot.frame.origin.y + dashboardScreenshot.frame.size.height + 10, screenWidth()/2, 100)];
    } else {
        [progress configureText:text atFrame:CGRectMake(20, dashboardScreenshot.frame.origin.y + dashboardScreenshot.frame.size.height + 10, screenWidth()-40, 100)];
    }
    
    [progress.tapGesture addTarget:self action:@selector(endIntro:)];
    
    [UIView animateWithDuration:.25 animations:^{
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        [overlayBackground addSubview:progress];
        [UIView animateWithDuration:.25 animations:^{
            [progress setAlpha:1.0];
        }];
    }];
}

- (void)endIntro:(UITapGestureRecognizer*)sender {
    [UIView animateWithDuration:.35 animations:^{
        [dashboardScreenshot setAlpha:0.0];
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:.35 animations:^{
            [overlayBackground setAlpha:0.0];
        }completion:^(BOOL finished) {
            [overlayBackground removeFromSuperview];
        }];
    }];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = keyboardValue.CGRectValue.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                     }
                     completion:nil];
}

- (void)showDemoProjects {
    //[self performSegueWithIdentifier:@"Demos" sender:nil];
    BHDemoProjectsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Demos"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.transitioningDelegate = self;
    [vc setTitle:@"Demo Projects"];
    [vc setCurrentUser:_currentUser];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)showHiddenProjects {
    BHHiddenProjectsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Hidden"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.transitioningDelegate = self;
    [vc setTitle:@"Hidden Projects"];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
}

@end
