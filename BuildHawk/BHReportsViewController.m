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
#import <SVProgressHUD/SVProgressHUD.h>
#import "BHTabBarViewController.h"
#import "BHProject.h"
#import "BHReportPhotoCell.h"
#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHReportPersonnelCell.h"
#import "BHPersonnelCell.h"
#define kForecastAPIKey @"32a0ebe578f183fac27d67bb57f230b5"
#import <SDWebImage/UIButton+WebCache.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import "Flurry.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "BHPeoplePickerViewController.h"

static NSString * const kReportPlaceholder = @"Report details...";
static NSString * const kNewReportPlaceholder = @"Add new report";
static NSString * const kPickFromList = @"Pick from company list";

@interface BHReportsViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UITextViewDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, MWPhotoBrowserDelegate> {
    NSMutableArray *reports;
    NSDateFormatter *dateFormatter;
    BOOL iPhone5;
    BOOL iPad;
    int windBearing;
    NSString *windDirection;
    NSString *windSpeed;
    NSString *weeklySummary;
    NSString *temp;
    NSString *icon;
    NSString *precip;
    NSString *weatherString;
    UITextField *countTextField;
    UITextView *reportBodyTextView;
    UITextView *weatherTextView;
    UIActionSheet *typePickerActionSheet;
    UIActionSheet *personnelActionSheet;
    UIActionSheet *reportActionSheet;
    UIAlertView *addOtherAlertView;
    BHProject *project;
    UIScrollView *reportScrollView;
    AFHTTPRequestOperationManager *manager;
    UIButton *photoButton;
    CGRect screen;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *createButton;
    User *savedUser;
    int removePhotoIdx;
    NSString *currentDateString;
    NSMutableArray *browserPhotos;
    CGFloat previousContentOffsetX;
    NSInteger page;
}

- (IBAction)backToDashboard;
- (IBAction)showDatePicker;
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
    if (!manager) {
        manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == [c] %@", [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    savedUser = [User MR_findFirstWithPredicate:predicate inContext:localContext];
    project = [(BHTabBarViewController*)self.tabBarController project];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Reports",[project name]];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    if (!reports) reports = [NSMutableArray array];
    page = 0;
    previousContentOffsetX = 0;
    
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] setBackgroundColor:kLightestGrayColor];
    
    self.datePickerContainer.transform = CGAffineTransformMakeTranslation(0, 220);
    [self.datePickerContainer setBackgroundColor:[UIColor colorWithWhite:1 alpha:.95]];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willShowKeyboard:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willHideKeyboard)
                                                 name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePersonnel:) name:@"ReportPersonnel" object:nil];
    
    [SVProgressHUD showWithStatus:@"Fetching reports..."];
    [self loadReports];
    [Flurry logEvent:@"Viewing report"];
    saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    createButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(createNewReport)];
}

