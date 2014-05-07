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
#import "Project.h"
#import "BHReportPhotoCell.h"
#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHReportPersonnelCell.h"
#import "BHPersonnelCell.h"
#define kForecastAPIKey @"32a0ebe578f183fac27d67bb57f230b5"
#import "UIButton+WebCache.h"
#import "MWPhotoBrowser.h"
#import "Project.h"
#import "Report.h"
#import "Flurry.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "BHPeoplePickerViewController.h"
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#import "BHChooseTopicsViewCell.h"
#import "BHSafetyTopicsCell.h"
#import "BHSafetyTopic.h"
#import "Sub+helper.h"

static NSString * const kReportPlaceholder = @"Report details...";
static NSString * const kNewReportPlaceholder = @"Add new report";
static NSString * const kPickFromList = @"Pick from company list";
static NSString * const kWeatherPlaceholder = @"Weather notes...";

@interface BHReportViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MWPhotoBrowserDelegate, CTAssetsPickerControllerDelegate> {
    CGFloat width;
    CGFloat height;
    NSDateFormatter *dateFormatter;
    BOOL iPhone5;
    BOOL iPad;
    BOOL choosingDate;
    BOOL saveToLibrary;
    BOOL shouldSave;
    int windBearing;
    NSString *windDirection;
    NSString *windSpeed;
    NSString *weeklySummary;
    NSString *temp;
    NSString *icon;
    NSString *precip;
    NSString *weatherString;
    UITextView *reportBodyTextView;
    UITextView *weatherTextView;
    UIActionSheet *typePickerActionSheet;
    UIActionSheet *personnelActionSheet;
    UIActionSheet *reportActionSheet;
    UIAlertView *addOtherAlertView;
    User *currentUser;
    UIScrollView *reportScrollView;
    AFHTTPRequestOperationManager *manager;
    UIView *photoButtonContainer;
    int removePhotoIdx;
    NSString *currentDateString;
    NSMutableArray *browserPhotos;
    CGFloat previousContentOffsetX;
    UITextField *countTextField;
    ALAssetsLibrary *library;
    UITableView* currentTableView;
    UIActionSheet *topicsActionSheet;
    NSMutableArray *_possibleTopics;
    NSInteger idx;
    Report *activeReport;
    Report *_previousReport;
    Report *_nextReport;
    UIBarButtonItem *saveButton;
}

- (IBAction)cancelDatePicker;
@end

@implementation BHReportViewController

@synthesize report = _report;
@synthesize reports = _reports;
@synthesize project = _project;
@synthesize reportType = _reportType;

- (void)viewDidLoad {
    self.view.backgroundColor = kLighterGrayColor;
    width = screenWidth();
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        iPad = YES;
    } else if ([UIScreen mainScreen].bounds.size.height == 568) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
    
    if (!manager) {
        manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    library = [[ALAssetsLibrary alloc]init];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    currentUser = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
    for (User *user in _project.users){
        NSLog(@"project user: %@ ",user.fullname);
    }
    for (Sub *sub in _project.subs){
        NSLog(@"project sub: %@ ",sub.name);
    }
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    
    self.datePickerContainer.transform = CGAffineTransformMakeTranslation(0, 220);
    [self.datePickerContainer setBackgroundColor:[UIColor colorWithWhite:1 alpha:.95]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePersonnel:) name:@"ReportPersonnel" object:nil];
    
    [Flurry logEvent:@"Viewing reports"];
    
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    [self.scrollView setContentSize:CGSizeMake(screenWidth()*3, screenHeight()-self.navigationController.navigationBar.frame.size.height-[[UIApplication sharedApplication] statusBarFrame].size.height)];
    
    if (_report.identifier && _report.identifier != 0){
        activeReport = _report;
        idx = [_reports indexOfObject:_report];
        if (idx > 0){
            _previousReport = [_reports objectAtIndex:idx-1];
            [self.scrollView setContentOffset:CGPointMake(screenWidth(), 0)];
        }
        _nextReport = [_reports objectAtIndex:idx+1];
        self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.createdDate];
    } else {
        _report = [Report MR_createEntity];
        _report.type = _reportType;
        _report.personnel =[ NSMutableArray array];
        _report.photos = [NSMutableArray array];
        self.title = _reportType;
        
        [self.scrollView setScrollEnabled:NO];
        [self.beforeTableView removeFromSuperview];
        [self.afterTableView removeFromSuperview];
        
        [self.scrollView setContentOffset:CGPointMake(screenWidth(), 0)];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yyyy"];
        NSDate *titleDate = [NSDate date];
        _report.createdAt = titleDate;
        _report.createdDate = [formatter stringFromDate:titleDate];
        [self loadWeather:titleDate forReport:_report];
    }
    [super viewDidLoad];
}

