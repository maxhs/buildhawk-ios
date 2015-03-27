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
    CGFloat width;
    CGFloat height;
    BOOL canLoadMoreReports;
    BOOL daily;
    BOOL safety;
    BOOL weekly;
    BOOL loading;
    NSMutableOrderedSet *_reports;
    NSMutableOrderedSet *_filteredReports;
    UIBarButtonItem *refreshButton;
    UIView *overlayBackground;
    UIImageView *reportsScreenshot;
    CGRect screen;
    NSIndexPath *indexPathForDeletion;
}
@property (strong, nonatomic) Project *project;
- (IBAction)cancelDatePicker;
- (IBAction)selectDate;
@end

@implementation BHReportsViewController

#pragma mark - Basic Setup
- (void)viewDidLoad {
    [super viewDidLoad];
    screen = [UIScreen mainScreen].bounds;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth(); height = screenHeight();
    } else {
        width = screenHeight(); height = screenWidth();
    }
    
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    self.project = [(Project*)[(BHTabBarViewController*)self.tabBarController project] MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project.identifier = %@",self.project.identifier];
    _reports = [Report MR_findAllSortedBy:@"reportDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(handleRefresh)];
    if (IDIOM == IPAD){
        
    } else {
        
        [_sortButton addTarget:self action:@selector(showSort) forControlEvents:UIControlEventTouchUpInside];
        CGFloat segmentedHeight = _segmentedControl.frame.size.height;
        [_segmentedControl setFrame:CGRectMake(8+width, 12, width-16, segmentedHeight)];
        CGRect segmentedControlFrame = _segmentedControl.frame;
        segmentedControlFrame.origin.x = width + 8;
        [_segmentedControl setFrame:segmentedControlFrame];
        [_topContainerScrollView setContentSize:CGSizeMake(width*2, _topContainerScrollView.frame.size.height)];
    }
    
    //set up the segmented control and action button segments as well as add refresh control and proper content inset to tableView
    [self setUpView];
    
    //set up the date picker stuff
    [_cancelButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_cancelButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_selectButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
    [_datePickerContainer setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    
    if (delegate.connected){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = _reports.count == 0 ? @"Fetching reports..." : @"Updating reports...";
            [ProgressHUD show:message];
        });
        [self loadReports];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.navigationItem.rightBarButtonItem = refreshButton;
}

- (void)reloadReports {
    self.project = [Project MR_findFirstByAttribute:@"identifier" withValue:self.project.identifier inContext:[NSManagedObjectContext MR_defaultContext]];
    [self.tableView reloadData];
}

#pragma mark - API

- (void)loadReports {
    if (delegate.connected){
        loading = YES;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:self.project.identifier forKey:@"project_id"];
        [parameters setObject:@10 forKey:@"count"];
        if (_reports.count){
            Report *lastReport = _reports.lastObject;
            NSNumber *beforeDate = [NSNumber numberWithDouble:[lastReport.reportDate timeIntervalSince1970]];
            [parameters setObject:beforeDate forKey:@"before_date"];
        }
        
        [manager GET:[NSString stringWithFormat:@"%@/reports",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting reports: %@",responseObject);
            if ([[responseObject objectForKey:@"reports"] isKindOfClass:[NSArray class]] && [(NSArray*)[responseObject objectForKey:@"reports"] count] > 10){
                canLoadMoreReports = YES;
            } else {
                canLoadMoreReports = NO;
            }
            [self updateLocalReports:[responseObject objectForKey:@"reports"]];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error getting reports: %@",error.description);
            [ProgressHUD dismiss];
            loading = NO;
        }];
    }
}

- (void)updateLocalReports:(NSArray*)array {
    NSMutableOrderedSet *reportSet = [NSMutableOrderedSet orderedSet];
    for (id obj in array) {
        Report *report = [Report MR_findFirstByAttribute:@"identifier" withValue:[obj objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!report){
            report = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [report populateFromDictionary:obj];
        } else {
            if ([report.saved isEqualToNumber:@YES]){
                [report populateFromDictionary:obj];
            } else {
                [report synchWithServer:^(BOOL completed) {
                    if (completed){
                        [report setSaved:@YES];
                        NSLog(@"Done synching Report %@ – %@ with server", report.type, report.dateString);
                    } else {
                        [report setSaved:@NO];
                        NSLog(@"Didn't synch Report %@ – %@ with server.", report.type, report.dateString);
                    }
                }];
            }
        }
        [reportSet addObject:report];
    }
    self.project.reports = reportSet;
    _reports = reportSet.array.mutableCopy;
    
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
                [self.tableView reloadData];
            }
        }
        [ProgressHUD dismiss];
    }];
}


