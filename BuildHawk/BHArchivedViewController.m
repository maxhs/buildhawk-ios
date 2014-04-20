//
//  BHArchivedViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHArchivedViewController.h"
#import "BHArchivedProjectCell.h"
#import "BHTabBarViewController.h"

@interface BHArchivedViewController (){
    BHProject *archivedProject;
    AFHTTPRequestOperationManager *manager;
}
@end

@implementation BHArchivedViewController
@synthesize archivedProjects = _archivedProjects;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!manager) manager = [AFHTTPRequestOperationManager manager];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
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
    return _archivedProjects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ArchivedCell";
    BHProject *project = [_archivedProjects objectAtIndex:indexPath.row];
    BHArchivedProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHArchivedProjectCell" owner:self options:nil] lastObject];
    }
    [cell.titleLabel setText:[project name]];
    
    if (project.address.formattedAddress.length){
        [cell.subtitleLabel setText:project.address.formattedAddress];
    } else {
        [cell.subtitleLabel setText:project.company.name];
    }
    
    [cell.projectButton setTag:indexPath.row];
    [cell.projectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
    [cell.titleLabel setTextColor:kDarkGrayColor];
    [cell.unarchiveButton setTag:indexPath.row];
    [cell.unarchiveButton addTarget:self action:@selector(confirmUnarchive:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (void)confirmUnarchive:(UIButton*)button {
    [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to make this project active?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Activate", nil] show];
    archivedProject = [_archivedProjects objectAtIndex:button.tag];
}

- (void)unarchiveProject{
    [manager POST:[NSString stringWithFormat:@"%@/projects/%@/unarchive",kApiBaseUrl,archivedProject.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully unarchived the project: %@",responseObject);
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_archivedProjects indexOfObject:archivedProject] inSection:0];
        [_archivedProjects removeObject:archivedProject];
        if (_archivedProjects.count == 0) [self.navigationController popViewControllerAnimated:YES];
        else [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to unarchive this project. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to unarchive the project: %@",error.description);
    }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Activate"]){
        [self unarchiveProject];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BHArchivedProjectCell *cell = (BHArchivedProjectCell*)[tableView cellForRowAtIndexPath:indexPath];
    [cell scroll];
}

- (void)goToProject:(UIButton*)button {
    BHProject *selectedProject = [_archivedProjects objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"ArchivedProject" sender:selectedProject];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Project"]) {
        BHProject *project = (BHProject*)sender;
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
        //[vc setUser:savedUser];
    }
}

@end
