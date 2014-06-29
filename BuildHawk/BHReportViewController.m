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
#import <CoreLocation/CoreLocation.h>
#import "BHReportPersonnelCell.h"
#import "BHPersonnelCell.h"
#import "BHSubcontractorCell.h"
#define kForecastAPIKey @"32a0ebe578f183fac27d67bb57f230b5"
#import "UIButton+WebCache.h"
#import "MWPhotoBrowser.h"
#import "Project+helper.h"
#import "Report.h"
#import "Flurry.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "BHPersonnelPickerViewController.h"
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#import "BHChooseTopicsViewCell.h"
#import "BHSafetyTopicsCell.h"
#import "SafetyTopic+helper.h"
#import "Photo+helper.h"
#import "BHAppDelegate.h"
#import "Subcontractor.h"
#import "BHReportPhotoScrollView.h"
#import "BHPersonnelCountTextField.h"
#import "BHSafetyTopicTransition.h"
#import "BHSafetyTopicViewController.h"
#import "Activity+helper.h"
#import "BHActivityCell.h"

static NSString * const kReportPlaceholder = @"Report details...";
static NSString * const kNewReportPlaceholder = @"Add new report";
static NSString * const kWeatherPlaceholder = @"Add your weather notes...";

@interface BHReportViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MWPhotoBrowserDelegate, CTAssetsPickerControllerDelegate, UIViewControllerTransitioningDelegate, UIPopoverControllerDelegate> {
    CGFloat width;
    CGFloat height;
    BOOL iPhone5;
    BOOL choosingDate;
    BOOL saveToLibrary;
    BOOL shouldSave;
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
    UITextView *reportBodyTextView;
    UITextView *weatherTextView;
    UIActionSheet *typePickerActionSheet;
    UIActionSheet *personnelActionSheet;
    UIActionSheet *reportActionSheet;
    UIAlertView *addOtherAlertView;
    User *currentUser;
    BHReportPhotoScrollView *reportScrollView;
    AFHTTPRequestOperationManager *manager;
    UIView *photoButtonContainer;
    int removePhotoIdx;
    NSString *currentDateString;
    NSMutableArray *browserPhotos;
    CGFloat previousContentOffsetX;
    UITextField *countTextField;
    ALAssetsLibrary *library;
    UIActionSheet *topicsActionSheet;
    NSInteger idx;
    UIBarButtonItem *saveCreateButton;
    UIBarButtonItem *doneButton;
    UIView *overlayBackground;
    BHReportTableView *_reportTableView;
}

@end

@implementation BHReportViewController

@synthesize report = _report;
@synthesize reports = _reports;
@synthesize project = _project;

