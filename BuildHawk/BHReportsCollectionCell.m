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
    UITextView *reportBodyTextView;
    UIView *photoButtonContainer;
    UIButton *commentsButton;
    UIButton *activityButton;
    UIButton *doneCommentButton;
    UIActionSheet *reportActionSheet;
    BHReportPhotoScrollView *reportPhotoScrollView;
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
    NSIndexPath *indexPathForDeletion;
}

@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) Report *report;
@end

@implementation BHReportsCollectionCell

- (void)configureForReport:(Report *)report withDateFormatter:(NSDateFormatter *)dateFormatter andNumberFormatter:(NSNumberFormatter *)number withTimeStampFormatter:(NSDateFormatter *)timeStamp withCommentFormatter:(NSDateFormatter *)comment withWidth:(CGFloat)w andHeight:(CGFloat)h {
    
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    self.project = [Project MR_findFirstByAttribute:@"identifier" withValue:self.projectId inContext:[NSManagedObjectContext MR_defaultContext]];
    
    if ([report.identifier isEqualToNumber:@0]){
        NSPredicate *newReportPredicate = [NSPredicate predicateWithFormat:@"dateString == %@ and type == %@ and project.identifier == %@",report.dateString, report.type,_projectId];
        self.report = [Report MR_findFirstWithPredicate:newReportPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
    } else {
        self.report = [Report MR_findFirstByAttribute:@"identifier" withValue:report.identifier inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    [_reportTableView setReport:self.report];
    
    formatter = dateFormatter;
    timeStampFormatter = timeStamp;
    commentFormatter = comment;
    numberFormatter = number;
    width = w;
    height = h;
    mainScreen = CGRectMake(0, 0, width, h);
    
    if (!self.report.wind.length){
        [self loadWeather:[formatter dateFromString:self.report.dateString]];
    }
    
    [_reportTableView reloadData];
    [self registerForKeyboardNotifications];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(BHReportTableView *)tableView {
    return 10;
}

- (NSInteger)tableView:(BHReportTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return  2;
    } else if (section == 1 && [self.report.type isEqualToString:kDaily]) {
        return 5;
    } else if (section == 2) {
        return 2;
    } else if (section == 3) {
        return self.report.reportUsers.count;
    } else if (section == 4) {
        return self.report.reportSubs.count;
    } else if (section == 5 && [self.report.type isEqualToString:kSafety]){
        return 1;
    } else if (section == 6 && [self.report.type isEqualToString:kSafety]){
        return self.report.safetyTopics.count;
    } else if (section == 7 || section == 8){
        return 1;
    } else if (section == 9){
        if (activities){
            if ([self.report.type isEqualToString:kDaily]){
                return self.report.dailyActivities.count;
            } else {
                return self.report.activities.count;
            }
        } else {
            return self.report.comments.count + 1;
        }
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(BHReportTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"ReportPickerCell";
        BHReportPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
        if (indexPath.row == 0){
            if (self.report.dateString.length) {
                [cell.textLabel setText:[NSString stringWithFormat:@"%@",self.report.dateString]];
            } else {
                [cell.textLabel setText:[NSString stringWithFormat:@"-"]];
            }
            [cell.textLabel setTextColor:[UIColor blackColor]];
        } else {
            if (self.report.author){
                [cell.textLabel setText:[NSString stringWithFormat:@"%@ - %@",self.report.type, self.report.author.fullname]];
            } else {
                [cell.textLabel setText:[NSString stringWithFormat:@"%@",self.report.type]];
            }
            
            if ([self.report.type isEqualToString:kDaily]){
                [cell.textLabel setTextColor:kDailyReportColor];
            } else if ([self.report.type isEqualToString:kWeekly]){
                [cell.textLabel setTextColor:kWeeklyReportColor];
            } else {
                [cell.textLabel setTextColor:kSafetyReportColor];
            }
        }
        return cell;
    } else if (indexPath.section == 1) {
        static NSString *CellIdentifier = @"ReportWeatherCell";
        BHReportWeatherCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        cell.textField.delegate = self;
        [cell.dailySummaryTextView setHidden:YES];
        [cell.textField setHidden:NO];
        [cell.imageView setImage:nil];
        switch (indexPath.row) {
            case 0:
            {
                [cell.label setText:@""];
                [cell.dailySummaryTextView setHidden:NO];
                [cell.textField setHidden:YES];
                if (self.report.weather.length) {
                    [cell.dailySummaryTextView setTextColor:[UIColor blackColor]];
                    [cell.dailySummaryTextView setText:self.report.weather];
                } else {
                    [cell.dailySummaryTextView setTextColor:[UIColor lightGrayColor]];
                    [cell.dailySummaryTextView setText:kWeatherPlaceholder];
                }
                cell.dailySummaryTextView.delegate = self;
                cell.dailySummaryTextView.tag = indexPath.section; weatherTextView = cell.dailySummaryTextView;
                CGRect weatherFrame = cell.dailySummaryTextView.frame;
                weatherFrame.size.width = width - weatherFrame.origin.x;
                weatherFrame.size.height = cell.frame.size.height;
                weatherFrame.origin.y = 0;
                [cell.dailySummaryTextView setFrame:weatherFrame];
                
                // set an image icon
                if ([self.report.weatherIcon isEqualToString:@"clear-day"] || [self.report.weatherIcon isEqualToString:@"clear-night"]) [cell.imageView setImage:[UIImage imageNamed:@"sunny"]];
                else if ([self.report.weatherIcon isEqualToString:@"cloudy"]) [cell.imageView setImage:[UIImage imageNamed:@"cloudy"]];
                else if ([self.report.weatherIcon isEqualToString:@"partly-cloudy-day"] || [self.report.weatherIcon isEqualToString:@"partly-cloudy-night"]) [cell.imageView setImage:[UIImage imageNamed:@"partly"]];
                else if ([self.report.weatherIcon isEqualToString:@"rain"] || [self.report.weatherIcon isEqualToString:@"sleet"]) {
                    [cell.imageView setImage:[UIImage imageNamed:@"rainy"]];
                } else if ([self.report.weatherIcon isEqualToString:@"fog"] || [self.report.weatherIcon isEqualToString:@"wind"]) {
                    [cell.imageView setImage:[UIImage imageNamed:@"wind"]];
                }
            }
                break;
            case 1:
                [cell.label setText:@"Temp"];
                tempTextField = cell.textField;
                [cell.textField setText:self.report.temp];
                break;
            case 2:
                [cell.label setText:@"Wind"];
                windTextField = cell.textField;
                [cell.textField setText:self.report.wind];
                break;
            case 3:
                [cell.label setText:@"Precip"];
                precipTextField = cell.textField;
                [cell.textField setText:self.report.precip];
                break;
            case 4:
                [cell.label setText:@"Humidity"];
                humidityTextField = cell.textField;
                [cell.textField setText:self.report.humidity];
                break;
                
            default:
                break;
        }
        
        return cell;
    } else if (indexPath.section == 2) {
        static NSString *CellIdentifier = @"ChooseReportPersonnelCell";
        BHChooseReportPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
        if (indexPath.row == 0){
            [cell.textLabel setText:@"Add / Edit"];
        } else {
            [cell.textLabel setText:@"Pre-fill from last report"];
            if (_canPrefill){
                [cell setUserInteractionEnabled:YES];
                [cell setAlpha:1.0];
            } else {
                [cell setUserInteractionEnabled:NO];
                [cell setAlpha:.5];
            }
        }
    
        return cell;
    } else if (indexPath.section == 3) {
        static NSString *CellIdentifier = @"ReportPersonnelCell";
        BHReportPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (self.report.reportUsers.count > indexPath.row){
            ReportUser *reportUser = [self.report.reportUsers objectAtIndex:indexPath.row];
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
        
        if (self.report.reportSubs.count > indexPath.row){
            ReportSub *reportSub = [self.report.reportSubs objectAtIndex:indexPath.row];
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
        
        if ([self.report.type isEqualToString:kSafety]){
            [cell.chooseTopicsButton setHidden:NO];
        } else {
            [cell.chooseTopicsButton setHidden:YES];
        }
        return cell;
    } else if (indexPath.section == 6) {
        static NSString *CellIdentifier = @"SafetyTopicCell";
        BHSafetyTopicsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (self.report.safetyTopics.count > indexPath.row){
            SafetyTopic *topic = [self.report.safetyTopics objectAtIndex:indexPath.row];
            [cell configureTopic:topic];
            [cell.removeButton setTag:topic.topicId.integerValue];
            [cell.removeButton addTarget:self action:@selector(removeTopic:) forControlEvents:UIControlEventTouchUpInside];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    } else if (indexPath.section == 7) {
        BHReportPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:cell.photoScrollView.panGestureRecognizer];
        reportPhotoScrollView = cell.photoScrollView;
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
        
        if (self.report.body.length) {
            [cell.reportBodyTextView setText:self.report.body];
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
        [reportBodyTextView setFont:[UIFont fontWithName:kMyriadPro size:17]];
        
        return cell;
    } else {
        if (activities){
            static NSString *CellIdentifier = @"ActivityCell";
            BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
            }
            
            if ([self.report.type isEqualToString:kDaily]){
                Activity *activity = self.report.dailyActivities[indexPath.row];
                [cell.timestampLabel setText:[timeStampFormatter stringFromDate:activity.createdDate]];
                [cell configureActivityForSynopsis:activity];
            } else if (self.report.activities.count > indexPath.row) {
                Activity *activity = self.report.activities[indexPath.row];
                [cell.timestampLabel setText:[timeStampFormatter stringFromDate:activity.createdDate]];
                [cell configureForActivity:activity];
            }
            
            return cell;
        } else {
            if (indexPath.row == 0){
                BHAddCommentCell *addCommentCell = [tableView dequeueReusableCellWithIdentifier:@"AddCommentCell"];
                if (addCommentCell == nil) {
                    addCommentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddCommentCell" owner:self options:nil] lastObject];
                }
                [addCommentCell configure];
                addCommentTextView.tag = indexPath.section;
                addCommentTextView = addCommentCell.messageTextView;
                addCommentTextView.delegate = self;
                [addCommentTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
                [addCommentCell.doneButton addTarget:self action:@selector(submitComment) forControlEvents:UIControlEventTouchUpInside];
                doneCommentButton = addCommentCell.doneButton;
                self.reportTableView = tableView; //what is this about?
                return addCommentCell;
            } else {
                BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
                if (cell == nil) {
                    cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
                }
                Comment *comment = [self.report.comments objectAtIndex:indexPath.row - 1];
                [cell configureForComment:comment];
                [cell.timestampLabel setText:[commentFormatter stringFromDate:comment.createdAt]];
                return cell;
            }
        }
    }
}

- (CGFloat)tableView:(BHReportTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 66;
            break;
        case 1:
            if ([self.report.type isEqualToString:kDaily]) {
                if (indexPath.row == 0){
                    return 100;
                } else {
                    return 54;
                }
            } else return 0;
            break;
        case 2:
            return 66;
            break;
        case 3:
            return 66;
            break;
        case 4:
            return 66;
            break;
        case 5:
            if ([self.report.type isEqualToString:kSafety]) {
                return 80;
            } else {
                return 0;
            }
            break;
        case 6:
            if ([self.report.type isEqualToString:kSafety]) return 66;
            else return 0;
        case 7:
            return 100;
            break;
        case 8:
            if (IDIOM == IPAD){
                return 400;
            } else {
                return 270;
            }
            break;
        default:
            return 80;
            break;
    }
}

- (CGFloat)tableView:(BHReportTableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 3 && !self.report.reportUsers.count){
        return 0;
    } else if (section == 4 && !self.report.reportSubs.count){
        return 0;
    } else if (section == 1 && ![self.report.type isEqualToString:kDaily]){
        return 0;
    } else if (section == 5 && ![self.report.type isEqualToString:kSafety]){
        return 0;
    } else if (section == 6){
        return 0;
    } else if (section == 9){
        if ([self.report.type isEqualToString:kDaily] && self.report.dailyActivities.count == 0){
            return 0;
        } else if (self.report.activities.count == 0){
            return 0;
        } else {
            return 40;
        }
    } else {
        return 40;
    }
}

- (UIView*)tableView:(BHReportTableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (![self.report.type isEqualToString:kDaily] && section == 1){
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else if (section == 9) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
        [headerView setBackgroundColor:kDarkerGrayColor];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
        headerLabel.layer.cornerRadius = 3.f;
        headerLabel.clipsToBounds = YES;
        [headerLabel setBackgroundColor:[UIColor clearColor]];
        [headerLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        [headerLabel setTextColor:[UIColor darkGrayColor]];
        
        [headerLabel setText:@""];
        
        activityButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [activityButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
        [activityButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
        
        NSString *activitiesTitle;
        if ([self.report.type isEqualToString:kDaily]){
            activitiesTitle = self.report.dailyActivities.count == 1 ? @"1 ACTIVITY" : [NSString stringWithFormat:@"%lu ACTIVITIES",(unsigned long)self.report.dailyActivities.count];
        } else {
            activitiesTitle = self.report.activities.count == 1 ? @"1 ACTIVITY" : [NSString stringWithFormat:@"%lu ACTIVITIES",(unsigned long)self.report.activities.count];
        }
        [activityButton setTitle:activitiesTitle forState:UIControlStateNormal];
        
        if (activities){
            [activityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [activityButton setBackgroundColor:[UIColor clearColor]];
        } else {
            [activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [activityButton setBackgroundColor:[UIColor whiteColor]];
        }
        [activityButton setFrame:CGRectMake(width/2, 0, width/2, 40)];
        [activityButton addTarget:self action:@selector(showActivities) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:activityButton];
        
        commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [commentsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [commentsButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
        
        NSString *commentsTitle = self.report.comments.count == 1 ? @"1 COMMENT" : [NSString stringWithFormat:@"%lu COMMENTS",(unsigned long)self.report.comments.count];
        [commentsButton setTitle:commentsTitle forState:UIControlStateNormal];
        if (activities){
            [commentsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [commentsButton setBackgroundColor:[UIColor whiteColor]];
        } else {
            [commentsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [commentsButton setBackgroundColor:[UIColor clearColor]];
        }
        
        [commentsButton setFrame:CGRectMake(0, 0, width/2, 40)];
        [commentsButton addTarget:self action:@selector(showComments) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:commentsButton];
        
        [headerView addSubview:headerLabel];
        return headerView;
        
    } else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
        [headerView setBackgroundColor:kLightestGrayColor];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, width,38)];
        [headerLabel setBackgroundColor:kLightestGrayColor];
        [headerLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        [headerLabel setTextColor:[UIColor darkGrayColor]];
        
        CGFloat leftLabelOffset,centerLabelOffset;
        if (IDIOM == IPAD){
            leftLabelOffset = 23;
            centerLabelOffset = width*.7;
        } else {
            leftLabelOffset = 10;
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
                [headerLabel setFrame:CGRectMake(leftLabelOffset, 0, screenWidth()*2/3, 40)];
                [headerLabel setTextAlignment:NSTextAlignmentLeft];
                [headerLabel setTextColor:[UIColor darkGrayColor]];
                [headerLabel setBackgroundColor:[UIColor clearColor]];
                UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(centerLabelOffset, 0, width*.4, 40)];
                [countLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
                [countLabel setText:@"# HOURS"];
                [countLabel setFont:[UIFont fontWithName:kMyriadPro size:15]];
                [countLabel setTextColor:[UIColor darkGrayColor]];
                [countLabel setBackgroundColor:[UIColor clearColor]];
                [headerView addSubview:countLabel];
            }
                break;
            case 4:
            {
                [headerLabel setText:@"COMPANIES"];
                [headerLabel setFrame:CGRectMake(leftLabelOffset, 0, width*2/3, 40)];
                [headerLabel setTextAlignment:NSTextAlignmentLeft];
                [headerLabel setTextColor:[UIColor lightGrayColor]];
                [headerLabel setBackgroundColor:[UIColor clearColor]];
                UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(centerLabelOffset, 0, width*.4, 40)];
                [countLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
                [countLabel setText:@"# ON SITE"];
                [countLabel setFont:[UIFont fontWithName:kMyriadPro size:15]];
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
                if ([self.report.type isEqualToString:kSafety]){
                    [headerLabel setText:@"PHOTO OF SIGN IN CARD / GROUP"];
                } else {
                    [headerLabel setText:@"PHOTOS"];
                }
                break;
            case 8:
                [headerLabel setText:@"NOTES"];
                break;
            case 9:
                if ([self.report.type isEqualToString:kDaily]){
                    [headerLabel setText:@"DAILY SUMMARY"];
                } else {
                    [headerLabel setText:[NSString stringWithFormat:@"%@ ACTIVITY",self.report.project.name.uppercaseString]];
                }
                activityButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [activityButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
                [activityButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
                [activityButton setTitle:@"ACTIVITY" forState:UIControlStateNormal];
                if (activities){
                    [activityButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                } else {
                    [activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                }
                [activityButton setFrame:CGRectMake(width*3/4-50, 0, 100, 40)];
                [activityButton addTarget:self action:@selector(showActivities) forControlEvents:UIControlEventTouchUpInside];
                [headerView addSubview:activityButton];
                
                commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [commentsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
                [commentsButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
                [commentsButton setTitle:@"COMMENTS" forState:UIControlStateNormal];
                if (activities){
                    [commentsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                } else {
                    [commentsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                }
                
                [commentsButton setFrame:CGRectMake(width/4-50, 0, 100, 40)];
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
    [self doneEditing];
    
    if ([self.project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to submit comments for a demo project task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if (addCommentTextView.text.length) {
            [ProgressHUD show:@"Adding comment..."];
            Comment *comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [comment setSaved:@NO];
            [comment setCreatedAt:[NSDate date]];
            if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
                User *currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
                [comment setUser:currentUser];
            }
            if (![self.report.identifier isEqualToNumber:@0]){
                [comment setReport:self.report];
            }
            if (addCommentTextView.text.length){
                [comment setBody:addCommentTextView.text];
            }
            [self.report addComment:comment];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                activities = NO; //redraw the tableview
                [_reportTableView beginUpdates];
                //NSIndexPath *indexPathForNewComment = [NSIndexPath indexPathForRow:1 inSection:9];
                //[_reportTableView insertRowsAtIndexPaths:@[indexPathForNewComment] withRowAnimation:UITableViewRowAnimationFade];
                [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:9] withRowAnimation:UITableViewRowAnimationAutomatic];
                [_reportTableView endUpdates];
            }];
            
            [comment synchWithServer:^(BOOL completed) {
                [ProgressHUD dismiss];
                if (completed){
                    [comment setSaved:@YES];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        NSLog(@"Success synching comment with server");
                    }];
                } else {
                    [comment setSaved:@NO];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        NSLog(@"Couldn't synch comment with server");
                        [[appDelegate syncController] update];
                    }];
                }
            }];
            addCommentTextView.text = kAddCommentPlaceholder;
            addCommentTextView.textColor = [UIColor lightGrayColor];
        }
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 9){
        if (activities || indexPath.row == 0){
            return NO;
        } else {
            Comment *comment = [self.report.comments objectAtIndex:indexPath.row - 1];
            //ensure that there's a signed in user and ask whether they're the current author
            if (comment && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && ([comment.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] || [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUberAdmin])){
                return YES;
            } else {
                return NO;
            }
        }
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = indexPath;
        [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to delete this comment?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self deleteComment];
    }
}

- (void)deleteComment {
    if ([_project.demo isEqualToNumber:@YES]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete comments from a demo project checklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        Comment *comment = self.report.comments[indexPathForDeletion.row-1];
        if ([comment.identifier isEqualToNumber:@0]){
            [self.report removeComment:comment];
            [comment MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            
            [self.reportTableView beginUpdates];
            [self.reportTableView reloadSections:[NSIndexSet indexSetWithIndex:indexPathForDeletion.section] withRowAnimation:UITableViewRowAnimationFade];
            [self.reportTableView endUpdates];
            
        } else if (appDelegate.connected) {
            [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kApiBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully deleted activity: %@",responseObject);
                [self.report removeComment:comment];
                [comment MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                [self.reportTableView beginUpdates];
                //[self.reportTableView reloadSections:[NSIndexSet indexSetWithIndex:indexPathForDeletion.section] withRowAnimation:UITableViewRowAnimationFade];
                [self.reportTableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
                [self.reportTableView endUpdates];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                //NSLog(@"Failed to delete comment: %@",error.description);
            }];
        }else {
            [[[UIAlertView alloc] initWithTitle:@"Offline" message:@"Deleting comments is disabled while offline." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }
}

- (void)tableView:(BHReportTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0){
            [self showDatePicker];
        } else {
            [self tapTypePicker];
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0){
            [self showPersonnelActionSheet];
        } else {
            [self prefill];
        }
    } else if (indexPath.section == 6 && [self.report.type isEqualToString:kSafety]){
        if (self.report.safetyTopics.count > indexPath.row){
            SafetyTopic *topic = [self.report.safetyTopics objectAtIndex:indexPath.row];
            if (self.delegate && [self.delegate respondsToSelector:@selector(showSafetyTopic:fromCellRect:)]){
                [self.delegate showSafetyTopic:topic fromCellRect:[tableView rectForRowAtIndexPath:indexPath]];
            }
        }
    } else if (indexPath.section == tableView.numberOfSections - 1){
        if (activities){
            Activity *activity;
            if ([self.report.type isEqualToString:kDaily]){
                activity = self.report.dailyActivities[indexPath.row];
            } else {
                activity = self.report.activities[indexPath.row];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(showActivity:)]){
                [self.delegate showActivity:activity];
            }
        }
    }
}

- (void)showActivities {
    [activityButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [commentsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    activities = YES;
    [_reportTableView beginUpdates];
    [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:9] withRowAnimation:UITableViewRowAnimationFade];
    [_reportTableView endUpdates];
}

- (void)showComments {
    [activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [commentsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    activities = NO;
    [_reportTableView beginUpdates];
    [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:9] withRowAnimation:UITableViewRowAnimationFade];
    [_reportTableView endUpdates];
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
    if (notification) {
        NSDictionary* info = [notification userInfo];
        NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
        NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
        CGRect convertedKeyboardFrame = [_reportTableView convertRect:keyboardValue.CGRectValue fromView:[(BHAppDelegate*)[UIApplication sharedApplication].delegate window]];
        CGFloat keyboardHeight = convertedKeyboardFrame.size.height;
        [UIView animateWithDuration:duration
                              delay:0
                            options:curve | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             _reportTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                             _reportTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         } completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (notification) {
        NSDictionary* info = [notification userInfo];
        NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
        [UIView animateWithDuration:duration
                              delay:0
                            options:curve | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             _reportTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                             _reportTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                         } completion:^(BOOL finished) {
                             [self doneEditing];
                         }];
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
    if (!textView.text.length || [textView.text isEqualToString:kReportPlaceholder] || [textView.text isEqualToString:kWeatherPlaceholder] || [textView.text isEqualToString:kAddCommentPlaceholder]) {
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
            self.report.body = @"";
        } else if (textView.text.length){
            self.report.body = textView.text;
        }
    } else if (textView.tag == 1) {
        if (textView.text.length) {
            if (![self.report.weather isEqualToString:textView.text]){
                self.report.weather = textView.text;
                [self.report setSaved:@NO];
            }
        } else {
            self.report.weather = @"";
            [textView setText:kWeatherPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
        }
    } else {
        [self doneEditing];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
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
        if ([(BHPersonnelCountTextField*)textField personnelType] == kUserHours && textField.tag < self.report.reportUsers.count) {
            ReportUser *reportUser = [self.report.reportUsers objectAtIndex:textField.tag];
            reportUser.hours = [numberFormatter numberFromString:textField.text];
        } else if ([(BHPersonnelCountTextField*)textField personnelType] == kSubcontractorCount && textField.tag < self.report.reportSubs.count) {
            ReportSub *reportSub = [self.report.reportSubs objectAtIndex:textField.tag];
            reportSub.count = [numberFormatter numberFromString:textField.text];
        }
    } else if (textField == tempTextField){
        if (![tempTextField.text isEqualToString:self.report.temp]){
            [self.report setTemp:tempTextField.text];
            [self.report setSaved:@NO];
        }
    } else if (textField == precipTextField){
        if (![precipTextField.text isEqualToString:self.report.precip]){
            [self.report setPrecip:precipTextField.text];
            [self.report setSaved:@NO];
        }
    } else if (textField == windTextField){
        if (![windTextField.text isEqualToString:self.report.wind]){
            [self.report setWind:windTextField.text];
            [self.report setSaved:@NO];
        }
    } else if (textField == humidityTextField){
        if (![humidityTextField.text isEqualToString:self.report.humidity]){
            [self.report setHumidity:humidityTextField.text];
            [self.report setSaved:@NO];
        }
    }
    [self doneEditing];
}

-(void)doneEditing {
    if (doneCommentButton.alpha > 0.f){
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
    [manager POST:[NSString stringWithFormat:@"%@/subs",kApiBaseUrl] parameters:@{@"name":user.email,@"project_id":self.project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    reportPhotoScrollView.delegate = self;
    [reportPhotoScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    reportPhotoScrollView.showsHorizontalScrollIndicator = NO;
    
    float imageSize = 92.0;
    float space = 4.0;
    int index = 0;
    for (Photo *photo in self.report.photos) {
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        } else if (photo.urlSmall.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        }
        [imageButton setTag:[self.report.photos indexOfObject:photo]];
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),reportPhotoScrollView.frame.size.height/2-imageSize/2,imageSize, imageSize)];
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageButton.imageView.layer.cornerRadius = 2.0;
        [imageButton setBackgroundColor:kLightestGrayColor];
        [imageButton.imageView setBackgroundColor:kLightestGrayColor];
        [imageButton.imageView.layer setBackgroundColor:kLightestGrayColor.CGColor];
        imageButton.imageView.layer.shouldRasterize = YES;
        imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton addTarget:self action:@selector(existingPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [reportPhotoScrollView addSubview:imageButton];
        index++;
    }
    
    [reportPhotoScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    if (reportPhotoScrollView.isHidden) [reportPhotoScrollView setHidden:NO];
}

- (void)existingPhotoButtonTapped:(UIButton*)button {
    [self showPhotoDetail:button];
    removePhotoIdx = button.tag;
}

- (void)showPhotoDetail:(UIButton*)button {
    browserPhotos = [NSMutableArray new];
    for (Photo *photo in self.report.photos) {
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

- (void)prefill {
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
        [self showTopicsActionSheet];
    } else if (appDelegate.connected) {
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
            for (SafetyTopic *topic in self.project.company.safetyTopics) {
                if (![topicsSet containsObject:topic]) {
                    NSLog(@"Deleting safety topic that no longer exists: %@",topic.title);
                    [topic MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                }
            }
            self.project.company.safetyTopics = topicsSet;
            [self showTopicsActionSheet];
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self showTopicsActionSheet];
            [ProgressHUD dismiss];
            //NSLog(@"failed to get possible topics: %@",error.description);
        }];
    } else {
        [self showTopicsActionSheet];
    }
}

- (void)showTopicsActionSheet {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showTopicsActionSheet)]){
        [self.delegate showTopicsActionSheet];
    }
}

#pragma mark - UITextView Delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)thisText {
    if ([thisText isEqualToString:@"\n"]) {
        if (textView == addCommentTextView && textView.text.length) {
            [self submitComment];
            [self doneEditing];
            return NO;
        } else {
            return YES;
        }
    }
    return YES;
}

- (void)removeUser:(UIButton*)button {
    if (self.report.reportUsers.count > button.tag){
        ReportUser *reportUser = [self.report.reportUsers objectAtIndex:button.tag];
        if (reportUser && ![self.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) {
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            [parameters setObject:self.report.identifier forKey:@"report_id"];
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
        
        [_reportTableView beginUpdates];
        [self.report removeReportUser:reportUser];
        [reportUser MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    }
}

- (void)removeSubcontractor:(UIButton*)button {
    //NSLog(@"remove subcontractor button tag: %d",button.tag);
    if (self.report.reportSubs.count > button.tag){
        ReportSub *reportSub = [self.report.reportSubs objectAtIndex:button.tag];
        if (![self.report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) {
            if (reportSub && ![reportSub.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                [parameters setObject:self.report.identifier forKey:@"report_id"];
                [parameters setObject:reportSub.companyId forKey:@"company_id"];
                [manager DELETE:[NSString stringWithFormat:@"%@/reports/remove_personnel",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSLog(@"success removing report subcontractor: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failure removing report subcontractor: %@",error.description);
                }];
            }
        }
        [_reportTableView beginUpdates];
        [self.report removeReportSubcontractor:reportSub];
        [reportSub MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [_reportTableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationFade];
        [_reportTableView endUpdates];
    }
}

- (void)removeTopic:(UIButton*)button {
    SafetyTopic *topic;
    for (SafetyTopic *t in self.report.safetyTopics) {
        if (t.topicId.integerValue == button.tag){
            topic = t;
            break;
        }
    }
    [_reportTableView beginUpdates];
    //update the datasource. make sure to fetch the indexPathForDeletion before you remove the topic!
    NSIndexPath *indexPathForTopicDeletion = [NSIndexPath indexPathForRow:[self.report.safetyTopics indexOfObject:topic] inSection:6];
    [self.report removeSafetyTopic:topic];
    [topic MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    //update the UI
    [_reportTableView deleteRowsAtIndexPaths:@[indexPathForTopicDeletion] withRowAnimation:UITableViewRowAnimationFade];
    [_reportTableView endUpdates];
}

#pragma mark - Weather Stuff

- (void)loadWeather:(NSDate*)reportDate {
    int unixTimestamp = [reportDate timeIntervalSince1970];
    if (self.project.address.latitude && self.project.address.longitude) {
        [manager GET:[NSString stringWithFormat:@"https://api.forecast.io/forecast/%@/%@,%@,%i",kForecastAPIKey,self.project.address.latitude, self.project.address.longitude,unixTimestamp] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                [self.report setHumidity:[NSString stringWithFormat:@"%.0f%%", [[dailyData objectForKey:@"humidity"] floatValue]*100]];
                [self.report setPrecip:[NSString stringWithFormat:@"%.0f%%", [[dailyData objectForKey:@"precipProbability"] floatValue]*100]];
                [self.report setTemp:[NSString stringWithFormat:@"%@° / %@°",min,max]];
                [self.report setWeatherIcon:[dailyData objectForKey:@"icon"]];
                [self.report setWeather:[dailyData objectForKey:@"summary"]];
                if ([[[dailyData objectForKey:@"windSpeed"] stringValue] length]){
                    windSpeed = [[dailyData objectForKey:@"windSpeed"] stringValue];
                    if (windSpeed.length > 3){
                        windSpeed = [windSpeed substringToIndex:3];
                    }
                }
                windDirection = [self windDirection:[[responseObject objectForKey:@"windBearing"] intValue]];
                [self.report setWind:[NSString stringWithFormat:@"%@mph %@",windSpeed, windDirection]];
                weatherString = [NSString stringWithFormat:@"%@. Temp: %@. Wind: %@mph %@.",[dailyData objectForKey:@"summary"],temp,windSpeed, windDirection];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_reportTableView reloadData];
                });
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldn't find weather data for this report." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (appDelegate.connected){
                NSLog(@"Failed to get the weather: %@",error.description);
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldn't find weather data for this report." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
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
