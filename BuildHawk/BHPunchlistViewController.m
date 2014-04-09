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
#import "UIButton+WebCache.h"
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"
#import "Flurry.h"
#import "Project.h"

@interface BHPunchlistViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
    NSMutableArray *listItems;
    NSDateFormatter *dateFormatter;
    AFHTTPRequestOperationManager *manager;
    BHProject *project;
    NSMutableArray *activeListItems;
    NSMutableArray *completedListItems;
    NSMutableArray *locationListItems;
    NSMutableSet *locationSet;
    NSMutableArray *assigneeListItems;
    NSMutableSet *assigneeSet;
    UIActionSheet *locationActionSheet;
    UIActionSheet *assigneeActionSheet;
    UIRefreshControl *refreshControl;
    BOOL showCompleted;
    BOOL showActive;
    BOOL showByLocation;
    BOOL showByAssignee;
    BOOL iOS7;
    BOOL firstLoad;
    Project *savedProject;
    NSMutableArray *personnel;
}
@end

@implementation BHPunchlistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    project =[(BHTabBarViewController*)self.tabBarController project];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Worklists",project.name];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.rowHeight = 82;
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
        iOS7 = YES;
    } else {
        iOS7 = NO;
    }
    firstLoad = YES;
    [self.segmentedControl setTintColor:kDarkGrayColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    if (!manager) manager = [AFHTTPRequestOperationManager manager];
    //if (!listItems) listItems = [NSMutableArray array];
    if (!completedListItems) completedListItems = [NSMutableArray array];
    if (!activeListItems) activeListItems = [NSMutableArray array];
    if (!locationListItems) locationListItems = [NSMutableArray array];
    if (!assigneeListItems) assigneeListItems = [NSMutableArray array];
    if (!locationSet) locationSet = [NSMutableSet set];
    if (!assigneeSet) assigneeSet = [NSMutableSet set];
    if (!personnel) personnel = [NSMutableArray array];
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    [Flurry logEvent:@"Viewing punchlist"];
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", project.identifier];
    savedProject = [Project MR_findFirstWithPredicate:predicate inContext:localContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createItem) name:@"CreatePunchlistSegue" object:nil];
}

- (void)createItem {
    [self performSegueWithIdentifier:@"CreateItem" sender:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [SVProgressHUD showWithStatus:@"Getting Worklist..."];
    [self loadPunchlist];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowCreatePunchlist" object:nil];
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
    [activeListItems removeAllObjects];
    showCompleted = NO;
    showByAssignee = NO;
    showByLocation = NO;
    showActive = NO;
    switch (sender.selectedSegmentIndex) {
        case 0:
            showActive = YES;
            [self filterActive];
            break;
        case 1:
            showByLocation = YES;
            [self filterLocation];
            break;
        case 2:
            showByAssignee = YES;
            [self filterAssignee];
            break;
        case 3:
            showCompleted = YES;
            [self filterCompleted];
            break;
        default:
            break;
    }
}

- (void)handleRefresh:(id)sender {
    firstLoad = YES;
    [SVProgressHUD showWithStatus:@"Refreshing..."];
    [self loadPunchlist];
}

- (void)filterLocation {
    locationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Location" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString *location in locationSet.allObjects) {
        [locationActionSheet addButtonWithTitle:location];
    }
    locationActionSheet.cancelButtonIndex = [locationActionSheet addButtonWithTitle:@"Cancel"];
    [locationActionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)filterAssignee {
    assigneeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assignees" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (id assignee in personnel) {
        if ([assignee isKindOfClass:[BHUser class]] && [[(BHUser*)assignee fullname] length]) [assigneeActionSheet addButtonWithTitle:[(BHUser*)assignee fullname]];
        else if ([assignee isKindOfClass:[BHSub class]] && [[(BHSub*)assignee name] length]) [assigneeActionSheet addButtonWithTitle:[(BHSub*)assignee name]];
    }
    assigneeActionSheet.cancelButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Cancel"];
    [assigneeActionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)filterActive {
    for (BHPunchlistItem *item in listItems){
        if(!item.completed) {
            [activeListItems addObject:item];
        }
    }
    [self.tableView reloadData];
}

- (void)filterCompleted {
    for (BHPunchlistItem *item in listItems){
        if(item.completed) {
            [completedListItems addObject:item];
        }
    }
    [self.tableView reloadData];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == assigneeActionSheet) {
        //[assigneeListItems removeAllObjects];
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] length]) {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
            if (buttonTitle.length){
                NSPredicate *testForFullName = [NSPredicate predicateWithFormat:@"fullname like %@",buttonTitle];
                NSPredicate *testForName = [NSPredicate predicateWithFormat:@"name like %@",buttonTitle];
                for (BHPunchlistItem *item in listItems){
                    id obj = item.assignees.firstObject;
                    if ([obj isKindOfClass:[BHSub class]]) {
                        if([testForName evaluateWithObject:obj]) {
                            [assigneeListItems addObject:item];
                        }
                    } else if ([obj isKindOfClass:[BHUser class]]){
                        if([testForFullName evaluateWithObject:obj]) {
                            [assigneeListItems addObject:item];
                        }
                    }
                }
            }
            [self.tableView reloadData];
        }
    } else if (actionSheet == locationActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] length]) {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
            NSPredicate *testForLocation = [NSPredicate predicateWithFormat:@"location like %@",buttonTitle];
            for (BHPunchlistItem *item in listItems){
                if([testForLocation evaluateWithObject:item]) {
                    [locationListItems addObject:item];
                }
            }
            [self.tableView reloadData];
        }
    }
}

