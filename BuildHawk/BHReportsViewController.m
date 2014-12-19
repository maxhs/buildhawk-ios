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

@interface BHReportsViewController () <BHReportDelegate> {
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    Project *_project;
    UIRefreshControl *refreshControl;
    BOOL daily;
    BOOL safety;
    BOOL weekly;
    BOOL loading;
    NSMutableArray *_filteredReports;
    UIBarButtonItem *sortButton;
    UIBarButtonItem *hideSortButton;
    UIView *overlayBackground;
    UIImageView *reportsScreenshot;
    CGRect screen;
    NSIndexPath *indexPathForDeletion;
}
- (IBAction)cancelDatePicker;
- (IBAction)selectDate;
@end

@implementation BHReportsViewController

#pragma mark - Basic Setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    screen = [UIScreen mainScreen].bounds;
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    _project = [(BHTabBarViewController*)self.tabBarController project];
    
    //add refresh control and set up the tableView
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    self.tableView.rowHeight = 90;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    //ensure there's some space in between the filters and the top of the tableview
    self.tableView.contentInset = UIEdgeInsetsMake(6, 0, self.tabBarController.tabBar.frame.size.height, 0);
    
    //set up the segmented control and action button segments
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    [self sortButtonTreatment:_addReportButton];
    [self sortButtonTreatment:_selectDateButton];
    [_addReportButton addTarget:self action:@selector(newReport) forControlEvents:UIControlEventTouchUpInside];
    [_selectDateButton addTarget:self action:@selector(showDatePicker) forControlEvents:UIControlEventTouchUpInside];
    
    if (IDIOM != IPAD){
        sortButton = [[UIBarButtonItem alloc] initWithTitle:@"Sort" style:UIBarButtonItemStylePlain target:self action:@selector(showSort)];
        hideSortButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(hideSort)];
    }
    
    //set up the date picker stuff
    [_cancelButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_cancelButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_selectButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
    [_datePickerContainer setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    
    if (delegate.connected){
        if (_project.reports.count == 0){
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenReports]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ProgressHUD show:@"Fetching reports..."];
                });
            } else {
                overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlayUnderNav:NO];
                [self slide1];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenReports];
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ProgressHUD show:@"Updating reports..."];
            });
        }
        [self loadReports];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadReports) name:@"ReloadReports" object:nil];
}

- (void)reloadReports {
    _project = [Project MR_findFirstByAttribute:@"identifier" withValue:_project.identifier inContext:[NSManagedObjectContext MR_defaultContext]];
    [self.tableView reloadData];
}

- (void)sortButtonTreatment:(UIButton*)button {
    button.layer.borderColor = [UIColor blackColor].CGColor;
    button.layer.borderWidth = 1.f;
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.layer.cornerRadius = 3.6f;
    [button.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
    button.clipsToBounds = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (IDIOM == IPAD){
        self.tabBarController.navigationItem.rightBarButtonItem = nil;
    } else {
        self.tabBarController.navigationItem.rightBarButtonItem = sortButton;
    }
}

#pragma mark - API

- (void)loadReports {
    if (delegate.connected){
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"%@/reports",kApiBaseUrl] parameters:@{@"project_id":_project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting reports: %@",responseObject);
            [self updateLocalReports:[responseObject objectForKey:@"reports"]];
        
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error getting reports: %@",error.description);
            [ProgressHUD dismiss];
            loading = NO;
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        }];
    }
}

