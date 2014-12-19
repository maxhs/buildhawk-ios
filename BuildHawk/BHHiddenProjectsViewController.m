//
//  BHHiddenProjectsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHHiddenProjectsViewController.h"
#import "BHHiddenProjectCell.h"
#import "BHTabBarViewController.h"
#import "Address.h"
#import "Company.h"
#import "User+helper.h"
#import "BHAppDelegate.h"
#import <RESideMenu/RESideMenu.h>
#import "BHDashboardViewController.h"

@interface BHHiddenProjectsViewController (){
    Project *hiddenProject;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UIBarButtonItem *backButton;
    BOOL loading;
}
@end

@implementation BHHiddenProjectsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    self.tableView.rowHeight = 88.f;
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    loading = YES;
    _currentUser = [(BHAppDelegate*)[UIApplication sharedApplication].delegate currentUser];
    [self loadHiddenProjects];
}

- (void)loadHiddenProjects {
    if (_currentUser){
        [ProgressHUD show:@"Loading hidden projects..."];
        [manager GET:[NSString stringWithFormat:@"%@/projects/hidden",kApiBaseUrl] parameters:@{@"user_id":_currentUser.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success fetching hidden projects: %@",responseObject);
            NSMutableOrderedSet *hiddenProjectSet = [NSMutableOrderedSet orderedSet];
            for (NSDictionary *projectDict in [responseObject objectForKey:@"projects"]){
                Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:[projectDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (project){
                    [project updateFromDictionary:projectDict];
                } else {
                    project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [project populateFromDictionary:projectDict];
                }
                
                [hiddenProjectSet addObject:project];
            }
            _currentUser.hiddenProjects = hiddenProjectSet;
            loading = NO;
            
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get hidden projects: %@",error.description);
            [ProgressHUD dismiss];
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load your hidden projects. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)back {
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if ([self.presentingViewController isKindOfClass:[RESideMenu class]]){
            [[(UINavigationController*)[(RESideMenu*)self.presentingViewController contentViewController] viewControllers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                //don't add the project to the dashboard projects list if it's in a group
                if ([obj isKindOfClass:[BHDashboardViewController class]]){
                    BHDashboardViewController *vc = (BHDashboardViewController*)obj;
                    [vc loadProjects];
                    *stop = YES;
                }
            }];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (loading){
        return 0;
    } else if (_currentUser.hiddenProjects.count == 0){
        return 1;
    } else {
        return _currentUser.hiddenProjects.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!loading && _currentUser.hiddenProjects.count == 0){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NothingCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.textLabel setText:@"No hidden projects..."];
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProIt] size:0]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        return cell;
    } else {
        static NSString *CellIdentifier = @"HiddenProjectCell";
        Project *project = [_currentUser.hiddenProjects objectAtIndex:indexPath.row];
        BHHiddenProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [cell.titleLabel setText:[project name]];
        if (project.address.formattedAddress.length){
            [cell.subtitleLabel setText:project.address.formattedAddress];
        } else {
            [cell.subtitleLabel setText:project.company.name];
        }
        
        [cell.projectButton setTag:project.identifier.integerValue];
        [cell.projectButton addTarget:self action:@selector(confirmActivate:) forControlEvents:UIControlEventTouchUpInside];
        //[cell.projectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
        [cell.titleLabel setTextColor:kDarkGrayColor];
        [cell.unhideButton setTag:project.identifier.integerValue];
        [cell.unhideButton addTarget:self action:@selector(confirmActivate:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
}

- (void)confirmActivate:(UIButton*)button {
    [[[UIAlertView alloc] initWithTitle:@"Hidden Project" message:@"This project is currently hidden. You can activate this project to take a closer look." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Activate", nil] show];
    hiddenProject = [Project MR_findFirstByAttribute:@"identifier" withValue:[NSNumber numberWithInteger:button.tag]];
}

- (void)activateProject {
    [ProgressHUD show:[NSString stringWithFormat:@"Activating %@...",hiddenProject.name]];
    [manager POST:[NSString stringWithFormat:@"%@/projects/%@/activate",kApiBaseUrl,hiddenProject.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Successfully activated the project: %@",responseObject);
        
        NSIndexPath *indexPathToHide = [NSIndexPath indexPathForRow:[_currentUser.hiddenProjects indexOfObject:hiddenProject] inSection:0];
        [_currentUser activateProject:hiddenProject];
        [_currentUser addProject:hiddenProject];
        
        [ProgressHUD dismiss];
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfAndWait];
        
        //run down the view hierarchy to find the Dashboard vc and reload the tableview.
        if ([self.presentingViewController isKindOfClass:[RESideMenu class]]){
            [[(UINavigationController*)[(RESideMenu*)self.presentingViewController contentViewController] viewControllers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                //don't add the project to the dashboard projects list if it's in a group
                if ([obj isKindOfClass:[BHDashboardViewController class]] && !hiddenProject.group){
                    BHDashboardViewController *vc = (BHDashboardViewController*)obj;
                    [vc.projects addObject:hiddenProject];
                    [vc.tableView reloadData];
                    *stop = YES;
                }
            }];
        }
        
        if (_currentUser.hiddenProjects.count == 0) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                
            }];
        } else {
            
            //update the UI
            [self.tableView beginUpdates];
            if ([self.tableView cellForRowAtIndexPath:indexPathToHide] != nil){
                [self.tableView deleteRowsAtIndexPaths:@[indexPathToHide] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            }
            [self.tableView endUpdates];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to unhide this project. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to unhide the project: %@",error.description);
    }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Activate"]){
        [self activateProject];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [ProgressHUD dismiss];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"did select");
    if ([cell isKindOfClass:[BHHiddenProjectCell class]]){
        [(BHHiddenProjectCell*)cell scroll];
    }
}

- (void)goToProject:(UIButton*)button {
    Project *selectedProject = [Project MR_findFirstByAttribute:@"identifier" withValue:[NSNumber numberWithInteger:button.tag]];
    [self performSegueWithIdentifier:@"HiddenProject" sender:selectedProject];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"HiddenProject"]) {
        Project *project = (Project*)sender;
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:project];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