- (void)loadPunchlist {
    
    [manager GET:[NSString stringWithFormat:@"%@/punchlists/%@", kApiBaseUrl,project.identifier] parameters:@{@"id":project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading punchlist: %@",responseObject);
        [listItems removeAllObjects];
        listItems = [BHUtilities punchlistItemsFromJSONArray:[[responseObject objectForKey:@"punchlist"] objectForKey:@"punchlist_items"]];
        personnel = [BHUtilities personnelFromJSONArray:[[responseObject objectForKey:@"punchlist"] objectForKey:@"personnel"]];
        
        [activeListItems removeAllObjects];
        for (BHPunchlistItem *item in listItems){
            if(!item.completed) {
                [activeListItems addObject:item];
            }
            if (item.location.length) {
                [locationSet addObject:item.location];
            }
            if (item.assignees) {
                [assigneeSet addObject:item.assignees.firstObject];
            }
        }
        if (firstLoad){
            showActive = YES;
            firstLoad = NO;
        }
        [self.tableView reloadData];
        [SVProgressHUD dismiss];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error loading worklists: %@",error.description);
        [SVProgressHUD dismiss];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your worklist. Please try again soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (completedListItems.count || showCompleted) return completedListItems.count;
    else if (activeListItems.count || showActive) return activeListItems.count;
    else if (locationListItems.count || showByLocation) return locationListItems.count;
    else if (assigneeListItems.count || showByAssignee) return assigneeListItems.count;
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
    if (completedListItems.count || showCompleted) {
        item = [completedListItems objectAtIndex:indexPath.row];
    } else if (activeListItems.count || showActive) {
        item = [activeListItems objectAtIndex:indexPath.row];
    } else if (locationListItems.count || showByLocation) {
        item = [locationListItems objectAtIndex:indexPath.row];
    } else if (assigneeListItems.count || showByAssignee) {
        item = [assigneeListItems objectAtIndex:indexPath.row];
    } else {
        item = [listItems objectAtIndex:indexPath.row];
    }
    [cell.itemLabel setText:item.body];
    [cell.itemLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:19]];
    cell.itemLabel.numberOfLines = 0;

    if (item.photos.count) {
        [cell.photoButton setImageWithURL:[NSURL URLWithString:[[item.photos firstObject] url100]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"]];
    } else {
        [cell.photoButton setImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"] forState:UIControlStateNormal];
    }
    cell.photoButton.imageView.layer.cornerRadius = 2.0;
    [cell.photoButton.imageView setBackgroundColor:[UIColor clearColor]];
    [cell.photoButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    cell.photoButton.imageView.layer.shouldRasterize = YES;
    cell.photoButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [cell.photoButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    cell.photoButton.clipsToBounds = YES;
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
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
        [vc setTitle:@"New Item"];
        [vc setNewItem:YES];
        [vc setProject:project];
        [vc setLocationSet:locationSet];
        //if (savedUser)[vc setSavedUser:savedUser];
    } else if ([segue.identifier isEqualToString:@"PunchlistItem"]) {
        BHPunchlistItemViewController *vc = segue.destinationViewController;
        [vc setProject:project];
        [vc setNewItem:NO];
        BHPunchlistItem *item;
        if (showActive && activeListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [activeListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showByLocation && locationListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [locationListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showByAssignee && assigneeListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [assigneeListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showCompleted && completedListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [completedListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (listItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [listItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        }
        [vc setTitle:[NSString stringWithFormat:@"%@",item.createdOn]];
        [vc setPunchlistItem:item];
        [vc setLocationSet:locationSet];
        //if (savedUser)[vc setSavedUser:savedUser];
    }
        
}

@end