- (void)viewDidLoad {
    self.view.backgroundColor = kLighterGrayColor;
    width = screenWidth();
    if ([UIScreen mainScreen].bounds.size.height == 568) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
    [super viewDidLoad];
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    library = [[ALAssetsLibrary alloc]init];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    currentUser = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    [_datePickerContainer setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    
    CGFloat scrollViewWidth;
    if (_reports.count == 1){
        scrollViewWidth = screenWidth();
    } else if (_reports.count == 2){
        scrollViewWidth = screenWidth()*2;
    } else {
        scrollViewWidth = screenWidth()*3;
    }
    [self.scrollView setContentSize:CGSizeMake(scrollViewWidth, screenHeight()-self.navigationController.navigationBar.frame.size.height-[[UIApplication sharedApplication] statusBarFrame].size.height)];
    
    
    if ([_report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        [self.scrollView setScrollEnabled:NO];
        [self.activeTableView removeFromSuperview];
        [self.afterTableView removeFromSuperview];
        _report.createdAt = [NSDate date];
        self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.createdDate];
        [self.beforeTableView setReport:_report];
        _reportTableView = self.beforeTableView;
        [self loadWeather:[formatter dateFromString:_report.createdDate] forTableView:self.beforeTableView];
        saveCreateButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(send)];
    } else {
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
        self.title = [NSString stringWithFormat:@"%@ - %@",_reportTableView.report.type, _reportTableView.report.createdDate];
        saveCreateButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(send)];
    }
    previousContentOffsetX = _scrollView.contentOffset.x;
    
    [_cancelButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePersonnel:) name:@"ReportPersonnel" object:nil];
    [Flurry logEvent:@"Viewing reports"];
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
            NSLog(@"first report");
            idx = 0;
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",[(Report*)_reports.firstObject type], [(Report*)_reports.firstObject createdDate]];
            [self.beforeTableView setReport:_reports.firstObject];
            _reportTableView = self.beforeTableView;
            
            if (_reports.count > 2){
                [self.activeTableView setReport:[_reports objectAtIndex:idx+1]];
                [self.activeTableView reloadData];
                [self.afterTableView setReport:[_reports objectAtIndex:idx+2]];
            }
        } else if (idx == _reports.count-2 && x >= screenWidth()){
            NSLog(@"last report");
            idx = [_reports indexOfObject:_reports.lastObject];
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",[(Report*)_reports.lastObject type], [(Report*)_reports.lastObject createdDate]];
            if (_reports.count > 2){
                [self.beforeTableView setReport:[_reports objectAtIndex:idx-2]];
            }
            [self.afterTableView setReport:_reports.lastObject];
            _reportTableView = self.afterTableView;
            
            [self.afterTableView reloadData];
            [self.activeTableView reloadData];
            
        } else if (x >= screenWidth() && idx < _reports.count-2){
            NSLog(@"moved forward");
            idx ++;
            [self.activeTableView setReport:[_reports objectAtIndex:idx]];
            _reportTableView = self.activeTableView;
            if (idx > 0) [self.beforeTableView setReport:[_reports objectAtIndex:idx-1]];
            if (idx < _reports.count - 1) [self.afterTableView setReport:[_reports objectAtIndex:idx+1]];
            
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",_reportTableView.report.type, _reportTableView.report.createdDate];
            [self.activeTableView reloadData];
            [self.afterTableView reloadData];
            [self.beforeTableView reloadData];
            
        } else if (x <= screenWidth() && idx > 1){
            NSLog(@"moved backward: %d",idx);
            idx --;
            [self.activeTableView setReport:[_reports objectAtIndex:idx]];
            [self.beforeTableView setReport:[_reports objectAtIndex:idx-1]];
            [self.afterTableView setReport:[_reports objectAtIndex:idx+1]];
            _reportTableView = self.activeTableView;
            
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",_reportTableView.report.type, _reportTableView.report.createdDate];
            [self.activeTableView reloadData];
            [self.beforeTableView reloadData];
            [self.afterTableView reloadData];
        }
        
        if (idx != 0 && idx != _reports.count-1){
            [_scrollView setContentOffset:CGPointMake(screenWidth(), 0)];
            previousContentOffsetX = screenWidth();
        } else {
            previousContentOffsetX = x;
        }
    }
    [self doneEditing];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == tableView.numberOfSections-1 && indexPath.row == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading

    }
}

