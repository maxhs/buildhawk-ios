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
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>
#import "Flurry.h"
#import <AssetsLibrary/AssetsLibrary.h>

static NSString * const kAddOther = @"Add other...";
static NSString * const kReportPlaceholder = @"Report details...";
static NSString * const kNewReportPlaceholder = @"Add new report";

@interface BHReportsViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UITextViewDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate> {
    NSMutableArray *reports;
    NSDateFormatter *dateFormatter;
    BOOL iPhone5;
    BOOL iPad;
    int windBearing;
    NSString *windDirection;
    NSString *windSpeed;
    NSString *nowSummary;
    NSString *daySummary;
    NSString *weeklySummary;
    NSString *temp;
    NSString *hourlySummary;
    NSString *icon;
    NSString *weatherString;
    UITextField *countTextField;
    UITextView *reportBodyTextView;
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
}

- (IBAction)backToDashboard;
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
    project = [(BHTabBarViewController*)self.tabBarController project];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Reports",[project name]];
    [self loadWeather];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    if (!reports) reports = [NSMutableArray array];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableViewLeft setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableViewRight setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    //disable scrollview's vertical scrolling, but keep the tableview vertically scrolling.
    if (iPad) {
        [self.scrollView setContentSize:CGSizeMake(screen.size.width,self.scrollView.frame.size.height)];
    } else {
        [self.scrollView setContentSize:CGSizeMake(screen.size.width,self.scrollView.frame.size.height-113)];
    }
    [self.scrollView setContentInset:UIEdgeInsetsMake(0, screen.size.width, 0, 0)];
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willShowKeyboard:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willHideKeyboard)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [SVProgressHUD showWithStatus:@"Fetching reports..."];
    [self loadReportsForProject];
    [Flurry logEvent:@"Viewing report"];
}

- (void)loadWeather {
    [manager GET:[NSString stringWithFormat:@"https://api.forecast.io/forecast/%@/%f,%f",kForecastAPIKey, project.address.latitude, project.address.longitude] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithDictionary:[responseObject objectForKey:@"currently"]];
        icon = [dictionary objectForKey:@"icon"];
        if ([[[dictionary objectForKey:@"temperature"] stringValue] length] > 4){
            temp = [[[dictionary objectForKey:@"temperature"] stringValue]substringToIndex:4];
        } else {
            temp = [[dictionary objectForKey:@"temperature"] stringValue];
        }
        if ([[[dictionary objectForKey:@"windSpeed"] stringValue] length]) windSpeed = [[[dictionary objectForKey:@"windSpeed"] stringValue] substringToIndex:3];
        daySummary = [dictionary objectForKey:@"summary"];
        windDirection = [self windDirection:[[dictionary objectForKey:@"windBearing"] intValue]];
        nowSummary = [[[responseObject valueForKeyPath:@"daily.date"] objectAtIndex:0] objectForKey:@"summary"];
        hourlySummary = [responseObject valueForKeyPath:@"hourly.summary"];
        weatherString = [NSString stringWithFormat:@"%@. Temp: %@ °. Wind: %@mph %@.",daySummary,temp,windSpeed, windDirection];
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get the weather: %@",error.description);
    }];
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


- (void)loadNext {
    [SVProgressHUD showWithStatus:@"Loading next report..."];
    [self performSelector:@selector(dismissOverlay) withObject:nil afterDelay:1.0];
}

- (void)loadPrevious {
    [SVProgressHUD showWithStatus:@"Loading previous report..."];
    [self performSelector:@selector(dismissOverlay) withObject:nil afterDelay:1.0];
}

- (void)dismissOverlay {
    [SVProgressHUD dismiss];
    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldn't find a report that fit those criteria." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    static NSInteger previousPage = 0;
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    if (previousPage != page) {
        NSLog(@"page changed! %i",page);
        if (page == 1) [self loadNext];
        else if (page == -1) [self loadPrevious];
        previousPage = page;
    }
}

