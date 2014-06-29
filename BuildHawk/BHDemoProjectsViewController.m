//
//  BHDemoProjectsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/12/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHDemoProjectsViewController.h"
#import "Project.h"
#import "BHDashboardProjectCell.h"
#import "BHTabBarViewController.h"
#import "BHProjectSynopsisViewController.h"
#import "BHAppDelegate.h"
#import "Company+helper.h"

@interface BHDemoProjectsViewController () {
    NSMutableArray *demoProjects;
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *recentChecklistItems;
    NSMutableArray *recentDocuments;
    NSMutableArray *recentlyCompletedWorklistItems;
    NSMutableArray *notifications;
    NSMutableArray *upcomingChecklistItems;
    NSMutableArray *phases;
    NSMutableDictionary *dashboardDetailDict;
    Project *archivedProject;
}

@end

@implementation BHDemoProjectsViewController
@synthesize currentUser = _currentUser;

- (void)viewDidLoad
{
    demoProjects = [NSMutableArray array];
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    dashboardDetailDict = [NSMutableDictionary dictionary];
    phases = [NSMutableArray array];
    demoProjects = [Project MR_findByAttribute:@"demo" withValue:[NSNumber numberWithBool:YES]].mutableCopy;
    [self loadDemos];
    self.title = @"Demo Projects";
    [super viewDidLoad];
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
    return demoProjects.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

- (void)loadDemos {
    [ProgressHUD show:@"Loading Demo Projects..."];
    [manager GET:[NSString stringWithFormat:@"%@/projects/demo",kApiBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"demo projects response object: %@",responseObject);
        [self updateProjects:[responseObject objectForKey:@"projects"]];
        [self loadDetailView];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error while loading demos: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading the demo projects. Please try again soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        //if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    }];
}

- (void)updateProjects:(NSArray*)projectsArray {
    for (id obj in projectsArray) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [obj objectForKey:@"id"]];
        Project *project = [Project MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!project) {
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            NSLog(@"Creating a new project for local storage: %@",project.name);
            [demoProjects addObject:project];
        }
        [project populateFromDictionary:obj];
    }
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"What happened during demo project save? %hhd %@",success, error);
        [self.tableView reloadData];
    }];

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Project *project = [demoProjects objectAtIndex:indexPath.row];
    static NSString *CellIdentifier = @"ProjectCell";
    BHDashboardProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardProjectCell" owner:self options:nil] lastObject];
    }
    [cell.titleLabel setText:[project name]];
    
    if (project.address.formattedAddress.length){
        [cell.subtitleLabel setText:project.address.formattedAddress];
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

- (void)loadDetailView {
    for (Project *proj in demoProjects){
        [phases removeAllObjects];
        [manager GET:[NSString stringWithFormat:@"%@/projects/dash",kApiBaseUrl] parameters:@{@"id":proj.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting dashboard detail view for demo projects: %@",[responseObject objectForKey:@"project"]);
            phases = [[[responseObject objectForKey:@"project"] objectForKey:@"phases"] mutableCopy];
            [dashboardDetailDict setObject:[responseObject objectForKey:@"project"] forKey:proj.identifier];
            if (dashboardDetailDict.count == demoProjects.count) {
                //NSLog(@"dashboard detail array after addition: %@, %i",dashboardDetailDict, dashboardDetailDict.count);
                [self.tableView reloadData];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure getting dashboard: %@",error.description);
            self.tableView.allowsSelection = YES;
        }];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
}

- (void)goToProject:(UIButton*)button {
    NSLog(@"should be going to project");
    Project *selectedProject = [demoProjects objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"Project" sender:selectedProject];
}
- (void)goToProjectDetail:(UIButton*)button {
    NSLog(@"should be going to detail");
    Project *selectedProject = [demoProjects objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"DashboardDetail" sender:selectedProject];
}

- (void)confirmArchive:(UIButton*)button{
    [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to archive this project? Once archived, a project can still be managed from the web, but will no longer be visible here." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Archive", nil] show];
    archivedProject = [demoProjects objectAtIndex:button.tag];
    BHDashboardProjectCell *cell = (BHDashboardProjectCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:button.tag inSection:0]];
    [cell.scrollView setContentOffset:CGPointZero animated:YES];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Archive"]){
        [self archiveProject];
    }
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
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[demoProjects indexOfObject:archivedProject] inSection:0];

            [_currentUser.company removeProject:archivedProject];
            
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to archive this project. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to archive the project: %@",error.description);
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        Project *selectedProject = [demoProjects objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"DashboardDetail" sender:selectedProject];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Project"]) {
        Project *project = (Project*)sender;
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
    } else if ([segue.identifier isEqualToString:@"DashboardDetail"]) {
        Project *project = (Project*)sender;
        BHProjectSynopsisViewController *detailVC = [segue destinationViewController];
        [detailVC setProject:project];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [ProgressHUD dismiss];
    [super viewWillDisappear:animated];
}

@end
