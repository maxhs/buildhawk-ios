//
//  BHTasksViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHTasksViewController.h"
#import "BHTaskCell.h"
#import "BHTaskViewController.h"
#import "WorklistItem+helper.h"
#import "Worklist+helper.h"
#import "Photo.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "UIButton+WebCache.h"
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"
#import "Flurry.h"
#import "Project.h"
#import "BHOverlayView.h"
#import "Subcontractor.h"
#import "Company.h"
#import "ConnectUser+helper.h"

@interface BHTasksViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
    NSDateFormatter *dateFormatter;
    AFHTTPRequestOperationManager *manager;
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
    BOOL firstLoad;
    BOOL loading;
    UIBarButtonItem *addButton;
    UIView *overlayBackground;
    UIImageView *worklistScreenshot;
    NSInteger lastSegmentIndex;
    NSIndexPath *indexPathForDeletion;
}
@end

@implementation BHTasksViewController
@synthesize project = _project;
@synthesize worklistItems = _worklistItems;

- (void)viewDidLoad {
    [super viewDidLoad];
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    if (!_project) _project = [(BHTabBarViewController*)self.tabBarController project];
    self.navigationItem.title = [NSString stringWithFormat:@"Tasks: %@",_project.name];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.rowHeight = 82;
    showActive = YES;
    showCompleted = NO;
    showByAssignee = NO;
    showByLocation = NO;
    firstLoad = YES;
    
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createItem)];
    [self.segmentedControl setTintColor:kDarkGrayColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    
    completedListItems = [NSMutableArray array];
    activeListItems = [NSMutableArray array];
    locationListItems = [NSMutableArray array];
    assigneeListItems = [NSMutableArray array];
    locationSet = [NSMutableSet set];
    assigneeSet = [NSMutableSet set];
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    [Flurry logEvent:@"Viewing task"];
    
    if (_connectMode){
        _worklistItems = _project.userConnectItems.array.mutableCopy;
        [self drawWorklist];
    } else if ([_project.worklist.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        [ProgressHUD show:@"Getting tasks..."];
        loading = YES;
        [self loadWorklist];
    } else {
        loading = YES;
        _worklistItems = _project.worklist.worklistItems.array.mutableCopy;
        [self drawWorklist];
        [self loadWorklist];
    }
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTask:) name:@"ReloadTask" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addTask:) name:@"AddTask" object:nil];
}

- (void)createItem {
    [self performSegueWithIdentifier:@"CreateItem" sender:nil];
}

- (void)addTask:(NSNotification*)notification {
    WorklistItem *newItem = [notification.userInfo objectForKey:@"task"];
    [_worklistItems insertObject:newItem atIndex:0];
    firstLoad = YES;
    [self drawWorklist];
}

- (void)reloadTask:(NSNotification*)notification {
    NSDictionary *userInfo = notification.userInfo;
    WorklistItem *notificationTask = [userInfo objectForKey:@"task"];
    //NSLog(@"notification task: %@",notificationTask);
    if ([notificationTask.completed isEqualToNumber:[NSNumber numberWithBool:YES]]){
        if (![completedListItems containsObject:notificationTask]){
            [completedListItems insertObject:notificationTask atIndex:0];
        }
        [_segmentedControl setSelectedSegmentIndex:3];
        [self resetSegments];
        showCompleted = YES;
        [self filterCompleted];
    } else {
        showActive = YES;
        [_segmentedControl setSelectedSegmentIndex:0];
        [self resetSegments];
        showActive = YES;
        
        if (![_worklistItems containsObject:notificationTask]){
            [_worklistItems addObject:notificationTask];
        }
        [self filterActive];
    }
    
    //add the location to the list of possible locations:
    if (notificationTask.location.length){
        [locationSet addObject:notificationTask.location];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_connectMode && self.segmentedControl.numberOfSegments == 4){
        [self.segmentedControl removeSegmentAtIndex:2 animated:NO];
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenWorklist]){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlayUnderNav:NO];
        [self slide1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenWorklist];
    }
    if (!_connectMode){
        self.tabBarController.navigationItem.rightBarButtonItem = addButton;
    }
}