- (void)loadReport {
    if (_reportTableView.report.identifier){
        [ProgressHUD show:@"Fetching report..."];
        NSString *slashSafeDate = [_reportTableView.report.createdDate stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
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
        return tableView.report.activities.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(BHReportTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"ReportPickerCell";
        BHReportPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportPickerCell" owner:self options:nil] lastObject];
        }
        [cell configure];
        [cell.typePickerButton setTitle:tableView.report.type forState:UIControlStateNormal];
        if (tableView.report.createdDate.length) {
            [cell.datePickerButton setTitle:tableView.report.createdDate forState:UIControlStateNormal];
            choosingDate = NO;
        } else {
            [cell.datePickerButton setTitle:@"" forState:UIControlStateNormal];
            choosingDate = YES;
        }
        
        [cell.typePickerButton addTarget:self action:@selector(tapTypePicker) forControlEvents:UIControlEventTouchUpInside];
        [cell.datePickerButton addTarget:self action:@selector(showDatePicker:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    } else if (indexPath.section == 1) {
        static NSString *CellIdentifier = @"ReportWeatherCell";
        BHReportWeatherCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            if (IDIOM == IPAD){
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportWeatherCell_iPad" owner:self options:nil] lastObject];
            } else {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportWeatherCell" owner:self options:nil] lastObject];
            }
        }
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
        static NSString *CellIdentifier = @"ReportPersonnelCell";
        BHReportPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportPersonnelCell" owner:self options:nil] lastObject];
        }
        [cell configureCell];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell.choosePersonnelButton addTarget:self action:@selector(showPersonnelActionSheet) forControlEvents:UIControlEventTouchUpInside];
        if (idx > 0){
            [cell.prefillButton setUserInteractionEnabled:YES];
            [cell.prefillButton addTarget:self action:@selector(prefill) forControlEvents:UIControlEventTouchUpInside];
            [cell.prefillButton setAlpha:1];
        } else {
            [cell.prefillButton setUserInteractionEnabled:NO];
            [cell.prefillButton setAlpha:.5];
        }
        return cell;

    } else if (indexPath.section == 3) {
        static NSString *CellIdentifier = @"PersonnelCell";
        BHPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPersonnelCell" owner:self options:nil] lastObject];;
        }
        
        if (tableView.report.reportUsers.count > indexPath.row){
            ReportUser *reportUser = [tableView.report.reportUsers objectAtIndex:indexPath.row];
            [cell.personLabel setText:reportUser.fullname];
            if (reportUser.hours){
                [cell.countTextField setText:[NSString stringWithFormat:@"%@",reportUser.hours]];
            } else {
                [cell.countTextField setText:@"-"];
            }
            [cell.countTextField setPersonnelType:kUserHours];
            [cell.countTextField setHidden:NO];
        }
        
        countTextField = cell.countTextField;
        countTextField.delegate = self;
        [cell.removeButton setTag:indexPath.row];
        [cell.removeButton addTarget:self action:@selector(removeUser:) forControlEvents:UIControlEventTouchUpInside];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    } else if (indexPath.section == 4) {
        static NSString *CellIdentifier = @"SubcontractorCell";
        BHSubcontractorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHSubcontractorCell" owner:self options:nil] lastObject];;
        }
        
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
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChooseTopicsViewCell" owner:self options:nil] lastObject];
        }
        [cell.chooseTopicsButton addTarget:self action:@selector(chooseTopics:) forControlEvents:UIControlEventTouchUpInside];
        [cell configureCell];
        if ([tableView.report.type isEqualToString:kSafety]){
            [cell.chooseTopicsButton setHidden:NO];
        } else {
            [cell.chooseTopicsButton setHidden:YES];
        }
        return cell;
    } else if (indexPath.section == 6) {
        static NSString *CellIdentifier = @"SafetyTopicCell";
        BHSafetyTopicsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHSafetyTopicsCell" owner:self options:nil] lastObject];
        }
        if (tableView.report.safetyTopics.count > indexPath.row){
            SafetyTopic *topic = [tableView.report.safetyTopics objectAtIndex:indexPath.row];
            [cell configureTopic:topic];
            [cell.removeButton setTag:indexPath.row];
            [cell.removeButton addTarget:self action:@selector(removeTopic:) forControlEvents:UIControlEventTouchUpInside];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    } else if (indexPath.section == 7) {
        BHReportPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportPhotoCell" owner:self options:nil] lastObject];
        }
        reportScrollView = cell.photoScrollView;
        photoButtonContainer = cell.photoButtonContainerView;
        [cell.photoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        [cell.libraryButton addTarget:self action:@selector(choosePhoto) forControlEvents:UIControlEventTouchUpInside];
        [self redrawScrollView:tableView];
        return cell;
    } else if (indexPath.section == 8) {
        static NSString *CellIdentifier = @"ReportSectionCell";
        BHReportSectionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportSectionCell" owner:self options:nil] lastObject];
            [self outlineTextView:cell.reportBodyTextView];
        }
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

        return cell;
    } else {
        static NSString *CellIdentifier = @"ActivityCell";
        BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
        }
        Activity *activity = tableView.report.activities[indexPath.row];
        [cell.textLabel setText:activity.body];
        return cell;
    }
}

- (void)outlineTextView:(UITextView*)textView {
    textView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    textView.layer.borderWidth = .5f;
    textView.layer.cornerRadius = 2.f;
    textView.clipsToBounds = YES;
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
        default:
            if (iPhone5){
                return 266;
            } else if (IDIOM == IPAD){
                return 408;
            } else {
                return 180;
            }
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
    } else {
        return 34;
    }
}