- (void)deleteReport{
    [ProgressHUD show:@"Deleting..."];
    Report *report;
    if (daily || weekly || safety){
        report = [_filteredReports objectAtIndex:indexPathForDeletion.row];
    } else {
        report = [_reports objectAtIndex:indexPathForDeletion.row];
    }
    [manager DELETE:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl, report.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {

        //NSLog(@"Success deleting report: %@",responseObject);
        
        // First, remove the report from all data sources
        [self.tableView beginUpdates];
        
        [self.project removeReport:report];
        if (safety || weekly || daily){
            [_filteredReports removeObject:report];
            //Then update the UI
            if (_filteredReports.count){
                [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            }
        } else {
            [_reports removeObject:report];
            //Then update the UI
            if (_reports.count){
                [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
        [self.tableView endUpdates];
        
        [report MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD dismiss];
            indexPathForDeletion = nil;
        }];
        
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
        [_reports removeAllObjects];
        [self loadReports];
    } else {
        [self reloadReports];
    }
}

#pragma mark - Sorting & filtering

- (void)showSort {
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [_topContainerScrollView setContentOffset:CGPointMake(width, 0)];
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideSort {
    self.tabBarController.navigationItem.rightBarButtonItem = refreshButton;
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [_topContainerScrollView setContentOffset:CGPointZero];

    } completion:^(BOOL finished) {
        
    }];
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
            break;
            
        default:
            break;
    }
}

- (void)filter:(NSString*)type {
    if (!_filteredReports){
        _filteredReports = [NSMutableOrderedSet orderedSet];
    }
    [_filteredReports removeAllObjects];
    for (Report *report in _reports){
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
        if (_reports.count){
            return _reports.count;
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
        if (_reports.count){
            Report *report = [_reports objectAtIndex:indexPath.row];
            [cell configureReport:report];
        } else if (!loading) {
            return [self generateNothingCellForIndexPath:indexPath];
        }
    }
    CGRect photoButtonFrame = cell.photoButton.frame;
    CGFloat differential = width-photoButtonFrame.size.width;
    photoButtonFrame.origin.x = differential;
    [cell.photoButton setFrame:photoButtonFrame];
    
    CGRect photoCountBubbleFrame = cell.photoCountBubble.frame;
    photoCountBubbleFrame.origin.x = photoButtonFrame.origin.x-photoCountBubbleFrame.size.width/2;
    [cell.photoCountBubble setFrame:photoCountBubbleFrame];
    
    CGRect reportNotesFrame = cell.notesLabel.frame;
    reportNotesFrame.size.width = width - reportNotesFrame.origin.x - photoButtonFrame.size.width;
    [cell.notesLabel setFrame:reportNotesFrame];
    
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
    } else if (_reports.count > indexPath.row) {
        selectedReport = [_reports objectAtIndex:indexPath.row];
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
    } else if (_reports.count) {
        report = [_reports objectAtIndex:indexPath.row];
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

#pragma mark - ScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == _tableView){
        float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (bottomEdge >= scrollView.contentSize.height) {
            // at the bottom of the scrollView
            if (canLoadMoreReports && !loading){
                NSLog(@"infinite scroll loading more reports");
                [self loadReports];
            }
        }
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
    if (weekly){
        [self performSegueWithIdentifier:@"Report" sender:kWeekly];
    } else if (safety){
        [self performSegueWithIdentifier:@"Report" sender:kSafety];
    } else {
        [self performSegueWithIdentifier:@"Report" sender:kDaily];
    }
}

- (void)reportCreated:(Report *)r {
    Report *report = [r MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    daily = NO;
    weekly = NO;
    safety = NO;
    [self.project addReport:report];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self.tableView reloadData];
}

- (void)reportUpdated:(Report *)r {
    //Report *report = [r MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project.identifier = %@",self.project.identifier];
    _reports = [Report MR_findAllSortedBy:@"reportDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
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
        [vc setProject:self.project];
        
        //seguing to an existing report
        if ([sender isKindOfClass:[Report class]]){
            Report *report = (Report*)sender;
            [vc setReport:report];
            if (daily){
                [vc setReportType:kDaily];
            } else if (safety){
                [vc setReportType:kSafety];
            } else if (weekly){
                [vc setReportType:kWeekly];
            }
        } else if ([sender isKindOfClass:[NSString class]]) {
            NSString *senderString = (NSString*)sender;
            if ([senderString rangeOfString:@"/"].location == NSNotFound){
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"MM/dd/yyyy"];
                [vc setReportDateString:[formatter stringFromDate:[NSDate date]]];
                [vc setReportType:(NSString*)sender];
            } else {
                [vc setReportDateString:senderString];
                [vc setReportType:kDaily];
            }
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
    __block Report *_report;
    [_reports enumerateObjectsUsingBlock:^(Report *report, NSUInteger idx, BOOL *stop) {
        if ([report.dateString isEqualToString:selectedDateString]){
            _report = report;
            *stop = YES;
        }
    }];
    
    if (_report){
        [self performSegueWithIdentifier:@"Report" sender:_report];
    } else {
        [self performSegueWithIdentifier:@"Report" sender:selectedDateString];
    }
}

- (void)setUpView {
    self.tableView.rowHeight = 90.f;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.37]];
    
    //ensure there's some space in between the filters and the top of the tableview
    self.tableView.contentInset = UIEdgeInsetsMake(_topActionContainer.frame.size.height, 0, self.tabBarController.tabBar.frame.size.height, 0);
    
    [_segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    [_segmentedControl setBackgroundColor:[UIColor clearColor]];
    if (IDIOM == IPAD){
        [_topActionContainer setBackgroundColor:kDarkerGrayColor];
        [_addReportButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_addReportButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
        _addReportButton.layer.cornerRadius = 7.f;
        _addReportButton.clipsToBounds = YES;
        [_segmentedControl setTintColor:[UIColor whiteColor]];
    } else {
        CGRect topContainerFrame = CGRectMake(0, 0, _topContainerScrollView.contentSize.width, _topContainerScrollView.contentSize.height);
        UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:topContainerFrame];
        [backgroundToolbar setTranslucent:YES];
        [_topContainerScrollView addSubview:backgroundToolbar];
        [_topContainerScrollView sendSubviewToBack:backgroundToolbar];
        [backgroundToolbar setBarStyle:UIBarStyleDefault];
        [_calendarButton setFrame:CGRectMake(0, 0, width/3, _topActionContainer.frame.size.height)];
        [_sortButton setFrame:CGRectMake(width/3, 0, width/3, _topActionContainer.frame.size.height)];
        [_addReportButton setFrame:CGRectMake((2*width)/3, 0, width/2, _topActionContainer.frame.size.height)];
        [_segmentedControl setTintColor:[UIColor blackColor]];
    }

    [_calendarButton addTarget:self action:@selector(showDatePicker) forControlEvents:UIControlEventTouchUpInside];
    [_addReportButton addTarget:self action:@selector(newReport) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect datePickerContainerRect = _datePickerContainer.frame;
    if (IDIOM == IPAD){
        datePickerContainerRect.origin.y = height;
    } else {
        datePickerContainerRect.origin.y = height - self.tabBarController.navigationController.navigationBar.frame.size.height - 20.f;
    }
    
    datePickerContainerRect.size.width = width;
    [_datePickerContainer setFrame:datePickerContainerRect];
    CGRect datePickerRect = _datePicker.frame;
    datePickerRect.size.width = width;
    [_datePicker setFrame:datePickerRect];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self cancelDatePicker];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