- (void)loadWeather:(NSDate*)reportDate forReport:(BHReport*)report {
    int dateInt = [reportDate timeIntervalSince1970];
    if (project.address.latitude && project.address.longitude) {
        [manager GET:[NSString stringWithFormat:@"https://api.forecast.io/forecast/%@/%f,%f,%i",kForecastAPIKey,project.address.latitude, project.address.longitude,dateInt] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"response object %i %@",dateInt,responseObject);
            NSDictionary *dictionary = [NSDictionary dictionaryWithDictionary:[responseObject objectForKey:@"currently"]];
            NSDictionary *dailyData = [[[responseObject objectForKey:@"daily"] objectForKey:@"data"] firstObject];
            NSString *min = [[dailyData objectForKey:@"apparentTemperatureMin"] stringValue];
            NSString *max = [[dailyData objectForKey:@"apparentTemperatureMax"] stringValue];
            if (min.length > 4){
                min = [min substringToIndex:4];
            }
            if (max.length > 4){
                max = [max substringToIndex:4];
            }
            [report setPrecip:[NSString stringWithFormat:@"%.0f%%", [[dictionary objectForKey:@"precipProbability"] floatValue]*100]];
            NSLog(@"report precip; %@",report.precip);
            [report setTemp:[NSString stringWithFormat:@"%@° / %@°",min,max]];
            [report setWeatherIcon:[dictionary objectForKey:@"icon"]];
            if ([[[dictionary objectForKey:@"windSpeed"] stringValue] length])
                windSpeed = [[[dictionary objectForKey:@"windSpeed"] stringValue] substringToIndex:3];
            windDirection = [self windDirection:[[responseObject objectForKey:@"windBearing"] intValue]];
            [report setWind:[NSString stringWithFormat:@"%@mph %@",windSpeed, windDirection]];
            weatherString = [NSString stringWithFormat:@"%@. Temp: %@. Wind: %@mph %@.",[dictionary objectForKey:@"summary"],temp,windSpeed, windDirection];
            dispatch_async(dispatch_get_main_queue(), ^{
                [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
            });

            [self.scrollView setContentOffset:CGPointMake((screen.size.width*reports.count)-screen.size.width, self.scrollView.contentOffset.y) animated:NO];
            NSLog(@"page for weather reload: %i",page);
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

- (void)dismissOverlay {
    [SVProgressHUD dismiss];
    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldn't find a report that fit those criteria." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.scrollView && previousContentOffsetX != scrollView.contentOffset.x){
        float fractionalPage = scrollView.contentOffset.x / screen.size.width;
        page = lround(fractionalPage);
        _report = [reports objectAtIndex:page];
        if (_report.identifier.length) {
            self.navigationItem.rightBarButtonItem = saveButton;
        } else {
            self.navigationItem.rightBarButtonItem = createButton;
        }
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
        previousContentOffsetX = scrollView.contentOffset.x;
    }
}

- (void)loadReports {
    [SVProgressHUD showWithStatus:@"Fetching reports..."];
    [manager GET:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success getting reports: %@",responseObject);
        reports = [BHUtilities reportsFromJSONArray:[responseObject objectForKey:@"reports"]];
        [self drawReports];
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting reports: %@",error.description);
        [SVProgressHUD dismiss];
    }];
}

- (void)drawReports{
    if (reports.count) {
        BHReport *lastReport = reports.lastObject;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yyyy"];
        NSString *dateString = [formatter stringFromDate:[NSDate date]];
        if([lastReport isKindOfClass:[BHReport class]] && [lastReport.createdDate isEqualToString:dateString]) {
            int idx = 1;
            for (BHReport *report in reports){
                if (reports.lastObject != report){
                    UITableView *newTableView = [[UITableView alloc] init];
                    newTableView.delegate = self;
                    newTableView.dataSource = self;
                    [newTableView setFrame:CGRectMake((screen.size.width * idx), 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
                    [newTableView setContentInset:self.tableView.contentInset];
                    newTableView.autoresizingMask = self.tableView.autoresizingMask;
                    [self.scrollView addSubview:newTableView];
                    idx ++;
                }
            }
            _report = lastReport;
            NSLog(@"you're looking at the first report");
            self.navigationItem.rightBarButtonItem = saveButton;
            if (iPad) {
                [self.scrollView setContentSize:CGSizeMake(reports.count*screen.size.width,self.scrollView.frame.size.height-300)];
            } else {
                [self.scrollView setContentSize:CGSizeMake(reports.count*screen.size.width,self.scrollView.frame.size.height-113)];
            }
            [self.scrollView setContentOffset:CGPointMake(screen.size.width*(reports.count)-screen.size.width, self.scrollView.contentOffset.y)];
        } else {
            int idx = 1;
            for (BHReport *report in reports){
                UITableView *newTableView = [[UITableView alloc] init];
                newTableView.delegate = self;
                newTableView.dataSource = self;
                [newTableView setFrame:CGRectMake((screen.size.width * idx), 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
                [newTableView setContentInset:self.tableView.contentInset];
                newTableView.autoresizingMask = self.tableView.autoresizingMask;
                [self.scrollView addSubview:newTableView];
                idx ++;
            }
            NSLog(@"should be a new report");
            [self newReportObject:dateString];
        }
    } else {
        [self newReportObject:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) {
        NSLog(@"_report.personnel.count: %i",1+_report.personnel.count);
        return (1 + _report.personnel.count);
    }
    else return 1;
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
        NSString *reportTitle = [_report.title copy];
        [cell.typePickerButton setTitle:_report.type forState:UIControlStateNormal];
        [cell.datePickerButton setTitle:reportTitle forState:UIControlStateNormal];
        [cell.typePickerButton addTarget:self action:@selector(tapTypePicker) forControlEvents:UIControlEventTouchUpInside];
        [cell.datePickerButton addTarget:self action:@selector(showDatePicker) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.windTextField setDelegate:self];
        [cell.tempTextField setDelegate:self];
        [cell.dailySummaryTextView setDelegate:self];
        weatherTextView = cell.dailySummaryTextView;
        
        NSLog(@"report has existing weather for report date: %@ with wind: %@",_report.createdDate, _report.wind);
        [cell.dailySummaryTextView setText:_report.weather];
        [cell.tempTextField setText:_report.temp];
        [cell.windTextField setText:_report.wind];
        [cell.precipTextField setText:_report.precip];
        
        if ([_report.weatherIcon isEqualToString:@"clear-day"] || [_report.weatherIcon isEqualToString:@"clear-night"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"sunny"]];
        else if ([_report.weatherIcon isEqualToString:@"cloudy"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"cloudy"]];
        else if ([_report.weatherIcon isEqualToString:@"partly-cloudy-day"] || [_report.weatherIcon isEqualToString:@"partly-cloudy-night"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"partly"]];
        else if ([_report.weatherIcon isEqualToString:@"rain"] || [_report.weatherIcon isEqualToString:@"sleet"]) {
            [cell.weatherImageView setImage:[UIImage imageNamed:@"rainy"]];
        } else if ([_report.weatherIcon isEqualToString:@"fog"] || [_report.weatherIcon isEqualToString:@"wind"]) {
            [cell.weatherImageView setImage:[UIImage imageNamed:@"wind"]];
        } else [cell.weatherImageView setImage:nil];
        
        return cell;
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
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
        } else {
            static NSString *CellIdentifier = @"PersonnelCell";
            BHPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPersonnelCell" owner:self options:nil] lastObject];;
            }
            id obj = [_report.personnel objectAtIndex:indexPath.row-1];
            if ([obj isKindOfClass:[BHUser class]]){
                [cell.personLabel setText:[(BHUser*)obj fullname]];
                NSLog(@"should be setting person label: %@",[(BHUser*)obj fullname]);
                [cell.countTextField setText:@"1"];
                cell.countTextField.userInteractionEnabled = NO;
            } else if ([obj isKindOfClass:[BHSub class]]) {
                [cell.personLabel setText:[(BHSub*)obj name]];
                NSLog(@"should be setting person label: %@",[(BHSub*)obj name]);
                [cell.countTextField setText:[NSString stringWithFormat:@"%@",[(BHSub*)obj count]]];
                cell.countTextField.userInteractionEnabled = YES;
            }
            countTextField.delegate = self;
            [cell.removeButton setTag:indexPath.row-1];
            [cell.countTextField setTag:indexPath.row-1];
            countTextField = cell.countTextField;
            [cell.removeButton addTarget:self action:@selector(removePersonnel:) forControlEvents:UIControlEventTouchUpInside];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return cell;
        }
    } else if (indexPath.section == 2) {
        BHReportPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportPhotoCell" owner:self options:nil] lastObject];
        }
        reportScrollView = cell.photoScrollView;
        photoButton = cell.photoButton;
        [photoButton addTarget:self action:@selector(photoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
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
        [cell.reportBodyTextView setDelegate:self];
        
        if (_report.body.length) {
            [cell.reportBodyTextView setText:_report.body];
            [cell.reportBodyTextView setTextColor:[UIColor darkGrayColor]];
        } else {
            [cell.reportBodyTextView setText:kReportPlaceholder];
            [cell.reportBodyTextView setTextColor:[UIColor lightGrayColor]];
        }
        
        reportBodyTextView = cell.reportBodyTextView;
        return cell;
    }
}

- (void)pickReport {
    reportActionSheet = [[UIActionSheet alloc] initWithTitle:@"Reports" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (BHReport *report in reports) {
        [reportActionSheet addButtonWithTitle:report.title];
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
            return 170;
            break;
        case 1:
            if (indexPath.row == 0) return 140;
            else return 66;
            break;
        case 2:
            return 120;
            break;
        default:
            return 180;
            break;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 32)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 1)];
    [separator setBackgroundColor:kLightGrayColor];
    [headerView addSubview:separator];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,screen.size.width,32)];
    [headerLabel setFont:[UIFont fontWithName:kHelveticaNeueMedium size:15]];
    [headerLabel setBackgroundColor:kDarkerGrayColor];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setTextColor:[UIColor whiteColor]];
        switch (section) {
            case 0:
                [headerLabel setText:@"Report Info"];
                break;
            case 1:
                [headerLabel setText:@"Personnel on Site"];
                break;
            case 2:
                [headerLabel setText:@"Photos"];
                break;
            case 3:
                [headerLabel setText:@"Notes"];
                break;
            default:
                [headerLabel setText:@""];
                break;
        }
    [headerView addSubview:headerLabel];
    return headerView;
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem = doneButton;
    [textView becomeFirstResponder];
    if ([textView.text isEqualToString:kReportPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor darkGrayColor]];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == reportBodyTextView){
        if (textView.text.length) {
            _report.body = textView.text;
        } else {
            [textView setText:kReportPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
        }
    } else if (textView == weatherTextView) {
    
    }
    [self doneEditing];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = nil;
    if (_report.identifier.length) {
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem = createButton;
    }
    if (textField == countTextField){
        BHSub *sub = [[BHSub alloc] init];
        sub = [_report.personnel objectAtIndex:textField.tag];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSLog(@"textfield text: %@, tag: %i",textField.text, textField.tag);
        sub.count = [f numberFromString:textField.text];
        [_report.personnel replaceObjectAtIndex:textField.tag withObject:sub];
    }
    [self doneEditing];
}

