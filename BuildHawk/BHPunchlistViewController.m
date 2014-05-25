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
#import "PunchlistItem+helper.h"
#import "Punchlist+helper.h"
#import "Photo.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "UIButton+WebCache.h"
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"
#import "Flurry.h"
#import "Project.h"
#import "BHOverlayView.h"

@interface BHPunchlistViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
    Project *project;
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
}
@end

@implementation BHPunchlistViewController

- (void)viewDidLoad {
    project =[(BHTabBarViewController*)self.tabBarController project];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Worklists",project.name];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.rowHeight = 82;
    showActive = YES;
    showCompleted = NO;
    showByAssignee = NO;
    showByLocation = NO;

    firstLoad = YES;
    [self.segmentedControl setTintColor:kDarkGrayColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    completedListItems = [NSMutableArray array];
    activeListItems = [NSMutableArray array];
    locationListItems = [NSMutableArray array];
    assigneeListItems = [NSMutableArray array];
    locationSet = [NSMutableSet set];
    assigneeSet = [NSMutableSet set];
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    [Flurry logEvent:@"Viewing punchlist"];
    /*NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", project.identifier];
    savedProject = [Project MR_findFirstWithPredicate:predicate inContext:localContext];*/
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createItem)];
    self.tabBarController.navigationItem.rightBarButtonItem = addButton;
    if ([project.punchlist.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        NSLog(@"found punchlist");
        [self drawPunchlist];
    } else {
        [ProgressHUD show:@"Getting Worklist..."];
    }
    [super viewDidLoad];
}

- (void)createItem {
    [self performSegueWithIdentifier:@"CreateItem" sender:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    loading = YES;
    [self loadPunchlist];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenWorklist]){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlay:NO];
        [self slide1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenWorklist];
    }
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
    NSString *worklistText = @"Click the \"+\" to add a new worklist item, or tap any row to view, edit or mark an item complete.";
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

