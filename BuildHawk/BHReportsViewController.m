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
    Project *project;
    UIRefreshControl *refreshControl;
    BOOL daily;
    BOOL safety;
    BOOL weekly;
    BOOL loading;
    NSMutableArray *_filteredReports;
    UIBarButtonItem *addButton;
    UIBarButtonItem *datePickerButton;
}

@end

@implementation BHReportsViewController

- (void)viewDidLoad {
    
    manager = [AFHTTPRequestOperationManager manager];
    project = [(BHTabBarViewController*)self.tabBarController project];
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", project.identifier];
    //project = [Project MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    /*NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"project.identifier == %@", project.identifier];
    [Report MR_deleteAllMatchingPredicate:aPredicate];*/
    
    
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
    if (_reports.count == 0){
        NSLog(@"couldn't find any local reports");
        [ProgressHUD show:@"Fetching reports..."];
    }
}

- (void)loadReports {
    loading = YES;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project.identifier == %@", project.identifier];
    _reports = [[Report MR_findAllSortedBy:@"createdDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]] mutableCopy];
    
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
    NSLog(@"local project: %@",project.name);
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

@end
