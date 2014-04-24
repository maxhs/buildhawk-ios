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

@interface BHReportsViewController () {
    NSMutableArray *_reports;
    NSMutableArray *_possibleTopics;
    AFHTTPRequestOperationManager *manager;
    Project *savedProject;
    BHProject *project;
    UIRefreshControl *refreshControl;
    BOOL daily;
    BOOL safety;
    BOOL weekly;
    NSMutableArray *_filteredReports;
    UIBarButtonItem *addButton;
    UIBarButtonItem *datePickerButton;
}

@end

@implementation BHReportsViewController

- (void)viewDidLoad {
    manager = [AFHTTPRequestOperationManager manager];
    project = [(BHTabBarViewController*)self.tabBarController project];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", project.identifier];
    savedProject = [Project MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
    [super viewDidLoad];
    [self loadReports];
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    _filteredReports = [NSMutableArray array];
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newReport)];
    datePickerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"calendar"] style:UIBarButtonItemStylePlain target:self action:@selector(chooseDate)];
    
}

- (void)chooseDate {
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tabBarController.navigationItem.rightBarButtonItems = @[addButton,datePickerButton];
}

- (void)loadReports {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project.identifier == %@", project.identifier];
    _reports = [[Report MR_findAllSortedBy:@"createdDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]] mutableCopy];
    for (Report *report in _reports){
        NSLog(@"saved reports: %@, %i",report.identifier, [(NSArray*)report.photos count]);
    }
    //if (_reports.count == 0){
 
        [ProgressHUD show:@"Fetching reports..."];
    //}
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
    NSLog(@"local project: %@",savedProject.name);
    for (id obj in array) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@",[obj objectForKey:@"id"]];
        Report *savedReport = [Report MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (savedReport){
            [savedReport populateWithDict:obj];
        } else {
            Report *newReport = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [newReport populateWithDict:obj];
            NSLog(@"had to create a new report");
            newReport.project = savedProject;
            [_reports addObject:newReport];
        }
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
        return _filteredReports.count;
    } else {
        return _reports.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ReportCell";
    BHReportCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportCell" owner:self options:nil] lastObject];
    }
    Report *report;
    if (weekly || safety || daily){
        report = [_filteredReports objectAtIndex:indexPath.row];
    } else {
        report = [_reports objectAtIndex:indexPath.row];
    }
    
    [cell configureReport:report];
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
        [tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        //[SVProgressHUD dismiss];
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
        [vc setSavedProject:savedProject];
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
    self.tabBarController.navigationItem.rightBarButtonItems = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
