//
//  BHReportViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHReportViewController.h"
#import "BHReportPickerCell.h"
#import "BHReportSectionCell.h"
#import "BHReportWeatherCell.h"
#import "BHTabBarViewController.h"
#import "BHReportPhotoCell.h"
#import "BHActivityCell.h"
#import "BHChooseTopicsViewCell.h"
#import "BHSafetyTopicsCell.h"
#import "BHChooseReportPersonnelCell.h"
#import "BHReportPersonnelCell.h"
#import "UIButton+WebCache.h"
#import "MWPhotoBrowser.h"
#import "Flurry.h"
#import "BHAppDelegate.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#import "BHReportPhotoScrollView.h"
#import "BHPersonnelCountTextField.h"
#import "BHSafetyTopicTransition.h"
#import "BHSafetyTopicViewController.h"
#import "BHTaskViewController.h"
#import "BHChecklistItemViewController.h"
#import "BHPersonnelPickerViewController.h"
#import "Activity+helper.h"
#import "Project+helper.h"
#import "Photo+helper.h"
#import "SafetyTopic+helper.h"
#import "Address+helper.h"
#import "Report+helper.h"

#define kForecastAPIKey @"32a0ebe578f183fac27d67bb57f230b5"
static NSString * const kReportPlaceholder = @"Report details...";
static NSString * const kNewReportPlaceholder = @"Add new report";
static NSString * const kWeatherPlaceholder = @"Add your weather notes...";

@interface BHReportViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MWPhotoBrowserDelegate, CTAssetsPickerControllerDelegate, UIViewControllerTransitioningDelegate, UIPopoverControllerDelegate> {
    BHAppDelegate *appDelegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    BOOL choosingDate;
    BOOL saveToLibrary;
    BOOL topicsFetched;
    int windBearing;
    NSString *windDirection;
    NSString *windSpeed;
    NSString *weeklySummary;
    NSString *temp;
    NSString *icon;
    NSString *precip;
    NSString *weatherString;
    NSDateFormatter *formatter;
    NSDateFormatter *timeStampFormatter;
    NSNumberFormatter *numberFormatter;
    UITextView *reportBodyTextView;
    UITextView *weatherTextView;
    UIActionSheet *typePickerActionSheet;
    UIActionSheet *personnelActionSheet;
    UIActionSheet *reportActionSheet;
    UIAlertView *addOtherAlertView;
    User *currentUser;
    BHReportPhotoScrollView *reportScrollView;
    
    UIView *photoButtonContainer;
    NSInteger removePhotoIdx;
    NSString *currentDateString;
    NSMutableArray *browserPhotos;
    CGFloat previousContentOffsetX;
    UITextField *countTextField;
    ALAssetsLibrary *library;
    UIActionSheet *topicsActionSheet;
    UIAlertView *newTopicAlertView;
    NSInteger idx;
    UIBarButtonItem *saveCreateButton;
    UIBarButtonItem *doneButton;
    UIView *overlayBackground;
    NSMutableArray *reportActivities;
    Report *activereport;
    UIBarButtonItem *backButton;
    
    BOOL activities;
    UIButton *commentsButton;
    UIButton *activityButton;
    UIRefreshControl *activeRefreshControl;
    UIRefreshControl *beforeRefreshControl;
    UIRefreshControl *afterRefreshControl;
}

@end

@implementation BHReportViewController

@synthesize report = _report;
@synthesize reports = _reports;
@synthesize project = _project;
@synthesize reportTableView = _reportTableView;

- (void)viewDidLoad {
    self.view.backgroundColor = kLighterGrayColor;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    [super viewDidLoad];
    appDelegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [appDelegate manager];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    currentUser = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];

    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    if (self.navigationController.viewControllers.firstObject == self){
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePersonnel:) name:@"ReportPersonnel" object:nil];
    
    [self setUpTableViewsForReports];
    [self setUpFormatters];
    [self setUpDatePicker];
    [self registerForKeyboardNotifications];
    
    [Flurry logEvent:@"Viewing reports"];
}

- (void)setUpTableViewsForReports {
    // We either don't have multiple reports OR this is a new report
    if ([_report.identifier isEqualToNumber:@0]){
        [self.scrollView setScrollEnabled:NO];
        [self.activeTableView removeFromSuperview];
        [self.afterTableView removeFromSuperview];
        _report.createdAt = [NSDate date];
        self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.dateString];
        [self.beforeTableView setReport:_report];
        _reportTableView = self.beforeTableView;
        [self loadWeather:[formatter dateFromString:_report.dateString] forTableView:self.beforeTableView];
        saveCreateButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
    } else if (!_reports || _reports.count == 0){
        [self.activeTableView removeFromSuperview];
        [self.afterTableView removeFromSuperview];
        [self.scrollView setContentSize:CGSizeMake(width, self.beforeTableView.frame.size.height)];
        self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.dateString];
        [self.beforeTableView setReport:_report];
        _reportTableView = self.beforeTableView;
        saveCreateButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
    } else {
        saveCreateButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
        idx = [_reports indexOfObject:_report];
        if (idx == 0) {
            [self.beforeTableView setReport:_report];
            _reportTableView = self.beforeTableView;
            if (_reports.count > 2)[self.activeTableView setReport:[_reports objectAtIndex:1]];
            else if (_reports.count == 2) {
                [self.afterTableView removeFromSuperview];
                [self.activeTableView setReport:[_reports objectAtIndex:1]];
            } else {
                [self.afterTableView removeFromSuperview];
                [self.activeTableView removeFromSuperview];
            }
        } else if (idx == _reports.count-1) {
            if (_reports.count > 2){
                [self.afterTableView setReport:_report];
                _reportTableView = self.afterTableView;
                [self.activeTableView setReport:[_reports objectAtIndex:idx-1]];
                [self.scrollView setContentOffset:CGPointMake(screenWidth()*2, 0)];
                [self.activeTableView reloadData];
            } else if (_reports.count == 2){
                [self.beforeTableView setReport:[_reports objectAtIndex:idx-1]];
                [self.activeTableView setReport:_report];
                _reportTableView = self.activeTableView;
                [self.afterTableView removeFromSuperview];
                [self.scrollView setContentOffset:CGPointMake(screenWidth(), 0)];
                [self.activeTableView reloadData];
            } else {
                [self.beforeTableView setReport:_report];
                _reportTableView = self.beforeTableView;
                [self.beforeTableView reloadData];
                [self.afterTableView removeFromSuperview];
                [self.activeTableView removeFromSuperview];
            }
        } else {
            [self.scrollView setContentOffset:CGPointMake(screenWidth(), 0)];
            if (_reports.count > 2){
                [self.beforeTableView setReport:[_reports objectAtIndex:idx-1]];
                [self.afterTableView setReport:[_reports objectAtIndex:idx+1]];
            }
            [self.activeTableView setReport:_report];
            _reportTableView = self.activeTableView;
        }
    }

    self.title = [NSString stringWithFormat:@"%@ - %@",_reportTableView.report.type, _reportTableView.report.dateString];
    
    //set up the scrollView
    CGFloat scrollViewWidth;
    if (_reports.count == 1){
        scrollViewWidth = width;
    } else if (_reports.count == 2){
        scrollViewWidth = width*2;
    } else {
        scrollViewWidth = width*3;
    }
    [self.scrollView setContentSize:CGSizeMake(scrollViewWidth, screenHeight()-self.navigationController.navigationBar.frame.size.height-[[UIApplication sharedApplication] statusBarFrame].size.height)];
    previousContentOffsetX = _scrollView.contentOffset.x;
    
    //set up the refresh controls
    activeRefreshControl = [[UIRefreshControl alloc] init];
    [activeRefreshControl setTintColor:kDarkGrayColor];
    [activeRefreshControl addTarget:self action:@selector(refreshReport:) forControlEvents:UIControlEventValueChanged];
    [_activeTableView addSubview:activeRefreshControl];
    if (self.beforeTableView){
        beforeRefreshControl = [[UIRefreshControl alloc] init];
        [beforeRefreshControl setTintColor:kDarkGrayColor];
        [beforeRefreshControl addTarget:self action:@selector(refreshReport:) forControlEvents:UIControlEventValueChanged];
        [_beforeTableView addSubview:beforeRefreshControl];
    }
    if (self.afterTableView){
        afterRefreshControl = [[UIRefreshControl alloc] init];
        [afterRefreshControl setTintColor:kDarkGrayColor];
        [afterRefreshControl addTarget:self action:@selector(refreshReport:) forControlEvents:UIControlEventValueChanged];
        [_afterTableView addSubview:afterRefreshControl];
    }
}