- (void)loadWeather:(NSDate*)reportDate forReport:(Report*)report {
    int dateInt = [reportDate timeIntervalSince1970];
    if (_project.address.latitude && _project.address.longitude) {
        [manager GET:[NSString stringWithFormat:@"https://api.forecast.io/forecast/%@/%@,%@,%i",kForecastAPIKey,_project.address.latitude, _project.address.longitude,dateInt] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"response object %i %@",dateInt,responseObject);
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
            [report setHumidity:[NSString stringWithFormat:@"%.0f%%", [[dailyData objectForKey:@"humidity"] floatValue]*100]];
            [report setPrecip:[NSString stringWithFormat:@"%.0f%%", [[dailyData objectForKey:@"precipProbability"] floatValue]*100]];
            [report setTemp:[NSString stringWithFormat:@"%@° / %@°",max,min]];
            [report setWeatherIcon:[dailyData objectForKey:@"icon"]];
            [report setWeather:[dailyData objectForKey:@"summary"]];
            if ([[[dailyData objectForKey:@"windSpeed"] stringValue] length]){
                windSpeed = [[dailyData objectForKey:@"windSpeed"] stringValue];
                if (windSpeed.length > 3){
                    windSpeed = [windSpeed substringToIndex:3];
                }
            }
            windDirection = [self windDirection:[[responseObject objectForKey:@"windBearing"] intValue]];
            [report setWind:[NSString stringWithFormat:@"%@mph %@",windSpeed, windDirection]];
            weatherString = [NSString stringWithFormat:@"%@. Temp: %@. Wind: %@mph %@.",[dailyData objectForKey:@"summary"],temp,windSpeed, windDirection];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.activeTableView reloadData];
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get the weather: %@",error.description);
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat x = self.scrollView.contentOffset.x;
    if (x >= screenWidth()*2 && idx < _reports.count-2){
        NSLog(@"moved forward");
        Report *reportCopy = _nextReport;
        _report = reportCopy;
        idx ++;
        Report *newNext = [_reports objectAtIndex:idx+1];
        _nextReport = newNext;
        Report *newPrevious = [_reports objectAtIndex:idx-1];
        _previousReport = newPrevious;
        [self.activeTableView reloadData];
        
    } else if (x <= 0 && idx > 1){
        NSLog(@"moved backward");
        Report *reportCopy = _previousReport;
        _report = reportCopy;
        idx --;
        Report *newNext = [_reports objectAtIndex:idx+1];
        _nextReport = newNext;
        Report *newPrevious = [_reports objectAtIndex:idx-1];
        _previousReport = newPrevious;
        [self.activeTableView reloadData];
        
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == tableView.numberOfSections-1 && indexPath.row == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        if (tableView == self.beforeTableView){
            NSLog(@"finished loading before tableview");
        } else if (tableView == self.activeTableView){
            NSLog(@"finished loading active tableview");
            [self.scrollView setContentOffset:CGPointMake(screenWidth(), 0)];
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.createdDate];
            [self.beforeTableView reloadData];
            [self.afterTableView reloadData];
        } else {
            NSLog(@"finished loading after tableview");
        }
    }
}

