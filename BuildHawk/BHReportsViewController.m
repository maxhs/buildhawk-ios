//
//  BHReportsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHReportsViewController.h"
#import "BHReportCell.h"
#import "BHReportViewController.h"
#import "BHTabBarViewController.h"
#import "ProgressHUD.h"
#import "BHOverlayView.h"
#import "BHAppDelegate.h"
#import "Project+helper.h"
#import "SafetyTopic+helper.h"

@interface BHReportsViewController () {
    NSMutableArray *_possibleTopics;
    AFHTTPRequestOperationManager *manager;
    Project *project;
    UIRefreshControl *refreshControl;
    BOOL daily;
    BOOL safety;
    BOOL weekly;
    BOOL loading;
    NSMutableArray *_filteredReports;
    UIBarButtonItem *addButton;
    UIBarButtonItem *datePickerButton;
    UIView *overlayBackground;
    UIImageView *reportsScreenshot;
    CGRect screen;
    NSIndexPath *indexPathForDeletion;
}
- (IBAction)cancelDatePicker;
- (IBAction)selectDate;
@end

@implementation BHReportsViewController

- (void)viewDidLoad {
    manager = [AFHTTPRequestOperationManager manager];
    project = [(BHTabBarViewController*)self.tabBarController project];
    [super viewDidLoad];

    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    screen = [UIScreen mainScreen].bounds;
    
    [_datePickerContainer setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    _filteredReports = [NSMutableArray array];
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newReport)];
    datePickerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"calendar"] style:UIBarButtonItemStylePlain target:self action:@selector(showDatePicker)];
    datePickerButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, -60);
    addButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, -5);
    
    [_cancelButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    _possibleTopics = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadReport:) name:@"ReloadReport" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenReports]){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlay:NO];
        [self slide1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenReports];
    } else if (project.reports.count == 0){
        [ProgressHUD show:@"Fetching reports..."];
    }
    [self loadReports];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:.25 animations:^{
        self.tabBarController.navigationItem.rightBarButtonItems = @[addButton,datePickerButton];
    }];
}

- (void)reloadReport:(NSNotification*)notification {
    NSLog(@"should be reloading a report, like because a photo just posted: %@",notification.userInfo);
}

- (void)loadReports {
    loading = YES;
    [manager GET:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success getting reports: %@",responseObject);
        [self updateLocalReports:[responseObject objectForKey:@"reports"]];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        loading = NO;
        
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting reports: %@",error.description);
        [ProgressHUD dismiss];
        loading = NO;
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        
    }];
}

- (void)handleRefresh {
    [self loadReports];
}

-(void)segmentedControlTapped:(UISegmentedControl*)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            if (daily){
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                daily = NO;
                [self.tableView reloadData];
            } else {
                weekly = NO;
                safety = NO;
                daily = YES;
                [self filter:kDaily];
            }
            
            break;
        case 1:
            if (safety){
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                safety = NO;
                [self.tableView reloadData];
            } else {
                daily = NO;
                weekly = NO;
                safety = YES;
                [self filter:kSafety];
            }
            
            break;
        case 2:
            if (weekly){
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                weekly = NO;
                [self.tableView reloadData];
            } else {
                daily = NO;
                safety = NO;
                weekly = YES;
                [self filter:kWeekly];
            }
            
        default:
            break;
    }
}

- (void)filter:(NSString*)type {
    [_filteredReports removeAllObjects];
    for (Report *report in project.reports){
        if ([report.type isEqualToString:type]){
            [_filteredReports addObject:report];
        }
    }
    [self.tableView reloadData];
}

