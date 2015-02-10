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
#import "Task+helper.h"
#import "Tasklist+helper.h"
#import "Photo.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "UIButton+WebCache.h"
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"
#import "Project.h"
#import "BHOverlayView.h"
#import "Subcontractor.h"
#import "Company.h"

@interface BHTasksViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, UIPopoverPresentationControllerDelegate, BHTaskDelegate> {
    NSDateFormatter *dateFormatter;
    BHAppDelegate *delegate;
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
    BOOL loading;
    UIBarButtonItem *addButton;
    UIView *overlayBackground;
    UIImageView *tasklistScreenshot;
    NSInteger lastSegmentIndex;
    NSIndexPath *indexPathForDeletion;
    UIAlertController *locationAlertController;
    UIAlertController *assigneeAlertController;
}
@end

@implementation BHTasksViewController
@synthesize project = _project;
@synthesize tasks = _tasks;

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    
    //set the project to be the tab bar project IF the project wasn't already set, i.e. if it was a buildhawk connect thing
    if (!_project){
        _project = [Project MR_findFirstByAttribute:@"identifier" withValue:[(Project*)[(BHTabBarViewController*)self.tabBarController project] identifier] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    //set the project title
    self.navigationItem.title = [NSString stringWithFormat:@"Tasks: %@",_project.name];
    
    //adjust the inset so that there's some space in between the segmented control (at the top) and the tab bar (at the bottom)
    //CGFloat topInset = IDIOM == IPAD ? 14 : 14;
    self.tableView.contentInset = UIEdgeInsetsMake(14.f, 0, self.tabBarController.tabBar.frame.size.height, 0);
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.rowHeight = 82;
    
    showActive = YES;
    showCompleted = NO;
    showByAssignee = NO;
    showByLocation = NO;
    
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
    
    if (_connectMode){
        _tasks = _project.userConnectItems.array.mutableCopy;
        [self drawTasklist];
    } else if ([_project.tasklist.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        [ProgressHUD show:@"Getting tasks..."];
        loading = YES;
        [self loadTasklist];
    } else {
        loading = YES;
        _tasks = _project.tasklist.tasks.array.mutableCopy;
        [self drawTasklist];
        [self loadTasklist];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTask:) name:@"ReloadTask" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addTask:) name:@"AddTask" object:nil];
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
    if (!_connectMode){
        self.tabBarController.navigationItem.rightBarButtonItem = addButton;
    }
}

- (void)createItem {
    [self performSegueWithIdentifier:@"CreateItem" sender:nil];
}

- (void)newTaskCreated:(Task *)newTask {
    //NSLog(@"new task created: %@",newTask.photos.firstObject);
    [_tasks insertObject:newTask atIndex:0];
    [self drawTasklist];
}

- (void)reloadTask:(NSNotification*)notification {
    NSDictionary *userInfo = notification.userInfo;
    Task *notificationTask = [userInfo objectForKey:@"task"];
    //NSLog(@"notification task: %@",notificationTask);
    if ([notificationTask.completed isEqualToNumber:@YES]){
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
        
        if (![_tasks containsObject:notificationTask]){
            [_tasks addObject:notificationTask];
        }
        [self filterActive];
    }
    
    //add the location to the list of possible locations:
    if (notificationTask.locations.count){
        [locationSet addObjectsFromArray:notificationTask.locations.array];
    }
}

