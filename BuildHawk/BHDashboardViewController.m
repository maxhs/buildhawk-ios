//
//  BHDashboardViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHDashboardViewController.h"
#import "BHDashboardProjectCell.h"
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

@interface BHDashboardViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UIAlertViewDelegate> {
    CGRect searchContainerRect;
    NSMutableArray *projects;
    UIRefreshControl *refreshControl;
    BOOL iPhone5;
    BOOL iPad;
    BOOL loadProgress;
    NSMutableArray *filteredProjects;
    User *savedUser;
    NSMutableArray *recentChecklistItems;
    NSMutableArray *recentDocuments;
    NSMutableArray *recentlyCompletedWorklistItems;
    NSMutableArray *notifications;
    NSMutableArray *upcomingChecklistItems;
    NSMutableArray *categories;
    NSMutableArray *dashboardDetailArray;
    AFHTTPRequestOperationManager *manager;
}

@property (weak, nonatomic) IBOutlet UIView *searchContainerBackgroundView;
@end

@implementation BHDashboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = NO;
        self.searchContainerView.transform = CGAffineTransformMakeTranslation(0, -88);
    } else {
        iPad = YES;
    }
    if (!projects) projects = [NSMutableArray array];
    if (!filteredProjects) filteredProjects = [NSMutableArray array];
    
    SWRevealViewController *revealController = [self revealViewController];
    [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];
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
    if (!dashboardDetailArray) dashboardDetailArray = [NSMutableArray array];
    if (!categories) categories = [NSMutableArray array];
    loadProgress = YES;
    [self loadProjects];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (IBAction)revealMenu {
    [self.revealViewController revealToggleAnimated:YES];
}

- (void)loadDetailView {
    for (BHProject *proj in projects){
        /*if (!recentChecklistItems) recentChecklistItems = [NSMutableArray array];
        if (!recentDocuments) recentDocuments = [NSMutableArray array];
        if (!recentlyCompletedWorklistItems) recentlyCompletedWorklistItems = [NSMutableArray array];
        if (!notifications) notifications = [NSMutableArray array];
        if (!upcomingChecklistItems) upcomingChecklistItems = [NSMutableArray array];*/
        [categories removeAllObjects];
        [manager GET:[NSString stringWithFormat:@"%@/dash",kApiBaseUrl] parameters:@{@"pid":proj.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success getting dashboard detail view: %@",responseObject);
            /*recentChecklistItems = [BHUtilities checklistItemsFromJSONArray:[responseObject objectForKey:@"cl_changed"]];
            upcomingChecklistItems = [BHUtilities checklistItemsFromJSONArray:[responseObject objectForKey:@"cl_due_soon"]];
            recentDocuments = [BHUtilities photosFromJSONArray:[responseObject objectForKey:@"recent_docs"]];
            recentlyCompletedWorklistItems = [BHUtilities punchlistItemsFromJSONArray:[responseObject objectForKey:@"wl_completed"]];*/
            categories = [[responseObject objectForKey:@"cl_categories"] mutableCopy];
            [dashboardDetailArray addObject:@{@"categories":categories}];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure getting dashboard: %@",error.description);
        }];
    }
    [self.tableView reloadData];
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
    [SVProgressHUD showWithStatus:@"Fetching projects..."];
    [manager GET:[NSString stringWithFormat:@"%@/projects",kApiBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"load projects response object: %@",responseObject);
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [self saveToMR:[self projectsFromJSONArray:[responseObject objectForKey:@"rows"]]];
        [SVProgressHUD dismiss];
        [self.tableView reloadData];
        //[self loadDetailView];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error while loading projects: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your projects. Please try again soon" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [SVProgressHUD dismiss];
    }];
}

- (void)saveToMR:(id)forSave {
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    savedUser = [User MR_findFirst];
    savedUser.bhprojects = forSave;
    /*for (BHProject *proj in projects) {
        Project *project = [Project MR_createInContext:localContext];
        project.identifier = proj.identifier;
        project.name = proj.name;
        project.users = proj.users;
        //[savedUser addProjectsObject:project];
    }*/
    [localContext MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"saved user after projects: %@",savedUser);
        projects = savedUser.bhprojects;
        [self.tableView reloadData];
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
    static NSString *CellIdentifier = @"ProjectCell";
    BHDashboardProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardProjectCell" owner:self options:nil] lastObject];
    }
    BHProject *project;
    if (tableView == self.searchDisplayController.searchResultsTableView){
        project = [filteredProjects objectAtIndex:indexPath.row];
    } else {
        project = [projects objectAtIndex:indexPath.row];
    }
    [cell.titleLabel setText:[project name]];
    if (project.users.count){
        //[cell.subtitleLabel setText:[project.users objectAtIndex:0]];
    } else {
        [cell.subtitleLabel setText:project.company.name];
    }
    
    if (dashboardDetailArray.count){
        NSDictionary *dict = [dashboardDetailArray objectAtIndex:indexPath.row];
        
        [cell.progressLabel setText:[NSString stringWithFormat:@"%.1f%%",(100*[self calculateCategories:[dict objectForKey:@"categories"]])]];
    }
    [cell.projectButton setTag:indexPath.row];
    [cell.projectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
    [cell.titleLabel setTextColor:kDarkGrayColor];
    return cell;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"DashboardRevealed" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Project"]) {
        BHTabBarViewController *vc = [segue destinationViewController];
        UIButton *button = (UIButton*) sender;
        BHProject *project = [projects objectAtIndex:button.tag];
        [vc setProject:project];
        [vc setUser:savedUser];
    } else if ([segue.identifier isEqualToString:@"DashboardRevealed"]) {
        BHDashboardDetailViewController *detailVC = [segue destinationViewController];
        BHProject *project = [projects objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        [detailVC setProject:project];
    }
}

- (void)goToProject:(UIButton*)button {
    [self performSegueWithIdentifier:@"Project" sender:button];
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

//#pragma mark - Fetched results controller
//
//- (NSFetchedResultsController *)fetchedResultsController
//{
//    if (_fetchedResultsController != nil) {
//        return _fetchedResultsController;
//    }
//    
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    // Edit the entity name as appropriate.
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
//    [fetchRequest setEntity:entity];
//    
//    // Set the batch size to a suitable number.
//    [fetchRequest setFetchBatchSize:20];
//    
//    // Edit the sort key as appropriate.
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
//    NSArray *sortDescriptors = @[sortDescriptor];
//    
//    [fetchRequest setSortDescriptors:sortDescriptors];
//    
//    // Edit the section name key path and cache name if appropriate.
//    // nil for section name key path means "no sections".
//    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
//    aFetchedResultsController.delegate = self;
//    self.fetchedResultsController = aFetchedResultsController;
//    
//	NSError *error = nil;
//	if (![self.fetchedResultsController performFetch:&error]) {
//        // Replace this implementation with code to handle the error appropriately.
//        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//	    abort();
//	}
//    
//    return _fetchedResultsController;
//}
//
//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
//{
//    [self.tableView beginUpdates];
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
//           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
//{
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath
//{
//    UITableView *tableView = self.tableView;
//    
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeUpdate:
//            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
//            break;
//            
//        case NSFetchedResultsChangeMove:
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}
//
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
//{
//    [self.tableView endUpdates];
//}
//
///*
// // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
// 
// - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
// {
// // In the simplest, most efficient, case, reload the table view.
// [self.tableView reloadData];
// }
// */
//
//- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
//{
//    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
//}

@end
