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
#import "BHDashboardDetailViewController.h"

@interface BHDemoProjectsViewController () {
    NSMutableArray *demoProjects;
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *recentChecklistItems;
    NSMutableArray *recentDocuments;
    NSMutableArray *recentlyCompletedWorklistItems;
    NSMutableArray *notifications;
    NSMutableArray *upcomingChecklistItems;
    NSMutableArray *categories;
    NSMutableDictionary *dashboardDetailDict;
}

@end

@implementation BHDemoProjectsViewController

- (void)viewDidLoad
{
    demoProjects = [NSMutableArray array];
    manager = [AFHTTPRequestOperationManager manager];
    dashboardDetailDict = [NSMutableDictionary dictionary];
    categories = [NSMutableArray array];
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
        NSLog(@"demo projects response object: %@",responseObject);
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
            project = [Project MR_createEntity];
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
    } else {
        [cell.subtitleLabel setText:project.company.name];
    }
    
    [cell.progressLabel setText:project.progressPercentage];
    
    [cell.projectButton setTag:indexPath.row];
    [cell.projectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
    [cell.titleLabel setTextColor:kDarkGrayColor];
    [cell.archiveButton setTag:indexPath.row];
    [cell.archiveButton addTarget:self action:@selector(confirmArchive:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (void)loadDetailView {
    for (Project *proj in demoProjects){
        [categories removeAllObjects];
        [manager GET:[NSString stringWithFormat:@"%@/projects/dash",kApiBaseUrl] parameters:@{@"id":proj.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success getting dashboard detail view for demo projects: %@",[responseObject objectForKey:@"project"]);
            categories = [[[responseObject objectForKey:@"project"] objectForKey:@"categories"] mutableCopy];
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

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [ProgressHUD dismiss];
    }
}

- (void)goToProject:(UIButton*)button {
    Project *selectedProject = [demoProjects objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"Project" sender:selectedProject];
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
    if ([segue.identifier isEqualToString:@"Project"]) {
        Project *project = (Project*)sender;
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
    } else if ([segue.identifier isEqualToString:@"DashboardDetail"]) {
        Project *project = (Project*)sender;
        BHDashboardDetailViewController *detailVC = [segue destinationViewController];
        [detailVC setProject:project];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [ProgressHUD dismiss];
    [super viewWillDisappear:animated];
}

@end
