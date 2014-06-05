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
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
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
    
    [_cancelButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    
    _possibleTopics = [NSMutableArray array];
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

- (void)loadReports {
    loading = YES;
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project.identifier == %@", project.identifier];
    [manager GET:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success getting reports: %@",responseObject);
        [self loadOptions];
        [self updateLocalReports:[responseObject objectForKey:@"reports"]];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting reports: %@",error.description);
        [ProgressHUD dismiss];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        
    }];
}

- (void)handleRefresh:(id)sender {
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

- (void)loadOptions {
    [manager GET:[NSString stringWithFormat:@"%@/reports/options",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting possible topics: %@",responseObject);
        NSArray *topicResponseArray = [responseObject objectForKey:@"possible_topics"];
        NSMutableOrderedSet *topicsSet = [NSMutableOrderedSet orderedSet];
        for (id dict in topicResponseArray){
            SafetyTopic *topic = [SafetyTopic MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
            if (!topic){
                topic = [SafetyTopic MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [topic populateWithDict:dict];
            [topicsSet addObject:topic];
        }
        for (SafetyTopic *topic in project.company.safetyTopics) {
            if (![topicsSet containsObject:topic]) {
                NSLog(@"deleting safety topic that no longer exists: %@",topic.title);
                [topic MR_deleteEntity];
            }
        }
        project.company.safetyTopics = topicsSet;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed to get possible topics: %@",error.description);
    }];
}

- (void)updateLocalReports:(NSArray*)array {
    NSMutableOrderedSet *reportSet = [NSMutableOrderedSet orderedSet];
    
    for (id obj in array) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@",[obj objectForKey:@"id"]];
        Report *report = [Report MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!report){
            report = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [report populateWithDict:obj];
        [reportSet addObject:report];
    }
    for (Report *report in project.reports) {
        if (![reportSet containsObject:report]) {
            NSLog(@"deleting a report that no longer exists: %@",report.createdDate);
            [report MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }
    project.reports = reportSet;
    [self saveContext];
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
    //[self saveContext];
}
- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        loading = NO;
        [ProgressHUD dismiss];
        if (safety) {
            [self filter:kSafety];
        } else if (weekly) {
            [self filter:kWeekly];
        } else if (daily) {
            [self filter:kDaily];
        } else {
            [self.tableView reloadData];
        }
        NSLog(@"What happened during reports save? %hhd %@",success, error);
    }];
}

@end
