//
//  BHReportsCollectionCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/5/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHAppDelegate.h"
#import "BHReportsCollectionCell.h"
#import "BHReportPersonnelCell.h"
#import "BHReportPickerCell.h"
#import "BHReportSectionCell.h"
#import "BHReportWeatherCell.h"
#import "BHReportPhotoCell.h"
#import "BHActivityCell.h"
#import "BHChooseTopicsViewCell.h"
#import "BHSafetyTopicsCell.h"
#import "BHAddCommentCell.h"
#import "BHChooseReportPersonnelCell.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <CoreLocation/CoreLocation.h>
#import "BHReportPhotoScrollView.h"
#import "BHPersonnelCountTextField.h"
#import "BHSafetyTopicTransition.h"
#import "BHSafetyTopicViewController.h"
#import "Comment+helper.h"
#import "Project+helper.h"
#import "SafetyTopic+helper.h"
#import "Address+helper.h"
#import "Company+helper.h"

static NSString * const kReportPlaceholder = @"Report details...";
static NSString * const kNewReportPlaceholder = @"Add new report";
static NSString * const kWeatherPlaceholder = @"Add your weather notes...";

@interface BHReportsCollectionCell () <UIActionSheetDelegate, UIAlertViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIPopoverControllerDelegate, UIViewControllerTransitioningDelegate> {
    BHAppDelegate *appDelegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    CGRect mainScreen;
    BOOL activities;
    
    UITextField *windTextField;
    UITextField *tempTextField;
    UITextField *precipTextField;
    UITextField *humidityTextField;
    UITextView *weatherTextView;
    UITextView *addCommentTextView;
    NSDateFormatter *formatter;
    NSDateFormatter *timeStampFormatter;
    NSNumberFormatter *numberFormatter;
    NSDateFormatter *commentFormatter;
    UITextField *countTextField;
    BHReportPhotoScrollView *reportScrollView;
    
    UITextView *reportBodyTextView;
    UIView *photoButtonContainer;
    UIButton *commentsButton;
    UIButton *activityButton;
    UIRefreshControl *refreshControl;
    UIButton *doneCommentButton;
    Project *_project;
    Report *_report;

    UIActionSheet *reportActionSheet;
    
    NSInteger removePhotoIdx;
    BOOL choosingDate;
    BOOL topicsFetched;
    int windBearing;
    NSString *windDirection;
    NSString *windSpeed;
    NSString *weeklySummary;
    NSString *temp;
    NSString *icon;
    NSString *precip;
    NSString *weatherString;
    NSMutableArray *browserPhotos;
}

@end

@implementation BHReportsCollectionCell

- (void)configureForReport:(NSNumber *)reportId withDateFormatter:(NSDateFormatter *)dateFormatter andNumberFormatter:(NSNumberFormatter *)number withTimeStampFormatter:(NSDateFormatter *)timeStamp withCommentFormatter:(NSDateFormatter *)comment withWidth:(CGFloat)w andHeight:(CGFloat)h {
    _report = [Report MR_findFirstByAttribute:@"identifier" withValue:reportId inContext:[NSManagedObjectContext MR_defaultContext]];
    [_reportTableView setReport:_report];
    _project = _report.project;
    
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    
    [self registerForKeyboardNotifications];
    
    formatter = dateFormatter;
    timeStampFormatter = timeStamp;
    commentFormatter = comment;
    numberFormatter = number;
    width = w;
    height = h;
    mainScreen = CGRectMake(0, 0, width, h);
    
    //set up the refresh controls
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl setTintColor:kDarkGrayColor];
    [refreshControl addTarget:self action:@selector(refreshReport) forControlEvents:UIControlEventValueChanged];
    [_reportTableView addSubview:refreshControl];
    
    if (!_report.wind.length){
        [self loadWeather:[formatter dateFromString:_report.dateString]];
    }
    
    //default to showing activities
    activities = YES;
    [_reportTableView reloadData];
}