- (void)drawWorklist {
    if (_worklistItems.count > 0){
        [activeListItems removeAllObjects];
        [completedListItems removeAllObjects];
        [locationSet removeAllObjects];
        [assigneeSet removeAllObjects];
        
        for (WorklistItem *item in _worklistItems){
            if([item.completed isEqualToNumber:[NSNumber numberWithBool:NO]]) {
                [activeListItems addObject:item];
            }
            if (item.location.length) {
                [locationSet addObject:item.location];
            }
            if (!_connectMode) {
                if (item.assignees.count > 0){
                    [assigneeSet addObject:item.assignees.firstObject];
                } else if (item.connectAssignees.count > 0){
                    [assigneeSet addObject:item.connectAssignees.firstObject];
                }
            }
        }
    }

    loading = NO;
    if (showActive){
        [self filterActive];
    } else if (showByAssignee){
        [self.tableView reloadData];
    } else if (showByLocation){
        [self.tableView reloadData];
    } else if (showCompleted){
        [self filterCompleted];
    } else {
        [self.tableView reloadData];
    }
    [ProgressHUD dismiss];
    if (refreshControl.isRefreshing) [refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)segmentedControlTapped:(UISegmentedControl*)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            if (showActive == YES){
                [self resetSegments];
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                [self.tableView reloadData];
            } else {
                [self resetSegments];
                showActive = YES;
                [self filterActive];
            }
            
            break;
        case 1:
            if (showByLocation == YES){
                [self resetSegments];
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                [self.tableView reloadData];
            } else {
                [self resetSegments];
                showByLocation = YES;
                [self filterLocation];
            }
            
            break;
        case 2:
            if (_connectMode){
                //not necessary to show assignee during connect mode
                if (showCompleted == YES){
                    [self resetSegments];
                    [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                    [self.tableView reloadData];
                } else {
                    [self resetSegments];
                    showCompleted = YES;
                    [self filterCompleted];
                }
            } else {
                if (showByAssignee == YES){
                    [self resetSegments];
                    [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                    [self.tableView reloadData];
                } else {
                    [self resetSegments];
                    showByAssignee = YES;
                    [self filterAssignee];
                }
            }
            
            break;
        case 3:
            if (showCompleted == YES){
                [self resetSegments];
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                [self.tableView reloadData];
            } else {
                [self resetSegments];
                showCompleted = YES;
                [self filterCompleted];
            }
            
            break;
        default:
            break;
    }
}

- (void)resetSegments {
    [completedListItems removeAllObjects];
    [locationListItems removeAllObjects];
    [assigneeListItems removeAllObjects];
    [activeListItems removeAllObjects];
    showCompleted = NO;
    showByAssignee = NO;
    showByLocation = NO;
    showActive = NO;
}

- (void)handleRefresh {
    [ProgressHUD show:@"Refreshing..."];
    if (_connectMode){
        [self connectRefresh];
    } else {
        [self loadWorklist];
    }
}

- (void)connectRefresh {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([(WorklistItem*)_worklistItems.firstObject project]){
        [parameters setObject:[[(WorklistItem*)_worklistItems.firstObject project] identifier] forKey:@"project_id"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
        
    [_worklistItems removeAllObjects];
    [manager GET:[NSString stringWithFormat:@"%@/connect",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success with connect refresh: %@",responseObject);
        
        for (NSDictionary *dict in [responseObject objectForKey:@"worklist_items"]){
            WorklistItem *item = [WorklistItem MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!item){
                item = [WorklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [item populateFromDictionary:dict];
            [_worklistItems addObject:item];
        }
        [self drawWorklist];
        [ProgressHUD dismiss];
        if (refreshControl.isRefreshing)[refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        if (refreshControl.isRefreshing)[refreshControl endRefreshing];
        NSLog(@"Failure with connect refresh: %@",error.description);
    }];
}

- (void)filterLocation {
    if (locationSet.allObjects.count){
        locationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Location" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        for (NSString *location in locationSet.allObjects) {
            [locationActionSheet addButtonWithTitle:location];
        }
        locationActionSheet.cancelButtonIndex = [locationActionSheet addButtonWithTitle:@"Cancel"];
        if (self.tabBarController){
            [locationActionSheet showFromTabBar:self.tabBarController.tabBar];
        } else {
            [locationActionSheet showInView:self.view];
        }
    }
}

- (void)filterAssignee {
    if (assigneeSet.count){
        assigneeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assignees" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        for (id assignee in assigneeSet) {
            if ([assignee isKindOfClass:[User class]] && [[(User*)assignee fullname] length]) {
                [assigneeActionSheet addButtonWithTitle:[(User*)assignee fullname]];
            } else if ([assignee isKindOfClass:[ConnectUser class]]){
                [assigneeActionSheet addButtonWithTitle:[(ConnectUser*)assignee fullname]];
            }
        }
        assigneeActionSheet.cancelButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Cancel"];
        if (self.tabBarController){
            [assigneeActionSheet showFromTabBar:self.tabBarController.tabBar];
        } else {
            [assigneeActionSheet showInView:self.view];
        }
    }
}

- (void)filterActive {
    [activeListItems removeAllObjects];
    for (WorklistItem *item in _worklistItems){
        if([item.completed isEqualToNumber:[NSNumber numberWithBool:NO]]) {
            [activeListItems addObject:item];
        }
    }
    [self.tableView reloadData];
    lastSegmentIndex = self.segmentedControl.selectedSegmentIndex;
}

- (void)filterCompleted {
    [completedListItems removeAllObjects];
    for (WorklistItem *item in _worklistItems){
        if([item.completed isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            [completedListItems addObject:item];
        }
    }
    [self.tableView reloadData];
    lastSegmentIndex = self.segmentedControl.selectedSegmentIndex;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex == buttonIndex){
        [self.segmentedControl setSelectedSegmentIndex:lastSegmentIndex];
        [self segmentedControlTapped:self.segmentedControl];
    } else if (actionSheet == assigneeActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] length]) {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
            if (buttonTitle.length){
                NSPredicate *testForFullName = [NSPredicate predicateWithFormat:@"fullname like %@",buttonTitle];
                for (WorklistItem *item in _worklistItems){
                    //testing both users and connect users since both have a "fullname" attribute
                    if (item.assignees.count && [testForFullName evaluateWithObject:item.assignees.firstObject]){
                        [assigneeListItems addObject:item];
                    } else if (item.connectAssignees.count && [testForFullName evaluateWithObject:item.connectAssignees.firstObject]) {
                        [assigneeListItems addObject:item];
                    }
                }
            }
            [self.tableView reloadData];
            lastSegmentIndex = self.segmentedControl.selectedSegmentIndex;
        }
    } else if (actionSheet == locationActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] length]) {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
            NSPredicate *testForLocation = [NSPredicate predicateWithFormat:@"location like %@",buttonTitle];
            for (WorklistItem *item in _worklistItems){
                if([testForLocation evaluateWithObject:item]) {
                    [locationListItems addObject:item];
                }
            }
            [self.tableView reloadData];
            lastSegmentIndex = self.segmentedControl.selectedSegmentIndex;
        }
    }
}

