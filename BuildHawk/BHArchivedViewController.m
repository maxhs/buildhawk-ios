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
#import "Address.h"
#import "Company.h"
#import "User+helper.h"
#import "BHAppDelegate.h"
#import <RESideMenu/RESideMenu.h>
#import "BHDashboardViewController.h"

@interface BHArchivedViewController (){
    Project *archivedProject;
    AFHTTPRequestOperationManager *manager;
    UIBarButtonItem *backButton;
    BOOL loading;
}
@end

@implementation BHArchivedViewController
@synthesize currentUser = _currentUser;

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    loading = YES;
    [self loadArchived];
}

- (void)loadArchived {
    [ProgressHUD show:@"Loading archived projects..."];
    [manager GET:[NSString stringWithFormat:@"%@/projects/archived",kApiBaseUrl] parameters:@{@"user_id":_currentUser.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success fetching archived projects: %@",responseObject);
        NSMutableOrderedSet *archivedProjectSet = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *projectDict in [responseObject objectForKey:@"projects"]){
            Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:(NSNumber*)[projectDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (project){
                [project update:projectDict];
            } else {
                project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [project populateFromDictionary:projectDict];
            [archivedProjectSet addObject:project];
        }
        _currentUser.archivedProjects = archivedProjectSet;
        loading = NO;
        [self.tableView reloadData];
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get archived projects: %@",error.description);
        [ProgressHUD dismiss];
    }];
}

- (void)back {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
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
    if (!loading && _currentUser.archivedProjects.count == 0){
        return 1;
    } else {
        return _currentUser.archivedProjects.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_currentUser.archivedProjects.count == 0){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NothingCell"];
        [cell.textLabel setText:@"No archived projects..."];
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        [cell.textLabel setFont:[UIFont italicSystemFontOfSize:17]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        return cell;
    } else {
        static NSString *CellIdentifier = @"ArchivedCell";
        Project *project = [_currentUser.archivedProjects objectAtIndex:indexPath.row];
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
}

- (void)confirmUnarchive:(UIButton*)button {
    [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to make this project active?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Activate", nil] show];
    archivedProject = [_currentUser.archivedProjects objectAtIndex:button.tag];
}

- (void)unarchiveProject{
    [manager POST:[NSString stringWithFormat:@"%@/projects/%@/unarchive",kApiBaseUrl,archivedProject.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully unarchived the project: %@",responseObject);
        [_currentUser unarchiveProject:archivedProject];
        [_currentUser addProject:archivedProject];
        if (_currentUser.archivedProjects.count == 0) {
            //run down the view hierarchy to find the Dashboard vc and reload the tableview.
            if ([self.presentingViewController isKindOfClass:[RESideMenu class]]){
                [[(UINavigationController*)[(RESideMenu*)self.presentingViewController contentViewController] viewControllers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([obj isKindOfClass:[BHDashboardViewController class]]){
                        [[(BHDashboardViewController*)obj tableView] reloadData];
                        *stop = YES;
                    }
                }];
            }
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                
            }];
        } else{
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
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
        [ProgressHUD dismiss];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BHArchivedProjectCell *cell = (BHArchivedProjectCell*)[tableView cellForRowAtIndexPath:indexPath];
    [cell scroll];
}

- (void)goToProject:(UIButton*)button {
    Project *selectedProject = [_currentUser.archivedProjects objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"ArchivedProject" sender:selectedProject];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"ArchivedProject"]) {
        Project *project = (Project*)sender;
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
        [vc setUser:_currentUser];
    }
}

@end