-(void)doneEditing {
    if (_report.identifier.length){
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem = createButton;
    }
    [self.view endEditing:YES];
}

-(void)tapTypePicker {
    typePickerActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Report Type" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Daily",@"Monthly",@"Safety", nil];
    [typePickerActionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == typePickerActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
           
        } else {
            _report.type = [actionSheet buttonTitleAtIndex:buttonIndex];
        }
    } else if (actionSheet == personnelActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
            
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kAddOther]) {
            addOtherAlertView = [[UIAlertView alloc] initWithTitle:@"Add other personnel" message:@"Enter personnel name(s):" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
            addOtherAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [addOtherAlertView show];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kCompanyUsers]) {
            [self performSegueWithIdentifier:@"PeoplePicker" sender:nil];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kSubcontractors]) {
            [self performSegueWithIdentifier:@"SubPicker" sender:nil];
        }
    } else if (actionSheet == reportActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kNewReportPlaceholder]) {
            self.navigationItem.rightBarButtonItem = createButton;
            [self newReportObject:nil];
        } else {
            for (BHReport *report in reports){
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", [reportActionSheet buttonTitleAtIndex:buttonIndex]];
                if([predicate evaluateWithObject:report.title]) {
                    _report = report;
                    break;
                }
            }
        }
    }
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
}