- (void)loadReport {
    if (_report.identifier){
        [ProgressHUD show:@"Fetching report..."];
        NSString *slashSafeDate = [_report.createdDate stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.activeTableView) {
        activeReport = _report;
    } else if (tableView == self.beforeTableView){
        activeReport = _previousReport;
    } else {
        activeReport = _nextReport;
    }
    return 8;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 && !_reportType.length){
        return  0;
    } else if (section == 3) {
        return (activeReport.subs.count + activeReport.users.count);
    } else if (section == 4){
        if ([activeReport.type isEqualToString:kSafety]){
            return 1;
        } else {
            return 0;
        }
    } else if (section == 5){
        if ([activeReport.type isEqualToString:kSafety]){
            return activeReport.safetyTopics.count;
        } else {
            return 0;
        }
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"ReportPickerCell";
        BHReportPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportPickerCell" owner:self options:nil] lastObject];
        }
        [cell configure];
        [cell.typePickerButton setTitle:activeReport.type forState:UIControlStateNormal];
        if (activeReport.createdDate.length) {
            [cell.datePickerButton setTitle:activeReport.createdDate forState:UIControlStateNormal];
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
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportWeatherCell" owner:self options:nil] lastObject];
        }

        [cell.windTextField setUserInteractionEnabled:NO];
        [cell.tempTextField setUserInteractionEnabled:NO];
        [cell.precipTextField setUserInteractionEnabled:NO];
        [cell.humidityTextField setUserInteractionEnabled:NO];
        
        if (iPad) {
            cell.windLabel.transform = CGAffineTransformMakeTranslation(218, 0);
            cell.windTextField.transform = CGAffineTransformMakeTranslation(224, 0);
            cell.tempLabel.transform = CGAffineTransformMakeTranslation(218, 0);
            cell.tempTextField.transform = CGAffineTransformMakeTranslation(224, 0);
            cell.precipLabel.transform = CGAffineTransformMakeTranslation(218, 0);
            cell.precipTextField.transform = CGAffineTransformMakeTranslation(224, 0);
            cell.humidityLabel.transform = CGAffineTransformMakeTranslation(218, 0);
            cell.humidityTextField.transform = CGAffineTransformMakeTranslation(224, 0);

            cell.dailySummaryTextView.transform = CGAffineTransformMakeTranslation(224, 0);
            cell.weatherImageView.transform = CGAffineTransformMakeTranslation(224, 0);
        }
        
        if (activeReport.weather.length) {
            [cell.dailySummaryTextView setTextColor:[UIColor blackColor]];
            [cell.dailySummaryTextView setText:activeReport.weather];
        } else {
            [cell.dailySummaryTextView setTextColor:[UIColor lightGrayColor]];
            [cell.dailySummaryTextView setText:kWeatherPlaceholder];
        }
        [cell.windLabel setText:@"Wind:"];
        [cell.tempLabel setText:@"Temp:"];
        [cell.humidityLabel setText:@"Humidity:"];
        [cell.precipLabel setText:@"Precip:"];
        
        weatherTextView = cell.dailySummaryTextView;
        weatherTextView.delegate = self;
        
        [cell.tempTextField setText:activeReport.temp];
        [cell.windTextField setText:activeReport.wind];
        [cell.precipTextField setText:activeReport.precip];
        [cell.humidityTextField setText:activeReport.humidity];
        
        if ([activeReport.weatherIcon isEqualToString:@"clear-day"] || [activeReport.weatherIcon isEqualToString:@"clear-night"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"sunny"]];
        else if ([activeReport.weatherIcon isEqualToString:@"cloudy"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"cloudy"]];
        else if ([activeReport.weatherIcon isEqualToString:@"partly-cloudy-day"] || [activeReport.weatherIcon isEqualToString:@"partly-cloudy-night"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"partly"]];
        else if ([activeReport.weatherIcon isEqualToString:@"rain"] || [activeReport.weatherIcon isEqualToString:@"sleet"]) {
            [cell.weatherImageView setImage:[UIImage imageNamed:@"rainy"]];
        } else if ([activeReport.weatherIcon isEqualToString:@"fog"] || [activeReport.weatherIcon isEqualToString:@"wind"]) {
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
        [cell.pickFromListButton addTarget:self action:@selector(pickFromList:) forControlEvents:UIControlEventTouchUpInside];
        /*if (reports.count > 1){
            [cell.prefillButton addTarget:self action:@selector(prefill) forControlEvents:UIControlEventTouchUpInside];
            [cell.prefillButton setAlpha:1];
        } else {
            [cell.prefillButton setUserInteractionEnabled:NO];
            [cell.prefillButton setAlpha:.5];
        }*/
        return cell;

    } else if (indexPath.section == 3) {
        static NSString *CellIdentifier = @"PersonnelCell";
        BHPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPersonnelCell" owner:self options:nil] lastObject];;
        }
        if ((activeReport.subs.count + activeReport.users.count) > indexPath.row){
            id obj = [activeReport.personnel objectAtIndex:indexPath.row];
            if ([obj isKindOfClass:[BHUser class]]){
                [cell.personLabel setText:[(BHUser*)obj fullname]];
                [cell.countTextField setHidden:YES];
            } else if ([obj isKindOfClass:[Sub class]]) {
                [cell.personLabel setText:[(Sub*)obj name]];
                [cell.countTextField setTag:indexPath.row-1];
                [cell.countTextField setText:[NSString stringWithFormat:@"%@",[(Sub*)obj count]]];
                [cell.countTextField setHidden:NO];
            }
        }
        countTextField = cell.countTextField;
        countTextField.delegate = self;
        [cell.removeButton setTag:indexPath.row];
        [cell.removeButton addTarget:self action:@selector(removePersonnel:) forControlEvents:UIControlEventTouchUpInside];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    } else if (indexPath.section == 4) {
        static NSString *CellIdentifier = @"ChooseTopicsCell";
        BHChooseTopicsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChooseTopicsViewCell" owner:self options:nil] lastObject];
        }
        [cell.chooseTopicsButton addTarget:self action:@selector(chooseTopics:) forControlEvents:UIControlEventTouchUpInside];
        [cell configureCell];
        return cell;
    } else if (indexPath.section == 5) {
        static NSString *CellIdentifier = @"SafetyTopicCell";
        BHSafetyTopicsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHSafetyTopicsCell" owner:self options:nil] lastObject];;
        }
        BHSafetyTopic *topic = [activeReport.safetyTopics objectAtIndex:indexPath.row];
        [cell configureTopic:topic];
        [cell.removeButton setTag:indexPath.row];
        [cell.removeButton addTarget:self action:@selector(removeTopic:) forControlEvents:UIControlEventTouchUpInside];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    } else if (indexPath.section == 6) {
        BHReportPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportPhotoCell" owner:self options:nil] lastObject];
        }
        reportScrollView = cell.photoScrollView;
        photoButtonContainer = cell.photoButtonContainerView;
        //if (iPad && !_report.photos.count) photoButtonContainer.transform = CGAffineTransformMakeTranslation(224, 0);
        [cell.photoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        [cell.libraryButton addTarget:self action:@selector(choosePhoto) forControlEvents:UIControlEventTouchUpInside];
        [cell configureCell];
        [self redrawScrollView];
        return cell;
    } else {
        static NSString *CellIdentifier = @"ReportSectionCell";
        BHReportSectionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportSectionCell" owner:self options:nil] lastObject];
            [self outlineTextView:cell.reportBodyTextView];
        }
        [cell configureCell];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell.reportSectionLabel setText:@"General Remarks"];
        
        if (activeReport.body.length) {
            [cell.reportBodyTextView setText:activeReport.body];
            [cell.reportBodyTextView setTextColor:[UIColor darkGrayColor]];
        } else {
            [cell.reportBodyTextView setText:kReportPlaceholder];
            [cell.reportBodyTextView setTextColor:[UIColor lightGrayColor]];
        }
        reportBodyTextView = cell.reportBodyTextView;
        reportBodyTextView.delegate = self;
        return cell;
    }
}