- (UIView*)tableView:(BHReportTableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (![tableView.report.type isEqualToString:kDaily] && section == 1){
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else if (section == 0 && ![tableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 34)];
        [headerView setBackgroundColor:kDarkerGrayColor];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,screenWidth(),34)];
        [headerLabel setFont:[UIFont systemFontOfSize:15]];
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        [headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:1]];
            switch (section) {
                case 0:
                    [headerLabel setText:@"Details"];
                    break;
                case 1:
                    [headerLabel setText:@"Weather"];
                    break;
                case 2:
                    [headerLabel setText:@"Personnel"];
                    break;
                case 3:
                {
                    [headerLabel setText:@"Personnel"];
                    [headerLabel setFrame:CGRectMake(5, 0, screenWidth()*2/3, 34)];
                    [headerLabel setTextAlignment:NSTextAlignmentLeft];
                    [headerLabel setTextColor:[UIColor lightGrayColor]];
                    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenWidth()*.65, 0, screenWidth()*.4, 34)];
                    [countLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
                    [countLabel setText:@"# Hours"];
                    [countLabel setFont:[UIFont systemFontOfSize:14]];
                    [countLabel setTextColor:[UIColor lightGrayColor]];
                    [headerView addSubview:countLabel];
                    [headerView setBackgroundColor:[UIColor whiteColor]];
                }
                    break;
                case 4:
                {
                    [headerLabel setText:@"Subcontractors"];
                    [headerLabel setFrame:CGRectMake(5, 0, screenWidth()*2/3, 34)];
                    [headerLabel setTextAlignment:NSTextAlignmentLeft];
                    [headerLabel setTextColor:[UIColor lightGrayColor]];
                    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenWidth()*.65, 0, screenWidth()*.4, 34)];
                    [countLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
                    [countLabel setText:@"# On Site"];
                    [countLabel setFont:[UIFont systemFontOfSize:14]];
                    [countLabel setTextColor:[UIColor lightGrayColor]];
                    [headerView addSubview:countLabel];
                    [headerView setBackgroundColor:[UIColor whiteColor]];
                }
                    break;
                case 5:
                    [headerLabel setText:@"Safety Topics Covered"];
                    [headerView setFrame:CGRectMake(0, 0, 0, 0)];
                    break;
                case 6:
                    [headerView setFrame:CGRectMake(0, 0, 0, 0)];
                    break;
                case 7:
                    if ([tableView.report.type isEqualToString:kSafety]){
                        [headerLabel setText:@"Photo of Sign In Card / Group"];
                    } else {
                        [headerLabel setText:@"Photos"];
                    }
                    break;
                case 8:
                    [headerLabel setText:@"Notes"];
                    break;
                default:
                    [headerLabel setText:@""];
                    break;
            }
        [headerView addSubview:headerLabel];
        return headerView;
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