- (void)updatePersonnel:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    _report.personnel = [info objectForKey:kpersonnel];
    NSLog(@"report: %@",_report.identifier);
    NSLog(@"updating personnel with %@",info);
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)newReportObject:(NSString*)dateParam {
    self.navigationItem.rightBarButtonItem = createButton;
    BHReport *newReport = [[BHReport alloc] init];
    newReport.type = kDaily;
    newReport.personnel = [NSMutableArray array];
    newReport.photos = [NSMutableArray array];
    newReport.createdDate = newReport.title;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    if (dateParam.length){
        newReport.title = dateParam;
        newReport.createdDate = dateParam;
        [self loadWeather:[formatter dateFromString:dateParam] forReport:newReport];
    } else {
        NSDate *titleDate = [NSDate date];
        newReport.createdAt = titleDate;
        newReport.title = [formatter stringFromDate:titleDate];
        [self loadWeather:titleDate forReport:newReport];
    }
    
    [reports addObject:newReport];
    
    UITableView *newTableView = [[UITableView alloc] initWithFrame:CGRectMake((screen.size.width * reports.count)-screen.size.width, 0, screen.size.width, screen.size.height) style:UITableViewStylePlain];
    [newTableView setNeedsLayout];
    [newTableView setNeedsDisplay];
    newTableView.delegate = self;
    newTableView.dataSource = self;
    [newTableView setContentInset:self.tableView.contentInset];
    newTableView.autoresizingMask = self.tableView.autoresizingMask;
    [self.scrollView addSubview:newTableView];

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
            sub.count = [NSNumber numberWithInt:1];
            if (![_report.personnel containsObject:sub]) {
                [_report.personnel addObject:sub];
                NSLog(@"just added: %@",sub.name);
                [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
            } else [[[UIAlertView alloc] initWithTitle:@"Already added!" message:@"Personnel already included" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]) {
        [self removePhoto];
    }
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
    //[self doneEditing];
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
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:@"Remove"
                                         otherButtonTitles:@"Photo Gallery", nil];
    [actionSheet showInView:self.view];
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
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [vc setDelegate:self];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)takePhoto {
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
    NSString *albumName = @"BuildHawk";
    UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:0.5 orientation:UIImageOrientationUp];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
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
            NSLog(@"saved image failed.\nerror code %i\n%@", error.code, [error localizedDescription]);
        }
    }];
}