- (void)refreshReport {
    [manager GET:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,_reportTableView.report.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success fetching report after refresh: %@",responseObject);
        [_reportTableView.report populateWithDict:[responseObject objectForKey:@"report"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [_reportTableView reloadData];
        }];
        [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching report: %@",error.description);
        [refreshControl endRefreshing];
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to refresh this report." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
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
        if (activities){
            if ([tableView.report.type isEqualToString:kDaily]){
                return tableView.report.dailyActivities.count;
            } else {
                return tableView.report.activities.count;
            }
        } else {
            return tableView.report.comments.count + 1;
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
            //choosingDate = NO;
        } else {
            [cell.datePickerButton setTitle:@"" forState:UIControlStateNormal];
            //choosingDate = YES;
        }
        
        [cell.typePickerButton addTarget:self action:@selector(tapTypePicker) forControlEvents:UIControlEventTouchUpInside];
        [cell.datePickerButton addTarget:self action:@selector(showDatePicker) forControlEvents:UIControlEventTouchUpInside];
        
        /*if ([tableView.report.saved isEqualToNumber:@NO]){
            UILabel *unsavedHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 34)];
            [unsavedHeaderLabel setBackgroundColor:kLightestGrayColor];
            [unsavedHeaderLabel setText:@"Unsaved changes"];
            tableView.tableHeaderView = unsavedHeaderLabel;
            NSLog(@"unsaved changes");
        } else {
            tableView.tableHeaderView = nil;
        }*/
        
        return cell;
    } else if (indexPath.section == 1) {
        static NSString *CellIdentifier = @"ReportWeatherCell";
        BHReportWeatherCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        windTextField = cell.windTextField;
        cell.windTextField.delegate = self;
        
        tempTextField = cell.tempTextField;
        cell.tempTextField.delegate = self;
        
        precipTextField = cell.precipTextField;
        cell.precipTextField.delegate = self;
        
        humidityTextField = cell.humidityTextField;
        cell.humidityTextField.delegate = self;
        
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
        [cell.choosePersonnelButton addTarget:self action:@selector(showPersonnelActionSheet) forControlEvents:UIControlEventTouchUpInside];
    
        // manually set the frames //
        CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
        CGFloat originX = cellRect.size.width/2 - cell.choosePersonnelButton.frame.size.width/2;
        CGRect choosePersonnelRect = cell.choosePersonnelButton.frame;
        choosePersonnelRect.origin.x = originX;
        [cell.choosePersonnelButton setFrame:choosePersonnelRect];
        CGRect prefillButtonRect = cell.prefillButton.frame;
        prefillButtonRect.origin.x = originX;
        [cell.prefillButton setFrame:prefillButtonRect];
        // ** //
        
        if (_canPrefill){
            [cell.prefillButton setUserInteractionEnabled:YES];
            [cell.prefillButton addTarget:self action:@selector(prefill) forControlEvents:UIControlEventTouchUpInside];
            [cell.prefillButton setAlpha:1];
        } else {
            [cell.prefillButton setUserInteractionEnabled:NO];
            [cell.prefillButton setAlpha:.5];
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
        CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
        CGFloat buttonHeight = cell.chooseTopicsButton.frame.size.height;
        CGFloat buttonWidth = cell.chooseTopicsButton.frame.size.width;
        [cell.chooseTopicsButton setFrame:CGRectMake(cellRect.size.width/2-buttonWidth/2, cellRect.size.height/2-buttonHeight/2, buttonWidth, buttonHeight)];
        
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
        [self redrawScrollView];
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
        
        CGRect reportNotesFrame = cell.reportBodyTextView.frame;
        reportNotesFrame.size.width = width-10;
        [cell.reportBodyTextView setFrame:reportNotesFrame];
        
        reportBodyTextView = cell.reportBodyTextView;
        [reportBodyTextView setFont:[UIFont fontWithName:kMyriadProRegular size:17]];
        
        return cell;
    } else {
        if (!activities){
            if (indexPath.row == 0){
                BHAddCommentCell *addCommentCell = [tableView dequeueReusableCellWithIdentifier:@"AddCommentCell"];
                if (addCommentCell == nil) {
                    addCommentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddCommentCell" owner:self options:nil] lastObject];
                }
                [addCommentCell configure];
                addCommentTextView.tag = indexPath.section;
                addCommentTextView = addCommentCell.messageTextView;
                addCommentTextView.delegate = self;
                [addCommentTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
                [addCommentCell.doneButton addTarget:self action:@selector(submitComment) forControlEvents:UIControlEventTouchUpInside];
                doneCommentButton = addCommentCell.doneButton;
                _reportTableView = tableView;
                return addCommentCell;
            } else {
                BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
                if (cell == nil) {
                    cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
                }
                Comment *comment = [tableView.report.comments objectAtIndex:indexPath.row - 1];
                [cell configureForComment:comment];
                [cell.timestampLabel setText:[commentFormatter stringFromDate:comment.createdAt]];
                return cell;
            }
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
            } else {
                return 210;
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
    } else if (section == 9) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
        [headerView setBackgroundColor:kDarkerGrayColor];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
        headerLabel.layer.cornerRadius = 3.f;
        headerLabel.clipsToBounds = YES;
        [headerLabel setBackgroundColor:[UIColor clearColor]];
        [headerLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        [headerLabel setTextColor:[UIColor darkGrayColor]];
        
        [headerLabel setText:@""];
        
        activityButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [activityButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
        [activityButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
        
        NSString *activitiesTitle = tableView.report.activities.count == 1 ? @"1 ACTIVITY" : [NSString stringWithFormat:@"%lu ACTIVITIES",(unsigned long)tableView.report.activities.count];
        [activityButton setTitle:activitiesTitle forState:UIControlStateNormal];
        
        if (activities){
            [activityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [activityButton setBackgroundColor:[UIColor clearColor]];
        } else {
            [activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [activityButton setBackgroundColor:[UIColor whiteColor]];
        }
        [activityButton setFrame:CGRectMake(0, 0, width/2, 40)];
        [activityButton addTarget:self action:@selector(showActivities) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:activityButton];
        
        commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [commentsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [commentsButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
        
        NSString *commentsTitle = tableView.report.comments.count == 1 ? @"1 COMMENT" : [NSString stringWithFormat:@"%lu COMMENTS",(unsigned long)tableView.report.comments.count];
        [commentsButton setTitle:commentsTitle forState:UIControlStateNormal];
        if (activities){
            [commentsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [commentsButton setBackgroundColor:[UIColor whiteColor]];
        } else {
            [commentsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [commentsButton setBackgroundColor:[UIColor clearColor]];
        }
        
        [commentsButton setFrame:CGRectMake(width/2, 0, width/2, 40)];
        [commentsButton addTarget:self action:@selector(showComments) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:commentsButton];
        
        [headerView addSubview:headerLabel];
        return headerView;
        
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
                NSLog(@"it's a safety report");
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
                if ([tableView.report.type isEqualToString:kDaily]){
                    [headerLabel setText:@"DAILY SUMMARY"];
                } else {
                    [headerLabel setText:[NSString stringWithFormat:@"%@ ACTIVITY",tableView.report.project.name.uppercaseString]];
                }
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

#pragma mark - Header & Comments Section

- (void)submitComment {
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to submit comments for a demo project task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if (addCommentTextView.text.length) {
            [ProgressHUD show:@"Adding comment..."];
            NSDictionary *commentDict = @{@"report_id":_reportTableView.report.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"body":addCommentTextView.text};
            [manager POST:[NSString stringWithFormat:@"%@/comments",kApiBaseUrl] parameters:@{@"comment":commentDict} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"success creating a comment for task: %@",responseObject);
                
                Comment *comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [comment populateFromDictionary:[responseObject objectForKey:@"comment"]];
                NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:_reportTableView.report.comments];
                [set insertObject:comment atIndex:0];
                [_reportTableView.report setComments:set];
                
                //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
                
                [_reportTableView beginUpdates];
                [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:9] withRowAnimation:UITableViewRowAnimationFade];
                //[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [_reportTableView endUpdates];
                
                addCommentTextView.text = kAddCommentPlaceholder;
                addCommentTextView.textColor = [UIColor lightGrayColor];
                
                [ProgressHUD dismiss];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [ProgressHUD dismiss];
                NSLog(@"Failure creating a comment for task: %@",error.description);
            }];
        }
    }
    [self doneEditing];
}

- (void)tableView:(BHReportTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"did select: %lu in section %lu",(long)indexPath.row, (long)indexPath.section);
    if (indexPath.section == 6 && [tableView.report.type isEqualToString:kSafety]){
        if (tableView.report.safetyTopics.count > indexPath.row){
            SafetyTopic *topic = [tableView.report.safetyTopics objectAtIndex:indexPath.row];
            if (self.delegate && [self.delegate respondsToSelector:@selector(showSafetyTopic:fromCellRect:)]){
                [self.delegate showSafetyTopic:topic fromCellRect:[tableView rectForRowAtIndexPath:indexPath]];
            }
        }
    } else if (indexPath.section == tableView.numberOfSections - 1){
        Activity *activity;
        if ([tableView.report.type isEqualToString:kDaily]){
            activity = tableView.report.dailyActivities[indexPath.row];
        } else {
            activity = tableView.report.activities[indexPath.row];
        }
        
        /*if (activity.task){
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
        }*/
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

-(void)textViewDidBeginEditing:(UITextView *)textView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(beginEditing)]){
        [self.delegate beginEditing];
    }
    
    [_report setSaved:@NO];
    if ([textView.text isEqualToString:kReportPlaceholder] || [textView.text isEqualToString:kWeatherPlaceholder] || [textView.text isEqualToString:kAddCommentPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor blackColor]];
    }
    
    if (textView.tag == 8){
        
        [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:8] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
    } else if (textView.tag == 1){
        
        [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
    } else if (textView.tag == 9 || textView == addCommentTextView){
        [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:9] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        [UIView animateWithDuration:.25 animations:^{
            doneCommentButton.alpha = 1.0;
        }];
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(beginEditing)]){
        [self.delegate beginEditing];
    }
    
    [_report setSaved:@NO];
    if ([textField isKindOfClass:[BHPersonnelCountTextField class]]) {
        if ([(BHPersonnelCountTextField*)textField personnelType] == kUserHours){
            [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:3] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        } else {
            [_reportTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:4] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
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
    } else if (textField == tempTextField){
        [_report setTemp:tempTextField.text];
    } else if (textField == precipTextField){
        [_report setPrecip:precipTextField.text];
    } else if (textField == windTextField){
        [_report setWind:windTextField.text];
    } else if (textField == humidityTextField){
        [_report setHumidity:humidityTextField.text];
    }
    [self doneEditing];
}

-(void)doneEditing {
    if (self.delegate && [self.delegate respondsToSelector:@selector(doneEditing)]){
        [self.delegate doneEditing];
    }
    if (doneCommentButton.alpha > 0){
        [UIView animateWithDuration:.25 animations:^{
            doneCommentButton.alpha = 0.0;
        }];
    }
}

- (void)showPersonnelActionSheet {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showPersonnelActionSheet)]){
        [self.delegate showPersonnelActionSheet];
    }
}

-(void)tapTypePicker {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showReportTypePicker)]){
        [self.delegate showReportTypePicker];
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

- (void)choosePhoto {
    if (self.delegate && [self.delegate respondsToSelector:@selector(choosePhoto)]){
        [self.delegate choosePhoto];
    }
}

- (void)takePhoto {
    if (self.delegate && [self.delegate respondsToSelector:@selector(takePhoto)]){
        [self.delegate takePhoto];
    }
}

- (void)redrawScrollView {
    reportScrollView.delegate = self;
    [reportScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    reportScrollView.showsHorizontalScrollIndicator = NO;
    
    float imageSize = 70.0;
    float space = 4.0;
    int index = 0;
    for (Photo *photo in _report.photos) {
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        } else if (photo.urlSmall.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        } else if (photo.urlThumb.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlThumb] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        }
        [imageButton setTag:[_report.photos indexOfObject:photo]];
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(showPhotoBrowserWithPhotos:withCurrentIndex:)]){
        [self.delegate showPhotoBrowserWithPhotos:browserPhotos withCurrentIndex:button.tag];
    }
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
    // TO DO ensure correct frame is being used (when rotated)
    CGFloat keyboardHeight = keyboardValue.CGRectValue.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _reportTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         _reportTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _reportTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         _reportTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                     }
                     completion:nil];
}