- (void)showDatePicker:(id)sender{
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
    NSString *dateString = [formatter stringFromDate:self.datePicker.date];
    BOOL duplicate = NO;
    for (Report *report in _project.reports){
        if ([report.type isEqualToString:_report.type] && [report.createdDate isEqualToString:dateString]) duplicate = YES;
    }
    if (duplicate){
        [[[UIAlertView alloc] initWithTitle:@"Duplicate Report" message:@"A report with that date and type already exists." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        _report.createdDate = dateString;
        self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.createdDate];
        [self.beforeTableView reloadData];
        if ([_report.type isEqualToString:kDaily]){
            [self loadWeather:[formatter dateFromString:_report.createdDate] forTableView:self.beforeTableView];
        }
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
    shouldSave = YES;
    self.navigationItem.rightBarButtonItem = doneButton;
    if ([textView.text isEqualToString:kReportPlaceholder] || [textView.text isEqualToString:kWeatherPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor blackColor]];
    }
    
    if (textView.tag == 8){
        
        [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:8] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
    } else if (textView.tag == 1){
        
        [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
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
    shouldSave = YES;
    if (textField == countTextField) {
        [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:3] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isKindOfClass:[BHPersonnelCountTextField class]]) {
        if ([(BHPersonnelCountTextField*)textField personnelType] == kUserHours && textField.tag < _reportTableView.report.reportUsers.count) {
            ReportUser *reportUser = [_reportTableView.report.reportUsers objectAtIndex:textField.tag];
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            reportUser.hours = [f numberFromString:textField.text];
        } else if ([(BHPersonnelCountTextField*)textField personnelType] == kSubcontractorCount && textField.tag < _reportTableView.report.reportSubs.count) {
            ReportSub *reportSub = [_reportTableView.report.reportSubs objectAtIndex:textField.tag];
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            reportSub.count = [f numberFromString:textField.text];
        }
    }
    [self doneEditing];
}

-(void)doneEditing {
    self.navigationItem.rightBarButtonItem = saveCreateButton;
    [self.view endEditing:YES];
}

-(void)tapTypePicker {
    typePickerActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Report Type" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kDaily,kWeekly,kSafety, nil];
    [typePickerActionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    shouldSave = YES;
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (actionSheet == typePickerActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]){
        BOOL duplicate = NO;
        for (Report *report in _project.reports){
            if ([report.type isEqualToString:buttonTitle] && [report.createdDate isEqualToString:_reportTableView.report.createdDate]) duplicate = YES;
        }
        if (!duplicate){
            _reportTableView.report.type = buttonTitle;
            self.title = [NSString stringWithFormat:@"%@ - %@",_reportTableView.report.type, _reportTableView.report.createdDate];
            [self.beforeTableView reloadData];
            if ([_reportTableView.report.type isEqualToString:kDaily]){
                [self loadWeather:[formatter dateFromString:_reportTableView.report.createdDate] forTableView:self.beforeTableView];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Duplicate Report" message:@"A report with that date and type already exists." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    } else if (actionSheet == personnelActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
            
        } else if ([buttonTitle isEqualToString:kIndividual]) {
            [self performSegueWithIdentifier:@"PersonnelPicker" sender:kIndividual];
        } else if ([buttonTitle isEqualToString:kCompany]){
            [self performSegueWithIdentifier:@"PersonnelPicker" sender:kCompany];
        }
        if (idx == 0){
            [self.beforeTableView reloadData];
        } else if (idx == _reports.count - 1){
            [self.afterTableView reloadData];
        } else {
            [self.activeTableView reloadData];
        }
        
    } else if (actionSheet == topicsActionSheet) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"Cancel"]){
            
        } else if ([title isEqualToString:kAddNew]){
            UIAlertView *newTopicAlertView = [[UIAlertView alloc] initWithTitle:@"Custom Safety Topic" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
            newTopicAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [[newTopicAlertView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [newTopicAlertView show];
        } else {
            SafetyTopic *newTopic = [SafetyTopic MR_findFirstByAttribute:@"title" withValue:buttonTitle];
            [_reportTableView.report addSafetyTopic:newTopic];
            [_reportTableView reloadData];
        }
    }
}

- (void)updatePersonnel:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    NSMutableOrderedSet *orderedSet;
    if ([info objectForKey:kUsers]){
        orderedSet = [info objectForKey:kUsers];
        for (ReportUser *reportUser in (NSMutableOrderedSet*)[info objectForKey:kpersonnel]){
            reportUser.report = _reportTableView.report;
            [_reportTableView.report addReportUser:reportUser];
        }
        _reportTableView.report.reportUsers = orderedSet;
        
        [_reportTableView beginUpdates];
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
        
    } else if ([info objectForKey:kSubcontractors]){
        orderedSet = [info objectForKey:kSubcontractors];
        for (ReportSub *reportSub in orderedSet){
            reportSub.report = _reportTableView.report;
        }
        _reportTableView.report.reportSubs = orderedSet;
        
        [_reportTableView beginUpdates];
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    }
    //NSLog(@"update personnel: %@",orderedSet);
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
        [self send];
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Discard"]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Add"]) {
        SafetyTopic *topic = [SafetyTopic MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [topic setTitle:[[alertView textFieldAtIndex:0] text]];
        if (![_reportTableView.report.safetyTopics containsObject:topic]) {
            [_report addSafetyTopic:topic];
            [self.activeTableView reloadData];
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

- (void)existingPhotoButtonTapped:(UIButton*)button;
{
    [self showPhotoDetail:button];
    removePhotoIdx = button.tag;
}

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
        [vc setModalPresentationStyle:UIModalPresentationFullScreen];
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We're unable to access a camera on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [reportScrollView setAlpha:0.0];
    [picker dismissViewControllerAnimated:YES completion:nil];
    Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [newPhoto setImage:[self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]]];

    [_reportTableView beginUpdates];
    [_reportTableView.report addPhoto:newPhoto];
    [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:7] withRowAnimation:UITableViewRowAnimationFade];
    [_reportTableView endUpdates];
    [self saveImage:newPhoto];
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    [self dismissViewControllerAnimated:YES completion:^{
        for (id asset in assets) {
            if (asset != nil) {
                ALAssetRepresentation* representation = [asset defaultRepresentation];
                UIImageOrientation orientation = UIImageOrientationUp;
                NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
                if (orientationValue != nil) {
                    orientation = [orientationValue intValue];
                }
                
                UIImage* image = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                     scale:[UIScreen mainScreen].scale orientation:orientation];
                Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [newPhoto setImage:[self fixOrientation:image]];
                [_reportTableView.report addPhoto:newPhoto];
                [self saveImage:newPhoto];
            }
        }
        [_reportTableView beginUpdates];
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:7] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    }];
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
                NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
            }
        }];
    }
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    [_reportTableView.report removePhoto:photoToRemove];
    [_reportTableView beginUpdates];
    [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:7] withRowAnimation:UITableViewRowAnimationFade];
    [_reportTableView endUpdates];
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
        if (photo.urlSmall.length){
            [imageButton setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal];
        } if (photo.urlThumb.length){
            [imageButton setImageWithURL:[NSURL URLWithString:photo.urlThumb] forState:UIControlStateNormal];
        } else if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        }
        [imageButton setTag:[tableView.report.photos indexOfObject:photo]];
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),reportScrollView.frame.size.height/2-imageSize/2,imageSize, imageSize)];
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        //imageButton.imageView.clipsToBounds = YES;
        imageButton.imageView.layer.cornerRadius = 2.0;
        [imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        [imageButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
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
        [browserPhotos addObject:mwPhoto];
    }
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]) {
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
    NSUInteger currentIdx = [_reports indexOfObject:_reportTableView.report];
    if (currentIdx != NSNotFound && currentIdx > 0) {
        Report *previousReport = [_reports objectAtIndex:currentIdx-1];
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

- (void)showPersonnelActionSheet {
    personnelActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to add?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: kIndividual, kCompany, nil];
    [personnelActionSheet showInView:self.view];
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
            NSLog(@"success getting possible topics: %@",responseObject);
            topicsFetched = YES;
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
        if ([sender isEqualToString:kIndividual]) {
            BHPersonnelPickerViewController *vc = [segue destinationViewController];
            [vc setOrderedUsers:_reportTableView.report.reportUsers.mutableCopy];
            [vc setUsers:_project.users.mutableCopy];
        } else if ([sender isEqualToString:kCompany]){
            BHPersonnelPickerViewController *vc = [segue destinationViewController];
            [vc setOrderedSubs:_reportTableView.report.reportSubs.mutableCopy];
            [vc setCompany:_project.company];
        }
    }
}

