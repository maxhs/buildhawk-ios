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
#import "BHProject.h"
#import "User.h"
#import "Project.h"
#import "BHAddress.h"
#import "BHCompany.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"
#import "BHGroupViewController.h"
#import "BHArchivedViewController.h"

@interface BHDashboardViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UIAlertViewDelegate> {
    CGRect searchContainerRect;
    NSMutableArray *projects;
    UIRefreshControl *refreshControl;
    BOOL iPhone5;
    BOOL iPad;
    NSMutableArray *filteredProjects;
    User *savedUser;
    NSMutableArray *recentChecklistItems;
    NSMutableArray *recentDocuments;
    NSMutableArray *recentlyCompletedWorklistItems;
    NSMutableArray *notifications;
    NSMutableArray *upcomingChecklistItems;
    NSMutableArray *categories;
    NSMutableDictionary *dashboardDetailDict;
    AFHTTPRequestOperationManager *manager;
    CGRect screen;
    BHProject *archivedProject;
    NSMutableArray *archivedProjects;
    UIBarButtonItem *archiveButtonItem;
}

@property (weak, nonatomic) IBOutlet UIView *searchContainerBackgroundView;
@end

@implementation BHDashboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    screen = [UIScreen mainScreen].bounds;
    if (screen.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = NO;
        self.searchContainerView.transform = CGAffineTransformMakeTranslation(0, -88);
    } else {
        iPad = YES;
    }
    projects = [NSMutableArray array];
    filteredProjects = [NSMutableArray array];
    
    SWRevealViewController *revealController = [self revealViewController];
    if (iPad){
        revealController.rearViewRevealWidth = screen.size.width - 62;
    } else {
        revealController.rearViewRevealWidth = screen.size.width - 52;
    }
    
    //[self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];
    searchContainerRect = self.searchContainerView.frame;
    
    NSDate *now = [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    self.navigationItem.title = [dateFormatter stringFromDate:now];

    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    [self.searchContainerBackgroundView setBackgroundColor:kDarkGrayColor];
    if (!manager) manager = [AFHTTPRequestOperationManager manager];
    if (!dashboardDetailDict) dashboardDetailDict = [NSMutableDictionary dictionary];
    if (!categories) categories = [NSMutableArray array];
    [self loadProjects];
    archiveButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Archived" style:UIBarButtonItemStylePlain target:self action:@selector(getArchived)];
}

- (void)getArchived {
    [self performSegueWithIdentifier:@"Archived" sender:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!projects.count){
        [SVProgressHUD showWithStatus:@"Fetching projects..."];
    }
}

- (IBAction)revealMenu {
    [self.revealViewController revealToggleAnimated:YES];
}

- (void)loadDetailView {
    for (BHProject *proj in projects){
        [categories removeAllObjects];
        [manager GET:[NSString stringWithFormat:@"%@/projects/dash",kApiBaseUrl] parameters:@{@"id":proj.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting dashboard detail view: %@",[responseObject objectForKey:@"project"]);
            categories = [[[responseObject objectForKey:@"project"] objectForKey:@"categories"] mutableCopy];
            [dashboardDetailDict setObject:[responseObject objectForKey:@"project"] forKey:proj.identifier];
            
            if (dashboardDetailDict.count == projects.count) {
                //NSLog(@"dashboard detail array after addition: %@, %i",dashboardDetailDict, dashboardDetailDict.count);
                [self.tableView reloadData];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure getting dashboard: %@",error.description);
        }];
    }
}

- (void)handleRefresh:(id)sender {
    [self loadProjects];
}

- (NSMutableArray *)projectsFromJSONArray:(NSArray *) array {
    NSMutableArray *theseProjects = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *projectDictionary in array) {
        BHProject *project = [[BHProject alloc] initWithDictionary:projectDictionary];
        [theseProjects addObject:project];
    }
    return theseProjects;
}

- (void)loadProjects {
    [SVProgressHUD dismiss];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [SVProgressHUD showWithStatus:@"Fetching projects..."];
        [manager GET:[NSString stringWithFormat:@"%@/projects",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"load projects response object: %@",responseObject);
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            [self saveToMR:[self projectsFromJSONArray:[responseObject objectForKey:@"projects"]]];
            [self.tableView reloadData];
            [self loadArchived];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error while loading projects: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your projects. Please try again soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            [SVProgressHUD dismiss];
        }];
    } else {
        [(BHAppDelegate*)[UIApplication sharedApplication].delegate logout];
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your projects. Please log in and try again." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)saveToMR:(id)forSave {
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    savedUser = [User MR_findFirst];
    savedUser.bhprojects = forSave;
    for (BHProject *proj in forSave) {
        if (!proj.group){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", proj.identifier];
            Project *savedProject = [Project MR_findFirstWithPredicate:predicate inContext:localContext];
            if (savedProject){
                NSLog(@"Found saved project %@",proj.name);
                savedProject.identifier = proj.identifier;
                savedProject.name = proj.name;
                savedProject.users = proj.users;
                savedProject.subs = proj.subs;
            } else {
                NSLog(@"Creating a new project for local storage: %@",proj.name);
                Project *project = [Project MR_createInContext:localContext];
                project.identifier = proj.identifier;
                project.name = proj.name;
                project.users = proj.users;
                project.subs = proj.subs;
            }
        }
    }

    [localContext MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        projects = savedUser.bhprojects;
        [self loadDetailView];
        [self.tableView reloadData];
    }];
}