- (void)updateLocalReports:(NSArray*)array {
    NSMutableOrderedSet *reportSet = [NSMutableOrderedSet orderedSet];
    for (id obj in array) {
        Report *report = [Report MR_findFirstByAttribute:@"identifier" withValue:[obj objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!report){
            report = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [report populateWithDict:obj];
        } else {
            if ([report.saved isEqualToNumber:@YES]){
                [report updateWithDict:obj];
            } else {
                NSLog(@"Report %@ - %@ has unsaved local changes",report.type, report.dateString);
            }
        }
        
        [reportSet addObject:report];
    }
    for (Report *report in _project.reports) {
        if (![reportSet containsObject:report]) {
            NSLog(@"Deleting a report that no longer exists: %@",report.dateString);
            [_project removeReport:report];
            [report MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }
    _project.reports = reportSet;
    
    //save!
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
        loading = NO;
        
        if (self.isViewLoaded && self.view.window){
            if (safety) {
                [self filter:kSafety];
            } else if (weekly) {
                [self filter:kWeekly];
            } else if (daily) {
                [self filter:kDaily];
            } else {
                //begin to update the UI if the view is still visible
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
            }
        }
        
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [ProgressHUD dismiss];
        
    }];
}


- (void)deleteReport{
    [ProgressHUD show:@"Deleting..."];
    Report *report;
    if (daily || weekly || safety){
        report = [_filteredReports objectAtIndex:indexPathForDeletion.row];
    } else {
        report = [_project.reports objectAtIndex:indexPathForDeletion.row];
    }
    [manager DELETE:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl, report.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //will return success = true if the report was found and deleted or success = false if the report was not found, e.g. if it had already been deleted on the server side.
        //NSLog(@"Success deleting report: %@",responseObject);
        
        //remove the report from all data sources
        [_project removeReport:report];
        [report MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        if (safety || weekly || daily){
            [_filteredReports removeObject:report];
        }
        
        //update the UI
        if (indexPathForDeletion && [self.tableView cellForRowAtIndexPath:indexPathForDeletion] != nil){
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [ProgressHUD dismiss];
        indexPathForDeletion = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Error deleting notification: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to delete this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        [ProgressHUD dismiss];
        indexPathForDeletion = nil;
    }];
}

- (void)handleRefresh {
    if (delegate.connected){
        [ProgressHUD show:@"Refreshing..."];
        [self loadReports];
    } else {
        [self reloadReports];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    }
}

#pragma mark - Sorting & filtering

- (void)showSort {
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _segmentedControl.transform = CGAffineTransformMakeTranslation(-screenWidth(), 0);
        _topActionContainer.transform = CGAffineTransformMakeTranslation(-screenWidth(), 0);
        self.tabBarController.navigationItem.rightBarButtonItem = hideSortButton;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideSort {
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _segmentedControl.transform = CGAffineTransformIdentity;
        _topActionContainer.transform = CGAffineTransformIdentity;
        self.tabBarController.navigationItem.rightBarButtonItem = sortButton;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)segmentedControlTapped:(UISegmentedControl*)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            if (daily){
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                daily = NO;
                [sortButton setTitle:@"Sort"];
                [self.tableView reloadData];
            } else {
                weekly = NO;
                safety = NO;
                daily = YES;
                [sortButton setTitle:kDaily];
                [self filter:kDaily];
            }
            
            break;
        case 1:
            if (safety){
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                safety = NO;
                [sortButton setTitle:@"Sort"];
                [self.tableView reloadData];
            } else {
                daily = NO;
                weekly = NO;
                safety = YES;
                [sortButton setTitle:kSafety];
                [self filter:kSafety];
            }
            
            break;
        case 2:
            if (weekly){
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                weekly = NO;
                [sortButton setTitle:@"Sort"];
                [self.tableView reloadData];
            } else {
                daily = NO;
                safety = NO;
                weekly = YES;
                [sortButton setTitle:kWeekly];
                [self filter:kWeekly];
            }
            break;
            
        default:
            break;
    }
}

- (void)filter:(NSString*)type {
    if (!_filteredReports){
        _filteredReports = [NSMutableArray array];
    }
    [_filteredReports removeAllObjects];
    for (Report *report in _project.reports){
        if ([report.type isEqualToString:type]){
            [_filteredReports addObject:report];
        }
    }
    [self.tableView reloadData];
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
        if (_project.reports.count){
            return _project.reports.count;
        } else if (loading) {
            return 0;
        } else {
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ReportCell";
    BHReportCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (weekly || safety || daily){
        if (_filteredReports.count){
            Report *report = [_filteredReports objectAtIndex:indexPath.row];
            [cell configureReport:report];
        } else if (!loading) {
            return [self generateNothingCellForIndexPath:indexPath];
        }
    } else {
        if (_project.reports.count){
            Report *report = [_project.reports objectAtIndex:indexPath.row];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Report *selectedReport;
    if ((daily || weekly || safety) && _filteredReports.count > indexPath.row){
        selectedReport = [_filteredReports objectAtIndex:indexPath.row];
    } else if (_project.reports.count > indexPath.row) {
        selectedReport = [_project.reports objectAtIndex:indexPath.row];
    }
    if (selectedReport)
        [self performSegueWithIdentifier:@"Report" sender:selectedReport];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == tableView.numberOfSections-1 && indexPath.row == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        [ProgressHUD dismiss];
    }
}
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    Report *report;
    if (_filteredReports.count && (safety || weekly || daily)){
        report = [_filteredReports objectAtIndex:indexPath.row];
    } else if (_project.reports.count) {
        report = [_project.reports objectAtIndex:indexPath.row];
    }
    
    //ensure that there's a signed in user and ask whether they're the current author
    if (report && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && ([report.author.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] || [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUberAdmin])){
        return YES;
    }
    
    return NO;
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

- (void)newReportCreated:(NSNumber *)reportId {
    NSLog(@"new report delegate method: %@",reportId);
    Report *report = [Report MR_findFirstByAttribute:@"identifier" withValue:reportId inContext:[NSManagedObjectContext MR_defaultContext]];
    daily = NO;
    weekly = NO;
    safety = NO;
    [_project addReport:report];
    [self.tableView reloadData];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kDaily]){
        [self performSegueWithIdentifier:@"Report" sender:kDaily];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kWeekly]){
        [self performSegueWithIdentifier:@"Report" sender:kWeekly];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kSafety]){
        [self performSegueWithIdentifier:@"Report" sender:kSafety];
    }
    [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([[segue identifier] isEqualToString:@"Report"]){
        BHReportViewController *vc = [segue destinationViewController];
        vc.reportDelegate = self;
        [vc setProjectId:_project.identifier];
        
        //seguing to an existing report
        if ([sender isKindOfClass:[Report class]]){
            [vc setInitialReportId:[(Report*)sender identifier]];
            if (daily || safety || weekly){
                [vc setReports:_filteredReports];
            } else {
                [vc setReports:_project.reports.array.mutableCopy];
            }
        } else if ([sender isKindOfClass:[NSString class]]) {
        
        //seguing to a new report
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MM/dd/yyyy"];
            [vc setReportDateString:[formatter stringFromDate:[NSDate date]]];
            [vc setReportType:(NSString*)sender];
        }
    }
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
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlayUnderNav:YES];
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
    [_project.reports enumerateObjectsUsingBlock:^(Report *report, NSUInteger idx, BOOL *stop) {
        if ([report.dateString isEqualToString:selectedDateString]){
            [self performSegueWithIdentifier:@"Report" sender:report];
            *stop = YES;
        }
        if (idx == _project.reports.count-1){
            Report *newReport = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            newReport.project = _project;
            newReport.dateString = selectedDateString;
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
        reportsScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reportsScreenshot"]];
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
    [self cancelDatePicker];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
    self.tabBarController.navigationItem.rightBarButtonItems = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
