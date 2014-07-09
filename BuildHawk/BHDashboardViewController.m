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
#import "User.h"
#import "Checklist+helper.h"
#import "Company+helper.h"
#import "Project+helper.h"
#import "Worklist+helper.h"
#import "Address.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"
#import "BHGroupViewController.h"
#import "BHArchivedViewController.h"
#import "BHOverlayView.h"
#import "BHTasksViewController.h"
#import "BHWorklistConnectCell.h"
#import "BHDemoProjectsViewController.h"

@interface BHDashboardViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIAlertViewDelegate> {
    CGRect searchContainerRect;
    BOOL iPhone5;
    BOOL loading;
    BOOL searching;
    NSMutableArray *filteredProjects;
    AFHTTPRequestOperationManager *manager;
    BHAppDelegate *delegate;
    User *currentUser;
    NSMutableArray *recentChecklistItems;
    NSMutableArray *recentlyCompletedWorklistItems;
    NSMutableArray *upcomingChecklistItems;
    
    CGRect screen;
    Project *archivedProject;
    UIBarButtonItem *archiveButtonItem;
    UIBarButtonItem *refreshButton;
    UIView *overlayBackground;
    UIImageView *dashboardScreenshot;
    NSManagedObjectContext *defaultContext;
    NSMutableOrderedSet *connectCompanies;
    NSMutableOrderedSet *connectProjects;
    NSMutableOrderedSet *groupSet;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftMenuButton;

@end

@implementation BHDashboardViewController

- (void)viewDidLoad {
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    [super viewDidLoad];
    [self.view setBackgroundColor:kDarkerGrayColor];
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = manager = [delegate manager];
    if (delegate.currentUser){
        currentUser = delegate.currentUser;
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
        currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    }
    loading = YES;
    self.leftMenuButton.imageInsets = UIEdgeInsetsMake(0, -8, 0, 0);
    self.tableView.rowHeight = 88;
    
    screen = [UIScreen mainScreen].bounds;
    filteredProjects = [NSMutableArray array];

    if (IDIOM == IPAD){
        if (screen.size.height == 568) iPhone5 = YES;
        else iPhone5 = NO;
    }
    
    NSDate *now = [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    self.navigationItem.title = [dateFormatter stringFromDate:now];

    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView setContentOffset:CGPointMake(0, 44)];
    
    if (currentUser.projects.count == 0){
        [ProgressHUD show:@"Fetching projects..."];
    } else {
        NSLog(@"User has projects already. Draw tableview, then update. Dismiss the logging in overlay.");
        [ProgressHUD dismiss];
        //[self.tableView reloadData];
    }
    [self loadProjects];

    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(handleRefresh)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    archiveButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Archived" style:UIBarButtonItemStylePlain target:self action:@selector(getArchived)];
    
    //set the search bar tint color so you can see the cursor
    /*for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setBackgroundColor:[UIColor clearColor]];
            [searchTextField setTextColor:[UIColor blackColor]];
            [searchTextField setTintColor:[UIColor blackColor]];
            break;
        }
    }*/
    [self.searchBar setPlaceholder:@"Search for projects..."];
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    connectProjects = [NSMutableOrderedSet orderedSet];
    currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
}

- (void)getArchived {
    [self performSegueWithIdentifier:@"Archived" sender:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenDashboard]){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlayUnderNav:NO];
        [self slide1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenDashboard];
    }
    [self loadConnectItems];
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
        self.tableView.allowsSelection = YES;
        [ProgressHUD dismiss];
    } else {
        NSMutableOrderedSet *projectSet = [NSMutableOrderedSet orderedSet];
        for (id obj in projectsArray) {
            Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:(NSNumber*)[obj objectForKey:@"id"]];
            if (!project){
                project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [project populateFromDictionary:obj];
            [projectSet addObject:project];
        }
        NSMutableOrderedSet *archivedSet = [NSMutableOrderedSet orderedSet];
        groupSet = [NSMutableOrderedSet orderedSet];
        for (Project *p in projectSet){
            if ([p.active isEqualToNumber:[NSNumber numberWithBool:NO]]){
                [projectSet removeObject:p];
                [archivedSet addObject:p];
            }
        }
        if (currentUser && self.isViewLoaded && self.view.window){
            if (archivedSet.count) currentUser.archivedProjects = archivedSet;
            currentUser.projects = projectSet;
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                NSLog(@"What happened during dashboard save? %hhd %@",success, error);
                loading = NO;
                [self.tableView reloadData];
                [ProgressHUD dismiss];
            }];
        }
    }
}

