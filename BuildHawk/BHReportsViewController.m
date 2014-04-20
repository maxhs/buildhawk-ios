//
//  BHReportsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHReportsViewController.h"
#import "BHReportPickerCell.h"
#import "BHReportSectionCell.h"
#import "BHReportWeatherCell.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "BHTabBarViewController.h"
#import "BHProject.h"
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

static NSString * const kReportPlaceholder = @"Report details...";
static NSString * const kNewReportPlaceholder = @"Add new report";
static NSString * const kPickFromList = @"Pick from company list";
static NSString * const kWeatherPlaceholder = @"Weather notes...";

@interface BHReportsViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MWPhotoBrowserDelegate, CTAssetsPickerControllerDelegate> {
    NSMutableArray *reports;
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
    BHProject *project;
    UIScrollView *reportScrollView;
    AFHTTPRequestOperationManager *manager;
    UIView *photoButtonContainer;
    CGRect screen;
    Project *savedProject;
    int removePhotoIdx;
    NSString *currentDateString;
    NSMutableArray *browserPhotos;
    CGFloat previousContentOffsetX;
    NSInteger page;
    UITextField *countTextField;
    ALAssetsLibrary *library;
    UIRefreshControl *refreshControl;
    UITableView* currentTableView;
    UIActionSheet *topicsActionSheet;
    NSMutableArray *_possibleTopics;
}

- (IBAction)cancelDatePicker;
@end

@implementation BHReportsViewController

@synthesize report = _report;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    screen = [[UIScreen mainScreen] bounds];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        iPad = YES;
    } else if ([UIScreen mainScreen].bounds.size.height == 568) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
    project = [(BHTabBarViewController*)self.tabBarController project];
    
    if (!manager) {
        manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    library = [[ALAssetsLibrary alloc]init];
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", project.identifier];
    savedProject = [Project MR_findFirstWithPredicate:predicate inContext:localContext];
    
    self.navigationController.title = [NSString stringWithFormat:@"%@",project.name];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    if (!reports) reports = [NSMutableArray array];
    
    self.datePickerContainer.transform = CGAffineTransformMakeTranslation(0, 220);
    [self.datePickerContainer setBackgroundColor:[UIColor colorWithWhite:1 alpha:.95]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePersonnel:) name:@"ReportPersonnel" object:nil];
    
    [self loadReports];
    [Flurry logEvent:@"Viewing report"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createNewReport) name:@"CreateReport" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:@"SaveReport" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doneEditing) name:@"DoneEditing" object:nil];
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)handleRefresh:(id)sender {
    [self loadReport];
}

- (void)loadWeather:(NSDate*)reportDate forReport:(BHReport*)report {
    int dateInt = [reportDate timeIntervalSince1970];
    if (project.address.latitude && project.address.longitude) {
        [manager GET:[NSString stringWithFormat:@"https://api.forecast.io/forecast/%@/%f,%f,%i",kForecastAPIKey,project.address.latitude, project.address.longitude,dateInt] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!currentTableView && reports.count) {
        page = reports.count - 1;
        currentTableView = (UITableView*)[self.scrollView.subviews objectAtIndex:page];
        [currentTableView reloadData];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    if (reports.count && _report.identifier.length){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Save" object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Create" object:nil];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.scrollView && previousContentOffsetX != scrollView.contentOffset.x){
        float fractionalPage = scrollView.contentOffset.x / screen.size.width;
        page = lround(fractionalPage);
        _report = [reports objectAtIndex:page];
        if (_report.identifier.length) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Save" object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Create" object:nil];
        }
        currentTableView = (UITableView*)[self.scrollView.subviews objectAtIndex:page];
        [currentTableView reloadData];
        previousContentOffsetX = scrollView.contentOffset.x;
    }
}
- (void)loadReport {
    if (_report.identifier.length){
        [SVProgressHUD showWithStatus:@"Fetching report..."];
        NSString *slashSafeDate = [_report.createdDate stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        [manager GET:[NSString stringWithFormat:@"%@/reports/%@/review_report",kApiBaseUrl,project.identifier] parameters:@{@"date_string":slashSafeDate} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting report: %@",responseObject);
            _report = [[BHReport alloc] initWithDictionary:[responseObject objectForKey:@"report"]];
            [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
            [SVProgressHUD dismiss];
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error getting report: %@",error.description);
            [SVProgressHUD dismiss];
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        }];
    } else {
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    }
}

- (void)loadReports {
    [SVProgressHUD showWithStatus:@"Fetching reports..." maskType:SVProgressHUDMaskTypeGradient];
    [manager GET:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success getting reports: %@",responseObject);
        [self loadOptions];
        reports = [BHUtilities reportsFromJSONArray:[responseObject objectForKey:@"reports"]];
        [self saveToMR];
        previousContentOffsetX = screen.size.width*reports.count;
        [self drawReports];
        [SVProgressHUD dismiss];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [self performSelector:@selector(refreshReport) withObject:nil afterDelay:.01];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting reports: %@",error.description);
        [SVProgressHUD dismiss];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    }];
}