- (void)loadWorklist {
    [manager GET:[NSString stringWithFormat:@"%@/worklists", kApiBaseUrl] parameters:@{@"project_id":_project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading worklist: %@",responseObject);
        if ([responseObject objectForKey:@"worklist"]) {
            [self updateWorklist:[responseObject objectForKey:@"worklist"]];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error loading worklists: %@",error.description);
        [ProgressHUD dismiss];
        loading = NO;
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    }];
}

- (void)updateWorklist:(NSDictionary*)dictionary {
    Worklist *worklist = [Worklist MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
    if (!worklist){
        worklist = [Worklist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    }
    [worklist populateFromDictionary:dictionary];
    if (_project.worklist.worklistItems.count > 0){
        for (WorklistItem *item in _project.worklist.worklistItems) {
            if (![worklist.worklistItems containsObject:item]) {
                NSLog(@"Deleting a task that no longer exists: %@",item.body);
                [item MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
    }
    if (_project){
        _project.worklist = worklist;
        _worklistItems = worklist.worklistItems.array.mutableCopy;
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"Worklist save: %hhd",success);
        //only bother drawing if the view is loaded
        if (self.isViewLoaded && self.view.window){
            [self drawWorklist];
        } else {
            [ProgressHUD dismiss];
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
    if (_worklistItems.count > 0){
        if (showCompleted) return completedListItems.count;
        else if (showActive) {
            return activeListItems.count;
        }
        else if (showByLocation) {
            return locationListItems.count;
        }
        else if (showByAssignee) return assigneeListItems.count;
        else return _worklistItems.count;
    } else {
        if (loading) return 0;
        else return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_worklistItems.count > 0){
        static NSString *CellIdentifier = @"TaskCell";
        BHTaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHTaskCell" owner:self options:nil] lastObject];
        }
        
        WorklistItem *item = nil;
        if (showCompleted) {
            item = [completedListItems objectAtIndex:indexPath.row];
        } else if (showActive) {
            item = [activeListItems objectAtIndex:indexPath.row];
        } else if (showByLocation) {
            item = [locationListItems objectAtIndex:indexPath.row];
        } else if (showByAssignee) {
            item = [assigneeListItems objectAtIndex:indexPath.row];
        } else {
            item = [_worklistItems objectAtIndex:indexPath.row];
        }
        
        [cell.itemLabel setText:item.body];
        [cell.createdLabel setText:[dateFormatter stringFromDate:item.createdAt]];
        
        if ([item.assignees.firstObject isKindOfClass:[User class]] && item.user){
            User *assignee = item.assignees.firstObject;
            [cell.ownerLabel setText:[NSString stringWithFormat:@"%@ \u2794 %@",item.user.fullname,assignee.fullname]];
            
        } else if ([item.connectAssignees.firstObject isKindOfClass:[ConnectUser class]]){
            ConnectUser *connectAssignee = item.connectAssignees.firstObject;
            [cell.ownerLabel setText:[NSString stringWithFormat:@"%@ \u2794 %@",item.user.fullname,connectAssignee.fullname]];
        } else if (item.user) {
            [cell.ownerLabel setText:item.user.fullname];
        } else {
            [cell.ownerLabel setText:@""];
        }
        
        if (item.photos.count) {
            if ([(Photo*)[item.photos firstObject] image]){
                [cell.photoButton setImage:[(Photo*)[item.photos firstObject] image] forState:UIControlStateNormal];
            } else {
                [cell.photoButton setImageWithURL:[NSURL URLWithString:[[item.photos firstObject] urlThumb]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"]];
            }
        } else {
            [cell.photoButton setImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"] forState:UIControlStateNormal];
        }
        [cell.photoButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
        cell.photoButton.imageView.layer.cornerRadius = 2.0;
        [cell.photoButton.imageView setBackgroundColor:[UIColor clearColor]];
        [cell.photoButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        cell.photoButton.imageView.layer.shouldRasterize = YES;
        cell.photoButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        //cell.photoButton.clipsToBounds = YES;
        return cell;
    } else {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"NothingCell"];
        UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nothingButton setTitle:@"No Tasks..." forState:UIControlStateNormal];
        [nothingButton.titleLabel setNumberOfLines:0];
        [nothingButton.titleLabel setFont:[UIFont fontWithName:kMyriadProLight size:20]];
        nothingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [nothingButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [nothingButton setBackgroundColor:[UIColor clearColor]];
        [cell addSubview:nothingButton];
        [nothingButton setFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height-100)];
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        [cell.backgroundView setBackgroundColor:[UIColor clearColor]];
        return cell;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        if (!loading && _worklistItems.count){
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
            //[ProgressHUD dismiss];
        }
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_worklistItems.count > 0){
        WorklistItem *item;
        if (showCompleted) {
            item = [completedListItems objectAtIndex:indexPath.row];
        } else if (showActive) {
            item = [activeListItems objectAtIndex:indexPath.row];
        } else if (showByLocation) {
            item = [locationListItems objectAtIndex:indexPath.row];
        } else if (showByAssignee) {
            item = [assigneeListItems objectAtIndex:indexPath.row];
        } else {
            item = [_worklistItems objectAtIndex:indexPath.row];
        }
        //ensure there's a signed in user and that the user is the owner of the current item/task
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [item.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_worklistItems.count){
        [self performSegueWithIdentifier:@"WorklistItem" sender:self];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    BHTaskViewController *vc = segue.destinationViewController;
    
    [vc setProject:_project];
    [vc setLocationSet:locationSet];
    
    if ([segue.identifier isEqualToString:@"CreateItem"]) {
        [vc setTitle:@"New Task"];
    } else if ([segue.identifier isEqualToString:@"WorklistItem"]) {
        WorklistItem *item;
        if (showActive && activeListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [activeListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showByLocation && locationListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [locationListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showByAssignee && assigneeListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [assigneeListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showCompleted && completedListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [completedListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (_worklistItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [_worklistItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        }
        [vc setTask:item];
        if (_connectMode){
            [vc setConnectMode:YES];
        } else {
            [vc setConnectMode:NO];
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = indexPath;
        [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to delete this task?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self deleteItem];
    } else {
        indexPathForDeletion = nil;
    }
}

- (void)deleteItem{
    [ProgressHUD show:@"Deleting..."];
    WorklistItem *item = [_project.worklist.worklistItems objectAtIndex:indexPathForDeletion.row];
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] DELETE:[NSString stringWithFormat:@"%@/worklist_items/%@",kApiBaseUrl, item.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (showCompleted) {
            [completedListItems removeObject:item];
        } else if (showActive) {
            [activeListItems removeObject:item];
        } else if (showByLocation) {
            [locationListItems removeObject:item];
        } else if (showByAssignee) {
            [assigneeListItems removeObject:item];
        } else {
            [_worklistItems removeObject:item];
        }
        
        [_project.worklist removeWorklistItem:item];
        [item MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        
        //check if view is loaded first
        if (self.isViewLoaded && self.view.window) {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        
        NSLog(@"Success deleting task: %@",responseObject);
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to delete this task. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Error deleting notification: %@",error.description);
        [ProgressHUD dismiss];
    }];
}

#pragma mark Intro Stuff

- (void)slide1 {
    BHOverlayView *worklist = [[BHOverlayView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    NSString *worklistText = @"The worklist is designed to be flexible: use it for anything from Requests for Information, to personal to-do list, to punch list items at the end of a job.";
    if (IDIOM == IPAD){
        worklistScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"worklistiPad"]];
        [worklistScreenshot setFrame:CGRectMake(29, 30, 710, 700)];
        [worklist configureText:worklistText atFrame:CGRectMake(100, worklistScreenshot.frame.origin.y + worklistScreenshot.frame.size.height + 20, screenWidth()-200, 100)];
    } else {
        worklistScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"worklistScreenshot"]];
        [worklistScreenshot setFrame:CGRectMake(20, 20, 280, 330)];
        [worklist configureText:worklistText atFrame:CGRectMake(20, worklistScreenshot.frame.origin.y + worklistScreenshot.frame.size.height, screenWidth()-40, 140)];
    }
    [worklistScreenshot setAlpha:0.0];
    [overlayBackground addSubview:worklistScreenshot];
    
    [worklist.tapGesture addTarget:self action:@selector(slide2:)];
    [overlayBackground addSubview:worklist];
    
    [UIView animateWithDuration:.25 animations:^{
        [worklist setAlpha:1.0];
        [worklistScreenshot setAlpha:1.0];
    }];
    
}

- (void)slide2:(UITapGestureRecognizer*)sender {
    BHOverlayView *worklist = [[BHOverlayView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    NSString *worklistText = @"Quickly filter items by status, location, or personnel assigned.";
    if (IDIOM == IPAD){
        [worklist configureText:worklistText atFrame:CGRectMake(100, worklistScreenshot.frame.origin.y + worklistScreenshot.frame.size.height + 20, screenWidth()-200, 100)];
    } else {
        [worklist configureText:worklistText atFrame:CGRectMake(20, worklistScreenshot.frame.origin.y + worklistScreenshot.frame.size.height + 10, screenWidth()-40, 100)];
    }
    [worklist.tapGesture addTarget:self action:@selector(slide3:)];
    
    [UIView animateWithDuration:.25 animations:^{
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        [overlayBackground addSubview:worklist];
        [UIView animateWithDuration:.25 animations:^{
            [worklist setAlpha:1.0];
        }];
    }];
}

- (void)slide3:(UITapGestureRecognizer*)sender {
    BHOverlayView *progress = [[BHOverlayView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    NSString *worklistText = @"Click the \"+\" to add a new task, or tap any row to view, edit or mark an item complete.";
    if (IDIOM == IPAD){
        [progress configureText:worklistText atFrame:CGRectMake(100, worklistScreenshot.frame.origin.y + worklistScreenshot.frame.size.height + 20, screenWidth()-200, 100)];
    } else {
        [progress configureText:worklistText atFrame:CGRectMake(20, worklistScreenshot.frame.origin.y + worklistScreenshot.frame.size.height + 10, screenWidth()-40, 100)];
    }
    [progress.tapGesture addTarget:self action:@selector(endIntro:)];
    
    [UIView animateWithDuration:.25 animations:^{
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        [overlayBackground addSubview:progress];
        [UIView animateWithDuration:.25 animations:^{
            [progress setAlpha:1.0];
        }];
    }];
}

- (void)endIntro:(UITapGestureRecognizer*)sender {
    [UIView animateWithDuration:.35 animations:^{
        [worklistScreenshot setAlpha:0.0];
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:.35 animations:^{
            [overlayBackground setAlpha:0.0];
        }completion:^(BOOL finished) {
            [overlayBackground removeFromSuperview];
            [worklistScreenshot removeFromSuperview];
        }];
    }];
}


-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
}
@end
