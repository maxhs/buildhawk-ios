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
#import "BHDashboardDetailViewController.h"
#import "BHTabBarViewController.h"
#import "User.h"
#import "Project.h"
#import "Project+helper.h"
#import "Address.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"
#import "BHGroupViewController.h"
#import "BHArchivedViewController.h"
#import "BHOverlayView.h"

@interface BHDashboardViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UIAlertViewDelegate,SWRevealViewControllerDelegate> {
    CGRect searchContainerRect;
    NSMutableArray *projects;
    NSMutableArray *groups;
    UIRefreshControl *refreshControl;
    BOOL iPhone5;
    BOOL loading;
    NSMutableArray *filteredProjects;
    User *savedUser;
    NSMutableArray *recentChecklistItems;
    NSMutableArray *recentlyCompletedWorklistItems;
    NSMutableArray *notifications;
    NSMutableArray *upcomingChecklistItems;
    NSMutableArray *categories;
    NSMutableDictionary *dashboardDetailDict;
    AFHTTPRequestOperationManager *manager;
    CGRect screen;
    Project *archivedProject;
    NSMutableArray *archivedProjects;
    UIBarButtonItem *archiveButtonItem;
    UIBarButtonItem *searchButton;
    UIView *overlayBackground;
    UIImageView *dashboardScreenshot;
    NSManagedObjectContext *defaultContext;
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
   
    manager = manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    loading = YES;
    screen = [UIScreen mainScreen].bounds;
    if (screen.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = NO;
    }
    
    projects = [NSMutableArray array];
    groups = [NSMutableArray array];
    filteredProjects = [NSMutableArray array];
    
    SWRevealViewController *revealController = [self revealViewController];
    revealController.delegate = self;
    if (IDIOM == IPAD){
        revealController.rearViewRevealWidth = screen.size.width - 62;
    } else {
        revealController.rearViewRevealWidth = screen.size.width - 52;
    }
    
    NSDate *now = [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    self.navigationItem.title = [dateFormatter stringFromDate:now];

    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    
    if (!dashboardDetailDict) dashboardDetailDict = [NSMutableDictionary dictionary];
    if (!categories) categories = [NSMutableArray array];
    [self loadProjects];

    searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(activateSearch)];
    self.navigationItem.rightBarButtonItems = @[searchButton];
    archiveButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Archived" style:UIBarButtonItemStylePlain target:self action:@selector(getArchived)];
    [self.searchDisplayController.searchBar setBackgroundColor:kDarkerGrayColor];
}

- (void)getArchived {
    [self performSegueWithIdentifier:@"Archived" sender:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenDashboard]){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlay];
        [self slide1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenDashboard];
    }
}

- (IBAction)revealMenu {
    [self.revealViewController revealToggleAnimated:YES];
    [self.view addGestureRecognizer:self.revealViewController.tapGestureRecognizer];
    self.tableView.userInteractionEnabled = NO;
}

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position {
    if (position == FrontViewPositionLeft) {
        self.tableView.userInteractionEnabled = YES;
    }
}

- (void)activateSearch {
    [self.searchDisplayController.searchBar becomeFirstResponder];
    [UIView animateWithDuration:.6 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect searchFrame = self.searchDisplayController.searchBar.frame;
        searchFrame.origin.x = 0;
        [self.searchDisplayController.searchBar setFrame:searchFrame];
        [self.searchDisplayController.searchBar setAlpha:1.0];
        CGRect tableFrame = self.tableView.frame;
        tableFrame.origin.y += 44;
        tableFrame.size.height += 44;
        [self.tableView setFrame:tableFrame];
    } completion:^(BOOL finished) {

    }];
}

- (void)endSearch {
    [UIView animateWithDuration:.6 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect searchFrame = self.searchDisplayController.searchBar.frame;
        searchFrame.origin.x = screenWidth();
        [self.searchDisplayController.searchBar setFrame:searchFrame];
        [self.searchDisplayController.searchBar setAlpha:0.0];
        CGRect tableFrame = self.tableView.frame;
        tableFrame.origin.y -= 44;
        tableFrame.size.height -= 44;
        [self.tableView setFrame:tableFrame];
    } completion:^(BOOL finished) {
        
    }];
}