- (void)drawPunchlist {
    if (project.punchlist.punchlistItems.count > 0){
        [activeListItems removeAllObjects];
        for (PunchlistItem *item in project.punchlist.punchlistItems.array){
            if([item.completed isEqualToNumber:[NSNumber numberWithBool:NO]]) {
                [activeListItems addObject:item];
            }
            if (item.location.length) {
                [locationSet addObject:item.location];
            }
            if (item.assignees.count > 0) {
                [assigneeSet addObject:item.assignees.firstObject];
            }
        }
    }
    if (firstLoad){
        showActive = YES;
        firstLoad = NO;
        [self.segmentedControl setSelectedSegmentIndex:0];
    }
    [self.tableView reloadData];
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
            if (showByAssignee == YES){
                [self resetSegments];
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                [self.tableView reloadData];
            } else {
                [self resetSegments];
                showByAssignee = YES;
                [self filterAssignee];
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

- (void)handleRefresh:(id)sender {
    firstLoad = YES;
    [self resetSegments];
    [ProgressHUD show:@"Refreshing..."];
    [self loadPunchlist];
}

- (void)filterLocation {
    if (locationSet.allObjects.count){
        locationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Location" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        for (NSString *location in locationSet.allObjects) {
            [locationActionSheet addButtonWithTitle:location];
        }
        locationActionSheet.cancelButtonIndex = [locationActionSheet addButtonWithTitle:@"Cancel"];
        [locationActionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

- (void)filterAssignee {
    if (assigneeSet.count){
        assigneeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assignees" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        for (id assignee in assigneeSet) {
            if ([assignee isKindOfClass:[User class]] && [[(User*)assignee fullname] length]) [assigneeActionSheet addButtonWithTitle:[(User*)assignee fullname]];
        }
        assigneeActionSheet.cancelButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Cancel"];
        [assigneeActionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

- (void)filterActive {
    [activeListItems removeAllObjects];
    for (PunchlistItem *item in project.punchlist.punchlistItems){
        if([item.completed isEqualToNumber:[NSNumber numberWithBool:NO]]) {
            [activeListItems addObject:item];
        }
    }
    [self.tableView reloadData];
}

- (void)filterCompleted {
    [completedListItems removeAllObjects];
    for (PunchlistItem *item in project.punchlist.punchlistItems){
        if([item.completed isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            [completedListItems addObject:item];
        }
    }
    [self.tableView reloadData];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex == buttonIndex){
        [self resetSegments];
        [self.segmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
        [self.tableView reloadData];
    } else if (actionSheet == assigneeActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] length]) {
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
            if (buttonTitle.length){
                NSPredicate *testForFullName = [NSPredicate predicateWithFormat:@"fullname like %@",buttonTitle];
                for (PunchlistItem *item in project.punchlist.punchlistItems){
                    if (item.assignees.count){
                        if([testForFullName evaluateWithObject:item.assignees.firstObject]) {
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
            for (PunchlistItem *item in project.punchlist.punchlistItems){
                if([testForLocation evaluateWithObject:item]) {
                    [locationListItems addObject:item];
                }
            }
            [self.tableView reloadData];
        }
    }
}

- (void)loadPunchlist {
    [manager GET:[NSString stringWithFormat:@"%@/punchlists/%@", kApiBaseUrl,project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading punchlist: %@",responseObject);
        //NSLog(@"punchlist items: %d",project.punchlist.punchlistItems.count);
        if (project.punchlist && ![project.punchlist.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [project.punchlist populateFromDictionary:[responseObject objectForKey:@"punchlist"]];
        } else {
            project.punchlist = [Punchlist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [project.punchlist populateFromDictionary:[responseObject objectForKey:@"punchlist"]];
        }
        loading = NO;
        [self drawPunchlist];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error loading worklists: %@",error.description);
        [ProgressHUD dismiss];
        loading = NO;
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
    if (showCompleted) return completedListItems.count;
    else if (showActive) {
        return activeListItems.count;
    }
    else if (showByLocation) {
        return locationListItems.count;
    }
    else if (showByAssignee) return assigneeListItems.count;
    else return project.punchlist.punchlistItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PunchlistItemCell";
    BHPunchlistItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPunchlistItemCell" owner:self options:nil] lastObject];
    }
    
    PunchlistItem *item;
    if (showCompleted) {
        item = [completedListItems objectAtIndex:indexPath.row];
    } else if (showActive) {
        item = [activeListItems objectAtIndex:indexPath.row];
    } else if (showByLocation) {
        item = [locationListItems objectAtIndex:indexPath.row];
    } else if (showByAssignee) {
        item = [assigneeListItems objectAtIndex:indexPath.row];
    } else {
        item = [project.punchlist.punchlistItems objectAtIndex:indexPath.row];
    }
    [cell.itemLabel setText:item.body];
    [cell.itemLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:19]];
    cell.itemLabel.numberOfLines = 0;

    if (item.photos.count) {
        [cell.photoButton setImageWithURL:[NSURL URLWithString:[[item.photos firstObject] urlThumb]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"]];
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
        if (!loading)[ProgressHUD dismiss];
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    PunchlistItem *item;
    if (showCompleted) {
        item = [completedListItems objectAtIndex:indexPath.row];
    } else if (showActive) {
        item = [activeListItems objectAtIndex:indexPath.row];
    } else if (showByLocation) {
        item = [locationListItems objectAtIndex:indexPath.row];
    } else if (showByAssignee) {
        item = [assigneeListItems objectAtIndex:indexPath.row];
    } else {
        item = [project.punchlist.punchlistItems objectAtIndex:indexPath.row];
    }
    if ([item.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"PunchlistItem" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"CreateItem"]) {
        BHPunchlistItemViewController *vc = segue.destinationViewController;
        [vc setTitle:@"New Item"];
        [vc setNewItem:YES];
        [vc setProject:project];
        [vc setLocationSet:locationSet];
    } else if ([segue.identifier isEqualToString:@"PunchlistItem"]) {
        BHPunchlistItemViewController *vc = segue.destinationViewController;
        [vc setProject:project];
        [vc setNewItem:NO];
        PunchlistItem *item;
        if (showActive && activeListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [activeListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showByLocation && locationListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [locationListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showByAssignee && assigneeListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [assigneeListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (showCompleted && completedListItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [completedListItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        } else if (project.punchlist.punchlistItems.count > self.tableView.indexPathForSelectedRow.row) {
            item = [project.punchlist.punchlistItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        }
        if (!dateFormatter) dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [vc setTitle:[NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:item.createdAt]]];
        [vc setPunchlistItem:item];
        [vc setLocationSet:locationSet];
        //if (savedUser)[vc setSavedUser:savedUser];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [self saveContext];
    [super viewDidDisappear:animated];
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"What happened during punchlist save? %hhd %@",success, error);
    }];
}

@end