- (void)loadConnectItems {
    [manager GET:[NSString stringWithFormat:@"%@/users/%@/connect",kApiBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success loading connect items: %@",responseObject);
        for (id itemDict in [responseObject objectForKey:@"worklist_items"]){
            WorklistItem *item = [WorklistItem MR_findFirstByAttribute:@"identifier" withValue:[itemDict objectForKey:@"id"]];
            if (!item) {
                item = [WorklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [item populateFromDictionary:itemDict];
        }
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure loading connect items: %@",error.description);
    }];
}

- (void)loadGroups {
    [manager GET:[NSString stringWithFormat:@"%@/groups",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"load groups response object: %@",responseObject);
        if ([responseObject objectForKey:@"groups"]){
            NSMutableOrderedSet *groups = [NSMutableOrderedSet orderedSet];
            for (NSDictionary *groupDict in [responseObject objectForKey:@"groups"]) {
                Group *group = [Group MR_findFirstByAttribute:@"identifier" withValue:[groupDict objectForKey:@"id"]];
                if (!group){
                    group = [Group MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [group populateWithDict:groupDict];
                [groups addObject:group];
            }
            for (Group *group in currentUser.company.groups) {
                if (![groups containsObject:group]) {
                    NSLog(@"Deleting a group that no longer exists: %@",group.name);
                    [group MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                }
            }
            currentUser.company.groups = groups;
        }
        [self loadArchived];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Error while loading groups: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your project groups. Please try again soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        
    }];
}

- (void)loadArchived {
    [manager GET:[NSString stringWithFormat:@"%@/projects/archived",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting archived projects: %@",responseObject);
        [self archiveProjects:[responseObject objectForKey:@"projects"]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get archived projects: %@",error.description);
    }];
}

- (void)archiveProjects:(NSArray*)projectsArray {
    NSMutableOrderedSet *projectSet = [NSMutableOrderedSet orderedSet];
    for (id obj in projectsArray) {
        //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [obj objectForKey:@"id"]];
        Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:(NSNumber*)[obj objectForKey:@"id"]];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [project populateFromDictionary:obj];
        NSLog(@"archived project name: %@",project.name);
        [projectSet addObject:project];
    }

    /*for (Project *p in currentUser.company.archivedProjects){
        if (![projectSet containsObject:p] && ![currentUser.projects containsObject:p]){
            NSLog(@"deleting archived project %@ because it no longer exists",p.name);
            [p MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }*/
    currentUser.company.archivedProjects = projectSet;
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
        return currentUser.projects.count;
    } else if (section == 1) {
        return groupSet.count;
    } else if (section == 2) {
        for (WorklistItem *item in currentUser.assignedWorklistItems){
            NSNumber *companyId = item.project.company.identifier;
            if (companyId && ![currentUser.company.identifier isEqualToNumber:companyId]) {
                [connectProjects addObject:item.project];
            }
        }
        NSLog(@"connect projects count: %d",connectProjects.count);
        return connectProjects.count;
    } else if (section == 3 && currentUser.archivedProjects.count) {
        NSLog(@"archived? %d",currentUser.archivedProjects.count);
        return 1;
    } else if (!loading && section == 4) {
        return 1;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        Project *project;
        if (searching && filteredProjects.count){
            project = [filteredProjects objectAtIndex:indexPath.row];
        } else {
            project = [currentUser.projects objectAtIndex:indexPath.row];
        }
        static NSString *CellIdentifier = @"ProjectCell";
        BHDashboardProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardProjectCell" owner:self options:nil] lastObject];
        }
        
        [cell configureForProject:project andUser:currentUser];
        
        [cell.progressButton setTitle:project.progressPercentage forState:UIControlStateNormal];
        [cell.progressButton setTag:indexPath.row];
        [cell.progressButton addTarget:self action:@selector(goToProjectDetail:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.projectButton setTag:indexPath.row];
        [cell.projectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.titleLabel setTextColor:kDarkGrayColor];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsCompanyAdmin] || [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsAdmin]){
            [cell.archiveButton setTag:indexPath.row];
            [cell.archiveButton addTarget:self action:@selector(confirmArchive:) forControlEvents:UIControlEventTouchUpInside];
            cell.scrollView.scrollEnabled = YES;
        } else {
            cell.scrollView.scrollEnabled = NO;
        }
        return cell;
    } else if (indexPath.section == 1) {
        static NSString *CellIdentifier = @"GroupCell";
        BHDashboardGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardGroupCell" owner:self options:nil] lastObject];
        }
        Group *group = [groupSet objectAtIndex:indexPath.row];
        [cell.nameLabel setText:group.name];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        [cell.groupCountLabel setHidden:NO];
        [cell.groupCountLabel setText:[NSString stringWithFormat:@"Projects: %@",group.projectsCount]];
        
        [cell.nameLabel setTextAlignment:NSTextAlignmentLeft];
        [cell.nameLabel setTextColor:kDarkGrayColor];
        return cell;
    } else if (indexPath.section == 2) {
        static NSString *CellIdentifier = @"ConnectCell";
        BHWorklistConnectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHWorklistConnectCell" owner:self options:nil] lastObject];
        }
        
        Project *project = [connectProjects objectAtIndex:indexPath.row];
        [cell.companyNameLabel setText:project.name];
        __block int count = 0;
        [currentUser.assignedWorklistItems enumerateObjectsUsingBlock:^(WorklistItem *item, NSUInteger idx, BOOL *stop) {
            if ([item.project.identifier isEqualToNumber:project.identifier]) {
                count ++;
            }
        }];
        [cell.projectsLabel setText:[NSString stringWithFormat:@"%d items",count]];
        
        return cell;
    } else if (indexPath.section == 3) {
        //Not really a group cell, just reusing that cell type
        static NSString *CellIdentifier = @"GroupCell";
        BHDashboardGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardGroupCell" owner:self options:nil] lastObject];
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell.textLabel setText:@"Archived Projects"];
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:20]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        [cell.groupCountLabel setHidden:YES];
        [cell.nameLabel setHidden:YES];
        return cell;
    } else {
        //Not really a group cell, just reusing that cell type
        static NSString *CellIdentifier = @"GroupCell";
        BHDashboardGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardGroupCell" owner:self options:nil] lastObject];
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell.textLabel setText:@"View Demo Project(s)"];
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:20]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        [cell.groupCountLabel setHidden:YES];
        [cell.nameLabel setHidden:YES];
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
    if (section == 1 && !currentUser.company.groups.count) return 0;
    else if (section == 2 && !currentUser.assignedWorklistItems) return 0;
    else if (section == 3 || section == 4) return 0;
    else return 34;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 34)];
    [headerView setBackgroundColor:kDarkerGrayColor];

    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, screenWidth()-7, 34)];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.font = [UIFont systemFontOfSize:15];
    headerLabel.numberOfLines = 0;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    switch (section) {
        case 0:
            if (currentUser.company.name.length){
                [headerLabel setText:[NSString stringWithFormat:@"%@ Projects",currentUser.company.name]];
            } else {
                [headerLabel setText:@"Projects"];
            }
            break;
        case 1:
            if (currentUser.company.groups.count)[headerLabel setText:[NSString stringWithFormat:@"%@ Project Groups",currentUser.company.name]];
            else return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            break;
        case 2:
            if (currentUser.assignedWorklistItems.count)[headerLabel setText:@"BuildHawk Connect"];
            else return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
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

- (void)confirmArchive:(UIButton*)button{
    [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to archive this project? Once archived, a project can still be managed from the web, but will no longer be visible here." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Archive", nil] show];
    archivedProject = [currentUser.projects objectAtIndex:button.tag];
    BHDashboardProjectCell *cell = (BHDashboardProjectCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:button.tag inSection:0]];
    [cell.scrollView setContentOffset:CGPointZero animated:YES];
}