- (void)handleRefresh:(id)sender {
    [self loadProjects];
}

- (void)loadProjects {
    NSPredicate *activePredicate = [NSPredicate predicateWithFormat:@"demo == %@",[NSNumber numberWithBool:NO]];
    projects = [[Project MR_findAllSortedBy:@"name" ascending:YES withPredicate:activePredicate] mutableCopy];
    //NSLog(@"projects count fetched from MR: %i",projects.count);
    if (projects.count == 0)[ProgressHUD show:@"Fetching projects..."];
    else [self.tableView reloadData];
    [manager GET:[NSString stringWithFormat:@"%@/projects",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"load projects response object: %@",responseObject);
        loading = NO;
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [self updateProjects:[responseObject objectForKey:@"projects"]];
        [self loadGroups];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error while loading projects: %@",error.description);
        loading = NO;
        //[[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your projects. Please try again soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [ProgressHUD dismiss];
    }];
}

- (void)updateProjects:(NSArray*)projectsArray {
    defaultContext = [NSManagedObjectContext MR_defaultContext];
    savedUser = [User MR_findFirst];
    if (projectsArray.count == 0){
        NSLog(@"no projects");
        self.tableView.allowsSelection = YES;
        [ProgressHUD dismiss];
    } else {
        for (id obj in projectsArray) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [obj objectForKey:@"id"]];
            Project *project = [Project MR_findFirstWithPredicate:predicate inContext:defaultContext];
            if (!project){
                project = [Project MR_createInContext:defaultContext];
                [projects addObject:project];
            }
            [project populateFromDictionary:obj];
        }

        [defaultContext MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"What happened during dashboard save? %hhd %@",success, error);
            [self.tableView reloadData];
        }];
    }
}

- (void)loadGroups {

    [manager GET:[NSString stringWithFormat:@"%@/groups",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"load groups response object: %@",responseObject);
        groups = [BHUtilities groupsFromJSONArray:[responseObject objectForKey:@"groups"]];
        [self loadArchived];
        //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Error while loading groups: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your project groups. Please try again soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    }];
}

- (void)loadArchived {
    [manager GET:[NSString stringWithFormat:@"%@/projects/archived",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting archived projects: %@",responseObject);
        archivedProjects = [BHUtilities projectsFromJSONArray:[responseObject objectForKey:@"projects"]];
        if (archivedProjects.count) self.navigationItem.rightBarButtonItems = @[searchButton,archiveButtonItem];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get archived projects: %@",error.description);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    } else {
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return filteredProjects.count;
    } else if (section == 0){
        return projects.count;
    } else if (section == 1) {
        return groups.count;
    } else if (loading && section == 2) {
        return 0;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        Project *project;
        if (tableView == self.searchDisplayController.searchResultsTableView){
            project = [filteredProjects objectAtIndex:indexPath.row];
        } else {
            project = [projects objectAtIndex:indexPath.row];
        }
        
        static NSString *CellIdentifier = @"ProjectCell";
        BHDashboardProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardProjectCell" owner:self options:nil] lastObject];
        }
        [cell.titleLabel setText:[project name]];

        if (project.address.formattedAddress){
            [cell.subtitleLabel setText:project.address.formattedAddress];
        } else {
            //[cell.subtitleLabel setText:project.company.name];
        }
        
        [cell.progressLabel setText:project.progressPercentage];
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
        BHProjectGroup *group = [groups objectAtIndex:indexPath.row];
        [cell.nameLabel setText:group.name];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (group.projectsCount){
            [cell.groupCountLabel setHidden:NO];
            [cell.groupCountLabel setText:[NSString stringWithFormat:@"Projects: %@",group.projectsCount]];
        } else {
            [cell.groupCountLabel setHidden:YES];
        }
        [cell.nameLabel setTextAlignment:NSTextAlignmentLeft];
        [cell.nameLabel setTextColor:kDarkGrayColor];
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
        
        [cell.textLabel setText:@"View Demo Projects"];
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:20]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        [cell.groupCountLabel setHidden:YES];
        [cell.nameLabel setHidden:YES];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [ProgressHUD dismiss];
    }
}