- (void)loadArchived {
    [manager GET:[NSString stringWithFormat:@"%@/projects/archived",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success getting archived projects: %@",responseObject);
        archivedProjects = [BHUtilities projectsFromJSONArray:[responseObject objectForKey:@"projects"]];
        if (archivedProjects.count) self.navigationItem.rightBarButtonItem = archiveButtonItem;
        else self.navigationItem.rightBarButtonItem = nil;
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) return projects.count;
    else if (tableView == self.searchDisplayController.searchResultsTableView) return filteredProjects.count;
    else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    BHProject *project;
    if (tableView == self.searchDisplayController.searchResultsTableView){
        project = [filteredProjects objectAtIndex:indexPath.row];
    } else {
        project = [projects objectAtIndex:indexPath.row];
    }
    if (project.group) {
        static NSString *CellIdentifier = @"GroupCell";
        BHDashboardGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardGroupCell" owner:self options:nil] lastObject];
        }
        [cell.nameLabel setText:project.group.name];
        
        if (project.group.projects.count){
            [cell.groupCountLabel setText:[NSString stringWithFormat:@"Projects: %i",project.group.projects.count]];
        }
        
        [cell.nameLabel setTextColor:kDarkGrayColor];
        return cell;
    } else {
        static NSString *CellIdentifier = @"ProjectCell";
        BHDashboardProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardProjectCell" owner:self options:nil] lastObject];
        }
        [cell.titleLabel setText:[project name]];

        if (project.address.formattedAddress.length){
            [cell.subtitleLabel setText:project.address.formattedAddress];
        } else {
            [cell.subtitleLabel setText:project.company.name];
        }
        
        if (dashboardDetailDict.count){
            NSDictionary *dict = [dashboardDetailDict objectForKey:project.identifier];
            [cell.progressLabel setText:[dict objectForKey:@"progress"]];
        }
        [cell.projectButton setTag:indexPath.row];
        [cell.projectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
        [cell.titleLabel setTextColor:kDarkGrayColor];
        [cell.archiveButton setTag:indexPath.row];
        [cell.archiveButton addTarget:self action:@selector(confirmArchive:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
}

- (CGFloat)calculateCategories:(NSMutableArray*)array {
    CGFloat completed = 0.0;
    CGFloat pending = 0.0;
    if (array.count) {
        for (NSDictionary *dict in array){
            if ([dict objectForKey:@"completed"]) completed += [[dict objectForKey:@"completed"] floatValue];
            if ([dict objectForKey:@"pending"]) pending += [[dict objectForKey:@"pending"] floatValue];
        }
    }
    if (completed > 0 && pending > 0){
        return (completed/pending);
    } else {
        return 0;
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
        [SVProgressHUD dismiss];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)confirmArchive:(UIButton*)button{
    [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to archive this project? Once archive, a project can still be managed from the web, but will no longer be visible here." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Archive", nil] show];
    archivedProject = [projects objectAtIndex:button.tag];
}

- (void)archiveProject{
    [manager POST:[NSString stringWithFormat:@"%@/projects/%@/archive",kApiBaseUrl,archivedProject.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully archived the project: %@",responseObject);
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[projects indexOfObject:archivedProject] inSection:0];
        [projects removeObject:archivedProject];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.searchContainerView setFrame:CGRectMake(0, 0, 320, self.view.frame.size.height)];
        [self.searchContainerBackgroundView setBackgroundColor:[UIColor whiteColor]];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.searchContainerView setFrame:searchContainerRect];
        [self.searchContainerBackgroundView setBackgroundColor:[UIColor colorWithWhite:.2 alpha:1.0]];
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BHProject *selectedProject;
    if (tableView == self.searchDisplayController.searchResultsTableView){
        [self.searchDisplayController setActive:NO animated:NO];
        selectedProject = [filteredProjects objectAtIndex:indexPath.row];
    } else {
        selectedProject = [projects objectAtIndex:indexPath.row];
    }
    if (selectedProject.group){
        [self performSegueWithIdentifier:@"Group" sender:selectedProject];
    } else {
        [self performSegueWithIdentifier:@"DashboardDetail" sender:selectedProject];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(BHProject*)project {
    if ([segue.identifier isEqualToString:@"Project"]) {
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
        [vc setUser:savedUser];
    } else if ([segue.identifier isEqualToString:@"DashboardDetail"]) {
        BHDashboardDetailViewController *detailVC = [segue destinationViewController];
        [detailVC setProject:project];
        NSDictionary *dict = [dashboardDetailDict objectForKey:project.identifier];
        [detailVC setRecentChecklistItems:[BHUtilities checklistItemsFromJSONArray:[dict objectForKey:@"recently_completed"]]];
        [detailVC setUpcomingChecklistItems:[BHUtilities checklistItemsFromJSONArray:[dict objectForKey:@"upcoming_items"]]];
        [detailVC setRecentDocuments:[BHUtilities photosFromJSONArray:[dict objectForKey:@"recent_documents"]]];
        [detailVC setRecentlyCompletedWorklistItems:[BHUtilities checklistItemsFromJSONArray:[dict objectForKey:@"recently_completed"]]];
        [detailVC setCategories:[dict objectForKey:@"categories"]];
    } else if ([segue.identifier isEqualToString:@"Group"]){
        BHGroupViewController *vc = [segue destinationViewController];
        [vc setTitle:project.group.name];
        [vc setProject:project];
    } else if ([segue.identifier isEqualToString:@"Archived"]){
        BHArchivedViewController *vc = [segue destinationViewController];
        [vc setTitle:@"Archived Projects"];
        [vc setArchivedProjects:archivedProjects];
    }
}

- (void)goToProject:(UIButton*)button {
    BHProject *selectedProject;
    if (self.searchDisplayController.isActive){
        selectedProject = [filteredProjects objectAtIndex:button.tag];
    } else {
        selectedProject = [projects objectAtIndex:button.tag];
    }
    [self performSegueWithIdentifier:@"Project" sender:selectedProject];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredProjects removeAllObjects]; // First clear the filtered array.
    for (BHProject *project in projects){
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

@end