- (void)removeUser:(UIButton*)button {
    if (_reportTableView.report.reportUsers.count > button.tag){
        ReportUser *reportUser = [_reportTableView.report.reportUsers objectAtIndex:button.tag];
        if (![_reportTableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) {
            if (reportUser && ![reportUser.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                [parameters setObject:_reportTableView.report.identifier forKey:@"report_id"];
                [parameters setObject:reportUser.userId forKey:@"user_id"];
                [manager DELETE:[NSString stringWithFormat:@"%@/reports/remove_personnel",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    //NSLog(@"success removing user: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failure removing user: %@",error.description);
                }];
            }
        }
        
        [_reportTableView.report removeReportUser:reportUser];
        
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
                    //NSLog(@"success removing report subcontractor: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failure removing report subcontractor: %@",error.description);
                }];
            }
        }
        
        [_reportTableView.report removeReportSubcontractor:reportSub];
        [_reportTableView beginUpdates];
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    }
}

- (void)removeTopic:(UIButton*)button {
    if (button.tag < _reportTableView.report.safetyTopics.count){
        SafetyTopic *topic = [_reportTableView.report.safetyTopics objectAtIndex:button.tag];
        if (![_reportTableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) {
            if (![topic.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                [parameters setObject:_reportTableView.report.identifier forKey:@"report_id"];
                [parameters setObject:topic.identifier forKey:@"safety_topic_id"];
                [manager DELETE:[NSString stringWithFormat:@"%@/safety_topics/%@",kApiBaseUrl,topic.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSLog(@"success removing safety topic: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failure removing safety topic: %@",error.description);
                }];
            }
        }
        NSIndexPath *forDeletion = [NSIndexPath indexPathForRow:button.tag inSection:6];
        [_reportTableView.report removeSafetyTopic:topic];
        
        [_reportTableView beginUpdates];
        [_reportTableView deleteRowsAtIndexPaths:@[forDeletion] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    }
}

- (void)send {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        if ([saveCreateButton.title isEqualToString:@"Save"]){
            [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to create new reports for demo projects." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    } else {
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:_project.identifier forKey:@"project_id"];
        if (_reportTableView.report.weather.length) [parameters setObject:_reportTableView.report.weather forKey:@"weather"];
        if (_reportTableView.report.createdDate.length) [parameters setObject:_reportTableView.report.createdDate forKey:@"created_date"];
        if (_reportTableView.report.type.length) [parameters setObject:_reportTableView.report.type forKey:@"report_type"];
        if (_reportTableView.report.precip.length) [parameters setObject:_reportTableView.report.precip forKey:@"precip"];
        if (_reportTableView.report.humidity.length) [parameters setObject:_reportTableView.report.humidity forKey:@"humidity"];
        if (_reportTableView.report.weatherIcon.length) [parameters setObject:_reportTableView.report.weatherIcon forKey:@"weather_icon"];
        if (_reportTableView.report.body.length){
            [parameters setObject:_reportTableView.report.body forKey:@"body"];
        }
        if (_reportTableView.report.reportUsers.count) {
            NSMutableArray *userArray = [NSMutableArray array];
            for (ReportUser *reportUser in _reportTableView.report.reportUsers) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                if (![reportUser.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) [dict setObject:reportUser.identifier forKey:@"id"];
                if (reportUser.fullname.length) [dict setObject:reportUser.fullname forKey:@"full_name"];
                if (reportUser.hours) [dict setObject:reportUser.hours forKey:@"hours"];
                [userArray addObject:dict];
            }
            if (userArray.count)[parameters setObject:userArray forKey:@"report_users"];
        }
        if (_reportTableView.report.reportSubs.count) {
            NSMutableArray *subArray = [NSMutableArray array];
            for (ReportSub *reportSub in _reportTableView.report.reportSubs) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                if (![reportSub.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) [dict setObject:reportSub.identifier forKey:@"id"];
                if (reportSub.name.length) [dict setObject:reportSub.name forKey:@"name"];
                if (reportSub.count) [dict setObject:reportSub.count forKey:@"count"];
                [subArray addObject:dict];
                
            }
            if (subArray.count)[parameters setObject:subArray forKey:@"report_companies"];
        }
        if (_reportTableView.report.safetyTopics.count) {
            NSMutableArray *topicsArray = [NSMutableArray array];
            for (SafetyTopic *topic in _reportTableView.report.safetyTopics) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                if (![topic.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) [dict setObject:topic.identifier forKey:@"id"];
                if (![topic.topicId isEqualToNumber:[NSNumber numberWithInt:0]]) [dict setObject:topic.topicId forKey:@"topic_id"];
                if (topic.title.length) [dict setObject:topic.title forKey:@"title"];
                //if (topic.info) [dict setObject:topic.info forKey:@"info"];
                [topicsArray addObject:dict];
            }
            if (topicsArray.count)[parameters setObject:topicsArray forKey:@"safety_topics"];
        }
        
        NSOrderedSet *photoSet = [NSOrderedSet orderedSetWithOrderedSet:_reportTableView.report.photos];
        
        if ([_reportTableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [ProgressHUD show:@"Creating report..."];
            
            //assign an author
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"author_id"];
            [manager POST:[NSString stringWithFormat:@"%@/reports",kApiBaseUrl] parameters:@{@"report":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"Success creating report: %@",responseObject);
                if ([responseObject objectForKey:@"duplicate"]){
                    [[[UIAlertView alloc] initWithTitle:@"Report Duplicate" message:@"A report for this date already exists." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    [ProgressHUD dismiss];
                } else {
                    if (photoSet.count){
                        [self uploadPhotos:photoSet forReportId:[[responseObject objectForKey:@"report"] objectForKey:@"id"]];
                    }
                    [_reportTableView.report populateWithDict:[responseObject objectForKey:@"report"]];
                    [_project addReport:_reportTableView.report];
                    
                    [ProgressHUD dismiss];
                    [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report added" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    [self.navigationController popViewControllerAnimated:YES];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while creating this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                NSLog(@"Failure creating report: %@",error.description);
                [ProgressHUD dismiss];
            }];
        } else {
            [ProgressHUD show:@"Saving report..."];
            [manager PATCH:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,_reportTableView.report.identifier] parameters:@{@"report":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"Success updating report: %@",responseObject);
                [_reportTableView.report clearReportUsers];
                [_reportTableView.report populateWithDict:[responseObject objectForKey:@"report"]];
                [ProgressHUD dismiss];
                [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report saved" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while saving this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                NSLog(@"Failure updating report: %@",error.description);
                [ProgressHUD dismiss];
            }];
        }
    }
}

- (void)saveImage:(Photo*)photo {
    [self saveImageToLibrary:photo.image];
    if ([_reportTableView.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        [self redrawScrollView:_reportTableView];
    } else {
        [self uploadPhotos:_reportTableView.report.photos forReportId:_reportTableView.report.identifier];
    }
}

- (void)uploadPhotos:(NSOrderedSet*)photoSet forReportId:(NSNumber*)identifier {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:NO]]){
        for (Photo *photo in photoSet){
            if (photo.image && [photo.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                NSData *imageData = UIImageJPEGRepresentation(photo.image, 1);
                [manager POST:[NSString stringWithFormat:@"%@/reports/photo",kApiBaseUrl] parameters:@{@"photo":@{@"report_id":identifier, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"project_id":_project.identifier, @"source":kReports, @"mobile":[NSNumber numberWithBool:YES],@"company_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]}} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {

                    [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
            
                } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    //NSLog(@"Success posting image to API: %@",responseObject);
                    Report *existingReport = [Report MR_findFirstByAttribute:@"identifier" withValue:identifier];
                    [existingReport populateWithDict:[responseObject objectForKey:@"report"]];
                    
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"failure posting image to API: %@",error.description);
                }];
            }
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"Reloading report after photo posting");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadReport" object:nil userInfo:@{@"report_id":identifier}];
        }];
        
    }
}

- (void)tableView:(BHReportViewController *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 6 && [tableView.report.type isEqualToString:kSafety]){
        SafetyTopic *topic = [tableView.report.safetyTopics objectAtIndex:indexPath.row];
        if (IDIOM == IPAD){
            BHSafetyTopicViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SafetyTopic"];
            [vc setTitle:[NSString stringWithFormat:@"%@ - %@", tableView.report.type, tableView.report.createdDate]];
            [vc setSafetyTopic:topic];
            self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
            self.popover.delegate = self;
            BHSafetyTopicsCell *cell = (BHSafetyTopicsCell*)[(UITableView*)tableView cellForRowAtIndexPath:indexPath];
            [self.popover presentPopoverFromRect:cell.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            
        } else {
            [self showSafetyTopic:topic forReport:tableView.report];
        }
    }
}

-(void)showSafetyTopic:(SafetyTopic*)safetyTopic forReport:(Report*)report {
    BHSafetyTopicViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SafetyTopic"];
    [vc setSafetyTopic:safetyTopic];
    [vc setTitle:[NSString stringWithFormat:@"%@ - %@", report.type, report.createdDate]];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[self saveContext];
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
}

- (void)back {
    if (shouldSave) {
        [[[UIAlertView alloc] initWithTitle:@"Unsaved Changes" message:@"Do you want to save your unsaved changes?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Save", nil] show];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