- (void)confirmArchive:(UIButton*)button{
    [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to archive this project? Once archive, a project can still be managed from the web, but will no longer be visible here." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Archive", nil] show];
    archivedProject = [projects objectAtIndex:button.tag];
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
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[projects indexOfObject:archivedProject] inSection:0];
            [projects removeObject:archivedProject];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
    //[self.navigationController setNavigationBarHidden:YES animated:YES];

}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self endSearch];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView == self.searchDisplayController.searchResultsTableView){
        [self.searchDisplayController setActive:NO animated:NO];
        Project *selectedProject = [filteredProjects objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"DashboardDetail" sender:selectedProject];
    } else if (indexPath.section == 0) {
        Project *selectedProject = [projects objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"DashboardDetail" sender:selectedProject];
    } else if (indexPath.section == 1) {
        BHProjectGroup *group = [groups objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"Group" sender:group];
    } else {
        [self performSegueWithIdentifier:@"Demos" sender:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Project"]) {
        Project *project = (Project*)sender;
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
        [vc setUser:savedUser];
    } else if ([segue.identifier isEqualToString:@"DashboardDetail"]) {
        Project *project = (Project*)sender;
        BHDashboardDetailViewController *detailVC = [segue destinationViewController];
        [detailVC setProject:project];
    } else if ([segue.identifier isEqualToString:@"Group"]){
        BHProjectGroup *group = (BHProjectGroup *)sender;
        BHGroupViewController *vc = [segue destinationViewController];
        [vc setTitle:group.name];
        [vc setGroup:group];
    } else if ([segue.identifier isEqualToString:@"Archived"]){
        BHArchivedViewController *vc = [segue destinationViewController];
        [vc setTitle:@"Archived Projects"];
        [vc setArchivedProjects:archivedProjects];
    }
}

- (void)goToProject:(UIButton*)button {
    Project *selectedProject;
    if (self.searchDisplayController.isActive){
        selectedProject = [filteredProjects objectAtIndex:button.tag];
    } else {
        selectedProject = [projects objectAtIndex:button.tag];
    }
    [self performSegueWithIdentifier:@"Project" sender:selectedProject];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredProjects removeAllObjects]; // First clear the filtered array.
    for (Project *project in projects){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:project.name]) {
            [filteredProjects addObject:project];
        }
    }
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
        [dashboardScreenshot setFrame:CGRectMake(20, 30, 280, 290)];
    }
    [dashboardScreenshot setAlpha:0.0];
    [overlayBackground addSubview:dashboardScreenshot];
    
    [dashboard configureText:@"This is your project dashboard. All your active projects will be listed here." atFrame:CGRectMake(10, dashboardScreenshot.frame.origin.y + dashboardScreenshot.frame.size.height + 20, screenWidth()-20, 100)];
    [dashboard.tapGesture addTarget:self action:@selector(slide3:)];
    [dashboard.label setTextAlignment:NSTextAlignmentCenter];
    
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
    [dashboard configureText:@"\"View Demo Projects\" will show you some examples of how you can use the app." atFrame:CGRectMake(10, dashboardScreenshot.frame.origin.y + dashboardScreenshot.frame.size.height + 20, screenWidth()-20, 100)];
    [dashboard.tapGesture addTarget:self action:@selector(slide4:)];
    [dashboard.label setTextAlignment:NSTextAlignmentCenter];
    
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
    [progress configureText:@"See detailed project overviews by tapping the % on the right side of each project." atFrame:CGRectMake(10, dashboardScreenshot.frame.origin.y + dashboardScreenshot.frame.size.height + 20, screenWidth()-20, 100)];
    
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

@end