- (void)outlineTextView:(UITextView*)textView {
    textView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    textView.layer.borderWidth = .5f;
    textView.layer.cornerRadius = 2.f;
    textView.clipsToBounds = YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            if (_reportType.length){
                return 70;
            } else {
                return 0;
            }
            break;
        case 1:
            if ([activeReport.type isEqualToString:kDaily]) return 100;
            else return 0;
            break;
        case 2:
            return 120;
            break;
        case 3:
            return 66;
            break;
        case 4:
            if ([activeReport.type isEqualToString:kSafety]) return 80;
            else return 0;
            break;
        case 5:
            if ([activeReport.type isEqualToString:kSafety]) return 66;
            else return 0;
        case 6:
            return 100;
            break;
        default:
            if (iPhone5){
                return 266;
            } else if (iPad){
                return 408;
            } else {
                return 180;
            }
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 && !_reportType.length){
        return 0;
    } else if (section == 3 || section == 5){
        return 0;
    } else if (section == 1 && ![activeReport.type isEqualToString:kDaily]){
        return 0;
    } else if (section == 4 && ![activeReport.type isEqualToString:kSafety]){
        return 0;
    } else {
        return 22;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (![activeReport.type isEqualToString:kDaily] && section == 1){
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else if (section == 0 && !_reportType.length){
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 22)];
        [headerView setBackgroundColor:[UIColor clearColor]];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,screenWidth(),22)];
        [headerLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
        [headerView setBackgroundColor:kDarkerGrayColor];
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        [headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:1]];
            switch (section) {
                case 0:
                    [headerLabel setText:@"Report Info"];
                    break;
                case 1:
                    [headerLabel setText:@"Weather"];
                    break;
                case 2:
                    [headerLabel setText:@"Personnel on Site"];
                    break;
                case 3:
                    [headerView setFrame:CGRectMake(0, 0, 0, 0)];
                    break;
                case 4:
                    [headerLabel setText:@"Safety Topics Covered"];
                    [headerView setFrame:CGRectMake(0, 0, 0, 0)];
                    break;
                case 5:
                    [headerView setFrame:CGRectMake(0, 0, 0, 0)];
                    break;
                case 6:
                    if ([activeReport.type isEqualToString:kSafety]){
                        [headerLabel setText:@"Photo of Sign In Card / Group"];
                    } else {
                        [headerLabel setText:@"Photos"];
                    }
                    break;
                case 7:
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

-(void)textViewDidBeginEditing:(UITextView *)textView {
    shouldSave = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Done" object:nil];
    if ([textView.text isEqualToString:kReportPlaceholder] || [textView.text isEqualToString:kWeatherPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor blackColor]];
    }
    if (textView == reportBodyTextView){
        [self.activeTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:7] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    } else if (textView == weatherTextView){
        [self.activeTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == reportBodyTextView){
        if ([textView.text isEqualToString:@""]) {
            [textView setText:kReportPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
            activeReport.body = @"";
        } else if (textView.text.length){
            activeReport.body = textView.text;
        }
    } else if (textView == weatherTextView) {
        if (textView.text.length) {
            activeReport.weather = textView.text;
        } else {
            activeReport.weather = @"";
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
        [self.activeTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(countTextField.tag+1) inSection:2] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Done" object:nil];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    Sub *sub = [[Sub alloc] init];
    if (textField.tag < (_report.subs.count + _report.users.count)) {
        sub = [_report.personnel objectAtIndex:textField.tag];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        sub.count = [f numberFromString:textField.text];
        [_report.personnel replaceObjectAtIndex:textField.tag withObject:sub];
    }
    [self doneEditing];
    
}

-(void)doneEditing {
    if (_report.identifier){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Save" object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Create" object:nil];
    }
    
    [self.view endEditing:YES];
    [self.activeTableView reloadData];
}

-(void)tapTypePicker {
    typePickerActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Report Type" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kDaily,kWeekly,kSafety, nil];
    [typePickerActionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    shouldSave = YES;
    if (actionSheet == typePickerActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]){
        
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        _report.type = buttonTitle;
        [self loadWeather:nil forReport:_report];
        [self.activeTableView reloadData];
        
    } else if (actionSheet == personnelActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
            
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kAddOther]) {
            addOtherAlertView = [[UIAlertView alloc] initWithTitle:@"Add other personnel" message:@"Enter personnel name(s):" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
            addOtherAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [addOtherAlertView show];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:[NSString stringWithFormat:@"%@ Personnel",currentUser.company.name]]) {
            [self performSegueWithIdentifier:@"PeoplePicker" sender:nil];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kSubcontractors]) {
            [self performSegueWithIdentifier:@"SubPicker" sender:nil];
        }
        [self.activeTableView reloadData];
        
    } else if (actionSheet == topicsActionSheet) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"Cancel"]){
            
        } else if ([title isEqualToString:kAddNew]){
            UIAlertView *newTopicAlertView = [[UIAlertView alloc] initWithTitle:@"New Safety Topic" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
            newTopicAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [newTopicAlertView show];
        } else {
            BHSafetyTopic *newTopic = [[BHSafetyTopic alloc] initWithDictionary:@{@"title":title}];
            if (!_report.safetyTopics){
                _report.safetyTopics = [NSMutableOrderedSet orderedSetWithObject:newTopic];
            } else {
                [_report addSafetyTopic:newTopic];
            }
            [self.activeTableView reloadData];
        }
    }
}

