//
//  BHGroupViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/15/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHGroupViewController.h"
#import "BHDashboardProjectCell.h"
#import "BHProjectSynopsisViewController.h"
#import "BHTabBarViewController.h"
#import "BHAppDelegate.h"
#import "Address+helper.h"

@interface BHGroupViewController () {    
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *_projects;
    Project *hiddenProject;
}

@end

@implementation BHGroupViewController
@synthesize group = _group;

- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.rowHeight = 88;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadGroup];
}

- (void)loadGroup {
    [ProgressHUD show:@"Fetching project groups..."];
    [manager GET:[NSString stringWithFormat:@"%@/groups/%@",kApiBaseUrl,_group.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success getting group: %@",responseObject);
        if ([responseObject objectForKey:@"group"] && [responseObject objectForKey:@"group"] != [NSNull null]){
            _group = [Group MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"group"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (_group){
                [_group updateWithDictionary:[responseObject objectForKey:@"group"]];
            } else {
                _group = [Group MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [_group populateWithDictionary:[responseObject objectForKey:@"group"]];
            }
        }
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting dashboard: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:nil message:@"Something went wrong while fetching projects for this group. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        [ProgressHUD dismiss];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _group.projects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Project *project = [_group.projects objectAtIndex:indexPath.row];
    static NSString *CellIdentifier = @"ProjectCell";
    BHDashboardProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardProjectCell" owner:self options:nil] lastObject];
    }
    [cell configureForProject:project andUser:delegate.currentUser];
    
    [cell.progressButton setTitle:project.progressPercentage forState:UIControlStateNormal];
    [cell.projectButton setTag:indexPath.row];
    [cell.projectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.nameLabel setTextColor:kDarkGrayColor];
    [cell.hideButton setTag:indexPath.row];
    [cell.hideButton addTarget:self action:@selector(confirmHide:) forControlEvents:UIControlEventTouchUpInside];
    return cell;

}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Project *selectedProject = _group.projects[indexPath.row];
    [self performSegueWithIdentifier:@"GroupDetail" sender:selectedProject];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Project*)project {
    [super prepareForSegue:segue sender:project];
    if ([segue.identifier isEqualToString:@"Project"]) {
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
    } else if ([segue.identifier isEqualToString:@"GroupDetail"]) {
        BHProjectSynopsisViewController *detailVC = [segue destinationViewController];
        [detailVC setProject:project];
    }
}

- (void)goToProject:(UIButton*)button {
    Project *selectedProject = [_group.projects objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"Project" sender:selectedProject];
}

- (void)confirmHide:(UIButton*)button{
    [[[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Once hidden, a project will no longer be visible inside this group." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Hide", nil] show];
    hiddenProject = [_group.projects objectAtIndex:button.tag];
}

- (void)hideProject{
    [manager POST:[NSString stringWithFormat:@"%@/projects/%@/archive",kApiBaseUrl,hiddenProject.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully hid the project: %@",responseObject);
        //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_group.projects indexOfObject:hiddenProject] inSection:0];
        
        [_group removeProject:hiddenProject];
        
        if (_group.projects.count){
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
        
        /*[self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];*/
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to hide this project. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to hide the project: %@",error.description);
    }];
}

#pragma mark - UIAlertView Delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Hide"]){
        [self hideProject];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