-(void)removeConfirm {
    [[[UIAlertView alloc] initWithTitle:@"Please Confirm" message:@"Are you sure you want to delete this photo?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil] show];
}

-(void)removePhoto {
    NSLog(@"should be removing photo with id: %i",removePhotoIdx);
    BHPhoto *photoToRemove = [_report.photos objectAtIndex:removePhotoIdx];
    if (photoToRemove.identifier.length) {
        [manager DELETE:[NSString stringWithFormat:@"%@/photos/%@",kApiBaseUrl,photoToRemove.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success removing photo");
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    }
    [_report.photos removeObjectAtIndex:removePhotoIdx];
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
}

- (void)redrawScrollView {
    NSLog(@"wheres the scrollview: %@",reportScrollView);
    reportScrollView.delegate = self;
    [reportScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    reportScrollView.showsHorizontalScrollIndicator=NO;
    
    float imageSize = 70.0;
    float space = 4.0;
    int index = 0;
    for (BHPhoto *photo in _report.photos) {
        __weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [imageButton setAlpha:0.0];
        
        if (photo.url200.length){
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url200] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
            }];
        } if (photo.url100.length){
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url100] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
            }];
        } else if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
            [UIView animateWithDuration:.25 animations:^{
                [imageButton setAlpha:1.0];
            }];
        }
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
    if (_report.photos.count > 0) {
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            photoButton.transform = CGAffineTransformMakeTranslation(-120, 0);
            [reportScrollView setAlpha:1.0];
        } completion:^(BOOL finished) {
            reportScrollView.layer.shouldRasterize = YES;
            reportScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        }];
    } else {
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            photoButton.transform = CGAffineTransformIdentity;
            [reportScrollView setAlpha:0.0];
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)showPhotoDetail:(UIButton*)button {
    browserPhotos = [NSMutableArray new];
    for (BHPhoto *photo in _report.photos) {
        MWPhoto *mwPhoto;
        mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setOriginalURL:[NSURL URLWithString:photo.orig]];
        [browserPhotos addObject:mwPhoto];
    }
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0){
        browser.wantsFullScreenLayout = YES; // iOS 5 & 6 only: Decide if you want the photo browser full screen, i.e. whether the status bar is affected (defaults to YES)
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

#pragma mark - UITextViewDelegate Methods

- (void)willShowKeyboard:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets;
    contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height+100, 0.0);
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] setContentInset:contentInsets];
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] setScrollIndicatorInsets:contentInsets];
    [self performSelector:@selector(scrollToAddReport) withObject:nil afterDelay:.25];
}