- (void)updatePersonnel:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    _report.personnel = [info objectForKey:kpersonnel];
    [self.activeTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addOtherAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            Sub *sub = [[Sub alloc] init];
            [sub setName:[[alertView textFieldAtIndex:0] text]];
            sub.count = [NSNumber numberWithFloat:0.f];
            if (![_report.personnel containsObject:sub]) {
                [_report.personnel addObject:sub];
                [self addSubToProject:sub];
                [self.activeTableView reloadData];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Already added!" message:@"Personnel already included" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        }
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Save"]) {
        [self save];
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Discard"]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Add"]) {
        BHSafetyTopic *topic = [[BHSafetyTopic alloc] init];
        [topic setTitle:[[alertView textFieldAtIndex:0] text]];
        if (![_report.safetyTopics containsObject:topic]) {
            [_report addSafetyTopic:topic];
            [self.activeTableView reloadData];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil message:@"Safety topic already added." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }
}

- (void)addSubToProject:(Sub*)sub {
    [manager POST:[NSString stringWithFormat:@"%@/subs",kApiBaseUrl] parameters:@{@"name":sub.name,@"project_id":_project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Just added a new sub from reports: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure creating a new sub from reports section: %@",error.description);
    }];
}

- (void)dismissDatePicker:(id)sender {
    CGRect toolbarTargetFrame = CGRectMake(0, self.view.bounds.size.height, width, 44);
    CGRect datePickerTargetFrame = CGRectMake(0, self.view.bounds.size.height+44, width, 216);
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.view viewWithTag:9].alpha = 0;
        [self.view viewWithTag:10].frame = datePickerTargetFrame;
        [self.view viewWithTag:11].frame = toolbarTargetFrame;
        self.scrollView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [[self.view viewWithTag:9] removeFromSuperview];
        [[self.view viewWithTag:10] removeFromSuperview];
        [[self.view viewWithTag:11] removeFromSuperview];
    }];
    
}

- (void)setDate:(id)sender {
    if ([self.view viewWithTag:9]) {
        return;
    }
    CGRect datePickerTargetFrame = CGRectMake(0, self.view.bounds.size.height-216-49, width, 216);
    [(UIButton*)sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    UIView *buttonLayer = [[UIView alloc] initWithFrame:self.view.bounds];
    buttonLayer.alpha = 0;
    buttonLayer.backgroundColor = [UIColor blackColor];
    buttonLayer.tag = 9;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDatePicker:)];
    [buttonLayer addGestureRecognizer:tapGesture];
    [self.view addSubview:buttonLayer];
    
    UIView *backgroundLayer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height+44, width, 216)];
    backgroundLayer.tag = 10;
    [backgroundLayer setBackgroundColor:[UIColor whiteColor]];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, width, 216)];
    [datePicker setDatePickerMode:UIDatePickerModeDate];
    [datePicker addTarget:self action:@selector(loadDate:) forControlEvents:UIControlEventValueChanged];
    
    [backgroundLayer addSubview:datePicker];
    [self.view addSubview:backgroundLayer];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.scrollView.transform = CGAffineTransformMakeTranslation(0, -44);
    [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //toolBar.frame = toolbarTargetFrame;
        backgroundLayer.frame = datePickerTargetFrame;
        buttonLayer.alpha = 0.7;
        self.scrollView.transform = CGAffineTransformMakeTranslation(0, -44);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)photoButtonTapped;
{
    UIActionSheet *actionSheet = nil;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Choose Existing Photo", @"Take Photo", nil];
        [actionSheet showInView:self.view];
    } else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Choose Existing Photo", nil];
        [actionSheet showInView:self.view];
    }
    
}

