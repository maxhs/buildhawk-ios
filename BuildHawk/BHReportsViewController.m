//
//  BHReportsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHReportsViewController.h"
#import "BHReportCell.h"
#import "Project.h"
#import "BHReportViewController.h"
#import "BHTabBarViewController.h"
#import "ProgressHUD.h"
#import "BHOverlayView.h"
#import "BHAppDelegate.h"

@interface BHReportsViewController () {
    NSMutableArray *_reports;
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
    
    [self loadReports];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tabBarController.navigationItem.rightBarButtonItems = @[addButton,datePickerButton];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenReports]){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlay];
        [self slide1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenReports];
    } else if (_reports.count == 0){
        [ProgressHUD show:@"Fetching reports..."];
    }
}

- (void)loadReports {
    loading = YES;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project.identifier == %@", project.identifier];
    _reports = [[Report MR_findAllSortedBy:@"createdAt" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]] mutableCopy];
    
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
    for (Report *report in _reports){
        if ([report.type isEqualToString:type]){
            [_filteredReports addObject:report];
        }
    }
    [self.tableView reloadData];
}

- (void)loadOptions {
    [manager GET:[NSString stringWithFormat:@"%@/reports/options",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting possible topics: %@",responseObject);
        _possibleTopics = [BHUtilities safetyTopicsFromJSONArray:[responseObject objectForKey:@"possible_topics"]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed to get possible topics: %@",error.description);
    }];
}

- (void)updateLocalReports:(NSArray*)array {
    if (array.count){
        for (id obj in array) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@",[obj objectForKey:@"id"]];
            Report *savedReport = [Report MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (savedReport){
                [savedReport populateWithDict:obj];
            } else {
                Report *newReport = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [newReport populateWithDict:obj];
                NSLog(@"had to create a new report");
                newReport.project = project;
                [_reports addObject:newReport];
            }
            loading = NO;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        }
    } else {
        loading = NO;
        [ProgressHUD dismiss];
        [self.tableView reloadData];
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
        if (_reports.count){
            return _reports.count;
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
        if (_reports.count){
            Report *report = [_reports objectAtIndex:indexPath.row];
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
    [nothingButton addTarget:self action:@selector(startWriting) forControlEvents:UIControlEventTouchUpInside];
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
    Report *selectedReport = [_reports objectAtIndex:indexPath.row];
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
        } else if (_reports.count && !daily && !weekly && !safety){
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
        [[[UIActionSheet alloc] initWithTitle:@"Report Type:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kDaily,kSafety,kWeekly, nil] showInView:self.view];
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
    if ([[segue identifier] isEqualToString:@"Report"]){
        BHReportViewController *vc = [segue destinationViewController];
        [vc setProject:project];
        if ([sender isKindOfClass:[Report class]]){
            [vc setReport:(Report*)sender];
            [vc setReports:_reports];
        } else if ([sender isKindOfClass:[NSString class]]) {
            [vc setReportType:(NSString*)sender];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //self.tabBarController.navigationItem.rightBarButtonItems = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelDatePicker{
    [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _datePickerContainer.transform = CGAffineTransformMakeTranslation(0, 220);
        self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
        [overlayBackground setAlpha:0];
    } completion:^(BOOL finished) {
        [overlayBackground removeFromSuperview];
    }];
}

- (void)showDatePicker{
    overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlay];
    [self.view insertSubview:overlayBackground belowSubview:_datePickerContainer];
    [self.view bringSubviewToFront:_datePickerContainer];
    [UIView animateWithDuration:0.75 delay:0 usingSpringWithDamping:.6 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _datePickerContainer.transform = CGAffineTransformMakeTranslation(0, -_datePickerContainer.frame.size.height);
        [overlayBackground setAlpha:0.70];
        if (IDIOM == IPAD)
            self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 56);
        else
            self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 49);
        
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)selectDate{
    [self cancelDatePicker];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    NSString *dateString = [formatter stringFromDate:self.datePicker.date];
    NSLog(@"selected date string: %@",dateString);
    /*_report.createdDate = dateString;
    self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.createdDate];
    [self.activeTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];*/
}

- (void)slide1 {
    BHOverlayView *navigation = [[BHOverlayView alloc] initWithFrame:screen];
    if (IDIOM == IPAD){
        reportsScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reportiPad"]];
        [reportsScreenshot setFrame:CGRectMake(screenWidth()/2-355, 40, 710, 505)];
        [navigation configureText:@"Filter by reporttype: Daily, Weekly, or Safety. Tap the calendar icon to jump to a specific date, or the plus to add a new report." atFrame:CGRectMake(screenWidth()/2-150, screenHeight()-310, 300, 100)];
    } else {
        reportsScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reportScreenshot"]];
        [reportsScreenshot setFrame:CGRectMake(screenWidth()/2-140, 40, 280, 330)];
        [navigation configureText:@"Filter by report type: Daily, Weekly, or Safety. Tap the calendar to see a specific date, or the plus to add a new report." atFrame:CGRectMake(20, 390, screenWidth()-40, 100)];
    }
    [reportsScreenshot setAlpha:0.0];
    //[navigation configureArrow:[UIImage imageNamed:@"downWhiteArrow"] atFrame:CGRectMake(screenWidth()/2-25, screenHeight()-200, 50, 110)];
    [navigation.tapGesture addTarget:self action:@selector(endIntro:)];
    [overlayBackground addSubview:navigation];
    [overlayBackground addSubview:reportsScreenshot];
    [UIView animateWithDuration:.25 animations:^{
        [reportsScreenshot setAlpha:1.0];
        [navigation setAlpha:1.0];
    }];
}


- (void)slide2:(UITapGestureRecognizer*)sender {
    BHOverlayView *checklist = [[BHOverlayView alloc] initWithFrame:screen];
    [checklist configureText:@"The first section is the checklist.\n\n Search for specific items or use the filters to quickly prioritize." atFrame:CGRectMake(10, screenHeight()/2+100, screenWidth()-20, 120)];
    [checklist.tapGesture addTarget:self action:@selector(slide3:)];
    [checklist.label setTextAlignment:NSTextAlignmentCenter];
    
    [UIView animateWithDuration:.35 animations:^{
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlay];
        [overlayBackground addSubview:checklist];
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        
        [UIView animateWithDuration:.25 animations:^{
            [overlayBackground setAlpha:0.0];
            [checklist setAlpha:1.0];
        } completion:^(BOOL finished) {
            [overlayBackground removeFromSuperview];
        }];
    }];
}

- (void)slide3:(UITapGestureRecognizer*)sender {
    BHOverlayView *tapToExpand = [[BHOverlayView alloc] initWithFrame:screen];
    [tapToExpand configureText:@"Tap any section to hide or expand the checklist items within." atFrame:CGRectMake(10, screenHeight()/2+100, screenWidth()-20, 100)];
    [tapToExpand.tapGesture addTarget:self action:@selector(endIntro:)];
    [tapToExpand.label setTextAlignment:NSTextAlignmentCenter];
    
    [UIView animateWithDuration:.25 animations:^{
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        [overlayBackground addSubview:tapToExpand];
        [UIView animateWithDuration:.25 animations:^{
            [tapToExpand setAlpha:1.0];
            [reportsScreenshot setAlpha:1.0];
        }];
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


@end