- (void)scrollToAddReport {
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)willHideKeyboard {
    
}

- (void)prefill{
    int currentIdx = [reports indexOfObject:_report];
    NSLog(@"current report index: %i",-currentIdx+reports.count);
    if (currentIdx != NSNotFound) {
        NSLog(@"current report index: %@",[[reports objectAtIndex:currentIdx-1] createdDate]);
        BHReport *previousReport = [reports objectAtIndex:currentIdx-1];
        _report.personnel = previousReport.personnel;
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
    }
}

- (void)pickFromList:(id)sender {
    personnelActionSheet = [[UIActionSheet alloc] initWithTitle:@"Personnel" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: kCompanyUsers,kSubcontractors, kAddOther, nil];
    [personnelActionSheet showInView:self.view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PeoplePicker"]){
        BHPeoplePickerViewController *vc = [segue destinationViewController];
        if (savedUser)[vc setUserArray:savedUser.coworkers];
        [vc setPersonnelArray:_report.personnel];
    } else if ([segue.identifier isEqualToString:@"SubPicker"]){
        BHPeoplePickerViewController *vc = [segue destinationViewController];
        if (savedUser)[vc setSubArray:savedUser.subcontractors];
        [vc setPersonnelArray:_report.personnel];
    }
}

- (void)removePersonnel:(UIButton*)button {
    id object = [_report.personnel objectAtIndex:button.tag];
    if (_report.identifier.length) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if ([object isKindOfClass:[BHSub class]]){
            [parameters setObject:[(BHSub*)object identifier] forKey:@"sub_id"];
        } else if ([object isKindOfClass:[BHUser class]]) {
            [parameters setObject:[(BHUser*)object identifier] forKey:@"user_id"];
        }
        
        [parameters setObject:_report.identifier forKey:@"report_id"];
    
        [manager DELETE:[NSString stringWithFormat:@"%@/reports/remove_personnel",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success removing personnel: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure removing personnel: %@",error.description);
    }];
    }
    [_report.personnel removeObject:object];
    [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
}

- (void)save {
    [SVProgressHUD showWithStatus:@"Saving report..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"author_id"];
    [parameters setObject:project.identifier forKey:@"project_id"];
    if (_report.weather.length) [parameters setObject:_report.weather forKey:@"weather"];
    if (_report.title.length) [parameters setObject:_report.title forKey:@"title"];
    if (_report.type.length) [parameters setObject:_report.type forKey:@"report_type"];
    if (_report.precip.length) [parameters setObject:_report.precip forKey:@"precip"];
    if (_report.weatherIcon.length) [parameters setObject:_report.weatherIcon forKey:@"icon"];
    if (![reportBodyTextView.text isEqualToString:kReportPlaceholder]) [parameters setObject:reportBodyTextView.text forKey:@"body"];
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

    [manager PUT:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,_report.identifier] parameters:@{@"report":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success updating report: %@",responseObject);
        BHReport *newReport = [[BHReport alloc] initWithDictionary:[responseObject objectForKey:@"report"]];
        for (BHReport *report in reports){
            if ([report.identifier isEqualToString:newReport.identifier]) {
                [reports replaceObjectAtIndex:[reports indexOfObject:report] withObject:newReport];
                break;
            }
        }
        [SVProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report saved" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while saving this report. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failure updating report: %@",error.description);
        [SVProgressHUD dismiss];
    }];
}