- (void)refreshReport:(UIRefreshControl*)refreshControl {
    BHReportTableView *reportTableView;
    if (refreshControl == activeRefreshControl){
        reportTableView = _activeTableView;
    } else if (refreshControl == beforeRefreshControl){
        reportTableView = _beforeTableView;
    } else {
        reportTableView = _afterTableView;
    }
    [manager GET:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,reportTableView.report.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success fetching report after refresh: %@",responseObject);
        [reportTableView.report populateWithDict:[responseObject objectForKey:@"report"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [reportTableView reloadData];
            [refreshControl endRefreshing];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching report: %@",error.description);
        [refreshControl endRefreshing];
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to refresh this report." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)loadWeather:(NSDate*)reportDate forTableView:(BHReportTableView*)tableView {
    int unixTimestamp = [reportDate timeIntervalSince1970];
    if (_project.address.latitude && _project.address.longitude) {
        [manager GET:[NSString stringWithFormat:@"https://api.forecast.io/forecast/%@/%@,%@,%i",kForecastAPIKey,_project.address.latitude, _project.address.longitude,unixTimestamp] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"response object %i %@",unixTimestamp,responseObject);
            if ([responseObject objectForKey:@"daily"]){
                //NSDictionary *weatherDict = [NSDictionary dictionaryWithDictionary:[responseObject objectForKey:@"currently"]];
                NSDictionary *dailyData = [[[responseObject objectForKey:@"daily"] objectForKey:@"data"] firstObject];
                NSString *min = [[dailyData objectForKey:@"apparentTemperatureMin"] stringValue];
                NSString *max = [[dailyData objectForKey:@"apparentTemperatureMax"] stringValue];
                if (min.length > 4){
                    min = [min substringToIndex:4];
                }
                if (max.length > 4){
                    max = [max substringToIndex:4];
                }
                [tableView.report setHumidity:[NSString stringWithFormat:@"%.0f%%", [[dailyData objectForKey:@"humidity"] floatValue]*100]];
                [tableView.report setPrecip:[NSString stringWithFormat:@"%.0f%%", [[dailyData objectForKey:@"precipProbability"] floatValue]*100]];
                [tableView.report setTemp:[NSString stringWithFormat:@"%@° / %@°",min,max]];
                [tableView.report setWeatherIcon:[dailyData objectForKey:@"icon"]];
                [tableView.report setWeather:[dailyData objectForKey:@"summary"]];
                if ([[[dailyData objectForKey:@"windSpeed"] stringValue] length]){
                    windSpeed = [[dailyData objectForKey:@"windSpeed"] stringValue];
                    if (windSpeed.length > 3){
                        windSpeed = [windSpeed substringToIndex:3];
                    }
                }
                windDirection = [self windDirection:[[responseObject objectForKey:@"windBearing"] intValue]];
                [tableView.report setWind:[NSString stringWithFormat:@"%@mph %@",windSpeed, windDirection]];
                weatherString = [NSString stringWithFormat:@"%@. Temp: %@. Wind: %@mph %@.",[dailyData objectForKey:@"summary"],temp,windSpeed, windDirection];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [tableView reloadData];
                });
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldn't find weather data for this report." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get the weather: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldn't find weather data for this report." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    }
}

- (NSString*)windDirection:(int)bearing {
    if (360 > bearing > 348.75 || 0 < bearing < 11.25) {
        return @"N";
    } else if (33.75 > bearing > 11.25) {
        return @"NNE";
    } else if (56.25 > bearing > 33.75) {
        return @"NE";
    } else if (78.75 > bearing > 56.25) {
        return @"ENE";
    } else if (101.25 > bearing > 78.75) {
        return @"E";
    } else if (123.75 > bearing > 101.25) {
        return @"ESE";
    } else if (146.25 > bearing > 123.75) {
        return @"SE";
    } else if (168.75 > bearing > 146.25) {
        return @"SSE";
    } else if (191.25 > bearing > 168.75) {
        return @"S";
    } else if (213.75 > bearing > 191.25) {
        return @"SSW";
    } else if (236.25 > bearing > 213.75) {
        return @"WSW";
    } else if (258.75 > bearing > 236.25) {
        return @"W";
    } else if (281.25 > bearing > 258.75) {
        return @"WNW";
    } else if (303.75 > bearing > 281.25) {
        return @"NW";
    } else if (326.25 > bearing > 303.75) {
        return @"NW";
    } else if (348.75 > bearing > 326.25) {
        return @"NNW";
    } else return @"";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = saveCreateButton;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat x = self.scrollView.contentOffset.x;
    if (![scrollView isKindOfClass:[BHReportTableView class]] && ![scrollView isKindOfClass:[BHReportPhotoScrollView class]] && scrollView.contentOffset.y == 0 && x != previousContentOffsetX){
        //NSLog(@"x: %f, previous x: %f, idx: %d", x, previousContentOffsetX, idx);
        if (idx <= 1 && self.scrollView.contentOffset.x < screenWidth()){
            idx = 0;
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",[(Report*)_reports.firstObject type], [(Report*)_reports.firstObject dateString]];
            [self.beforeTableView setReport:_reports.firstObject];
            _reportTableView = self.beforeTableView;
            
            if (_reports.count > 2){
                [self.activeTableView setReport:[_reports objectAtIndex:idx+1]];
                [self.activeTableView reloadData];
                [self.afterTableView setReport:[_reports objectAtIndex:idx+2]];
            }
        } else if (idx == _reports.count-2 && x >= screenWidth()){
            //NSLog(@"last report");
            idx = [_reports indexOfObject:_reports.lastObject];
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",[(Report*)_reports.lastObject type], [(Report*)_reports.lastObject dateString]];
            if (_reports.count > 2){
                [self.beforeTableView setReport:[_reports objectAtIndex:idx-2]];
            }
            [self.afterTableView setReport:_reports.lastObject];
            _reportTableView = self.afterTableView;
            
            [self.afterTableView reloadData];
            [self.activeTableView reloadData];
            [self.activeTableView setContentOffset:CGPointZero animated:NO];
            
        } else if (x >= screenWidth() && idx < _reports.count-2){
            //NSLog(@"moved forward");
            idx ++;
            [self.activeTableView setReport:[_reports objectAtIndex:idx]];
            _reportTableView = self.activeTableView;
            if (idx > 0) [self.beforeTableView setReport:[_reports objectAtIndex:idx-1]];
            if (idx < _reports.count - 1) [self.afterTableView setReport:[_reports objectAtIndex:idx+1]];
            
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",_reportTableView.report.type, _reportTableView.report.dateString];
            [self.activeTableView reloadData];
            [self.afterTableView reloadData];
            [self.beforeTableView reloadData];
            [self.activeTableView setContentOffset:CGPointZero animated:NO];
            
        } else if (x <= screenWidth() && idx > 1){
            //NSLog(@"moved backward: %d",idx);
            idx --;
            [self.activeTableView setReport:[_reports objectAtIndex:idx]];
            [self.beforeTableView setReport:[_reports objectAtIndex:idx-1]];
            [self.afterTableView setReport:[_reports objectAtIndex:idx+1]];
            _reportTableView = self.activeTableView;
            
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",_reportTableView.report.type, _reportTableView.report.dateString];
            [self.activeTableView reloadData];
            [self.beforeTableView reloadData];
            [self.afterTableView reloadData];
            [self.activeTableView setContentOffset:CGPointZero animated:NO];
        }
        
        if (idx != 0 && idx != _reports.count-1){
            [_scrollView setContentOffset:CGPointMake(screenWidth(), 0)];
            previousContentOffsetX = screenWidth();
        } else {
            previousContentOffsetX = x;
        }
        [self doneEditing];
    }
}

-(void)tableView:(BHReportTableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == tableView.numberOfSections-1 && indexPath.row == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading

    }
}

- (void)loadReport {
    if (_reportTableView.report.identifier){
        [ProgressHUD show:@"Fetching report..."];
        NSString *slashSafeDate = [_reportTableView.report.dateString stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        [manager GET:[NSString stringWithFormat:@"%@/reports/%@/review_report",kApiBaseUrl,_project.identifier] parameters:@{@"date_string":slashSafeDate} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting report: %@",responseObject);
            //_report = [[Report alloc] initWithDictionary:[responseObject objectForKey:@"report"]];
            [self.activeTableView reloadData];
            [ProgressHUD dismiss];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error getting report: %@",error.description);
            [ProgressHUD dismiss];
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(BHReportTableView *)tableView
{
    return 10;
}

- (NSInteger)tableView:(BHReportTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && [tableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        return  1;
    } else if (section == 1 && [tableView.report.type isEqualToString:kDaily]) {
        return 1;
    } else if (section == 2) {
        return 1;
    } else if (section == 3) {
        return tableView.report.reportUsers.count;
    } else if (section == 4) {
        return tableView.report.reportSubs.count;
    } else if (section == 5 && [tableView.report.type isEqualToString:kSafety]){
        return 1;
    } else if (section == 6 && [tableView.report.type isEqualToString:kSafety]){
        return tableView.report.safetyTopics.count;
    } else if (section == 7 || section == 8){
        return 1;
    } else if (section == 9){
        if ([tableView.report.type isEqualToString:kDaily]){
            return tableView.report.dailyActivities.count;
        } else {
            return tableView.report.activities.count;
        }
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(BHReportTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"ReportPickerCell";
        BHReportPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell configure];
        [cell.typePickerButton setTitle:tableView.report.type forState:UIControlStateNormal];
        if (tableView.report.dateString.length) {
            [cell.datePickerButton setTitle:tableView.report.dateString forState:UIControlStateNormal];
            choosingDate = NO;
        } else {
            [cell.datePickerButton setTitle:@"" forState:UIControlStateNormal];
            choosingDate = YES;
        }
        
        [cell.typePickerButton addTarget:self action:@selector(tapTypePicker) forControlEvents:UIControlEventTouchUpInside];
        [cell.datePickerButton addTarget:self action:@selector(showDatePicker:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([tableView.report.saved isEqualToNumber:@NO]){
            UILabel *unsavedHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 34)];
            [unsavedHeaderLabel setBackgroundColor:kLightestGrayColor];
            [unsavedHeaderLabel setText:@"Unsaved changes"];
            tableView.tableHeaderView = unsavedHeaderLabel;
            NSLog(@"unsaved changes");
        } else {
            tableView.tableHeaderView = nil;
        }
        
        return cell;
    } else if (indexPath.section == 1) {
        static NSString *CellIdentifier = @"ReportWeatherCell";
        BHReportWeatherCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

        [cell.windTextField setUserInteractionEnabled:NO];
        [cell.tempTextField setUserInteractionEnabled:NO];
        [cell.precipTextField setUserInteractionEnabled:NO];
        [cell.humidityTextField setUserInteractionEnabled:NO];
        
        if (tableView.report.weather.length) {
            [cell.dailySummaryTextView setTextColor:[UIColor blackColor]];
            [cell.dailySummaryTextView setText:tableView.report.weather];
        } else {
            [cell.dailySummaryTextView setTextColor:[UIColor lightGrayColor]];
            [cell.dailySummaryTextView setText:kWeatherPlaceholder];
        }
        [cell.windLabel setText:@"Wind:"];
        [cell.tempLabel setText:@"Temp:"];
        [cell.humidityLabel setText:@"Humidity:"];
        [cell.precipLabel setText:@"Precip:"];
        
        cell.dailySummaryTextView.delegate = self;
        cell.dailySummaryTextView.tag = indexPath.section;
        weatherTextView = cell.dailySummaryTextView;
        
        [cell.tempTextField setText:tableView.report.temp];
        [cell.windTextField setText:tableView.report.wind];
        [cell.precipTextField setText:tableView.report.precip];
        [cell.humidityTextField setText:tableView.report.humidity];
        
        if ([tableView.report.weatherIcon isEqualToString:@"clear-day"] || [tableView.report.weatherIcon isEqualToString:@"clear-night"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"sunny"]];
        else if ([tableView.report.weatherIcon isEqualToString:@"cloudy"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"cloudy"]];
        else if ([tableView.report.weatherIcon isEqualToString:@"partly-cloudy-day"] || [tableView.report.weatherIcon isEqualToString:@"partly-cloudy-night"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"partly"]];
        else if ([tableView.report.weatherIcon isEqualToString:@"rain"] || [tableView.report.weatherIcon isEqualToString:@"sleet"]) {
            [cell.weatherImageView setImage:[UIImage imageNamed:@"rainy"]];
        } else if ([tableView.report.weatherIcon isEqualToString:@"fog"] || [tableView.report.weatherIcon isEqualToString:@"wind"]) {
            [cell.weatherImageView setImage:[UIImage imageNamed:@"wind"]];
        } else [cell.weatherImageView setImage:nil];
        
        return cell;
    } else if (indexPath.section == 2) {
        static NSString *CellIdentifier = @"ChooseReportPersonnelCell";
        BHChooseReportPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell.choosePersonnelButton addTarget:self action:@selector(choosePersonnel) forControlEvents:UIControlEventTouchUpInside];
        if (idx == _reports.count-1){
            [cell.prefillButton setUserInteractionEnabled:NO];
            [cell.prefillButton setAlpha:.5];
        } else {
            [cell.prefillButton setUserInteractionEnabled:YES];
            [cell.prefillButton addTarget:self action:@selector(prefill) forControlEvents:UIControlEventTouchUpInside];
            [cell.prefillButton setAlpha:1];
        }
        return cell;

    } else if (indexPath.section == 3) {
        static NSString *CellIdentifier = @"ReportPersonnelCell";
        BHReportPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (tableView.report.reportUsers.count > indexPath.row){
            ReportUser *reportUser = [tableView.report.reportUsers objectAtIndex:indexPath.row];
            [cell.personLabel setText:reportUser.fullname];
            if (reportUser.hours){
                [cell.countTextField setText:[numberFormatter stringFromNumber:reportUser.hours]];
            } else {
                [cell.countTextField setText:@"-"];
            }
            [cell.countTextField setPersonnelType:kUserHours];
            [cell.countTextField setHidden:NO];
        }
        
        countTextField = cell.countTextField;
        [countTextField setTag:indexPath.row];
        [countTextField setKeyboardType:UIKeyboardTypeDecimalPad];
        countTextField.delegate = self;
        [cell.removeButton setTag:indexPath.row];
        [cell.removeButton addTarget:self action:@selector(removeUser:) forControlEvents:UIControlEventTouchUpInside];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        return cell;
    } else if (indexPath.section == 4) {
        static NSString *CellIdentifier = @"ReportPersonnelCell";
        BHReportPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (tableView.report.reportSubs.count > indexPath.row){
            ReportSub *reportSub = [tableView.report.reportSubs objectAtIndex:indexPath.row];
            [cell.personLabel setText:reportSub.name];
            if (reportSub.count){
                [cell.countTextField setText:[NSString stringWithFormat:@"%@",reportSub.count]];
            } else {
                [cell.countTextField setText:@"-"];
            }
            [cell.countTextField setHidden:NO];
            [cell.countTextField setPersonnelType:kSubcontractorCount];
        }
        
        countTextField = cell.countTextField;
        countTextField.delegate = self;
        [cell.removeButton setTag:indexPath.row];
        [cell.removeButton addTarget:self action:@selector(removeSubcontractor:) forControlEvents:UIControlEventTouchUpInside];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    } else if (indexPath.section == 5) {
        static NSString *CellIdentifier = @"ChooseTopicsCell";
        BHChooseTopicsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell.chooseTopicsButton addTarget:self action:@selector(chooseTopics:) forControlEvents:UIControlEventTouchUpInside];
    
        if ([tableView.report.type isEqualToString:kSafety]){
            [cell.chooseTopicsButton setHidden:NO];
        } else {
            [cell.chooseTopicsButton setHidden:YES];
        }
        return cell;
    } else if (indexPath.section == 6) {
        static NSString *CellIdentifier = @"SafetyTopicCell";
        BHSafetyTopicsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (tableView.report.safetyTopics.count > indexPath.row){
            SafetyTopic *topic = [tableView.report.safetyTopics objectAtIndex:indexPath.row];
            [cell configureTopic:topic];
            [cell.removeButton setTag:topic.topicId.integerValue];
            [cell.removeButton addTarget:self action:@selector(removeTopic:) forControlEvents:UIControlEventTouchUpInside];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    } else if (indexPath.section == 7) {
        BHReportPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        reportScrollView = cell.photoScrollView;
        photoButtonContainer = cell.photoButtonContainerView;
        [cell.photoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        [cell.libraryButton addTarget:self action:@selector(choosePhoto) forControlEvents:UIControlEventTouchUpInside];
        [self redrawScrollView:tableView];
        return cell;
    } else if (indexPath.section == 8) {
        static NSString *CellIdentifier = @"ReportSectionCell";
        BHReportSectionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        [cell configureCell];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell.reportSectionLabel setText:@"General Remarks"];
        
        if (tableView.report.body.length) {
            [cell.reportBodyTextView setText:tableView.report.body];
            [cell.reportBodyTextView setTextColor:[UIColor blackColor]];
        } else {
            [cell.reportBodyTextView setText:kReportPlaceholder];
            [cell.reportBodyTextView setTextColor:[UIColor lightGrayColor]];
        }
        cell.reportBodyTextView.delegate = self;
        [cell.reportBodyTextView setTag:indexPath.section];
        reportBodyTextView = cell.reportBodyTextView;
        [reportBodyTextView setFont:[UIFont fontWithName:kMyriadProRegular size:17]];

        return cell;
    } else {
        static NSString *CellIdentifier = @"ActivityCell";
        BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
        }
        
        Activity *activity;
        if ([tableView.report.type isEqualToString:kDaily]){
            activity = tableView.report.dailyActivities[indexPath.row];
            [cell configureActivityForSynopsis:activity];
        } else {
            activity = tableView.report.activities[indexPath.row];
            [cell configureForActivity:activity];
        }
    
        [cell.timestampLabel setText:[timeStampFormatter stringFromDate:activity.createdDate]];
        return cell;
    }
}

- (CGFloat)tableView:(BHReportTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            if ([tableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                return 70;
            } else {
                return 0;
            }
            break;
        case 1:
            if ([tableView.report.type isEqualToString:kDaily]) return 100;
            else return 0;
            break;
        case 2:
            return 120;
            break;
        case 3:
            return 66;
            break;
        case 4:
            return 66;
            break;
        case 5:
            if ([tableView.report.type isEqualToString:kSafety]) {
                return 80;
            } else {
                return 0;
            }
            break;
        case 6:
            if ([tableView.report.type isEqualToString:kSafety]) return 66;
            else return 0;
        case 7:
            return 100;
            break;
        case 8:
            if (IDIOM == IPAD){
                return 360;
            } else if ([UIScreen mainScreen].bounds.size.height == 568){
                return 210;
            } else {
                return 122;
            }
            break;
        default:
            return 80;
            break;
    }
}

- (CGFloat)tableView:(BHReportTableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 && ![tableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        return 0;
    } else if (section == 3 && !tableView.report.reportUsers.count){
        return 0;
    } else if (section == 4 && !tableView.report.reportSubs.count){
        return 0;
    } else if (section == 1 && ![tableView.report.type isEqualToString:kDaily]){
        return 0;
    } else if (section == 5 && ![tableView.report.type isEqualToString:kSafety]){
        return 0;
    } else if (section == 6){
        return 0;
    } else if (section == 9){
        if ([tableView.report.type isEqualToString:kDaily] && tableView.report.dailyActivities.count == 0){
            return 0;
        } else if (tableView.report.activities.count == 0){
            return 0;
        } else {
            return 40;
        }
    } else {
        return 40;
    }
}

- (UIView*)tableView:(BHReportTableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (![tableView.report.type isEqualToString:kDaily] && section == 1){
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else if (section == 0 && ![tableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
        [headerView setBackgroundColor:[UIColor whiteColor]];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, width,38)];
        [headerLabel setBackgroundColor:kLightestGrayColor];
        [headerLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        [headerLabel setTextColor:[UIColor darkGrayColor]];
        
        CGFloat leftLabelOffset,centerLabelOffset;
        if (IDIOM == IPAD){
            leftLabelOffset = 17;
            centerLabelOffset = width*.7;
        } else {
            leftLabelOffset = 5;
            centerLabelOffset = width*.65;
        }
        
        switch (section) {
            case 0:
                [headerLabel setText:@"REPORT DETAILS"];
                break;
            case 1:
                [headerLabel setText:@"WEATHER"];
                break;
            case 2:
                [headerLabel setText:@"PERSONNEL"];
                break;
            case 3:
            {
                [headerLabel setText:@"PERSONNEL"];
                [headerLabel setFrame:CGRectMake(leftLabelOffset, 0, screenWidth()*2/3, 34)];
                [headerLabel setTextAlignment:NSTextAlignmentLeft];
                [headerLabel setBackgroundColor:[UIColor clearColor]];
                [headerLabel setTextColor:[UIColor lightGrayColor]];
                
                UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(centerLabelOffset, 0, width*.4, 34)];
                [countLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
                [countLabel setText:@"# HOURS"];
                [countLabel setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
                [countLabel setTextColor:[UIColor lightGrayColor]];
                [countLabel setBackgroundColor:[UIColor whiteColor]];
                [headerView addSubview:countLabel];
            }
                break;
            case 4:
            {
                [headerLabel setText:@"COMPANIES"];
                [headerLabel setFrame:CGRectMake(leftLabelOffset, 0, width*2/3, 34)];
                [headerLabel setTextAlignment:NSTextAlignmentLeft];
                [headerLabel setTextColor:[UIColor lightGrayColor]];
                [headerLabel setBackgroundColor:[UIColor clearColor]];
                
                UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(centerLabelOffset, 0, width*.4, 34)];
                [countLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
                [countLabel setText:@"# ON SITE"];
                [countLabel setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
                [countLabel setTextColor:[UIColor lightGrayColor]];
                [headerView addSubview:countLabel];
            }
                break;
            case 5:
                [headerLabel setText:@"SAFETY TOPICS COVERED"];
                [headerView setFrame:CGRectMake(0, 0, 0, 0)];
                break;
            case 6:
                [headerView setFrame:CGRectMake(0, 0, 0, 0)];
                break;
            case 7:
                if ([tableView.report.type isEqualToString:kSafety]){
                    [headerLabel setText:@"PHOTO OF SIGN IN CARD / GROUP"];
                } else {
                    [headerLabel setText:@"PHOTOS"];
                }
                break;
            case 8:
                [headerLabel setText:@"NOTES"];
                break;
            case 9:
                //[headerLabel setText:[NSString stringWithFormat:@"%@ ACTIVITY",_project.name.uppercaseString]];
                activityButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [activityButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
                [activityButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
                [activityButton setTitle:@"ACTIVITY" forState:UIControlStateNormal];
                if (activities){
                    [activityButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                } else {
                    [activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                }
                [activityButton setFrame:CGRectMake(width/4-50, 0, 100, 40)];
                [activityButton addTarget:self action:@selector(showActivities) forControlEvents:UIControlEventTouchUpInside];
                [headerView addSubview:activityButton];
                
                commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [commentsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
                [commentsButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
                [commentsButton setTitle:@"COMMENTS" forState:UIControlStateNormal];
                if (activities){
                    [commentsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                } else {
                    [commentsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                }
                
                [commentsButton setFrame:CGRectMake(width*3/4-50, 0, 100, 40)];
                [commentsButton addTarget:self action:@selector(showComments) forControlEvents:UIControlEventTouchUpInside];
                [headerView addSubview:commentsButton];

                break;
            default:
                [headerLabel setText:@""];
                break;
            }
        [headerView addSubview:headerLabel];
        return headerView;
    }
}

- (void)showActivities {
    [activityButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [commentsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    activities = YES;
    [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:9] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showComments {
    [activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [commentsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    activities = NO;
    [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:9] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Date Picker

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

- (void)showDatePicker:(id)sender{
    if (overlayBackground == nil){
        overlayBackground = [appDelegate addOverlayUnderNav:YES];
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
    NSString *dateString = [formatter stringFromDate:self.datePicker.date];
    BOOL duplicate = NO;
    for (Report *report in _project.reports){
        if ([report.type isEqualToString:_report.type] && [report.dateString isEqualToString:dateString]) duplicate = YES;
    }
    if (duplicate){
        [[[UIAlertView alloc] initWithTitle:@"Duplicate Report" message:@"A report with that date and type already exists." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        _report.dateString = dateString;
        self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.dateString];
        [self.beforeTableView reloadData];
        if ([_report.type isEqualToString:kDaily]){
            [self loadWeather:[formatter dateFromString:_report.dateString] forTableView:self.beforeTableView];
        }
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
    [activereport setSaved:@NO];
    self.navigationItem.rightBarButtonItem = doneButton;
    if ([textView.text isEqualToString:kReportPlaceholder] || [textView.text isEqualToString:kWeatherPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor blackColor]];
    }
    
    if (textView.tag == 8){
        
        [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:8] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
    } else if (textView.tag == 1){
        
        [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.tag == 8){
        if ([textView.text isEqualToString:@""]) {
            [textView setText:kReportPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
            _reportTableView.report.body = @"";
        } else if (textView.text.length){
            _reportTableView.report.body = textView.text;
        }
    } else if (textView.tag == 1) {
        if (textView.text.length) {
            _reportTableView.report.weather = textView.text;
        } else {
            _reportTableView.report.weather = @"";
            [textView setText:kWeatherPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
        }
    } else {
        [self doneEditing];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [activereport setSaved:@NO];
    if ([textField isKindOfClass:[BHPersonnelCountTextField class]]) {
        if ([(BHPersonnelCountTextField*)textField personnelType] == kUserHours){
            [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:3] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        } else {
            [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:4] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isKindOfClass:[BHPersonnelCountTextField class]]) {
        if ([(BHPersonnelCountTextField*)textField personnelType] == kUserHours && textField.tag < _reportTableView.report.reportUsers.count) {
            ReportUser *reportUser = [_reportTableView.report.reportUsers objectAtIndex:textField.tag];
            
            reportUser.hours = [numberFormatter numberFromString:textField.text];
            NSLog(@"should be setting report user hours to: %@ for %@",[numberFormatter numberFromString:textField.text],reportUser.fullname);
        } else if ([(BHPersonnelCountTextField*)textField personnelType] == kSubcontractorCount && textField.tag < _reportTableView.report.reportSubs.count) {
            ReportSub *reportSub = [_reportTableView.report.reportSubs objectAtIndex:textField.tag];
            
            reportSub.count = [numberFormatter numberFromString:textField.text];
        }
    }
    [self doneEditing];
}

-(void)doneEditing {
    if (saveCreateButton)
        self.navigationItem.rightBarButtonItem = saveCreateButton;
    [self.view endEditing:YES];
}

- (void)choosePersonnel {
    personnelActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to add?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kIndividual,kCompany, nil];
    [personnelActionSheet showInView:self.view];
}

-(void)tapTypePicker {
    typePickerActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Report Type" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kDaily,kWeekly,kSafety, nil];
    [typePickerActionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    [activereport setSaved:@NO];
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]){
        //let the action sheet dismiss itself
    } else if (actionSheet == typePickerActionSheet){
        BOOL duplicate = NO;
        for (Report *report in _project.reports){
            if ([report.type isEqualToString:buttonTitle] && [report.dateString isEqualToString:_reportTableView.report.dateString]) duplicate = YES;
        }
        if (!duplicate){
            _reportTableView.report.type = buttonTitle;
            self.title = [NSString stringWithFormat:@"%@ - %@",_reportTableView.report.type, _reportTableView.report.dateString];
            [self.beforeTableView reloadData];
            if ([_reportTableView.report.type isEqualToString:kDaily]){
                [self loadWeather:[formatter dateFromString:_reportTableView.report.dateString] forTableView:self.beforeTableView];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Duplicate Report" message:@"A report with that date and type already exists." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    } else if (actionSheet == personnelActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kCompany]){
            [self performSegueWithIdentifier:@"PersonnelPicker" sender:kCompany];
        } else {
            [self performSegueWithIdentifier:@"PersonnelPicker" sender:kIndividual];
        }
    } else if (actionSheet == topicsActionSheet) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"Cancel"]){
            
        } else if ([title isEqualToString:kAddNew]){
            newTopicAlertView = [[UIAlertView alloc] initWithTitle:@"Custom safety topic:" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
            newTopicAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [[newTopicAlertView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [newTopicAlertView show];
        } else {
            SafetyTopic *newTopic = [SafetyTopic MR_findFirstByAttribute:@"title" withValue:buttonTitle inContext:[NSManagedObjectContext MR_defaultContext]];
            [_reportTableView.report addSafetyTopic:newTopic];
            [_reportTableView reloadData];
        }
    }
}

- (void)updatePersonnel:(NSNotification*)notification {
    //NSDictionary *info = [notification userInfo];
    [_reportTableView reloadData];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addOtherAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            ReportUser *user = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [user setFullname:[[alertView textFieldAtIndex:0] text]];
            user.hours = [NSNumber numberWithFloat:0.f];
            if (![_reportTableView.report.reportUsers containsObject:user]) {
                user.report = _reportTableView.report;
                [_reportTableView.report addReportUser:user];
                [self.activeTableView reloadData];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Already added!" message:@"Personnel already included" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        }
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Save"]) {
        [self post];
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Discard"]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (alertView == newTopicAlertView) {
        SafetyTopic *topic = [SafetyTopic MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [topic setTitle:[[alertView textFieldAtIndex:0] text]];
        if (![_reportTableView.report.safetyTopics containsObject:topic]) {
            [_reportTableView.report addSafetyTopic:topic];
            [_reportTableView beginUpdates];
            [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:6] withRowAnimation:UITableViewRowAnimationFade];
            [_reportTableView endUpdates];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil message:@"Safety topic already added." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }
}

- (void)addUserToProject:(User*)user {
    [manager POST:[NSString stringWithFormat:@"%@/subs",kApiBaseUrl] parameters:@{@"name":user.email,@"project_id":_project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Just added a new sub from reports: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure creating a new sub from reports section: %@",error.description);
    }];
}

#pragma mark - Photo Section

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
    if (picker.selectedAssets.count >= 10){
        [[[UIAlertView alloc] initWithTitle:nil message:@"We're unable to select more than 10 photos per batch." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
    // Allow 10 assets to be picked
    return (picker.selectedAssets.count < 10);
}

- (void)choosePhoto {
    saveToLibrary = NO;
    CTAssetsPickerController *controller = [[CTAssetsPickerController alloc] init];
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:NULL];
}

- (void)takePhoto {
    saveToLibrary = YES;
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
        [vc setDelegate:self];
        [self presentViewController:vc animated:YES completion:NULL];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We're unable to access a camera on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

//for taking a photo
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:NULL];
    Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [newPhoto setTakenAt:[NSDate date]];
    [newPhoto setImage:[self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]]];
    [_reportTableView.report addPhoto:newPhoto];
    [self redrawScrollView:_reportTableView];
    
    [self saveImage:newPhoto];
}

// for choosing a photo
- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    [self dismissViewControllerAnimated:YES completion:NULL];
    for (id asset in assets) {
        if (asset != nil) {
            ALAssetRepresentation* representation = [asset defaultRepresentation];
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil)
                orientation = [orientationValue intValue];
            
            UIImage* image = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                 scale:[UIScreen mainScreen].scale orientation:orientation];
            
            Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [newPhoto setTakenAt:[asset valueForProperty:ALAssetPropertyDate]];
            [newPhoto setImage:[self fixOrientation:image]];
            [_reportTableView.report addPhoto:newPhoto];
            [self saveImage:newPhoto];
        }
    }
    [self redrawScrollView:_reportTableView];
}

- (UIImage *)fixOrientation:(UIImage*)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *correctedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return correctedImage;
}

- (void)saveImageToLibrary:(UIImage*)originalImage {
    if (saveToLibrary){
        
        if (!library){
            library = [[ALAssetsLibrary alloc]init];
        }
        
        NSString *albumName = @"BuildHawk";
        UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:0.5 orientation:UIImageOrientationUp];
        
        [library addAssetsGroupAlbumWithName:albumName
                                 resultBlock:^(ALAssetsGroup *group) {
                                     
                                 }
                                failureBlock:^(NSError *error) {
                                    NSLog(@"error adding album");
                                }];
        
        __block ALAssetsGroup* groupToAddTo;
        [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                               usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                   if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                       
                                       groupToAddTo = group;
                                   }
                               }
                             failureBlock:^(NSError* error) {
                                 NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                             }];
        
        [library writeImageToSavedPhotosAlbum:imageToSave.CGImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error.code == 0) {
                [library assetForURL:assetURL
                         resultBlock:^(ALAsset *asset) {
                             [groupToAddTo addAsset:asset];
                         }
                        failureBlock:^(NSError* error) {
                            NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                        }];
            }
            else {
                //NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
            }
        }];
    }
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    [_reportTableView.report removePhoto:photoToRemove];
    if (self.isViewLoaded && self.view.window){
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:7] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [_reportTableView reloadData];
    }
}

- (void)redrawScrollView:(BHReportTableView*)tableView {
    reportScrollView.delegate = self;
    [reportScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    reportScrollView.showsHorizontalScrollIndicator = NO;

    float imageSize = 70.0;
    float space = 4.0;
    int index = 0;
    for (Photo *photo in tableView.report.photos) {
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        } else if (photo.urlSmall.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        } else if (photo.urlThumb.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlThumb] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        }
        [imageButton setTag:[tableView.report.photos indexOfObject:photo]];
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),reportScrollView.frame.size.height/2-imageSize/2,imageSize, imageSize)];
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageButton.imageView.layer.cornerRadius = 2.0;
        [imageButton setBackgroundColor:kLightestGrayColor];
        [imageButton.imageView setBackgroundColor:kLightestGrayColor];
        [imageButton.imageView.layer setBackgroundColor:kLightestGrayColor.CGColor];
        imageButton.imageView.layer.shouldRasterize = YES;
        imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton addTarget:self action:@selector(existingPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [reportScrollView addSubview:imageButton];
        index++;
    }
    
    [reportScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    if (reportScrollView.isHidden) [reportScrollView setHidden:NO];
    [reportScrollView setCanCancelContentTouches:YES];
    [reportScrollView setDelaysContentTouches:YES];
}

- (void)existingPhotoButtonTapped:(UIButton*)button {
    [self showPhotoDetail:button];
    removePhotoIdx = button.tag;
}

- (void)showPhotoDetail:(UIButton*)button {
    browserPhotos = [NSMutableArray new];
    for (Photo *photo in _reportTableView.report.photos) {
        MWPhoto *mwPhoto;
        if (photo.image){
            mwPhoto = [MWPhoto photoWithImage:photo.image];
        } else if (photo.urlLarge.length) {
            mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        }
        if (photo.caption.length) [mwPhoto setCaption:photo.caption];
        [mwPhoto setPhoto:photo];
        
        if (mwPhoto){
            [browserPhotos addObject:mwPhoto];
        }
    }
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    if ([_project.demo isEqualToNumber:@YES]) {
        browser.displayTrashButton = NO;
    }
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = NO;

    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:button.tag];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}

- (void)prefill {
    if ([_reportTableView.report.identifier isEqualToNumber:@0]){
        NSMutableOrderedSet *orderedReports = [NSMutableOrderedSet orderedSetWithArray:_reports];
        NSDate *newReportDate = [formatter dateFromString:_reportTableView.report.dateString];
        [_reports enumerateObjectsUsingBlock:^(Report *thisReport, NSUInteger index, BOOL *stop) {
            NSDate *thisReportDate = [formatter dateFromString:thisReport.dateString];
            if ([newReportDate compare:thisReportDate] == NSOrderedDescending) {
                [orderedReports insertObject:_reportTableView.report atIndex:index];
                _reports = orderedReports.array.mutableCopy;
                *stop = YES;
            }
        }];
    }
    NSUInteger currentIdx = [_reports indexOfObject:_reportTableView.report];
    if (currentIdx != NSNotFound && currentIdx+1 != _reports.count) {
        Report *previousReport = [_reports objectAtIndex:currentIdx+1];

        NSMutableOrderedSet *reportUsers = [NSMutableOrderedSet orderedSet];
        
        for (ReportUser *reportUser in previousReport.reportUsers){
            ReportUser *newReportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            newReportUser.fullname = reportUser.fullname;
            newReportUser.userId = reportUser.userId;
            newReportUser.hours = reportUser.hours;
            [reportUsers addObject:newReportUser];
        }
        _reportTableView.report.reportUsers = reportUsers;
        
        NSMutableOrderedSet *reportSubs = [NSMutableOrderedSet orderedSet];
        for (ReportSub *reportSub in previousReport.reportSubs){
            ReportSub *newReportSub = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            newReportSub.name = reportSub.name;
            newReportSub.companyId = reportSub.companyId;
            newReportSub.count = reportSub.count;
            [reportSubs addObject:newReportSub];
        }
        _reportTableView.report.reportSubs = reportSubs;
        
        [_reportTableView beginUpdates];
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    }
}

- (void)showTopicsActionSheet {
    topicsActionSheet = [[UIActionSheet alloc] initWithTitle:@"Safety Topics" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (SafetyTopic *topic in _project.company.safetyTopics){
        [topicsActionSheet addButtonWithTitle:topic.title];
    }
    [topicsActionSheet addButtonWithTitle:kAddNew];
    topicsActionSheet.cancelButtonIndex = [topicsActionSheet addButtonWithTitle:@"Cancel"];
    [topicsActionSheet showInView:self.view];
}

- (void)chooseTopics:(id)sender {
    if (topicsFetched){
        [self showTopicsActionSheet];
    } else {
        [ProgressHUD show:@"Fetching safety topics..."];
        [manager GET:[NSString stringWithFormat:@"%@/reports/options",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success getting possible topics: %@",responseObject);
            topicsFetched = YES;
            NSArray *topicResponseArray = [responseObject objectForKey:@"possible_topics"];
            NSMutableOrderedSet *topicsSet = [NSMutableOrderedSet orderedSet];
            for (id dict in topicResponseArray){
                SafetyTopic *topic = [SafetyTopic MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!topic){
                    topic = [SafetyTopic MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [topic populateWithDict:dict];
                [topicsSet addObject:topic];
            }
            for (SafetyTopic *topic in _project.company.safetyTopics) {
                if (![topicsSet containsObject:topic]) {
                    NSLog(@"Deleting safety topic that no longer exists: %@",topic.title);
                    [topic MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                }
            }
            _project.company.safetyTopics = topicsSet;

            [self showTopicsActionSheet];
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            NSLog(@"failed to get possible topics: %@",error.description);
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]){
        BHPersonnelPickerViewController *vc = [segue destinationViewController];
        [vc setProject:_project];
        [vc setReport:_reportTableView.report];
        [vc setCompany:_project.company];
        if ([sender isKindOfClass:[NSString class]] && [sender isEqualToString:kCompany]){
            [vc setCompanyMode:YES];
        } else {
            [vc setCompanyMode:NO];
        }
    }
}

- (void)removeUser:(UIButton*)button {
    if (_reportTableView.report.reportUsers.count > button.tag){
        ReportUser *reportUser = [_reportTableView.report.reportUsers objectAtIndex:button.tag];
        if (reportUser && ![_reportTableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) {
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            [parameters setObject:_reportTableView.report.identifier forKey:@"report_id"];
            if (![reportUser.userId isEqualToNumber:[NSNumber numberWithInt:0]]){
                [parameters setObject:reportUser.userId forKey:@"user_id"];
            }
            if (![reportUser.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                [parameters setObject:reportUser.identifier forKey:@"report_user_id"];
            }
            [manager DELETE:[NSString stringWithFormat:@"%@/reports/remove_personnel",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"Success removing report user: %@",responseObject);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failure removing user: %@",error.description);
            }];
        }
        
        [_reportTableView.report removeReportUser:reportUser];
        [reportUser MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [_reportTableView beginUpdates];
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    }
}

- (void)removeSubcontractor:(UIButton*)button {
    //NSLog(@"remove subcontractor button tag: %d",button.tag);
    if (_reportTableView.report.reportSubs.count > button.tag){
        ReportSub *reportSub = [_reportTableView.report.reportSubs objectAtIndex:button.tag];
        if (![_reportTableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) {
            if (reportSub && ![reportSub.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                [parameters setObject:_reportTableView.report.identifier forKey:@"report_id"];
                [parameters setObject:reportSub.companyId forKey:@"company_id"];
                [manager DELETE:[NSString stringWithFormat:@"%@/reports/remove_personnel",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSLog(@"success removing report subcontractor: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failure removing report subcontractor: %@",error.description);
                }];
            }
        }
        
        [_reportTableView.report removeReportSubcontractor:reportSub];
        [reportSub MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [_reportTableView beginUpdates];
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    }
}

- (void)removeTopic:(UIButton*)button {
    SafetyTopic *topic;
    for (SafetyTopic *t in _reportTableView.report.safetyTopics) {
        if (t.topicId.integerValue == button.tag){
            topic = t;
            break;
        }
    }
    
    //update the datasource. make sure to fetch the indexPathForDeletion before you remove the topic!
    NSIndexPath *forDeletion = [NSIndexPath indexPathForRow:[_reportTableView.report.safetyTopics indexOfObject:topic] inSection:6];
    [_reportTableView.report removeSafetyTopic:topic];
    [topic MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        
        //update the UI
    if (_reportTableView.report.safetyTopics.count > 0){
        [_reportTableView beginUpdates];
        [_reportTableView deleteRowsAtIndexPaths:@[forDeletion] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    } else {
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:6] withRowAnimation:UITableViewRowAnimationFade];
    }
   
}

- (void)post {
    if ([_project.demo isEqualToNumber:@YES]){
        if ([saveCreateButton.title isEqualToString:@"Save"]){
            [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to create new reports for demo projects." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        
    } else {
        
        if ([_reportTableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [ProgressHUD show:@"Creating report..."];
            
            //fetch the images
            NSOrderedSet *photoSet = [NSOrderedSet orderedSetWithOrderedSet:_reportTableView.report.photos];
            
            [_reportTableView.report synchWithServer:^(BOOL complete) {
                if (complete){
                    
                    //reattach the images we grabbed earlier.
                    for (Photo *photo in photoSet){
                        photo.report = _reportTableView.report;
                    }
                    //process and upload to AWS.
                    if (photoSet.count){
                        [self uploadPhotos:photoSet forReport:_reportTableView.report];
                    }
                    
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(newReportCreated:)]) {
                            [self.delegate newReportCreated:_reportTableView.report];
                        }
                        [ProgressHUD showSuccess:@"Report Added"];
                        [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report added" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                        [self.navigationController popViewControllerAnimated:YES];
                    }];
                    
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while creating this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    [ProgressHUD dismiss];
                }
            }];
            
        } else {
            [ProgressHUD show:@"Saving report..."];
            [_reportTableView.report synchWithServer:^(BOOL complete) {
                if (complete){
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        [ProgressHUD showSuccess:@"Report saved"];
                    }];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while saving this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    [ProgressHUD dismiss];
                }
            }];
        }
    }
}

- (void)saveImage:(Photo*)photo {
    [self saveImageToLibrary:photo.image];
    if ([_reportTableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        //[self redrawScrollView:_reportTableView];
    } else {
        [self uploadPhotos:[NSOrderedSet orderedSetWithObject:photo] forReport:_reportTableView.report];
    }
}

- (void)uploadPhotos:(NSOrderedSet*)photoSet forReport:(Report*)report {
    if ([_project.demo isEqualToNumber:@NO]){
        
        NSLog(@"existing report for photo upload? %@",report.identifier);
        [report setSaved:@NO];
        
        for (Photo *photo in photoSet){
            if (photo.image && [photo.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                NSData *imageData = UIImageJPEGRepresentation(photo.image, 1);
                
                NSMutableDictionary *photoParameters = [NSMutableDictionary dictionary];
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]){
                    [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"company_id"];
                }
                if (_project && _project.identifier){
                    [photoParameters setObject:_project.identifier forKey:@"project_id"];
                }
                [photoParameters setObject:report.identifier forKey:@"report_id"];
                [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
                [photoParameters setObject:kReports forKey:@"source"];
                [photoParameters setObject:@YES forKey:@"mobile"];
                [photoParameters setObject:[NSNumber numberWithDouble:[photo.takenAt timeIntervalSince1970]] forKey:@"taken_at"];
                
                [manager POST:[NSString stringWithFormat:@"%@/photos",kApiBaseUrl] parameters:@{@"photo":photoParameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {

                    [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
            
                } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSLog(@"Success posting report photo to API: %@",responseObject);
                    
                    if (photoSet.lastObject == photo){
                        [report populateWithDict:[responseObject objectForKey:@"report"]];
    
                        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                            //[[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadReport" object:nil userInfo:@{@"report_id":identifier}];
                        }];
                    }
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failure posting image to API: %@",error.description);
                    [appDelegate notifyError:error andOperation:operation andObject:photo];
                }];
            }
        }
    }
}

- (void)tableView:(BHReportTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 6 && [tableView.report.type isEqualToString:kSafety]){
        if (tableView.report.safetyTopics.count > indexPath.row){
            SafetyTopic *topic = [tableView.report.safetyTopics objectAtIndex:indexPath.row];
            dispatch_async(dispatch_get_main_queue(), ^{
                [ProgressHUD show:@"Fetching safety topic..."];
            });
            if (IDIOM == IPAD){
                BHSafetyTopicViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SafetyTopic"];
                [vc setTitle:[NSString stringWithFormat:@"%@ - %@", tableView.report.type, tableView.report.dateString]];
                [vc setSafetyTopic:topic];
                self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
                self.popover.delegate = self;
                BHSafetyTopicsCell *cell = (BHSafetyTopicsCell*)[(UITableView*)tableView cellForRowAtIndexPath:indexPath];
                [self.popover presentPopoverFromRect:cell.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                
            } else {
                [self showSafetyTopic:topic forReport:tableView.report];
            }
        }
    } else if (indexPath.section == tableView.numberOfSections - 1){
        Activity *activity;
        if ([tableView.report.type isEqualToString:kDaily]){
            activity = tableView.report.dailyActivities[indexPath.row];
        } else {
            activity = tableView.report.activities[indexPath.row];
        }
        
        if (activity.task){
            [ProgressHUD show:@"Loading..."];
            BHTaskViewController *taskVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"Task"];
            [taskVC setTask:activity.task];
            [taskVC setProject:activity.task.project];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:taskVC];
            [self presentViewController:nav animated:YES completion:nil];
        } else if (activity.report){
            if (![activity.report.identifier isEqualToNumber:tableView.report.identifier]){
                [ProgressHUD show:@"Loading..."];
                BHReportViewController *singleReportVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"Report"];
                [singleReportVC setReport:activity.report];
                //set the reports so that the check for unsaved changes method catches
                [singleReportVC setReports:@[activity.report].mutableCopy];
                [singleReportVC setProject:activity.report.project];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:singleReportVC];
                [self presentViewController:nav animated:YES completion:NULL];
            }
        } else if (activity.checklistItem){
            [ProgressHUD show:@"Loading..."];
            BHChecklistItemViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ChecklistItem"];
            [vc setItem:activity.checklistItem];
            [vc setProject:_project];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:NULL];
        }
    }
}

-(void)showSafetyTopic:(SafetyTopic*)safetyTopic forReport:(Report*)report {
    BHSafetyTopicViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SafetyTopic"];
    [vc setSafetyTopic:safetyTopic];
    [vc setTitle:[NSString stringWithFormat:@"%@ - %@", report.type, report.dateString]];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:nil];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    BHSafetyTopicTransition *animator = [BHSafetyTopicTransition new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    BHSafetyTopicTransition *animator = [BHSafetyTopicTransition new];
    return animator;
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = keyboardValue.CGRectValue.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.beforeTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         self.beforeTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         self.activeTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         self.activeTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         self.afterTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         self.afterTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.beforeTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         self.beforeTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                         self.activeTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         self.activeTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                         self.afterTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         self.afterTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                     }
                     completion:nil];
}

- (void)setUpDatePicker {
    [_datePickerContainer setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    [_cancelButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_cancelButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_selectButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
}

- (void)setUpFormatters {
    formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    
    timeStampFormatter = [[NSDateFormatter alloc] init];
    [timeStampFormatter setLocale:[NSLocale currentLocale]];
    [timeStampFormatter setDateFormat:@"MMM d \n h:mm a"];
    
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
}

- (void)back:(UIBarButtonItem*)backBarButton {
    if (backBarButton == backButton){
        if (self.checkForUnsavedChanges){
            
        } else {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
        }
    }
}

- (NSInteger)checkForUnsavedChanges {
    __block NSInteger unsavedCount = 0;
    [_reports enumerateObjectsUsingBlock:^(Report *report, NSUInteger idx, BOOL *stop) {
        if ([report.saved isEqualToNumber:@NO]){
            unsavedCount ++;
        }
    }];
    NSLog(@"unsaved changes count: %ld",(long)unsavedCount);
    if (unsavedCount) {
        NSString *message;
        if (unsavedCount == 1){
            message = [NSString stringWithFormat:@"1 report has unsaved changes. Do you want to save this report?"];
        } else {
            message = [NSString stringWithFormat:@"%ld reports have unsaved changed. Do you want to save these changes?",(long)unsavedCount];
        }
        [[[UIAlertView alloc] initWithTitle:@"Unsaved Changes" message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Save", nil] show];
    }
    return unsavedCount;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
}

@end
