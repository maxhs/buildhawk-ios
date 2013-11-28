//
//  BHPunchlistViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPunchlistViewController.h"
#import "BHPunchlistItemCell.h"
#import "BHPunchlistItemViewController.h"
#import "BHPunchlistItem.h"
#import "BHPunchlist.h"
#import "BHPhoto.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <SDWebImage/UIButton+WebCache.h>
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"
#import "Flurry.h"

@interface BHPunchlistViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
    NSMutableArray *listItems;
    NSDateFormatter *dateFormatter;
    AFHTTPRequestOperationManager *manager;
    BHProject *project;
    NSMutableArray *completedListItems;
    NSMutableArray *locationListItems;
    NSMutableSet *locationSet;
    NSMutableArray *assigneeListItems;
    NSMutableSet *assigneeSet;
    UIActionSheet *locationActionSheet;
    UIActionSheet *assigneeActionSheet;
}
- (IBAction)backToDashboard;
@end

@implementation BHPunchlistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    project =[(BHTabBarViewController*)self.tabBarController project];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Worklists",project.name];
    self.tableView.tableHeaderView = self.segmentContainerView;
    if (!listItems) listItems = [NSMutableArray array];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    [self.segmentedControl setTintColor:kDarkGrayColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    [self.segmentedControl setSelectedSegmentIndex:0];
    if (!manager) manager = [AFHTTPRequestOperationManager manager];
    if (!completedListItems) completedListItems = [NSMutableArray array];
    if (!locationListItems) locationListItems = [NSMutableArray array];
    if (!assigneeListItems) assigneeListItems = [NSMutableArray array];
    if (!locationSet) locationSet = [NSMutableSet set];
    if (!assigneeSet) assigneeSet = [NSMutableSet set];
    [Flurry logEvent:@"Viewing punchlist"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [SVProgressHUD showWithStatus:@"Fetching worklists..."];
    [self loadPunchlist];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)segmentedControlTapped:(UISegmentedControl*)sender {
    [completedListItems removeAllObjects];
    [locationListItems removeAllObjects];
    [assigneeListItems removeAllObjects];
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self.tableView reloadData];
            break;
        case 1:
            [self filterLocation];
            break;
        case 2:
            [self filterAssignee];
            break;
        case 3:
            [self filterCompleted];
            break;
        default:
            break;
    }
}

- (void)filterLocation {
    NSLog(@"Should be filtering by location");
    locationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assignees" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString *location in locationSet.allObjects) {
        [locationActionSheet addButtonWithTitle:location];
    }
    locationActionSheet.cancelButtonIndex = [locationActionSheet addButtonWithTitle:@"Cancel"];
    [locationActionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)filterAssignee {
    NSLog(@"Should be filtering by subcontractor");
    assigneeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assignees" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (BHUser *assignee in assigneeSet.allObjects) {
        NSLog(@"assignee: %@",assignee);
        if (assignee.fullname.length) [assigneeActionSheet addButtonWithTitle:assignee.fullname];
    }
    assigneeActionSheet.cancelButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Cancel"];
    [assigneeActionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)filterCompleted {
    NSLog(@"Should be filtering by completion");
    NSPredicate *testForTrue = [NSPredicate predicateWithFormat:@"completed == YES"];
    for (BHPunchlistItem *item in listItems){
        if([testForTrue evaluateWithObject:item.completed]) {
            [completedListItems addObject:item];
        }
    }
    [self.tableView reloadData];
}

- (void)loadPunchlist {
    [manager GET:[NSString stringWithFormat:@"%@/punchlists", kApiBaseUrl] parameters:@{@"pid":project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success loading punchlist: %@",responseObject);
        listItems = [BHUtilities punchlistItemsFromJSONArray:[responseObject objectForKey:@"rows"]];
        [self.tableView reloadData];
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error loading worklists: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your worklist. Please try again soon" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (completedListItems.count) return completedListItems.count;
    else if (locationListItems.count) return locationListItems.count;
    else if (assigneeListItems.count) return assigneeListItems.count;
    else return listItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PunchlistItemCell";
    BHPunchlistItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPunchlistItemCell" owner:self options:nil] lastObject];
    }
    
    BHPunchlistItem *item;
    if (completedListItems.count) {
        item = [completedListItems objectAtIndex:indexPath.row];
    } else if (locationListItems.count) {
        item = [locationListItems objectAtIndex:indexPath.row];
    } else if (assigneeListItems.count) {
        item = [assigneeListItems objectAtIndex:indexPath.row];
    } else {
        item = [listItems objectAtIndex:indexPath.row];
        if (item.location.length) {
            [locationSet addObject:item.location];
        }
        if (item.assignees) {
            [assigneeSet addObject:item.assignees.firstObject];
        }
    }
    [cell.itemLabel setText:item.name];
    [cell.itemLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:18]];
    cell.itemLabel.numberOfLines = 0;
    if (item.completedPhotos.count) {
        [cell.photoButton setImageWithURL:[NSURL URLWithString:[[item.completedPhotos firstObject] url200]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"]];
    } else if (item.createdPhotos.count) {
        [cell.photoButton setImageWithURL:[NSURL URLWithString:[[item.createdPhotos firstObject] url200]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"]];
    } else {
        [cell.photoButton setImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"] forState:UIControlStateNormal];
    }
    cell.photoButton.imageView.layer.cornerRadius = 3.0;
    [cell.photoButton.imageView setBackgroundColor:[UIColor clearColor]];
    [cell.photoButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    cell.photoButton.imageView.layer.shouldRasterize = YES;
    cell.photoButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [cell.photoButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    cell.photoButton.clipsToBounds = YES;
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"PunchlistItem" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CreateItem"]) {
        BHPunchlistItemViewController *vc = segue.destinationViewController;
        [vc setTitle:@"Add Item"];
        [vc setNewItem:YES];
    } else if ([segue.identifier isEqualToString:@"PunchlistItem"]) {
        BHPunchlistItemViewController *vc = segue.destinationViewController;
        [vc setNewItem:NO];
        BHPunchlistItem *item = [listItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        [vc setTitle:[NSString stringWithFormat:@"%@",item.createdOn]];
        [vc setPunchlistItem:item];
        [vc setProject:project];
    }
        
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