- (void)saveImage:(BHPhoto*)photo {
    [self saveImageToLibrary:photo.image];
    if (_report.identifier.length){
        NSData *imageData = UIImageJPEGRepresentation(photo.image, 0.5);
        [manager POST:[NSString stringWithFormat:@"%@/reports/photo",kApiBaseUrl] parameters:@{@"id":_report.identifier, @"photo[user_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"photo[project_id]":project.identifier, @"photo[source]":_report.title, @"photo[company_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
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
    } else {
        [self redrawScrollView];
    }
}

- (void)createNewReport {
    [SVProgressHUD showWithStatus:@"Creating report..."];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:project.identifier forKey:@"project_id"];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"author_id"];
    if (_report.weather.length) [parameters setObject:_report.weather forKey:@"weather"];
    if (_report.wind) [parameters setObject:_report.wind forKey:@"wind"];
    if (_report.temp.length) [parameters setObject:_report.temp forKey:@"temp"];
    if (_report.precip.length) [parameters setObject:_report.precip forKey:@"precip"];
    if (_report.weatherIcon.length) [parameters setObject:_report.weatherIcon forKey:@"weather_icon"];
    if (_report.title.length) [parameters setObject:_report.title forKey:@"title"];
    if (_report.createdDate.length) [parameters setObject:_report.createdDate forKey:@"created_date"];
    if (_report.type.length) [parameters setObject:_report.type forKey:@"report_type"];
    if (![reportBodyTextView.text isEqualToString:kReportPlaceholder]) [parameters setObject:reportBodyTextView.text forKey:@"body"];

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

    [manager POST:[NSString stringWithFormat:@"%@/reports",kApiBaseUrl] parameters:@{@"report":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating report: %@",responseObject);
        BHReport *newReport = [[BHReport alloc] initWithDictionary:[responseObject objectForKey:@"report"]];
        [reports replaceObjectAtIndex:[reports indexOfObject:_report] withObject:newReport];
        
        if (newReport.identifier.length){
            for (BHPhoto *photo in _report.photos) {
                if (photo.image){
                    NSData *imageData = UIImageJPEGRepresentation(photo.image, 0.5);
                    NSMutableDictionary *photoParameters = [NSMutableDictionary dictionary];
                    if (newReport.identifier.length) [photoParameters setObject:newReport.identifier forKey:@"report_id"];
                    [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"photo[user_id]"];
                    if (project.identifier.length) [photoParameters setObject:project.identifier forKey:@"photo[project_id]"];
                    [photoParameters setObject:newReport.title forKey:@"photo[source]"];
                    [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"photo[company_id]"];
                    
                    NSLog(@"photo params: %@",photoParameters);
                    [manager POST:[NSString stringWithFormat:@"%@/reports/photo",kApiBaseUrl] parameters:photoParameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                        [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
                    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        NSLog(@"Added photo to new report just now: %@",responseObject);
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"failure posting image to API: %@",error.description);
                    }];
                }
            }
        }
        [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
        [SVProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report added" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while creating this report. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failure updating report: %@",error.description);
        [SVProgressHUD dismiss];
    }];
}

- (IBAction)cancelDatePicker{
    [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.datePickerContainer.transform = CGAffineTransformMakeTranslation(0, 220);
        self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
        [self.overlayView setAlpha:0];
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)showDatePicker{
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
    int reportIdx;
    for (BHReport *report in reports){
        if ([report.createdDate isEqualToString:dateString]) {
            _report = report;
            reportIdx = [reports indexOfObject:report];
            [self.scrollView setContentOffset:CGPointMake(0+(screen.size.width*reportIdx), self.scrollView.contentOffset.y) animated:YES];
            [(UITableView*)[self.scrollView.subviews objectAtIndex:page] reloadData];
            return;
        }
    }
    NSLog(@"couldn't find report");
    [self newReportObject:dateString];
}

//#pragma mark - CLLocationManagerDelegateMethods
//
//- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
//    CLLocation *location = locations.lastObject;
//    [manager stopUpdatingLocation];
//}
//
//- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
//    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"We couldn't find your location. Please try again soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
//}

@end