- (void)archiveProject{
    [manager POST:[NSString stringWithFormat:@"%@/projects/%@/archive",kApiBaseUrl,archivedProject.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully archived the project: %@",responseObject);
        if ([responseObject objectForKey:@"user"]){
            [[NSUserDefaults standardUserDefaults] setBool:[[[responseObject objectForKey:@"user"] valueForKey:@"admin"] boolValue] forKey:kUserDefaultsAdmin];
            [[NSUserDefaults standardUserDefaults] setBool:[[[responseObject objectForKey:@"user"] valueForKey:@"company_admin"] boolValue] forKey:kUserDefaultsCompanyAdmin];
            [[NSUserDefaults standardUserDefaults] setBool:[[[responseObject objectForKey:@"user"] valueForKey:@"uber_admin"] boolValue] forKey:kUserDefaultsUberAdmin];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[[UIAlertView alloc] initWithTitle:@"Unable to Archive" message:@"Only administrators can archive projects." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            [self.tableView reloadData];
        } else {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[currentUser.projects indexOfObject:archivedProject] inSection:0];
            [currentUser.company removeProject:archivedProject];
            
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to archive this project. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to archive the project: %@",error.description);
    }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Archive"]){
        [self archiveProject];
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
        [self performSegueWithIdentifier:@"Project" sender:selectedProject];
    } else if (indexPath.section == 0) {
        Project *selectedProject = [currentUser.projects objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ProjectSynopsis" sender:selectedProject];
    } else if (indexPath.section == 1) {
        Group *group = [currentUser.company.groups objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"Group" sender:group];
    } else if (indexPath.section == 2) {
        [self performSegueWithIdentifier:@"WorklistConnect" sender:indexPath];
    } else if (indexPath.section == 3){
        [self performSegueWithIdentifier:@"Archived" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"Demos" sender:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Project"]) {
        Project *project = (Project*)sender;
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
        [vc setUser:currentUser];
    } else if ([segue.identifier isEqualToString:@"ProjectSynopsis"]) {
        Project *project = (Project*)sender;
        BHProjectSynopsisViewController *detailVC = [segue destinationViewController];
        [detailVC setProject:project];
    } else if ([segue.identifier isEqualToString:@"Group"]){
        Group *group = (Group *)sender;
        BHGroupViewController *vc = [segue destinationViewController];
        [vc setTitle:group.name];
        [vc setGroup:group];
    } else if ([segue.identifier isEqualToString:@"Demos"]){
        BHDemoProjectsViewController *vc = [segue destinationViewController];
        [vc setCurrentUser:currentUser];
    } else if ([segue.identifier isEqualToString:@"Archived"]){
        BHArchivedViewController *vc = [segue destinationViewController];
        [vc setTitle:@"Archived Projects"];
        [vc setArchivedProjects:currentUser.company.archivedProjects.mutableCopy];
    } else if ([segue.identifier isEqualToString:@"WorklistConnect"]){
        BHTasksViewController *vc = [segue destinationViewController];
        NSIndexPath *indexPath = (NSIndexPath*)sender;
        Project *project = [connectProjects objectAtIndex:indexPath.row];
        NSMutableArray *worklistItems = [NSMutableArray array];
        for (WorklistItem *item in currentUser.assignedWorklistItems){
            if ([item.project.identifier isEqualToNumber:project.identifier]) {
                [worklistItems addObject:item];
            }
        }
        [vc setWorklistItems:worklistItems];
        [vc setProject:project];
        [vc setConnectMode:YES];
    }
}

- (void)goToProject:(UIButton*)button {
    Project *selectedProject;
    if (searching && filteredProjects.count > button.tag){
        selectedProject = [filteredProjects objectAtIndex:button.tag];
    } else if (currentUser.projects.count > button.tag) {
        selectedProject = [currentUser.projects objectAtIndex:button.tag];
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
    Project *selectedProject = [currentUser.projects objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"ProjectSynopsis" sender:selectedProject];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredProjects removeAllObjects]; // First clear the filtered array.
    for (Project *project in currentUser.projects){
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
    [welcomeLabel.label setFont:[UIFont fontWithName:kHelveticaNeueLight size:18]];
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
        [dashboardScreenshot setFrame:CGRectMake(29, 30, 710, 462)];
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
    NSString *text = @"\"View Demo Project(s)\" will show you some examples of how you can use the app.";
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
}

@end