- (void)prefill {
    NSLog(@"should be prefilling");
    if (self.delegate && [self.delegate respondsToSelector:@selector(prefill)]){
        [self.delegate prefill];
    }
}

- (void)showDatePicker {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showDatePicker)]){
        [self.delegate showDatePicker];
    }
}

- (void)chooseTopics:(id)sender {
    if (topicsFetched){
        if (self.delegate && [self.delegate respondsToSelector:@selector(showTopicsActionSheet)]){
            [self.delegate showTopicsActionSheet];
        }
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
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(showTopicsActionSheet)]){
                [self.delegate showTopicsActionSheet];
            }
            
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            NSLog(@"failed to get possible topics: %@",error.description);
        }];
    }
}

#pragma mark - UITextView Delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)thisText {
    if ([thisText isEqualToString:@"\n"]) {
        if (textView == addCommentTextView && textView.text.length) {
            [self submitComment];
            [self doneEditing];
            [textView resignFirstResponder];
            return NO;
        } else {
            return YES;
        }
    }
    return YES;
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
    if (_report.safetyTopics.count > 0){
        [_reportTableView beginUpdates];
        [_reportTableView deleteRowsAtIndexPaths:@[forDeletion] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    } else {
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:6] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Weather Stuff

- (void)loadWeather:(NSDate*)reportDate {
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
                [_report setHumidity:[NSString stringWithFormat:@"%.0f%%", [[dailyData objectForKey:@"humidity"] floatValue]*100]];
                [_report setPrecip:[NSString stringWithFormat:@"%.0f%%", [[dailyData objectForKey:@"precipProbability"] floatValue]*100]];
                [_report setTemp:[NSString stringWithFormat:@"%@° / %@°",min,max]];
                [_report setWeatherIcon:[dailyData objectForKey:@"icon"]];
                [_report setWeather:[dailyData objectForKey:@"summary"]];
                if ([[[dailyData objectForKey:@"windSpeed"] stringValue] length]){
                    windSpeed = [[dailyData objectForKey:@"windSpeed"] stringValue];
                    if (windSpeed.length > 3){
                        windSpeed = [windSpeed substringToIndex:3];
                    }
                }
                windDirection = [self windDirection:[[responseObject objectForKey:@"windBearing"] intValue]];
                [_report setWind:[NSString stringWithFormat:@"%@mph %@",windSpeed, windDirection]];
                weatherString = [NSString stringWithFormat:@"%@. Temp: %@. Wind: %@mph %@.",[dailyData objectForKey:@"summary"],temp,windSpeed, windDirection];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_reportTableView reloadData];
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

@end
