//
//  BHGroupViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/15/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHGroupViewController.h"
#import "BHProjectGroup.h"
#import "BHDashboardProjectCell.h"
#import "BHDashboardDetailViewController.h"
#import "BHTabBarViewController.h"

@interface BHGroupViewController () {
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
}

@end

@implementation BHGroupViewController

@synthesize project = _project;

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [AFHTTPRequestOperationManager manager];
    if (!dashboardDetailDict) dashboardDetailDict = [NSMutableDictionary dictionary];
    if (!categories) categories = [NSMutableArray array];
    [self loadDetailView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadDetailView {
    for (BHProject *proj in _project.group.projects){
        [categories removeAllObjects];
        [manager GET:[NSString stringWithFormat:@"%@/projects/dash",kApiBaseUrl] parameters:@{@"id":proj.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting dashboard detail view: %@",[responseObject objectForKey:@"project"]);
            categories = [[[responseObject objectForKey:@"project"] objectForKey:@"categories"] mutableCopy];
            [dashboardDetailDict setObject:[responseObject objectForKey:@"project"] forKey:proj.identifier];
            
            if (dashboardDetailDict.count == _project.group.projects.count) {
                //NSLog(@"dashboard detail array after addition: %@, %i",dashboardDetailDict, dashboardDetailDict.count);
                [self.tableView reloadData];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure getting dashboard: %@",error.description);
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _project.group.projects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BHProject *project = [_project.group.projects objectAtIndex:indexPath.row];
    static NSString *CellIdentifier = @"ProjectCell";
    BHDashboardProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardProjectCell" owner:self options:nil] lastObject];
    }
    [cell.titleLabel setText:[project name]];
    
    if (project.address){
        [cell.subtitleLabel setText:[NSString stringWithFormat:@"%@, %@, %@ %@",project.address.street1,project.address.city,project.address.state,project.address.zip]];
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
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BHProject *selectedProject = [_project.group.projects objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"GroupDetail" sender:selectedProject];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(BHProject*)project {
    if ([segue.identifier isEqualToString:@"Project"]) {
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
    } else if ([segue.identifier isEqualToString:@"GroupDetail"]) {
        BHDashboardDetailViewController *detailVC = [segue destinationViewController];
        [detailVC setProject:project];
        NSDictionary *dict = [dashboardDetailDict objectForKey:project.identifier];
        [detailVC setRecentChecklistItems:[BHUtilities checklistItemsFromJSONArray:[dict objectForKey:@"recently_completed"]]];
        [detailVC setUpcomingChecklistItems:[BHUtilities checklistItemsFromJSONArray:[dict objectForKey:@"upcoming_items"]]];
        [detailVC setRecentDocuments:[BHUtilities photosFromJSONArray:[dict objectForKey:@"recent_documents"]]];
        [detailVC setRecentlyCompletedWorklistItems:[BHUtilities checklistItemsFromJSONArray:[dict objectForKey:@"recently_completed"]]];
        [detailVC setCategories:[dict objectForKey:@"categories"]];
    }
}

- (void)goToProject:(UIButton*)button {
    BHProject *selectedProject = [_project.group.projects objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"Project" sender:selectedProject];
}


- (void)confirmArchive:(UIButton*)button{
    [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to archive this project? Once archive, a project can still be managed from the web, but will no longer be visible here." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Archive", nil] show];
    archivedProject = [_project.group.projects objectAtIndex:button.tag];
}

- (void)archiveProject{
    [manager POST:[NSString stringWithFormat:@"%@/projects/%@/archive",kApiBaseUrl,archivedProject.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully archived the project: %@",responseObject);
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_project.group.projects indexOfObject:archivedProject] inSection:0];
        [_project.group.projects removeObject:archivedProject];
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
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