- (void)loadReportsForProject {
    [SVProgressHUD showWithStatus:@"Fetching reports..."];
    [manager GET:[NSString stringWithFormat:@"%@/reports",kApiBaseUrl] parameters:@{@"pid":project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success getting reports: %@",responseObject);
        reports = [BHUtilities reportsFromJSONArray:[responseObject objectForKey:@"rows"]];
        if (reports.count) {
            _report = [reports objectAtIndex:0];
            self.scrollView.scrollEnabled = YES;
        } else {
            self.scrollView.scrollEnabled = NO;
            [self newReportObject];
        }
        if (_report.identifier.length) {
            saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
            self.navigationItem.rightBarButtonItem = saveButton;
        } else {
            saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(createNewReport)];
            self.navigationItem.rightBarButtonItem = saveButton;
            NSLog(@"save button is now a create button");
        }
        [self.tableView reloadData];
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting reports: %@",error.description);
        [SVProgressHUD dismiss];
    }];
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
    if (section == 1) return (1 + _report.subcontractors.count);
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
        [cell.typePickerButton setTitle:_report.type forState:UIControlStateNormal];
        [cell.typePickerButton addTarget:self action:@selector(tapTypePicker) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.datePickerButton setTitle:_report.title forState:UIControlStateNormal];
        [cell.datePickerButton addTarget:self action:@selector(pickReport) forControlEvents:UIControlEventTouchUpInside];
        [cell configure];
        if (daySummary.length) {
            NSLog(@"icon: %@",icon);
            [cell.tempLabel setText:[NSString stringWithFormat:@"%@ °",temp]];
            [cell.windTextField setText:[NSString stringWithFormat:@"%@mph %@",windSpeed, windDirection]];
            if ([icon isEqualToString:@"clear-day"] || [icon isEqualToString:@"clear-night"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"sunny"]];
            else if ([icon isEqualToString:@"cloudy"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"cloudy"]];
            else if ([icon isEqualToString:@"partly-cloudy-day"] || [icon isEqualToString:@"partly-cloudy-night"]) [cell.weatherImageView setImage:[UIImage imageNamed:@"partly"]];
            else if ([icon isEqualToString:@"rain"] || [icon isEqualToString:@"fog"] || [icon isEqualToString:@"sleet"]) {
                [cell.weatherImageView setImage:[UIImage imageNamed:@"rainy"]];
            }
            [cell.dailySummaryTextView setText:hourlySummary];
        }
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
            [cell.reportSectionLabel setText:@"Personnel On Site"];
            [cell.pickFromListButton addTarget:self action:@selector(pickFromList:) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        } else {
            static NSString *CellIdentifier = @"PersonnelCell";
            BHPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPersonnelCell" owner:self options:nil] lastObject];
            }
            
            [cell.personLabel setText:[(BHSubcontractor*)[_report.subcontractors.allObjects objectAtIndex:indexPath.row-1] name]];
            [cell.countTextField setText:[NSString stringWithFormat:@"%@",[(BHSubcontractor*)[_report.subcontractors.allObjects objectAtIndex:indexPath.row-1] count]]];
            [cell.removeButton setTag:indexPath.row-1];
            
            [cell.countTextField setTag:indexPath.row-1];
            countTextField = cell.countTextField;
            countTextField.delegate = self;
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
    textView.layer.cornerRadius = 3.f;
    textView.clipsToBounds = YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 170;
            break;
        case 1:
            if (indexPath.row == 0) return 100;
            else return 66;
            break;
        case 2:
            return 120;
            break;
        default:
            return 200;
            break;
    }
}


-(void)textViewDidBeginEditing:(UITextView *)textView {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem = doneButton;
    if ([textView.text isEqualToString:kReportPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor darkGrayColor]];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    if (_report.identifier.length) {
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem = createButton;
    }
    if (textView.text.length && textView == reportBodyTextView) {
        _report.body = textView.text;
    } else {
        [textView setText:kReportPlaceholder];
        [textView setTextColor:[UIColor lightGrayColor]];
    }
    [self doneEditing];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (_report.identifier.length) {
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem = createButton;
    }
    BHSubcontractor *sub = [[BHSubcontractor alloc] init];
    sub = [_report.subcontractors.allObjects objectAtIndex:textField.tag];
    sub.count = textField.text;
    [_report.subcontractors removeObject:[_report.subcontractors.allObjects objectAtIndex:textField.tag]];
    [_report.subcontractors addObject:sub];
    [self doneEditing];
}

