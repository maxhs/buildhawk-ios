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

@interface BHGroupViewController () {
    NSMutableArray *_projects;
    AFHTTPRequestOperationManager *manager;
    CGRect screen;
    Project *archivedProject;
}

@end

@implementation BHGroupViewController
@synthesize group = _group;

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [self loadGroup];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadGroup {
    [ProgressHUD show:@"Fetching Group Projects..."];
    [manager GET:[NSString stringWithFormat:@"%@/groups/%@",kApiBaseUrl,_group.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success getting group: %@",responseObject);
        if ([responseObject objectForKey:@"group"] && [responseObject objectForKey:@"group"] != [NSNull null]){
            _group = [Group MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"group"] objectForKey:@"id"]];
            if (!_group){
                _group = [Group MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [_group populateWithDict:[responseObject objectForKey:@"group"]];
        }
        NSLog(@"group projects: %d",_group.projects.count);
        
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
    [cell.titleLabel setText:[project name]];
    
    if (project.address.formattedAddress.length){
        [cell.subtitleLabel setText:project.address.formattedAddress];
    } else {
        //[cell.subtitleLabel setText:project.company.name];
    }
    
    [cell.progressButton setTitle:project.progressPercentage forState:UIControlStateNormal];
    [cell.progressButton setTag:indexPath.row];
    [cell.progressButton addTarget:self action:@selector(goToProjectDetail:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.projectButton setTag:indexPath.row];
    [cell.projectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.titleLabel setTextColor:kDarkGrayColor];
    [cell.archiveButton setTag:indexPath.row];
    [cell.archiveButton addTarget:self action:@selector(confirmArchive:) forControlEvents:UIControlEventTouchUpInside];
    return cell;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Project *selectedProject = [_group.projects objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"Project" sender:selectedProject];
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

- (void)goToProjectDetail:(UIButton*)button {
    Project *selectedProject = [_group.projects objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"GroupDetail" sender:selectedProject];
}

- (void)confirmArchive:(UIButton*)button{
    [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to archive this project? Once archive, a project can still be managed from the web, but will no longer be visible here." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Archive", nil] show];
    archivedProject = [_group.projects objectAtIndex:button.tag];
}

- (void)archiveProject{
    [manager POST:[NSString stringWithFormat:@"%@/projects/%@/archive",kApiBaseUrl,archivedProject.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully archived the project: %@",responseObject);
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_group.projects indexOfObject:archivedProject] inSection:0];
        [_group removeProject:archivedProject];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
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

@end