- (void)loadOptions {
    [manager GET:[NSString stringWithFormat:@"%@/reports/options",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting possible topics: %@",responseObject);
        _possibleTopics = [BHUtilities safetyTopicsFromJSONArray:[responseObject objectForKey:@"possible_topics"]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed to get possible topics: %@",error.description);
    }];
}

- (void)saveToMR {
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];

    for (BHReport *rep in reports) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", rep.identifier];
        Report *savedReport = [Report MR_findFirstWithPredicate:predicate inContext:localContext];
        if (savedReport){
            //NSLog(@"found saved report %@",rep.createdDate);
            savedReport.identifier = rep.identifier;
            savedReport.createdDate = rep.createdDate;
        } else {
            //NSLog(@"had to create a new report for createdDate: %@",rep.createdDate);
            Report *newReport = [Report MR_createInContext:localContext];
            newReport.identifier = rep.identifier;
            newReport.createdDate = rep.createdDate;
        }
    }
    
    [localContext MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        //NSLog(@"Any errors saving Reports? %@",error);
    }];
}

- (void)refreshReport {
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
}

- (void)drawReports{
    if (reports.count) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yyyy"];
        NSString *dateString = [formatter stringFromDate:[NSDate date]];
        NSPredicate *testForTrue = [NSPredicate predicateWithFormat:@"createdDate == %@",dateString];
        BOOL foundReport = NO;
        for (BHReport *report in reports){
            if([testForTrue evaluateWithObject:report]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Save" object:nil];
                foundReport = YES;
                if (iPad) {
                    [self.scrollView setContentSize:CGSizeMake(reports.count*screen.size.width,self.scrollView.frame.size.height-300)];
                } else {
                    [self.scrollView setContentSize:CGSizeMake(reports.count*screen.size.width,self.scrollView.frame.size.height-113)];
                }
                break;
            }
        }
        if (!foundReport) {
            [self newReportObject:dateString andType:nil];
        }
        
        int idx = 1;
        page = reports.count - 1;
        for (BHReport *report in reports){
            if (report != reports.lastObject){                
                UITableView *newTableView = [[UITableView alloc] init];
                newTableView.delegate = self;
                newTableView.dataSource = self;
                newTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                [newTableView setFrame:CGRectMake((screen.size.width * idx), 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
                [newTableView setContentInset:self.tableView.contentInset];
                newTableView.autoresizingMask = self.tableView.autoresizingMask;
                [self.scrollView addSubview:newTableView];
            }
            idx ++;
            _report = report;
        }

        //[(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
        [self.scrollView setContentOffset:CGPointMake((screen.size.width*reports.count)-screen.size.width, self.scrollView.contentOffset.y) animated:NO];

    } else {
        //There are no existing reports
        [self newReportObject:nil andType:nil];
        _report = reports.firstObject;
        [self.tableView reloadData];
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
    return 8;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 3) {
        return (_report.personnel.count);
    } else if (section == 4){
        if ([_report.type isEqualToString:kSafety]){
            return 1;
        } else {
            return 0;
        }
    } else if (section == 5){
        if ([_report.type isEqualToString:kSafety]){
            return _report.safetyTopics.count;
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
        [cell.typePickerButton setTitle:_report.type forState:UIControlStateNormal];
        if (_report.createdDate.length) {
            [cell.datePickerButton setTitle:_report.createdDate forState:UIControlStateNormal];
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
        
        if (_report.weather.length) {
            [cell.dailySummaryTextView setTextColor:[UIColor blackColor]];
            [cell.dailySummaryTextView setText:_report.weather];
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
        
        [cell.tempTextField setText:_report.temp];
        [cell.windTextField setText:_report.wind];
        [cell.precipTextField setText:_report.precip];
        [cell.humidityTextField setText:_report.humidity];
        
        if ([_report.weatherIcon isEqualToString:@"clear-day"] || [_report.weatherIcon isEqualToString:@"clear-night"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"sunny"]];
        else if ([_report.weatherIcon isEqualToString:@"cloudy"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"cloudy"]];
        else if ([_report.weatherIcon isEqualToString:@"partly-cloudy-day"] || [_report.weatherIcon isEqualToString:@"partly-cloudy-night"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"partly"]];
        else if ([_report.weatherIcon isEqualToString:@"rain"] || [_report.weatherIcon isEqualToString:@"sleet"]) {
            [cell.weatherImageView setImage:[UIImage imageNamed:@"rainy"]];
        } else if ([_report.weatherIcon isEqualToString:@"fog"] || [_report.weatherIcon isEqualToString:@"wind"]) {
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
        if (reports.count > 1){
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
        if (_report.personnel && _report.personnel.count && [_report.personnel objectAtIndex:indexPath.row]){
            id obj = [_report.personnel objectAtIndex:indexPath.row];
            if ([obj isKindOfClass:[BHUser class]]){
                [cell.personLabel setText:[(BHUser*)obj fullname]];
                [cell.countTextField setText:@"1"];
                [cell.countTextField setUserInteractionEnabled:NO];
            } else if ([obj isKindOfClass:[BHSub class]]) {
                [cell.personLabel setText:[(BHSub*)obj name]];
                [cell.countTextField setTag:indexPath.row-1];
                [cell.countTextField setText:[NSString stringWithFormat:@"%@",[(BHSub*)obj count]]];
                [cell.countTextField setUserInteractionEnabled:YES];
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
        BHSafetyTopic *topic = [_report.safetyTopics objectAtIndex:indexPath.row];
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
        
        if (_report.body.length) {
            [cell.reportBodyTextView setText:_report.body];
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

- (void)pickReport {
    reportActionSheet = [[UIActionSheet alloc] initWithTitle:@"Reports" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (BHReport *report in reports) {
        [reportActionSheet addButtonWithTitle:report.createdDate];
    }
    [reportActionSheet addButtonWithTitle:kNewReportPlaceholder];
    reportActionSheet.cancelButtonIndex = [reportActionSheet addButtonWithTitle:@"Cancel"];
    [reportActionSheet showFromTabBar:self.tabBarController.tabBar];
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
            return 70;
            break;
        case 1:
            if ([_report.type isEqualToString:kDaily]) return 100;
            else return 0;
            break;
        case 2:
            return 120;
            break;
        case 3:
            return 66;
            break;
        case 4:
            if ([_report.type isEqualToString:kSafety]) return 80;
            else return 0;
            break;
        case 5:
            if ([_report.type isEqualToString:kSafety]) return 66;
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
    if (section == 3 || section == 5){
        return 0;
    } else if (section == 1 && ![_report.type isEqualToString:kDaily]){
        return 0;
    } else if (section == 4 && ![_report.type isEqualToString:kSafety]){
        return 0;
    } else {
        return 22;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (![_report.type isEqualToString:kDaily] && section == 1){
        return nil;
    } else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 22)];
        [headerView setBackgroundColor:[UIColor clearColor]];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,screen.size.width,22)];
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
                    if ([_report.type isEqualToString:kSafety]){
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

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        //[tableView addSubview:refreshControl];
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
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:7] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    } else if (textView == weatherTextView){
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == reportBodyTextView){
        if ([textView.text isEqualToString:@""]) {
            [textView setText:kReportPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
            _report.body = @"";
        } else if (textView.text.length){
            _report.body = textView.text;
        }
    } else if (textView == weatherTextView) {
        if (textView.text.length) {
            _report.weather = textView.text;
        } else {
            _report.weather = @"";
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
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(countTextField.tag+1) inSection:2] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Done" object:nil];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    BHSub *sub = [[BHSub alloc] init];
    if (textField.tag < _report.personnel.count) {
        sub = [_report.personnel objectAtIndex:textField.tag];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        sub.count = textField.text;
        [_report.personnel replaceObjectAtIndex:textField.tag withObject:sub];
    }
    [self doneEditing];
    
}

-(void)doneEditing {
    if (_report.identifier.length){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Save" object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Create" object:nil];
    }
    
    [self.view endEditing:YES];
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
}

-(void)tapTypePicker {
    typePickerActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Report Type" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kDaily,kWeekly,kSafety, nil];
    [typePickerActionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    shouldSave = YES;
    if (actionSheet == typePickerActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]){
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type == %@) AND (createdDate == %@)",buttonTitle, _report.createdDate];
        for (BHReport *report in reports){
            if([predicate evaluateWithObject:report]) {
                NSLog(@"found report: %@ %@ %@",report.createdDate, report.type, report.identifier);
                _report = report;
                _report.type = buttonTitle;
                NSUInteger reportIdx = [reports indexOfObject:report];
                [self.scrollView setContentOffset:CGPointMake(screen.size.width*reportIdx, self.scrollView.contentOffset.y) animated:YES];
                [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
                if (_report.identifier.length){
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Save" object:nil];
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Create" object:nil];
                }
                return;
            }
        }
        
        [self newReportObject:_report.createdDate andType:buttonTitle];
        int idx = reports.count-1;
        page = reports.count-1;
        UITableView *newTableView = [[UITableView alloc] init];
        newTableView.delegate = self;
        newTableView.dataSource = self;
        newTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [newTableView setFrame:CGRectMake((screen.size.width * idx), 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
        [newTableView setContentInset:self.tableView.contentInset];
        newTableView.autoresizingMask = self.tableView.autoresizingMask;
        [self.scrollView addSubview:newTableView];
        _report = reports.lastObject;
        
        if (iPad) {
            [self.scrollView setContentSize:CGSizeMake(reports.count*screen.size.width,self.scrollView.frame.size.height-300)];
        } else {
            [self.scrollView setContentSize:CGSizeMake(reports.count*screen.size.width,self.scrollView.frame.size.height-113)];
        }
        [self.scrollView setContentOffset:CGPointMake(screen.size.width*idx, self.scrollView.contentOffset.y) animated:YES];
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Create" object:nil];
        
    } else if (actionSheet == personnelActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
            
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kAddOther]) {
            addOtherAlertView = [[UIAlertView alloc] initWithTitle:@"Add other personnel" message:@"Enter personnel name(s):" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
            addOtherAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [addOtherAlertView show];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kUsers]) {
            [self performSegueWithIdentifier:@"PeoplePicker" sender:nil];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kSubcontractors]) {
            [self performSegueWithIdentifier:@"SubPicker" sender:nil];
        }
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
        
    } else if (actionSheet == reportActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kNewReportPlaceholder]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Create" object:nil];
            [self newReportObject:nil andType:nil];
        } else {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", [reportActionSheet buttonTitleAtIndex:buttonIndex]];
            for (BHReport *report in reports){
                if([predicate evaluateWithObject:report.createdDate]) {
                    _report = report;
                    break;
                }
            }
        }
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
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
                _report.safetyTopics = [NSMutableArray arrayWithObject:newTopic];
            } else {
                [_report.safetyTopics addObject:newTopic];
            }
            [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
        }
    }
}

- (void)updatePersonnel:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    _report.personnel = [info objectForKey:kpersonnel];
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)newReportObject:(NSString*)dateParam andType:(NSString*)reportType {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Create" object:nil];
    BHReport *newReport = [[BHReport alloc] init];
    if (reportType && reportType.length){
        newReport.type = reportType;
    } else {
        newReport.type = kDaily;
    }
    newReport.personnel = [NSMutableArray array];
    newReport.photos = [NSMutableArray array];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    if (dateParam.length){
        newReport.createdDate = dateParam;
        [self loadWeather:[formatter dateFromString:dateParam] forReport:newReport];
    } else {
        NSDate *titleDate = [NSDate date];
        newReport.createdAt = titleDate;
        newReport.createdDate = [formatter stringFromDate:titleDate];
        [self loadWeather:titleDate forReport:newReport];
    }
    
    [reports addObject:newReport];
    _report = newReport;
    if (iPad) {
        [self.scrollView setContentSize:CGSizeMake(reports.count*screen.size.width,self.scrollView.frame.size.height-300)];
    } else {
        [self.scrollView setContentSize:CGSizeMake(reports.count*screen.size.width,self.scrollView.frame.size.height-113)];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addOtherAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            BHSub *sub = [[BHSub alloc] init];
            [sub setName:[[alertView textFieldAtIndex:0] text]];
            sub.count = @"0";
            if (![_report.personnel containsObject:sub]) {
                [_report.personnel addObject:sub];
                [self addSubToProject:sub];
                [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
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
            [_report.safetyTopics addObject:topic];
            [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil message:@"Safety topic already added." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }
}

- (void)addSubToProject:(BHSub*)sub {
    [manager POST:[NSString stringWithFormat:@"%@/subs",kApiBaseUrl] parameters:@{@"name":sub.name,@"project_id":project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Just added a new sub from reports: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure creating a new sub from reports section: %@",error.description);
    }];
}

- (void)dismissDatePicker:(id)sender {
    CGRect toolbarTargetFrame = CGRectMake(0, self.view.bounds.size.height, screen.size.width, 44);
    CGRect datePickerTargetFrame = CGRectMake(0, self.view.bounds.size.height+44, screen.size.width, 216);
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
    CGRect datePickerTargetFrame = CGRectMake(0, self.view.bounds.size.height-216-49, screen.size.width, 216);
    [(UIButton*)sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    UIView *buttonLayer = [[UIView alloc] initWithFrame:self.view.bounds];
    buttonLayer.alpha = 0;
    buttonLayer.backgroundColor = [UIColor blackColor];
    buttonLayer.tag = 9;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDatePicker:)];
    [buttonLayer addGestureRecognizer:tapGesture];
    [self.view addSubview:buttonLayer];
    
    UIView *backgroundLayer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height+44, screen.size.width, 216)];
    backgroundLayer.tag = 10;
    [backgroundLayer setBackgroundColor:[UIColor whiteColor]];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 216)];
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
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
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
    if (photoToRemove.identifier.length){
        for (BHPhoto *photo in _report.photos){
            if ([photo.identifier isEqualToString:photoToRemove.identifier]) {
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
    if (_report.photos.count) {
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
    if (project.demo == YES) {
        browser.displayTrashButton = NO;
    }
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = NO;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0){
        browser.wantsFullScreenLayout = YES; //
    }
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
    NSUInteger currentIdx = [reports indexOfObject:_report];
    if (currentIdx != NSNotFound) {
        BHReport *previousReport = [reports objectAtIndex:currentIdx-1];
        _report.personnel = [NSMutableArray arrayWithArray:previousReport.personnel];
        for (id obj in _report.personnel){
            if ([obj isKindOfClass:[BHSub class]]){
                [(BHSub*)obj setCount:@"0"];
            }
        }
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
    }
}

- (void)pickFromList:(id)sender {
    personnelActionSheet = [[UIActionSheet alloc] initWithTitle:@"Project Personnel" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: kUsers,kSubcontractors, kAddOther, nil];
    [personnelActionSheet showFromTabBar:self.tabBarController.tabBar];
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
        if (savedProject)[vc setUserArray:savedProject.users];
        [vc setPersonnelArray:_report.personnel];
    } else if ([segue.identifier isEqualToString:@"SubPicker"]){
        BHPeoplePickerViewController *vc = [segue destinationViewController];
        if (savedProject)[vc setSubArray:savedProject.subs];
        [vc setPersonnelArray:_report.personnel];
    }
}

- (void)removePersonnel:(UIButton*)button {
    id object = [_report.personnel objectAtIndex:button.tag];
    if (_report.identifier.length && object != nil && object != [NSNull null]) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:_report.identifier forKey:@"report_id"];
        
        if ([object isKindOfClass:[BHSub class]]){
            BHSub *sub = (BHSub*)object;
            if (sub.identifier.length){
                [parameters setObject:sub.identifier forKey:@"sub_id"];
                [manager DELETE:[NSString stringWithFormat:@"%@/reports/remove_personnel",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    //NSLog(@"success removing personnel: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failure removing personnel: %@",error.description);
                }];
            }
        } else if ([object isKindOfClass:[BHUser class]]) {
            BHUser *user = (BHUser*)object;
            if (user.identifier.length){
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
        if (_report.identifier.length && topic != nil) {

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
        [_report.safetyTopics removeObject:topic];
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] deleteRowsAtIndexPaths:@[forDeletion] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)save {
    if (project.demo){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        [SVProgressHUD showWithStatus:@"Saving report..."];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"author_id"];
        [parameters setObject:project.identifier forKey:@"project_id"];
        if (_report.weather.length) [parameters setObject:_report.weather forKey:@"weather"];
        if (_report.createdDate.length) [parameters setObject:_report.createdDate forKey:@"created_date"];
        if (_report.type.length) [parameters setObject:_report.type forKey:@"report_type"];
        if (_report.precip.length) [parameters setObject:_report.precip forKey:@"precip"];
        if (_report.humidity.length) [parameters setObject:_report.humidity forKey:@"humidity"];
        if (_report.weatherIcon.length) [parameters setObject:_report.weatherIcon forKey:@"weather_icon"];
        if (reportBodyTextView.text.length && ![reportBodyTextView.text isEqualToString:kReportPlaceholder]) [parameters setObject:reportBodyTextView.text forKey:@"body"];
        if (_report.personnel.count) {
            NSMutableArray *subArray = [NSMutableArray array];
            NSMutableArray *userArray = [NSMutableArray array];
            for (id obj in _report.personnel) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                if ([obj isKindOfClass:[BHUser class]]){
                    BHUser *user = obj;
                    if (user.identifier.length) [dict setObject:user.identifier forKey:@"id"];
                    if (user.fullname.length) [dict setObject:user.fullname forKey:@"full_name"];
                    [userArray addObject:dict];
                } else if ([obj isKindOfClass:[BHSub class]]) {
                    BHSub *sub = obj;
                    if (sub.identifier.length) [dict setObject:sub.identifier forKey:@"id"];
                    if (sub.name.length) [dict setObject:sub.name forKey:@"name"];
                    if (sub.count) [dict setObject:[NSString stringWithFormat:@"%@",sub.count] forKey:@"count"];
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
            BHReport *newReport = [[BHReport alloc] initWithDictionary:[responseObject objectForKey:@"report"]];
            for (BHReport *report in reports){
                if ([report.identifier isEqualToString:newReport.identifier]) {
                    [reports replaceObjectAtIndex:[reports indexOfObject:report] withObject:newReport];
                    break;
                }
            }
            [SVProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report saved" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while saving this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            NSLog(@"Failure updating report: %@",error.description);
            [SVProgressHUD dismiss];
        }];
    }
}

- (void)saveImage:(BHPhoto*)photo {
    [self saveImageToLibrary:photo.image];
    if (_report.identifier.length){
        [self uploadPhoto:photo.image withReportId:_report.identifier];
    } else {
        [self redrawScrollView];
    }
}

- (void)uploadPhoto:(UIImage*)image withReportId:(NSString*)reportId {
    if (project.demo){
        
    } else {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        [manager POST:[NSString stringWithFormat:@"%@/reports/photo",kApiBaseUrl] parameters:@{@"photo[report_id]":reportId, @"photo[user_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"photo[project_id]":project.identifier, @"photo[source]":kReports, @"photo[company_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success posting image to API: %@",responseObject);
            BHReport *newReport = [[BHReport alloc] initWithDictionary:[responseObject objectForKey:@"report"]];
            for (BHReport *report in reports){
                if ([report.identifier isEqualToString:newReport.identifier]) {
                    [reports replaceObjectAtIndex:[reports indexOfObject:report] withObject:newReport];
                    break;
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"failure posting image to API: %@",error.description);
        }];
    }
}

- (void)createNewReport {
    if (project.demo){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to create new reports for demo projects." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        [SVProgressHUD showWithStatus:@"Creating report..."];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:project.identifier forKey:@"project_id"];
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

        if (_report.personnel.count) {
            NSMutableArray *subArray = [NSMutableArray array];
            NSMutableArray *userArray = [NSMutableArray array];
            for (id obj in _report.personnel) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                if ([obj isKindOfClass:[BHUser class]]){
                    BHUser *user = obj;
                    if (user.identifier.length) [dict setObject:user.identifier forKey:@"id"];
                    if (user.fullname.length) [dict setObject:user.fullname forKey:@"full_name"];
                    [userArray addObject:dict];
                } else if ([obj isKindOfClass:[BHSub class]]) {
                    BHSub *sub = obj;
                    if (sub.identifier.length) [dict setObject:sub.identifier forKey:@"id"];
                    if (sub.name.length) [dict setObject:sub.name forKey:@"name"];
                    if (sub.count) [dict setObject:[NSString stringWithFormat:@"%@",sub.count] forKey:@"count"];
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
            _report = [[BHReport alloc] initWithDictionary:[responseObject objectForKey:@"report"]];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type == %@) AND (createdDate == %@)",_report.type, _report.createdDate];
            NSUInteger idx;
            for (BHReport *report in reports){
                if([predicate evaluateWithObject:report]) {
                    idx = [reports indexOfObject:report];
                    break;
                }
            }
            if (idx)[reports replaceObjectAtIndex:idx withObject:_report];
            _report.photos = storedPhotos;
            if (_report.identifier.length){
                for (BHPhoto *photo in _report.photos) {
                    if (photo.image){
                        [self uploadPhoto:photo.image withReportId:_report.identifier];
                    }
                }
            }
            [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
            [SVProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report added" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while creating this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            NSLog(@"Failure updating report: %@",error.description);
            [SVProgressHUD dismiss];
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
    if (choosingDate) {
        _report.createdDate = dateString;
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
    } else {
        NSUInteger reportIdx;
        for (BHReport *report in reports){
            if ([report.createdDate isEqualToString:dateString]) {
                _report = report;
                reportIdx = [reports indexOfObject:report];
                [self.scrollView setContentOffset:CGPointMake(screen.size.width*reportIdx, self.scrollView.contentOffset.y) animated:YES];
                [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Save" object:nil];
                return;
            }
        }
        NSLog(@"couldn't find report");
        [self newReportObject:dateString andType:nil];
        int idx = (int)reports.count - 1;
        UITableView *newTableView = [[UITableView alloc] init];
        newTableView.delegate = self;
        newTableView.dataSource = self;
        newTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [newTableView setFrame:CGRectMake((screen.size.width * idx), 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
        [newTableView setContentInset:self.tableView.contentInset];
        newTableView.autoresizingMask = self.tableView.autoresizingMask;
        [self.scrollView addSubview:newTableView];
        [self.scrollView setContentOffset:CGPointMake(screen.size.width*idx, self.scrollView.contentOffset.y) animated:YES];
        _report = reports.lastObject;
        [newTableView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Create" object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Remove" object:nil];
}

- (void)back {
    if (shouldSave) {
        [[[UIAlertView alloc] initWithTitle:@"Unsaved Changes" message:@"Do you want to save your unsaved changes?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Save", nil] show];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
