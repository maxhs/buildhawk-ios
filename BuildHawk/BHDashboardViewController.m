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

@interface BHDashboardViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate> {
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
 
    if (!filteredProjects) filteredProjects = [NSMutableArray array];
    
    SWRevealViewController *revealController = [self revealViewController];
    [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];
    searchContainerRect = self.searchContainerView.frame;
    
    NSDate *now = [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    self.navigationItem.title = [dateFormatter stringFromDate:now];
    [self loadProjects];
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    
    [self.searchContainerBackgroundView setBackgroundColor:kDarkGrayColor];
}

- (IBAction)revealMenu {
    [self.revealViewController revealToggleAnimated:YES];
}

- (void)handleRefresh:(id)sender {
    [self loadProjects];
}

- (void)loadProjects {
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
    RKResponseDescriptor *projectsDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:projectMapping method:RKRequestMethodAny pathPattern:@"projects" keyPath:@"rows" statusCodes:statusCodes];
    
    // For any object of class Article, serialize into an NSMutableDictionary using the given mapping and nest
    // under the 'article' key path
    //RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:projectMapping objectClass:[BHProject class] rootKeyPath:nil method:RKRequestMethodAny];
    
    //[manager addRequestDescriptor:requestDescriptor];
    [SVProgressHUD showWithStatus:@"Fetching projects..."];
    [manager addResponseDescriptor:projectsDescriptor];
    [manager getObjectsAtPath:@"projects" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"mapping result for projects: %f",[[(BHProject*)mappingResult.firstObject address] latitude]);
        NSLog(@"mapping result for projects: %hhd",[(BHProject*)mappingResult.firstObject active]);
        projects = [mappingResult.array mutableCopy];
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
    if (project.assignees.count){
        [cell.subtitleLabel setText:[project.assignees objectAtIndex:0]];
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
        [self.searchContainerBackgroundView setBackgroundColor:kDarkGrayColor];
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

@end
