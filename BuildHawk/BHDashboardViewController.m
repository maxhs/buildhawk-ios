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
#import "BHAddress.h"
#import "BHCompany.h"
#import <RestKit/RestKit.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "BHTabBarViewController.h"
#import "Constants.h"

@interface BHDashboardViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, NSFetchedResultsControllerDelegate> {
    CGRect searchContainerRect;
    NSMutableArray *projects;
    UIRefreshControl *refreshControl;
    BOOL iPhone5;
    NSMutableArray *filteredProjects;
}

@property (weak, nonatomic) IBOutlet UIView *searchContainerBackgroundView;
@end

@implementation BHDashboardViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
        self.searchContainerView.transform = CGAffineTransformMakeTranslation(0, -88);
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
    
    [self.searchContainerBackgroundView setBackgroundColor:kBlueColor];
    [self loadProjects];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (IBAction)revealMenu {
    [self.revealViewController revealToggleAnimated:YES];
}

- (void)handleRefresh:(id)sender {
    [self loadProjects];
}

- (void)loadProjects {
    [projects removeAllObjects];
    RKObjectManager *manager = [RKObjectManager sharedManager];
    
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[BHAddress class]];
    [addressMapping addAttributeMappingsFromDictionary:@{
                                                         @"formatted_address":@"formattedAddress",
                                                         @"street_number":@"streetNumber",
                                                         @"route":@"route",
                                                         @"postal_code":@"postalCode",
                                                         @"loc.lat":@"latitude",
                                                         @"loc.lng":@"longitude"
                                                         }];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"address"
                                                                                             toKeyPath:@"address"
                                                                                           withMapping:addressMapping];
    
    RKObjectMapping *companyMapping = [RKObjectMapping mappingForClass:[BHCompany class]];
     [companyMapping addAttributeMappingsFromDictionary:@{
                                                          @"_id":@"identifier",
                                                          @"name":@"name",
                                                          }];
    RKRelationshipMapping *moreMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"company"
                                                                                             toKeyPath:@"company"
                                                                                           withMapping:companyMapping];
    
    RKObjectMapping *projectMapping = [RKObjectMapping mappingForClass:[BHProject class]];
    [projectMapping addAttributeMappingsFromArray:@[@"name", @"active"/*, @"company",@"timestamps",@"active"*/]];
    [projectMapping addAttributeMappingsFromDictionary:@{
                                                         @"_id" : @"identifier",
                                                         }];
    
    [projectMapping addPropertyMappingsFromArray:@[relationshipMapping, moreMapping]];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *projectsDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:projectMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"rows" statusCodes:statusCodes];
    
    [SVProgressHUD showWithStatus:@"Fetching projects..."];
    [manager addResponseDescriptor:projectsDescriptor];
    [manager getObjectsAtPath:@"projects" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"mapping result: %@",mappingResult.array);
        for (BHProject *project in mappingResult.array) {
            if ([project isKindOfClass:[BHProject class]]) {
                [projects addObject:project];
            }
        }
        projects = [mappingResult.array mutableCopy];
        NSLog(@"projects count: %i",projects.count);
        [SVProgressHUD dismiss];
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching projects for dashboard: %@",error.description);
        [SVProgressHUD dismiss];
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
        [cell.subtitleLabel setText:[project.users objectAtIndex:0]];
    } else {
        [cell.subtitleLabel setText:project.company.name];
    }
    [cell.projectButton setTag:0];
    [cell.projectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
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
        [self.searchContainerBackgroundView setBackgroundColor:kBlueColor];
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"DashboardRevealed" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    BHProject *project = [projects objectAtIndex:self.tableView.indexPathForSelectedRow.row];
    if ([segue.identifier isEqualToString:@"Project"]) {
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
    } else if ([segue.identifier isEqualToString:@"DashboardRevealed"]) {
        BHDashboardDetailViewController *detailVC = [segue destinationViewController];
        [detailVC setProject:project];
    }
}

- (void)goToProject:(UIButton*)button {
    [self performSegueWithIdentifier:@"Project" sender:button];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredProjects removeAllObjects]; // First clear the filtered array.
    NSLog(@"dashboard search text: %@",searchText);
    for (BHProject *project in projects){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:project.name]) {
            NSLog(@"able to add %@",project.name);
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

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
}

@end