- (void)updateLocalReports:(NSArray*)array {
    NSMutableOrderedSet *reportSet = [NSMutableOrderedSet orderedSet];
    for (id obj in array) {
        Report *report = [Report MR_findFirstByAttribute:@"identifier" withValue:[obj objectForKey:@"id"]];
        if (!report){
            report = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [report populateWithDict:obj];
        [reportSet addObject:report];
    }
    for (Report *report in project.reports) {
        if (![reportSet containsObject:report]) {
            NSLog(@"Deleting a report that no longer exists: %@",report.createdDate);
            [report MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }
    
    project.reports = reportSet;
    if (safety) {
        [self filter:kSafety];
    } else if (weekly) {
        [self filter:kWeekly];
    } else if (daily) {
        [self filter:kDaily];
    } else {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (daily || weekly || safety){
        if (_filteredReports.count){
            return _filteredReports.count;
        } else if (loading) {
            return 0;
        } else {
            return 1;
        }
    } else {
        if (project.reports.count){
            return project.reports.count;
        } else if (loading) {
            return 0;
        } else {
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ReportCell";
    BHReportCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportCell" owner:self options:nil] lastObject];
    }
  
    if (weekly || safety || daily){
        if (_filteredReports.count){
            Report *report = [_filteredReports objectAtIndex:indexPath.row];
            [cell configureReport:report];
        } else if (!loading) {
            return [self generateNothingCellForIndexPath:indexPath];
        }
    } else {
        if (project.reports.count){
            Report *report = [project.reports objectAtIndex:indexPath.row];
            [cell configureReport:report];
        } else if (!loading) {
            return [self generateNothingCellForIndexPath:indexPath];
        }
    }
    
    return cell;
}

- (UITableViewCell*)generateNothingCellForIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"NothingCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UIButton *nothingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [nothingButton setTitle:@"No reports..." forState:UIControlStateNormal];
    [nothingButton.titleLabel setNumberOfLines:0];
    [nothingButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:20]];
    nothingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [nothingButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [nothingButton setBackgroundColor:[UIColor clearColor]];
    [cell addSubview:nothingButton];
    [nothingButton setFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height-100)];
    cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    [cell.backgroundView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Report *selectedReport;
    if (daily || weekly || safety){
        selectedReport = [_filteredReports objectAtIndex:indexPath.row];
    } else {
        selectedReport = [project.reports objectAtIndex:indexPath.row];
    }
    [self performSegueWithIdentifier:@"Report" sender:selectedReport];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return 120;
    } else {
        return 90;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == tableView.numberOfSections-1 && indexPath.row == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        [ProgressHUD dismiss];
        if (_filteredReports.count){
            [tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        } else if (project.reports.count && !daily && !weekly && !safety){
            [tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        }
    }
}
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    Report *report;
    if (safety || weekly || daily){
        report = [_filteredReports objectAtIndex:indexPath.row];
    } else {
        report = [project.reports objectAtIndex:indexPath.row];
    }
    
    if ([report.author.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        return YES;
    } else {
        return NO;
    }
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = indexPath;
        [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to delete this report?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self deleteReport];
    } else {
        indexPathForDeletion = nil;
    }
}

- (void)deleteReport{
    [ProgressHUD show:@"Deleting..."];
    Report *report;
    if (daily || weekly || safety){
        report = [_filteredReports objectAtIndex:indexPathForDeletion.row];
    } else {
        report = [project.reports objectAtIndex:indexPathForDeletion.row];
    }
    [manager DELETE:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl, report.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success deleting report: %@",responseObject);
        
        //remove the report from all data sources
        [project removeReport:report];
        [report MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        if (safety || weekly || daily){
            [_filteredReports removeObject:report];
        }
        //update the UI
        [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
        [ProgressHUD dismiss];
        indexPathForDeletion = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Error deleting notification: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to delete this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        [ProgressHUD dismiss];
        indexPathForDeletion = nil;
    }];
}

- (void)newReport {
    if (daily){
        [self performSegueWithIdentifier:@"Report" sender:kDaily];
    } else if (weekly){
        [self performSegueWithIdentifier:@"Report" sender:kWeekly];
    } else if (safety){
        [self performSegueWithIdentifier:@"Report" sender:kSafety];
    } else {
        [[[UIActionSheet alloc] initWithTitle:@"Report Type:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kDaily,kSafety,kWeekly, nil] showFromTabBar:self.tabBarController.tabBar];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kDaily]){
        [self performSegueWithIdentifier:@"Report" sender:kDaily];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kWeekly]){
        [self performSegueWithIdentifier:@"Report" sender:kWeekly];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kSafety]){
        [self performSegueWithIdentifier:@"Report" sender:kSafety];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([[segue identifier] isEqualToString:@"Report"]){
        BHReportViewController *vc = [segue destinationViewController];
        [vc setProject:project];
        if (daily || safety || weekly){
            [vc setReports:_filteredReports];
        } else {
            [vc setReports:project.reports.array.mutableCopy];
        }
        
        if ([sender isKindOfClass:[Report class]]){
            [vc setReport:(Report*)sender];
        } else if ([sender isKindOfClass:[NSString class]]) {
            Report *newReport = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            newReport.type = (NSString*)sender;
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MM/dd/yyyy"];
            newReport.createdDate = [formatter stringFromDate:[NSDate date]];
            [vc setReport:newReport];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelDatePicker{
    [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _datePickerContainer.transform = CGAffineTransformIdentity;
        self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
        [overlayBackground setAlpha:0];
    } completion:^(BOOL finished) {
        overlayBackground = nil;
        [overlayBackground removeFromSuperview];
    }];
}

- (void)showDatePicker{
    if (overlayBackground == nil){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlay:YES];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelDatePicker)];
        tapGesture.numberOfTapsRequired = 1;
        [overlayBackground addGestureRecognizer:tapGesture];
        [self.view insertSubview:overlayBackground belowSubview:_datePickerContainer];
        [self.view bringSubviewToFront:_datePickerContainer];
        [UIView animateWithDuration:0.75 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _datePickerContainer.transform = CGAffineTransformMakeTranslation(0, -_datePickerContainer.frame.size.height);
            
            if (IDIOM == IPAD)
                self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 56);
            else
                self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 49);
            
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [self cancelDatePicker];
    }
}

- (IBAction)selectDate {
    [self cancelDatePicker];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    NSString *selectedDateString = [formatter stringFromDate:self.datePicker.date];
    [project.reports enumerateObjectsUsingBlock:^(Report *report, NSUInteger idx, BOOL *stop) {
        if ([report.createdDate isEqualToString:selectedDateString]){
            [self performSegueWithIdentifier:@"Report" sender:report];
            *stop = YES;
        }
        if (idx == project.reports.count-1){
            Report *newReport = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            newReport.createdDate = selectedDateString;
            newReport.type = kDaily;
            [self performSegueWithIdentifier:@"Report" sender:newReport];
            *stop = YES;
        };
    }];
}

- (void)slide1 {
    BHOverlayView *navigation = [[BHOverlayView alloc] initWithFrame:screen];
    NSString *text = @"Filter by report type: Daily, Weekly, or Safety. Tap the calendar icon to jump to a specific date, or the plus to add a new report.";
    if (IDIOM == IPAD){
        reportsScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reportiPad"]];
        [reportsScreenshot setFrame:CGRectMake(screenWidth()/2-350, 40, 710, 700)];
        [navigation configureText:text atFrame:CGRectMake(screenWidth()/4, reportsScreenshot.frame.origin.y+reportsScreenshot.frame.size.height, screenWidth()/2, 100)];
    } else {
        reportsScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reportScreenshot"]];
        [reportsScreenshot setFrame:CGRectMake(20, 20, 280, 330)];
        [navigation configureText:text atFrame:CGRectMake(20, reportsScreenshot.frame.origin.y+reportsScreenshot.frame.size.height, screenWidth()-40, 100)];
    }
    [reportsScreenshot setAlpha:0.0];
    [navigation.tapGesture addTarget:self action:@selector(endIntro:)];
    [overlayBackground addSubview:navigation];
    [overlayBackground addSubview:reportsScreenshot];
    [UIView animateWithDuration:.25 animations:^{
        [reportsScreenshot setAlpha:1.0];
        [navigation setAlpha:1.0];
    }];
}

- (void)endIntro:(UITapGestureRecognizer*)sender {
    [UIView animateWithDuration:.35 animations:^{
        [reportsScreenshot setAlpha:0.0];
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:.35 animations:^{
            [overlayBackground setAlpha:0.0];
        }completion:^(BOOL finished) {
            [reportsScreenshot removeFromSuperview];
            [overlayBackground removeFromSuperview];
        }];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.tabBarController.navigationItem.rightBarButtonItems = nil;
    [self cancelDatePicker];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveContext];
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

@end