- (void)drawTasklist {
    if (_tasks.count > 0){
        [activeListItems removeAllObjects];
        [completedListItems removeAllObjects];
        [locationSet removeAllObjects];
        [assigneeSet removeAllObjects];
        
        for (Task *task in _tasks){
            for (Location *location in task.locations){
                [locationSet addObject:location];
            }
           
            if (!_connectMode) {
                if (task.assignees.count > 0){
                    [assigneeSet addObject:task.assignees.firstObject];
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

#pragma mark - Custom Segmented Control

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
    if (delegate.connected){
        [ProgressHUD show:@"Refreshing..."];
        if (_connectMode){
            [self connectRefresh];
        } else {
            [self loadTasklist];
        }
    } else {
        [self drawTasklist];
    }
}

- (void)connectRefresh {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([(Task*)_tasks.firstObject project]){
        [parameters setObject:[[(Task*)_tasks.firstObject project] identifier] forKey:@"project_id"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
        
    [_tasks removeAllObjects];
    [manager GET:[NSString stringWithFormat:@"%@/connect",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success with connect refresh: %@",responseObject);
        
        for (NSDictionary *dict in [responseObject objectForKey:@"tasks"]){
            Task *item = [Task MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!item){
                item = [Task MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [item populateFromDictionary:dict];
            [_tasks addObject:item];
        }
        [self drawTasklist];
        [ProgressHUD dismiss];
        if (refreshControl.isRefreshing)[refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        if (refreshControl.isRefreshing)[refreshControl endRefreshing];
        NSLog(@"Failure with connect refresh: %@",error.description);
    }];
}

#pragma mark - Filters
- (void)filterLocation {
    if (locationSet.allObjects.count){
        // UIActionSheet is deprecated in iOS 8
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
            locationAlertController = [UIAlertController alertControllerWithTitle:@"Filter by location:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            for (Location *location in locationSet.allObjects) {
                UIAlertAction *locationAction = [UIAlertAction actionWithTitle:location.name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    NSPredicate *testForLocation = [NSPredicate predicateWithFormat:@"location like %@",location];
                    for (Task *task in _tasks)
                        if([testForLocation evaluateWithObject:task])
                            [locationListItems addObject:task];
                    lastSegmentIndex = self.segmentedControl.selectedSegmentIndex;
                    [self.tableView reloadData];
                }];
                
                [locationAlertController addAction:locationAction];
            }
            
            // set up the cancel action
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self.segmentedControl setSelectedSegmentIndex:lastSegmentIndex];
                [self segmentedControlTapped:self.segmentedControl];
            }];
            [locationAlertController addAction:cancel];
            locationAlertController.popoverPresentationController.delegate = self;
            [self presentViewController:locationAlertController animated:YES completion:nil];
        } else {
            locationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Location" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            for (NSString *location in locationSet.allObjects) {
                [locationActionSheet addButtonWithTitle:location];
            }
            if (IDIOM != IPAD){
                locationActionSheet.cancelButtonIndex = [locationActionSheet addButtonWithTitle:@"Cancel"];
            }
            if (self.tabBarController){
                [locationActionSheet showFromTabBar:self.tabBarController.tabBar];
            } else {
                [locationActionSheet showInView:self.view];
            }
        }
    }
}

// for the alert controller on iPad, which gets presented as a popover
- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
    popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [popoverPresentationController setSourceView:self.view];
    [popoverPresentationController setSourceRect:self.segmentedControl.frame];
}

- (void)filterAssignee {
    if (assigneeSet.count){
        // UIActionSheet is deprecated in iOS 8
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
            assigneeAlertController = [UIAlertController alertControllerWithTitle:@"Filter by assignee:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            for (id assignee in assigneeSet) {
                if ([assignee isKindOfClass:[User class]] && [[(User*)assignee fullname] length]) {
                    NSString *assigneeName = [(User*)assignee fullname];
                    UIAlertAction *assigneeAction = [UIAlertAction actionWithTitle:assigneeName style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        
                        NSPredicate *testForFullName = [NSPredicate predicateWithFormat:@"fullname like %@",assigneeName];
                        for (Task *task in _tasks)
                            if (task.assignees.count && [testForFullName evaluateWithObject:task.assignees.firstObject])
                                [assigneeListItems addObject:task];
                        
                        lastSegmentIndex = self.segmentedControl.selectedSegmentIndex;
                        [self.tableView reloadData];
                    }];
                    
                    [assigneeAlertController addAction:assigneeAction];
                }
            }
            
            // set up the cancel action
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self.segmentedControl setSelectedSegmentIndex:lastSegmentIndex];
                [self segmentedControlTapped:self.segmentedControl];
            }];
            [assigneeAlertController addAction:cancel];
            assigneeAlertController.popoverPresentationController.delegate = self;
            [self presentViewController:assigneeAlertController animated:YES completion:nil];
        } else {
            
            assigneeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assignees" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            for (id assignee in assigneeSet) {
                if ([assignee isKindOfClass:[User class]] && [[(User*)assignee fullname] length]) {
                    [assigneeActionSheet addButtonWithTitle:[(User*)assignee fullname]];
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
}

- (void)filterActive {
    [activeListItems removeAllObjects];
    for (Task *task in _tasks){
        if(![task.completed isEqualToNumber:@YES]) {
            [activeListItems addObject:task];
        }
    }
    [self.tableView reloadData];
    lastSegmentIndex = self.segmentedControl.selectedSegmentIndex;
}

- (void)filterCompleted {
    [completedListItems removeAllObjects];
    for (Task *item in _tasks){
        if([item.completed isEqualToNumber:@YES]) {
            [completedListItems addObject:item];
        }
    }
    [self.tableView reloadData];
    lastSegmentIndex = self.segmentedControl.selectedSegmentIndex;
}

#pragma mark - UIActionSheet delegate stuff

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.cancelButtonIndex == buttonIndex){
        [self.segmentedControl setSelectedSegmentIndex:lastSegmentIndex];
        [self segmentedControlTapped:self.segmentedControl];
    } else if (actionSheet == assigneeActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] length]) {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
            if (buttonTitle.length){
                NSPredicate *testForFullName = [NSPredicate predicateWithFormat:@"fullname like %@",buttonTitle];
                for (Task *task in _tasks)
                    //testing both users and connect users since both have a "fullname" attribute
                    if (task.assignees.count && [testForFullName evaluateWithObject:task.assignees.firstObject])
                        [assigneeListItems addObject:task];
                        
            }
            lastSegmentIndex = self.segmentedControl.selectedSegmentIndex;
            [self.tableView reloadData];
            
        }
    } else if (actionSheet == locationActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] length]) {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
            NSPredicate *testForLocation = [NSPredicate predicateWithFormat:@"location like %@",buttonTitle];
            for (Task *item in _tasks)
                if([testForLocation evaluateWithObject:item])
                    [locationListItems addObject:item];
    
            lastSegmentIndex = self.segmentedControl.selectedSegmentIndex;
            [self.tableView reloadData];
        }
    }
}