- (void)existingPhotoButtonTapped:(UIButton*)button;
{
    [self showPhotoDetail:button];
    removePhotoIdx = button.tag;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == personnelActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kAddOther]) {
            
        } else {
            
        }
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove"]) {
        [self removeConfirm];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Photo Gallery"]) {
        [self showPhotoDetail:nil];
    }
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
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [vc setDelegate:self];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [reportScrollView setAlpha:0.0];
    [picker dismissViewControllerAnimated:YES completion:nil];
    BHPhoto *newPhoto = [[BHPhoto alloc] init];
    [newPhoto setImage:[self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]]];
    [_report.photos addObject:newPhoto];
    [self saveImage:newPhoto];
    [self.activeTableView reloadData];
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
                
                CGFloat scale  = 1;
                UIImage* image = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                     scale:scale orientation:orientation];
                BHPhoto *newPhoto = [[BHPhoto alloc] init];
                [newPhoto setImage:[self fixOrientation:image]];
                [_report.photos addObject:newPhoto];
                if (_report.identifier)[self saveImage:newPhoto];
            }
        }
        [self redrawScrollView];
    }];
}

- (UIImage *)fixOrientation:(UIImage*)image {
    
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
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
                // try to get the asset
                [library assetForURL:assetURL
                         resultBlock:^(ALAsset *asset) {
                             // assign the photo to the album
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

-(void)removeConfirm {
    [[[UIAlertView alloc] initWithTitle:@"Please Confirm" message:@"Are you sure you want to delete this photo?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil] show];
}

-(void)removePhoto:(NSNotification*)notification {
    BHPhoto *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    if (photoToRemove.identifier){
        for (BHPhoto *photo in _report.photos){
            if ([photo.identifier isEqualToNumber:photoToRemove.identifier]) {
                [_report.photos removeObject:photo];
                [self redrawScrollView];
                break;
            }
        }
    } else {
        [_report.photos removeObjectAtIndex:removePhotoIdx];
        [self redrawScrollView];
    }
}

- (void)redrawScrollView {
    reportScrollView.delegate = self;
    [reportScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    reportScrollView.showsHorizontalScrollIndicator=NO;
    
    float imageSize = 70.0;
    float space = 4.0;
    int index = 0;
    for (BHPhoto *photo in _report.photos) {
        __weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        //[imageButton setAlpha:0.0];
    
        if (photo.url200.length){
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url200] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                /*[UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];*/
            }];
        } if (photo.url100.length){
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url100] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                /*[UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];*/
            }];
        } else if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
            /*[UIView animateWithDuration:.25 animations:^{
                [imageButton setAlpha:1.0];
            }];*/
        }
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageButton.imageView.clipsToBounds = YES;
        [imageButton setTag:[_report.photos indexOfObject:photo]];
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),6,imageSize, imageSize)];
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
    if ([(NSArray*)_report.photos count]) {
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            photoButtonContainer.transform = CGAffineTransformMakeTranslation(-90, 0);
            [reportScrollView setAlpha:1.0];
        } completion:^(BOOL finished) {
            reportScrollView.layer.shouldRasterize = YES;
            reportScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        }];
    } else {
        if (iPad) {
            photoButtonContainer.transform = CGAffineTransformMakeTranslation(224, 0);
        } else {
            [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                photoButtonContainer.transform = CGAffineTransformIdentity;
                [reportScrollView setAlpha:0.0];
            } completion:^(BOOL finished) {
            }];
        }
    }
}