-(void)doneEditing {
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
        } else {
            BHUser *user = [project.users objectAtIndex:buttonIndex];
            BHSubcontractor *subcontractor = [[BHSubcontractor alloc] init];
            subcontractor.name = user.fullname;
            subcontractor.count = @"1";
            if (![_report.subcontractors containsObject:subcontractor]) [_report.subcontractors addObject:subcontractor];
            else [[[UIAlertView alloc] initWithTitle:@"Already added!" message:@"Personnel already included" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    } else if (actionSheet == reportActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kNewReportPlaceholder]) {
            createButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(createNewReport)];
            self.navigationItem.rightBarButtonItem = createButton;
            NSLog(@"save button is now a create button");
            self.scrollView.scrollEnabled = NO;
            [self newReportObject];
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
    [self.tableView reloadData];
}

- (void)newReportObject {
    _report = [[BHReport alloc] init];
    _report.type = kDaily;
    _report.subcontractors = [NSMutableSet set];
    _report.photos = [NSMutableArray array];
    NSDate *titleDate = [NSDate date];
    _report.createdOn = titleDate;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    _report.title = [formatter stringFromDate:titleDate];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addOtherAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            BHUser *otherUser = [[BHUser alloc] init];
            [otherUser setFullname:[[alertView textFieldAtIndex:0] text]];
            BHSubcontractor *subcontractor = [[BHSubcontractor alloc] init];
            subcontractor.name = otherUser.fullname;
            subcontractor.count = @"1";
            if (![_report.subcontractors containsObject:subcontractor]) {
                [_report.subcontractors addObject:subcontractor];
                [self.tableView reloadData];
            } else [[[UIAlertView alloc] initWithTitle:@"Already added!" message:@"Personnel already included" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }
}

- (void)loadDate:(UIDatePicker *)sender {
    NSLog(@"Should be loading a report for: %@", sender.date);
    [SVProgressHUD showWithStatus:@"Fetching report..."];
    _report.createdOn = sender.date;
    [self.tableView reloadData];
    [self performSelector:@selector(dismissOverlay) withObject:nil afterDelay:1.0];
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
    
    /*UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, 320, 44)];
    toolBar.tag = 11;
    [toolBar setBarStyle:UIBarStyleDefault];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissDatePicker:)];
    [doneButton setTintColor:[UIColor blackColor]];
    [toolBar setItems:[NSArray arrayWithObjects:spacer, doneButton, nil]];
    [self.view addSubview:toolBar];*/
    
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
                                    destructiveButtonTitle:_report.photos.count ? @"Remove Last Photo" : nil
                                         otherButtonTitles:@"Choose Existing Photo", @"Take Photo", nil];
        [actionSheet showInView:self.view];
    } else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:_report.photos.count ? @"Remove Last Photo" : nil
                                         otherButtonTitles:@"Choose Existing Photo", nil];
        [actionSheet showInView:self.view];
    }
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == personnelActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kAddOther]) {
            
        } else {
            
        }
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove Last Photo"]) {
        [self removePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
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
    [newPhoto setImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [self saveImage:[self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]]];
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

- (void)savePostToLibrary:(UIImage*)originalImage {
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


- (void)saveImage:(UIImage*)image {
    NSDictionary *parameters = @{@"apikey":kFilepickerApiKey,@"filename":@"image.jpg",@"storePath":@"upload/"};
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    [manager POST:[NSString stringWithFormat:@"%@",kFilepickerBaseUrl] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"fileUpload" fileName:@"image.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BHPhoto *newPhoto = [[BHPhoto alloc] init];
        NSDictionary *tempDict = [[responseObject objectForKey:@"data"] firstObject];
        newPhoto.mimetype = [tempDict valueForKeyPath:@"data.type"];
        newPhoto.photoSize = [tempDict valueForKeyPath:@"data.size"];
        newPhoto.key = [tempDict valueForKeyPath:@"data.key"];
        newPhoto.url = [tempDict objectForKey:@"url"];
        newPhoto.filename =  [tempDict valueForKeyPath:@"data.filename"];
        [_report.photos addObject:newPhoto];
        [self redrawScrollView];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure posting image to filepicker: %@",error.description);
    }];
}


-(void)removePhoto {
    [_report.photos removeLastObject];
    if (_report.photos.count == 0){
        [UIView animateWithDuration:.35 delay:.35 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            photoButton.transform = CGAffineTransformIdentity;
            [reportScrollView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [reportScrollView setHidden:YES];
        }];
    } else {
        [UIView animateWithDuration:.35 delay:.35 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
        } completion:^(BOOL finished) {
        }];
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
        if (photo.url200.length){
            [imageButton setAlpha:0.0];
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url200] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
            }];
        } if (photo.url100.length){
            [imageButton setAlpha:0.0];
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url100] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
            }];
        } else if (photo.url.length){
            [imageButton setAlpha:0.0];
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
            }];
        } else {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        }
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),6,imageSize, imageSize)];
        [imageButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
        imageButton.imageView.layer.cornerRadius = 3.0;
        [imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        [imageButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        imageButton.imageView.layer.shouldRasterize = YES;
        imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
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

- (void)showPhotoDetail:(id)sender {
    NSMutableArray *tempPhotos = [NSMutableArray new];
    for (BHPhoto *photo in _report.photos) {
        IDMPhoto *idmPhoto;
        if (photo.orig.length){
            idmPhoto = [IDMPhoto photoWithURL:[NSURL URLWithString:photo.orig]];
        } else {
            idmPhoto = [IDMPhoto photoWithURL:[NSURL URLWithString:photo.url]];
        }
        [tempPhotos addObject:idmPhoto];
    }
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:tempPhotos];
    [self presentViewController:browser animated:YES completion:^{
        
    }];
}

#pragma mark - UITextViewDelegate Methods

- (void)willShowKeyboard:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets;
    contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height+49, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    // If active text field is hidden by keyboard, scroll it so it's visible
    /*CGRect aRect = self.view.frame;
     aRect.size.height -= kbSize.height;
     if (!CGRectContainsPoint(aRect, self.addComment.frame.origin) ) {
     CGPoint scrollPoint = CGPointMake(0.0, 0.0);
     [self.tableView setContentOffset:scrollPoint animated:YES];
     }*/
}

- (void)willHideKeyboard {
    self.tableView.scrollEnabled = YES;
}

- (void)pickFromList:(id)sender {
    personnelActionSheet = [[UIActionSheet alloc] initWithTitle:@"Personnel" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (BHUser *user in project.users) {
        [personnelActionSheet addButtonWithTitle:user.fullname];
    }
    [personnelActionSheet addButtonWithTitle:@"Add other..."];
    personnelActionSheet.cancelButtonIndex = [personnelActionSheet addButtonWithTitle:@"Cancel"];
    [personnelActionSheet showInView:self.view];
}

- (void)removePersonnel:(UIButton*)button {
    id object = [_report.subcontractors.allObjects objectAtIndex:button.tag];
    [_report.subcontractors removeObject:object];
    [self.tableView reloadData];
}

- (void)save {
    [SVProgressHUD showWithStatus:@"Saving report..."];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:_report.identifier forKey:@"_id"];
    [parameters setObject:[(BHTabBarViewController*)self.tabBarController project].identifier forKey:@"project._id"];
    if (weatherString.length) [parameters setObject:weatherString forKey:@"weather"];
    if (_report.title.length) [parameters setObject:_report.title forKey:@"title"];
    if (_report.type.length) [parameters setObject:_report.type forKey:@"type"];
    if (![reportBodyTextView.text isEqualToString:kReportPlaceholder]) [parameters setObject:reportBodyTextView.text forKey:@"body"];
    if (_report.subcontractors.allObjects.count) {
        NSMutableArray *subArray = [NSMutableArray arrayWithCapacity:_report.subcontractors.count];
        for (BHSubcontractor *sub in _report.subcontractors.allObjects) {
            NSMutableDictionary *subDict = [NSMutableDictionary dictionary];
            if (sub.identifier.length) [subDict setObject:sub.identifier forKey:@"_id"];
            if (sub.name.length) [subDict setObject:sub.name forKey:@"name"];
            if (sub.count.length) [subDict setObject:[NSString stringWithFormat:@"%@",sub.count] forKey:@"count"];
            [subArray addObject:subDict];
        }
        [parameters setObject:subArray forKey:@"subcontractors"];
    }
    if (_report.photos.count) {
        NSMutableArray *photoArray = [NSMutableArray arrayWithCapacity:_report.photos.count];
        for (BHPhoto *photo in _report.photos) {
            NSMutableDictionary *photoDict = [NSMutableDictionary dictionary];
            if (photo.identifier) [photoDict setObject:photo.identifier forKey:@"_id"];
            if (photo.url) [photoDict setObject:photo.url forKey:@"url"];
            if (photo.photoSize) [photoDict setObject:photo.photoSize forKey:@"size"];
            if (photo.mimetype) [photoDict setObject:photo.mimetype forKey:@"type"];
            [photoArray addObject:photoDict];
        }
        [parameters setObject:photoArray forKey:@"photos"];
    }
    NSLog(@"put parameters: %@",parameters);
    [manager PUT:[NSString stringWithFormat:@"%@/report",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success updating report: %@",responseObject);
        [SVProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report saved" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while saving this report. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failure updating report: %@",error.description);
        [SVProgressHUD dismiss];
    }];
}

- (void)createNewReport {
    [SVProgressHUD showWithStatus:@"Creating report..."];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (_report.identifier)[parameters setObject:_report.identifier forKey:@"_id"];
    [parameters setObject:[(BHTabBarViewController*)self.tabBarController project].identifier forKey:@"project._id"];
    if (weatherString.length) [parameters setObject:weatherString forKey:@"weather"];
    if (_report.title.length) [parameters setObject:_report.title forKey:@"title"];
    if (_report.type.length) [parameters setObject:_report.type forKey:@"type"];
    if (![reportBodyTextView.text isEqualToString:kReportPlaceholder]) [parameters setObject:reportBodyTextView.text forKey:@"body"];
    if (_report.subcontractors.allObjects.count) {
        NSMutableArray *subArray = [NSMutableArray arrayWithCapacity:_report.subcontractors.count];
        for (BHSubcontractor *sub in _report.subcontractors.allObjects) {
            NSMutableDictionary *subDict = [NSMutableDictionary dictionary];
            if (sub.identifier.length) [subDict setObject:sub.identifier forKey:@"_id"];
            if (sub.name.length) [subDict setObject:sub.name forKey:@"name"];
            if (sub.count.length) [subDict setObject:[NSString stringWithFormat:@"%@",sub.count] forKey:@"count"];
            [subArray addObject:subDict];
        }
        [parameters setObject:subArray forKey:@"subcontractors"];
    }
    if (_report.photos.count) {
        NSMutableArray *photoArray = [NSMutableArray arrayWithCapacity:_report.photos.count];
        for (BHPhoto *photo in _report.photos) {
            NSMutableDictionary *photoDict = [NSMutableDictionary dictionary];
            if (photo.identifier) [photoDict setObject:photo.identifier forKey:@"_id"];
            if (photo.url) [photoDict setObject:photo.url forKey:@"url"];
            if (photo.photoSize) [photoDict setObject:photo.photoSize forKey:@"size"];
            if (photo.mimetype) [photoDict setObject:photo.mimetype forKey:@"type"];
            [photoArray addObject:photoDict];
        }
        [parameters setObject:photoArray forKey:@"photos"];
    }
    NSLog(@"new report parameters: %@",parameters);
    [manager POST:[NSString stringWithFormat:@"%@/report",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success creating report: %@",responseObject);
        BHReport *newReport = [[BHReport alloc] initWithDictionary:responseObject];
        [reports addObject:newReport];
        [self.tableView reloadData];
        [SVProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Report added" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while creating this report. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failure updating report: %@",error.description);
        [SVProgressHUD dismiss];
    }];
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