- (void)loadTasklist {
    if (delegate.connected)
    [manager GET:[NSString stringWithFormat:@"%@/tasklists", kApiBaseUrl] parameters:@{@"project_id":_project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading tasklist: %@",responseObject);
        if ([responseObject objectForKey:@"tasklist"]) {
            [self updateTasklist:[responseObject objectForKey:@"tasklist"]];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error loading tasklists: %@",error.description);
        [ProgressHUD dismiss];
        loading = NO;
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    }];
}

- (void)updateTasklist:(NSDictionary*)dictionary {
    Tasklist *tasklist = [Tasklist MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
    if (!tasklist){
        tasklist = [Tasklist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    }
    [tasklist populateFromDictionary:dictionary];
    if (_project.tasklist.tasks.count > 0){
        for (Task *item in _project.tasklist.tasks) {
            if (![tasklist.tasks containsObject:item]) {
                NSLog(@"Deleting a task that no longer exists: %@",item.body);
                [item MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
    }
    if (_project){
        _project.tasklist = tasklist;
        _tasks = tasklist.tasks.array.mutableCopy;
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        //only bother drawing if the view is loaded
        if (self.isViewLoaded && self.view.window){
            [self drawTasklist];
        } else {
            [ProgressHUD dismiss];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_tasks.count > 0){
        if (showCompleted) return completedListItems.count;
        else if (showActive) return activeListItems.count;
        else if (showByLocation) return locationListItems.count;
        else if (showByAssignee) return assigneeListItems.count;
        else return _tasks.count;
    } else {
        if (loading) return 0;
        else return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_tasks.count > 0){
        static NSString *CellIdentifier = @"TaskCell";
        BHTaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        Task *task = nil;
        if (showCompleted) {
            task = [completedListItems objectAtIndex:indexPath.row];
        } else if (showActive) {
            task = [activeListItems objectAtIndex:indexPath.row];
        } else if (showByLocation) {
            task = [locationListItems objectAtIndex:indexPath.row];
        } else if (showByAssignee) {
            task = [assigneeListItems objectAtIndex:indexPath.row];
        } else {
            task = [_tasks objectAtIndex:indexPath.row];
        }
        [cell configureForTask:task];
        
        if (!dateFormatter){
            [self setupDateFormatter];
        }
        [cell.createdLabel setText:[dateFormatter stringFromDate:task.createdAt]];
    
        return cell;
    } else {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"NothingCell"];
        UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nothingButton setTitle:@"No Tasks..." forState:UIControlStateNormal];
        [nothingButton.titleLabel setNumberOfLines:0];
        [nothingButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0]];
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

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        if (!loading && _tasks.count){
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
            //[ProgressHUD dismiss];
        }
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_tasks.count){
        Task *task;
        if (showCompleted) {
            task = [completedListItems objectAtIndex:indexPath.row];
        } else if (showActive) {
            task = [activeListItems objectAtIndex:indexPath.row];
        } else if (showByLocation) {
            task = [locationListItems objectAtIndex:indexPath.row];
        } else if (showByAssignee) {
            task = [assigneeListItems objectAtIndex:indexPath.row];
        } else {
            task = [_tasks objectAtIndex:indexPath.row];
        }
        //ensure there's a signed in user and that the user is the owner of the current item/task
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && ([task.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] || [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUberAdmin])){
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_tasks.count){
        [self performSegueWithIdentifier:@"Task" sender:self];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Segue & Navigation stuff

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    BHTaskViewController *vc = segue.destinationViewController;
    vc.delegate = self;
    
    [vc setProject:_project];
    [vc setLocationSet:locationSet];
    
    if ([segue.identifier isEqualToString:@"CreateItem"]) {
        [vc setTitle:@"New Task"];
    } else if ([segue.identifier isEqualToString:@"Task"]) {
        Task *item;
        if (showActive && activeListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [activeListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showByLocation && locationListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [locationListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showByAssignee && assigneeListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [assigneeListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showCompleted && completedListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [completedListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (_tasks.count > self.tableView.indexPathForSelectedRow.row) {
            item = [_tasks objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        }
        [vc setTaskId:item.identifier];
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
        Task *task;
        if (showCompleted) {
            task = [completedListItems objectAtIndex:indexPath.row];
        } else if (showActive) {
            task = [activeListItems objectAtIndex:indexPath.row];
        } else if (showByLocation) {
            task = [locationListItems objectAtIndex:indexPath.row];
        } else if (showByAssignee) {
            task = [assigneeListItems objectAtIndex:indexPath.row];
        } else {
            task = [_tasks objectAtIndex:indexPath.row];
        }
        
        [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:[NSString stringWithFormat:@"Are you sure you want to delete \"%@\"?",task.body] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
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
    Task *task;
    if (showCompleted) {
        task = [completedListItems objectAtIndex:indexPathForDeletion.row];
    } else if (showActive) {
        task = [activeListItems objectAtIndex:indexPathForDeletion.row];
    } else if (showByLocation) {
        task = [locationListItems objectAtIndex:indexPathForDeletion.row];
    } else if (showByAssignee) {
        task = [assigneeListItems objectAtIndex:indexPathForDeletion.row];
    } else {
        task = [_tasks objectAtIndex:indexPathForDeletion.row];
    }
    
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] DELETE:[NSString stringWithFormat:@"%@/tasks/%@",kApiBaseUrl, task.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (showCompleted) {
            [completedListItems removeObject:task];
        } else if (showActive) {
            [activeListItems removeObject:task];
        } else if (showByLocation) {
            [locationListItems removeObject:task];
        } else if (showByAssignee) {
            [assigneeListItems removeObject:task];
        }
        
        //ensure that object is removed from datasource, then delete it from the local database
        [_tasks removeObject:task];
        [_project.tasklist removeTask:task];
        [task MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        
        //check if view is loaded first
        if (self.isViewLoaded && self.view.window) {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        
        //NSLog(@"Success deleting task: %@",responseObject);
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to delete this task. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to delete task: %@",error.description);
        [ProgressHUD dismiss];
    }];
}

- (void)setupDateFormatter {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