- (void)showPhotoDetail:(UIButton*)button {
    browserPhotos = [NSMutableArray new];
    for (BHPhoto *photo in _report.photos) {
        MWPhoto *mwPhoto;
        if (photo.image){
            mwPhoto = [MWPhoto photoWithImage:photo.image];
        } else if (photo.urlLarge.length) {
            mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        }
        
        [mwPhoto setBhphoto:photo];
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
    NSUInteger currentIdx = [_reports indexOfObject:_report];
    if (currentIdx != NSNotFound) {
        Report *previousReport = [_reports objectAtIndex:currentIdx-1];
        _report.personnel = [NSMutableArray arrayWithArray:previousReport.personnel];
        for (id obj in _report.personnel){
            if ([obj isKindOfClass:[Sub class]]){
                [(Sub*)obj setCount:[NSNumber numberWithFloat:0.f]];
            }
        }
        [self.activeTableView reloadData];
    }
}

- (void)pickFromList:(id)sender {
    
    personnelActionSheet = [[UIActionSheet alloc] initWithTitle:@"Project Personnel" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: [NSString stringWithFormat:@"%@ Personnel",currentUser.company.name],kSubcontractors, kAddOther, nil];
    [personnelActionSheet showInView:self.view];
}

- (void)chooseTopics:(id)sender {
    topicsActionSheet = [[UIActionSheet alloc] initWithTitle:@"Safety Topics" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (BHSafetyTopic *topic in _possibleTopics){
        [topicsActionSheet addButtonWithTitle:topic.title];
    }
    [topicsActionSheet addButtonWithTitle:kAddNew];
    topicsActionSheet.cancelButtonIndex = [topicsActionSheet addButtonWithTitle:@"Cancel"];
    [topicsActionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PeoplePicker"]){
        BHPeoplePickerViewController *vc = [segue destinationViewController];
        if (_project)[vc setUserArray:_project.users.array];
        [vc setPersonnelArray:_report.personnel];
    } else if ([segue.identifier isEqualToString:@"SubPicker"]){
        BHPeoplePickerViewController *vc = [segue destinationViewController];
        if (_project)[vc setSubArray:_project.subs.array];
        [vc setPersonnelArray:_report.personnel];
    }
}

- (void)removePersonnel:(UIButton*)button {
    id object = [_report.personnel objectAtIndex:button.tag];
    if (_report.identifier && object != nil && object != [NSNull null]) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:_report.identifier forKey:@"report_id"];
        
        if ([object isKindOfClass:[Sub class]]){
            Sub *sub = (Sub*)object;
            if (sub.identifier){
                [parameters setObject:sub.identifier forKey:@"sub_id"];
                [manager DELETE:[NSString stringWithFormat:@"%@/reports/remove_personnel",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    //NSLog(@"success removing personnel: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failure removing personnel: %@",error.description);
                }];
            }
        } else if ([object isKindOfClass:[BHUser class]]) {
            BHUser *user = (BHUser*)object;
            if (user.identifier){
                [parameters setObject:user.identifier forKey:@"user_id"];
                [manager DELETE:[NSString stringWithFormat:@"%@/reports/remove_personnel",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    //NSLog(@"success removing personnel: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failure removing personnel: %@",error.description);
                }];
            }
        }
    }
    NSIndexPath *forDeletion = [NSIndexPath indexPathForRow:button.tag inSection:3];
    [_report.personnel removeObject:object];
    [currentTableView deleteRowsAtIndexPaths:@[forDeletion] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)removeTopic:(UIButton*)button {
    if (button.tag < _report.safetyTopics.count){
        BHSafetyTopic *topic = [_report.safetyTopics objectAtIndex:button.tag];
        if (_report.identifier && topic != nil) {

            if (topic.identifier){
                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                [parameters setObject:_report.identifier forKey:@"report_id"];
                [parameters setObject:topic.identifier forKey:@"safety_topic_id"];
                [manager DELETE:[NSString stringWithFormat:@"%@/safety_topics/%@",kApiBaseUrl,topic.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSLog(@"success removing safety topic: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failure removing safety topic: %@",error.description);
                }];
            }
        }
        NSIndexPath *forDeletion = [NSIndexPath indexPathForRow:button.tag inSection:5];
        [[_report.safetyTopics mutableCopy] removeObject:topic];
    [self.activeTableView deleteRowsAtIndexPaths:@[forDeletion] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)save {
    if (_project.demo){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        [ProgressHUD show:@"Saving report..."];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"author_id"];
        [parameters setObject:_project.identifier forKey:@"project_id"];
        if (_report.weather.length) [parameters setObject:_report.weather forKey:@"weather"];
        if (_report.createdDate.length) [parameters setObject:_report.createdDate forKey:@"created_date"];
        if (_report.type.length) [parameters setObject:_report.type forKey:@"report_type"];
        if (_report.precip.length) [parameters setObject:_report.precip forKey:@"precip"];
        if (_report.humidity.length) [parameters setObject:_report.humidity forKey:@"humidity"];
        if (_report.weatherIcon.length) [parameters setObject:_report.weatherIcon forKey:@"weather_icon"];
        if (reportBodyTextView.text.length && ![reportBodyTextView.text isEqualToString:kReportPlaceholder]) [parameters setObject:reportBodyTextView.text forKey:@"body"];
        if (_report.subs.count + _report.users.count) {
            NSMutableArray *subArray = [NSMutableArray array];
            NSMutableArray *userArray = [NSMutableArray array];
            for (id obj in _report.personnel) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                if ([obj isKindOfClass:[User class]]){
                    User *user = obj;
                    if (user.identifier) [dict setObject:user.identifier forKey:@"id"];
                    if (user.fullname.length) [dict setObject:user.fullname forKey:@"full_name"];
                    if (user.hours) [dict setObject:user.hours forKey:@"hours"];
                    [userArray addObject:dict];
                } else if ([obj isKindOfClass:[Sub class]]) {
                    Sub *sub = obj;
                    if (sub.identifier) [dict setObject:sub.identifier forKey:@"id"];
                    if (sub.name.length) [dict setObject:sub.name forKey:@"name"];
                    if (sub.count) [dict setObject:sub.count forKey:@"count"];
                    [subArray addObject:dict];
                }
            }
            if (subArray.count)[parameters setObject:subArray forKey:@"report_subs"];
            if (userArray.count)[parameters setObject:userArray forKey:@"report_users"];
        }
        if (_report.safetyTopics.count) {
            NSMutableArray *topicsArray = [NSMutableArray array];
            for (BHSafetyTopic *topic in _report.safetyTopics) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                if (topic.identifier) [dict setObject:topic.identifier forKey:@"id"];
                if (topic.title) [dict setObject:topic.title forKey:@"title"];
                [topicsArray addObject:dict];
            }
            if (topicsArray.count)[parameters setObject:topicsArray forKey:@"safety_topics"];
        }

        [manager PUT:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,_report.identifier] parameters:@{@"report":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success updating report: %@",responseObject);
            [_report populateWithDict:[responseObject objectForKey:@"report"]];
        
            [ProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report saved" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while saving this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            NSLog(@"Failure updating report: %@",error.description);
            [ProgressHUD dismiss];
        }];
    }
}

- (void)saveImage:(BHPhoto*)photo {
    [self saveImageToLibrary:photo.image];
    if (_report.identifier){
        [self uploadPhoto:photo.image withReportId:_report.identifier];
    } else {
        [self redrawScrollView];
    }
}

- (void)uploadPhoto:(UIImage*)image withReportId:(NSNumber*)reportId {
    if (_project.demo){
        
    } else {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        [manager POST:[NSString stringWithFormat:@"%@/reports/photo",kApiBaseUrl] parameters:@{@"photo[report_id]":reportId, @"photo[user_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"photo[project_id]":_project.identifier, @"photo[source]":kReports, @"photo[company_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success posting image to API: %@",responseObject);
            Report *newReport = [Report MR_createEntity];
            [newReport populateWithDict:[responseObject objectForKey:@"report"]];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"failure posting image to API: %@",error.description);
        }];
    }
}

- (void)createNewReport {
    if (_project.demo){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to create new reports for demo projects." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        [ProgressHUD show:@"Creating report..."];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:_project.identifier forKey:@"project_id"];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"author_id"];
        if (_report.weather.length) [parameters setObject:_report.weather forKey:@"weather"];
        if (_report.wind) [parameters setObject:_report.wind forKey:@"wind"];
        if (_report.temp.length) [parameters setObject:_report.temp forKey:@"temp"];
        if (_report.precip.length) [parameters setObject:_report.precip forKey:@"precip"];
        if (_report.humidity.length) [parameters setObject:_report.humidity forKey:@"humidity"];
        if (_report.weatherIcon.length) [parameters setObject:_report.weatherIcon forKey:@"weather_icon"];
        if (_report.createdDate.length) [parameters setObject:_report.createdDate forKey:@"created_date"];
        if (_report.type.length) [parameters setObject:_report.type forKey:@"report_type"];
        if (reportBodyTextView.text.length && ![reportBodyTextView.text isEqualToString:kReportPlaceholder]) [parameters setObject:reportBodyTextView.text forKey:@"body"];

        if (_report.users.count + _report.subs.count) {
            NSMutableArray *subArray = [NSMutableArray array];
            NSMutableArray *userArray = [NSMutableArray array];
            for (id obj in _report.personnel) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                if ([obj isKindOfClass:[User class]]){
                    User *user = obj;
                    if (user.identifier) [dict setObject:user.identifier forKey:@"id"];
                    if (user.fullname.length) [dict setObject:user.fullname forKey:@"full_name"];
                    if (user.hours) [dict setObject:user.hours forKey:@"hours"];
                    [userArray addObject:dict];
                } else if ([obj isKindOfClass:[Sub class]]) {
                    Sub *sub = obj;
                    if (sub.identifier) [dict setObject:sub.identifier forKey:@"id"];
                    if (sub.name.length) [dict setObject:sub.name forKey:@"name"];
                    if (sub.count) [dict setObject:sub.count forKey:@"count"];
                    [subArray addObject:dict];
                }
            }
            if (subArray.count)[parameters setObject:subArray forKey:@"report_subs"];
            if (userArray.count)[parameters setObject:userArray forKey:@"report_users"];
        }
        if (_report.safetyTopics.count) {
            NSMutableArray *topicsArray = [NSMutableArray array];
            for (BHSafetyTopic *topic in _report.safetyTopics) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                if (topic.identifier) [dict setObject:topic.identifier forKey:@"id"];
                if (topic.title) [dict setObject:topic.title forKey:@"title"];
                [topicsArray addObject:dict];
            }
            if (topicsArray.count)[parameters setObject:topicsArray forKey:@"safety_topics"];
        }

        [manager POST:[NSString stringWithFormat:@"%@/reports",kApiBaseUrl] parameters:@{@"report":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success creating report: %@",responseObject);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Save" object:nil];
            NSMutableArray *storedPhotos = [NSMutableArray arrayWithArray:_report.photos];
            Report *newReport = [Report MR_createEntity];
            [newReport populateWithDict:[responseObject objectForKey:@"report"]];
            //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type == %@) AND (createdDate == %@)",_report.type, _report.createdDate];
            
            _report.photos = storedPhotos;
            if (_report.identifier){
                for (BHPhoto *photo in _report.photos) {
                    if (photo.image){
                        [self uploadPhoto:photo.image withReportId:_report.identifier];
                    }
                }
            }
            [self.activeTableView reloadData];
            [ProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report added" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while creating this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            NSLog(@"Failure updating report: %@",error.description);
            [ProgressHUD dismiss];
        }];
    }
}

- (IBAction)cancelDatePicker{
    [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.datePickerContainer.transform = CGAffineTransformMakeTranslation(0, 220);
        self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
        [self.overlayView setAlpha:0];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)showDatePicker:(UIButton*)button{
    [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.datePickerContainer.transform = CGAffineTransformIdentity;
        [self.overlayView setAlpha:0.70];
        if (iPad)
            self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 52);
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
    _report.createdDate = dateString;
    self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.createdDate];
    [self.activeTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self saveContext];
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Remove" object:nil];
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"What happened during report save? %hhd %@",success, error);
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
