//
//  BHProjectSynopsisViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHProjectSynopsisViewController.h"
#import "Constants.h"
#import "BHTabBarViewController.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "ChecklistItem.h"
#import "Photo.h"
#import "Task+helper.h"
#import "BHRecentDocumentCell.h"
#import "UIButton+WebCache.h"
#import "MWPhotoBrowser.h"
#import "BHChecklistViewController.h"
#import "BHChecklistItemViewController.h"
#import "BHTaskViewController.h"
#import "BHProgressCell.h"
#import "BHOverlayView.h"
#import "BHAppDelegate.h"
#import "User+helper.h"
#import "Phase+helper.h"
#import "Activity+helper.h"
#import "BHActivityCell.h"
#import "BHReminderCell.h"
#import "BHSynopsisCell.h"
#import "BHActivitiesViewController.h"
#import "Tasklist+helper.h"
#import "Reminder+helper.h"
#import "Address+helper.h"
#import "BHReportViewController.h"
#import "BHPastDueReminderCell.h"
#import "BHMapViewController.h"

@interface BHProjectSynopsisViewController () <UIScrollViewDelegate, MWPhotoBrowserDelegate> {
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIScrollView *documentsScrollView;
    CGRect screen;
    CGFloat width;
    CGFloat height;
    NSMutableArray *browserPhotos;
    UIView *overlayBackground;
    UIImageView *screenshotView;
    NSDateFormatter *formatter;
    NSDateFormatter *deadlineFormatter;
    NSIndexPath *indexPathForReminderDeletion;
    NSMutableOrderedSet *projectReminders;
    NSMutableOrderedSet *pastDueProjectReminders;
    UIBarButtonItem *refreshButton;
}
@end

@implementation BHProjectSynopsisViewController

@synthesize project = _project;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.title = _project.name;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    screen = [UIScreen mainScreen].bounds;
    
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(handleRefresh)];
    self.navigationItem.rightBarButtonItem = refreshButton;

    [self setUpFooter];
    [self setUpTimeFormatters];
    [ProgressHUD show:@"Fetching the latest..."];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadProject];
}

- (void)setUpFooter{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 66)];
    [footerView setBackgroundColor:kDarkGrayColor];
    UIButton *goToProjectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [goToProjectButton setTitle:@"Go to Project" forState:UIControlStateNormal];
    [goToProjectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [goToProjectButton.titleLabel setFont:[UIFont fontWithName:kMyriadProLight size:18]];
    [goToProjectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:goToProjectButton];
    [goToProjectButton setFrame:footerView.frame];
    self.tableView.tableFooterView = footerView;
}

- (void)setUpTimeFormatters {
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];

    deadlineFormatter = [[NSDateFormatter alloc] init];
    [deadlineFormatter setDateFormat:@"MMM, d"];
}

- (void)handleRefresh {
    if (delegate.connected){
        pastDueProjectReminders = nil;
        [ProgressHUD show:@"Refreshing project..."];
        [self loadProject];
    }
}

- (void)loadProject {
    if (delegate.connected){
        [manager GET:[NSString stringWithFormat:@"%@/projects/%@/dash",kApiBaseUrl,_project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting project synopsis: %@",responseObject);
            [_project populateFromDictionary:[responseObject objectForKey:@"project"]];
            [self.tableView reloadData];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            NSLog(@"Failed to get project synopsis: %@",error.description);
        }];
    }
}

- (void)parseReminders {
    if (!pastDueProjectReminders) {
        pastDueProjectReminders = [NSMutableOrderedSet orderedSet];

        [_project.pastDueReminders enumerateObjectsUsingBlock:^(Reminder *reminder, NSUInteger idx, BOOL *stop) {
            if (reminder.user && [reminder.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
                [pastDueProjectReminders addObject:reminder];
            }
        }];
        projectReminders = [NSMutableOrderedSet orderedSet];
        [_project.reminders enumerateObjectsUsingBlock:^(Reminder *reminder, NSUInteger idx, BOOL *stop) {
            if ([reminder.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
                [projectReminders addObject:reminder];
            }
        }];
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [self parseReminders];
    }
    return 8;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
        {
            //limit the reminders to the three most recent
            NSInteger reminderCount = 0;
            if (projectReminders.count > 3){
                reminderCount = 3;
            } else {
                reminderCount = projectReminders.count;
            }
            if (pastDueProjectReminders.count){
                return reminderCount + 1;
            } else {
                return reminderCount;
            }
        }
            break;
        case 1:
            return _project.upcomingItems.count;
            break;
        case 2:
            if (_project.activities.count > 3){
                return 3;
            } else {
                return _project.activities.count;
            }
            
            break;
        case 3:
            return _project.phases.count;
            break;
        case 4:
            if (_project.checklist.activities.count > 3){
                return 3;
            } else if (_project.checklist && _project.checklist.activities.count) {
                return _project.checklist.activities.count;
            } else {
                return 0;
            }
            break;
        case 5:
            if (_project.recentDocuments.count > 0) {
                return 1;
            } else {
                return 0;
            }
            break;
        case 6:
            if (_project.tasklist.activities.count > 3){
                return 3;
            } else {
                return _project.tasklist.activities.count;
            }
            break;
        case 7:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            if (pastDueProjectReminders.count > 0){
                if (indexPath.row == 0){
                    BHPastDueReminderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PastDueReminderCell"];
                    if (cell == nil) {
                        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPastDueReminderCell" owner:self options:nil] lastObject];
                    }
                    [cell.textLabel setText:[NSString stringWithFormat:@"%lu PAST DUE",(unsigned long)pastDueProjectReminders.count]];
                    [cell.textLabel setFont:[UIFont fontWithName:kMyriadProSemibold size:16]];
                    [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
                    [cell.textLabel setTextColor:[UIColor redColor]];
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"redDisclosure"]];
                    [cell setTintColor:[UIColor redColor]];
                    return cell;
                } else {
                    BHReminderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReminderCell"];
                    if (cell == nil) {
                        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReminderCell" owner:self options:nil] lastObject];
                    }
                    NSInteger row = indexPath.row - 1;
                    Reminder *reminder = projectReminders[row];
                    if ([reminder.reminderDate isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]]){
                        [cell.reminderDatetimeLabel setText:@""];
                    } else {
                        [cell.reminderDatetimeLabel setText:[formatter stringFromDate:reminder.reminderDate]];
                    }
                    
                    [cell configureForReminder:reminder];
                    cell.reminderButton.tag = row;
                    [cell.reminderButton addTarget:self action:@selector(goToReminder:) forControlEvents:UIControlEventTouchUpInside];
                    cell.deleteButton.tag = row;
                    [cell.deleteButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:13]];
                    [cell.deleteButton addTarget:self action:@selector(confirmDeleteReminder:) forControlEvents:UIControlEventTouchUpInside];
                    
                    return cell;
                }
                
            } else {
                BHReminderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReminderCell"];
                if (cell == nil) {
                    cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReminderCell" owner:self options:nil] lastObject];
                }
                Reminder *reminder = projectReminders[indexPath.row];
                if ([reminder.reminderDate isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]]){
                    [cell.reminderDatetimeLabel setText:@""];
                } else {
                    [cell.reminderDatetimeLabel setText:[formatter stringFromDate:reminder.reminderDate]];
                }
                
                [cell configureForReminder:reminder];
                cell.reminderButton.tag = indexPath.row;
                [cell.reminderButton addTarget:self action:@selector(goToReminder:) forControlEvents:UIControlEventTouchUpInside];
                cell.deleteButton.tag = indexPath.row;
                [cell.deleteButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:13]];
                [cell.deleteButton addTarget:self action:@selector(confirmDeleteReminder:) forControlEvents:UIControlEventTouchUpInside];
                
                return cell;
            }
        }
            break;
        case 1: {
            static NSString *CellIdentifier = @"ItemCell";
            BHSynopsisCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            ChecklistItem *checklistItem = [_project.upcomingItems objectAtIndex:indexPath.row];
            [cell.deadlineTextLabel setText:checklistItem.body];
            if (checklistItem.criticalDate) {
                [cell.deadlineTimeLabel setText:[NSString stringWithFormat:@"Deadline:\n%@",[deadlineFormatter stringFromDate:checklistItem.criticalDate]]];
                [cell.deadlineTimeLabel setTextColor:[UIColor blackColor]];
            } else {
                [cell.deadlineTimeLabel setText:@"No critical date listed"];
                [cell.deadlineTimeLabel setTextColor:[UIColor lightGrayColor]];
            }
            if ([checklistItem.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
                [cell.deadlineTextLabel setTextColor:[UIColor lightGrayColor]];
            }
            if ([[checklistItem type] isEqualToString:@"Com"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"communicateOutlineDark"]];
            } else if ([[checklistItem type] isEqualToString:@"S&C"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"s&c"]];
            } else {
                [cell.imageView setImage:[UIImage imageNamed:@"folder"]];
            }
            cell.deadlineTextLabel.numberOfLines = 0;
            return cell;
        }
            
            break;
        case 2: {
            BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
            }
            Activity *activity = [_project.activities objectAtIndex:indexPath.row];
            [cell configureActivityForSynopsis:activity];
            [cell.timestampLabel setText:[formatter stringFromDate:activity.createdDate]];
            [cell.separatorView setHidden:YES];
            return cell;
        }
            break;
        case 3: {
            BHProgressCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProgressCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            Phase *phase = [_project.phases objectAtIndex:indexPath.row];
            
            [cell.itemLabel setText:phase.name];
            CGFloat progress_count = [phase.progressCount floatValue];
            CGFloat all = [phase.itemCount floatValue];
            [cell.progressLabel setText:[NSString stringWithFormat:@"%.1f%%",(100*progress_count/all)]];
        
            CGFloat progressBarHeight = 7.f;
            if (IDIOM == IPAD) {
                [cell.progressView setFrame:CGRectMake(screen.size.width-320, cell.contentView.frame.size.height/2-progressBarHeight/2, 300, progressBarHeight)];
            } else {
                CGFloat barStartX = cell.progressLabel.frame.origin.x+cell.progressLabel.frame.size.width + 23.f;
                CGFloat progressWidth = width - 10 - barStartX;
                [cell.progressView setFrame:CGRectMake(barStartX, cell.contentView.frame.size.height/2-progressBarHeight/2, progressWidth, progressBarHeight)];
            }
            
            if (progress_count && all){
                cell.progressView.progress = (progress_count/all);
            } else {
                cell.progressView.progress = 0.f;
            }
            
            cell.progressView.color = kBlueColor;
            cell.progressView.showText = @NO;
            cell.progressView.borderRadius = @1;
            cell.progressView.showBackground = @NO;
            cell.progressView.backgroundColor = [UIColor colorWithWhite:.93 alpha:1];
            cell.progressView.showBackgroundInnerShadow = @NO;
            cell.progressView.type = LDProgressSolid;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        break;
        case 4:
        {
            BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
            }
            Activity *activity = [_project.checklist.activities objectAtIndex:indexPath.row];
            [cell configureActivityForSynopsis:activity];
            [cell.timestampLabel setText:[formatter stringFromDate:activity.createdDate]];
            
            return cell;
        }
            break;
        case 5: {
            BHRecentDocumentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentPhotosCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHRecentDocumentCell" owner:self options:nil] lastObject];
            }
            CGRect frame = cell.frame;
            frame.size.width = screen.size.width;
            [cell setFrame:frame];
            if (!documentsScrollView) {
                documentsScrollView = [[UIScrollView alloc] initWithFrame:cell.frame];
                [cell addSubview:documentsScrollView];
            }
            [self showDocuments];
            return cell;
        }
        
            break;
        case 6: {
            BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
            }
            Activity *activity = [_project.tasklist.activities objectAtIndex:indexPath.row];
            [cell configureActivityForSynopsis:activity];
            [cell.timestampLabel setText:[formatter stringFromDate:activity.createdDate]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
            break;
        case 7: {
            static NSString *CellIdentifier = @"SynopsisCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (_project.address.formattedAddress){
                [cell.textLabel setText:_project.address.formattedAddress];
            } else if (_project.address){
                [cell.textLabel setText:[NSString stringWithFormat:@"%@, %@, %@ %@",_project.address.street1,_project.address.city,_project.address.state,_project.address.zip]];
            }
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"Number of personnel: %lu",(unsigned long)_project.users.count]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel setFont:[UIFont fontWithName:kMyriadProLight size:21]];
            [cell.detailTextLabel setFont:[UIFont fontWithName:kMyriadProLight size:17]];
            return cell;
        }
            break;
        default:
            return nil;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        //show the past due reminder row only if there past due reminders present
        if (pastDueProjectReminders.count){
            if (indexPath.row == 0){
                return 50;
            } else {
                return 80;
            }
        } else {
            return 80;
        }
    }
    else if (indexPath.section == 5) return 110;
    else if (indexPath.section == 3) return 70;
    else return 80;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (projectReminders.count || pastDueProjectReminders.count){
                return 40;
            } else {
                return 0;
            }
            break;
        case 1:
            if ([(NSArray*)_project.upcomingItems count]){
                return 40;
            } else {
                return 0;
            }
            break;
        case 2:
            if (_project.activities.count){
                return 40;
            } else {
                return 0;
            }
            break;
        
        case 4:
            if (_project.checklist.activities.count){
                return 40;
            } else {
                return 0;
            }
            break;
        case 5:
            if (_project.recentDocuments.count){
                return 40;
            } else {
                return 0;
            }
            break;
        case 6:
            if (_project.tasklist.activities.count){
                return 40;
            } else {
                return 0;
            }
            break;
        default:
            return 40;
            break;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView* headerView;
    if (section == 0 && _project.reminders.count == 0 && _project.pastDueReminders.count == 0) {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else if (section == 2 && _project.recentDocuments.count == 0) {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else if (section == 4 && [(NSArray*)_project.recentItems count] == 0) {
        return nil;
    } else {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 40)];
    }
    [headerView setBackgroundColor:kDarkerGrayColor];
    
    // Add the label
    UILabel *headerLabel;
    headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, screen.size.width, 40)];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.font = [UIFont fontWithName:kMyriadPro size:16];
    headerLabel.numberOfLines = 0;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:headerLabel];
    
    switch (section) {
        case 0:
        {
            [headerLabel setText:@"REMINDERS"];
            if (projectReminders.count > 3){
                UIButton *allButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [allButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:12]];
                [allButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [allButton setFrame:CGRectMake(screen.size.width-44, 0, 44, 40)];
                [allButton setTitle:@"ALL" forState:UIControlStateNormal];
                [allButton addTarget:self action:@selector(loadReminders) forControlEvents:UIControlEventTouchUpInside];
                [headerView addSubview:allButton];
            }
        }
            break;
        case 1:
        {
            [headerLabel setText:@"UPCOMING DEADLINES"];
            if (_project.upcomingItems.count > 3){
                UIButton *allButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [allButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:12]];
                [allButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [allButton setFrame:CGRectMake(screen.size.width-44, 0, 44, 40)];
                [allButton setTitle:@"ALL" forState:UIControlStateNormal];
                [allButton addTarget:self action:@selector(showDeadlines) forControlEvents:UIControlEventTouchUpInside];
                [headerView addSubview:allButton];
            }
        }
            break;
        case 2:
        {
            [headerLabel setText:@"LATEST ACTIVITY"];
            if (_project.activities.count > 3){
                UIButton *allButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [allButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:12]];
                [allButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [allButton setFrame:CGRectMake(screen.size.width-44, 0, 44, 40)];
                [allButton setTitle:@"ALL" forState:UIControlStateNormal];
                [allButton addTarget:self action:@selector(showActivities) forControlEvents:UIControlEventTouchUpInside];
                [headerView addSubview:allButton];
            }
        }
            break;
        case 3:
            [headerLabel setText:@"PROGRESS"];
            break;
        case 4:
            [headerLabel setText:@"CHECKLIST"];
            break;
        case 5:
            [headerLabel setText:@"DOCUMENTS"];
            break;
        case 6:
            [headerLabel setText:@"TASKS"];
            break;
        case 7:
            [headerLabel setText:@"SUMMARY"];
            break;
            
        default:
            return nil;
            break;
    }
    return headerView;
}

- (void)confirmDeleteReminder:(UIButton*)button {
    [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to remove this reminder?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes",nil] show];
    indexPathForReminderDeletion = [NSIndexPath indexPathForRow:button.tag inSection:0];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self deleteReminder];
    } else {
        indexPathForReminderDeletion = nil;
    }
}

- (void)deleteReminder {
    Reminder *reminder = [projectReminders objectAtIndex:indexPathForReminderDeletion.row];
    [manager DELETE:[NSString stringWithFormat:@"%@/reminders/%@",kApiBaseUrl,reminder.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success deleting this reminder: %@",responseObject);
        
        [projectReminders removeObject:reminder];
        [delegate.currentUser.reminders removeObject:reminder];
        [reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        
        [self.tableView beginUpdates];
        if (projectReminders.count){
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForReminderDeletion] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.tableView endUpdates];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failured deleting this reminder: %@",error.description);
    }];
}

- (void)loadReminders {
    //load both active and past due reminders
    NSMutableOrderedSet *combinedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:pastDueProjectReminders];
    [combinedSet unionOrderedSet:projectReminders];
    [self performSegueWithIdentifier:@"Activities" sender:combinedSet];
}

- (void)showDeadlines {
    [self performSegueWithIdentifier:@"Activities" sender:_project.upcomingItems];
}

- (void)showActivities {
    [self performSegueWithIdentifier:@"Activities" sender:_project.activities];
}

#pragma mark - Display events

- (void)showDocuments {
    [documentsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    documentsScrollView.showsHorizontalScrollIndicator = NO;
    documentsScrollView.pagingEnabled = YES;
    documentsScrollView.delegate = self;
    int index = 0;
    CGRect photoRect = CGRectMake(5,5,100,100);
    for (Photo *photo in _project.recentDocuments) {
        if (index > 0) photoRect.origin.x += 105;
        
        /*
        __weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.urlSmall) [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal];
        else if (photo.urlThumb) [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlThumb] forState:UIControlStateNormal];
        */
        
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
        } else if (photo.urlSmall.length){
            [imageButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        }
        
        [imageButton setFrame:photoRect];
        [imageButton setTag:index];
        [imageButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
        imageButton.imageView.clipsToBounds = YES;
        [imageButton addTarget:self action:@selector(showPhotos:) forControlEvents:UIControlEventTouchUpInside];
        [imageButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [documentsScrollView addSubview:imageButton];
        index++;
    }
    [documentsScrollView setContentSize:CGSizeMake((_project.recentDocuments.count*105) + 5,documentsScrollView.frame.size.height)];
    documentsScrollView.layer.shouldRasterize = YES;
    documentsScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)showPhotos:(UIButton*)button {
    browserPhotos = [NSMutableArray new];
    for (Photo *photo in _project.recentDocuments) {
        MWPhoto *mwPhoto;
        mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setPhoto:photo];
        if (photo.caption.length){
            mwPhoto.caption = photo.caption;
        }
        [browserPhotos addObject:mwPhoto];
    }
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = NO;
    [browser setProject:_project];
    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:button.tag];
}

- (void)showPhotoDetail:(Photo*)photo {
    browserPhotos = [NSMutableArray new];
    MWPhoto *mwPhoto;
    mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
    [mwPhoto setPhoto:photo];
    if (photo.caption.length){
        mwPhoto.caption = photo.caption;
    }
    [browserPhotos addObject:mwPhoto];
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
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
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (pastDueProjectReminders.count){
            if (indexPath.row == 0){
                NSMutableOrderedSet *combinedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:pastDueProjectReminders];
                [combinedSet unionOrderedSet:projectReminders];
                [self performSegueWithIdentifier:@"Activities" sender:combinedSet];
            } else {
                BHReminderCell *cell = (BHReminderCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                [cell swipeScrollView];
            }
        } else {
            BHReminderCell *cell = (BHReminderCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell swipeScrollView];
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (indexPath.section == 1){
        ChecklistItem *item = [_project.upcomingItems objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ChecklistItem" sender:item];
    } else if (indexPath.section == 2){
        Activity *activity = _project.activities[indexPath.row];
        if (activity.report){
            [self performSegueWithIdentifier:@"Report" sender:activity.report];
        } else if (activity.checklistItem) {
            [self performSegueWithIdentifier:@"ChecklistItem" sender:activity.checklistItem];
        } else if (activity.task) {
            [self performSegueWithIdentifier:@"Task" sender:activity.task];
        } else if (activity.photo) {
            [self showPhotoDetail:activity.photo];
        }
    } else if (indexPath.section == 3){
        [self performSegueWithIdentifier:@"Project" sender:indexPath];
    } else if (indexPath.section == 4){
        Activity *activity = [_project.checklist.activities objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ChecklistItem" sender:activity.checklistItem];
    } else if (indexPath.section == 6){
        Activity *activity = [_project.tasklist.activities objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"Task" sender:activity.task];
    } else if (indexPath.section == 7){
        
        BHMapViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"MapView"];
        [vc setProject:_project];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:^{
            
        }];
        /*if (_project.address.latitude && ![_project.address.longitude isEqualToNumber:[NSNumber numberWithInt:0]]){
            NSURL *addressUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.apple.com/?ll=%@,%@",_project.address.latitude,_project.address.longitude]];
            [[UIApplication sharedApplication] openURL:addressUrl];
        }*/
    }
}

- (void)goToReminder:(UIButton*)button{
    Reminder *reminder = projectReminders[button.tag];
    if (reminder.checklistItem){
        [self performSegueWithIdentifier:@"ChecklistItem" sender:reminder.checklistItem];
    }
}

- (void)goToProject:(UIButton*)button {
    [self performSegueWithIdentifier:@"Project" sender:button];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Project"]) {
        BHTabBarViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[NSIndexPath class]]){
            [vc setChecklistIndexPath:(NSIndexPath*)sender];
        }
        [vc setProject:_project];
    } else if ([segue.identifier isEqualToString:@"ChecklistItem"]) {
        BHChecklistItemViewController *vc = [segue destinationViewController];
        [vc setProject:_project];
        if ([sender isKindOfClass:[ChecklistItem class]])
            [vc setItem:(ChecklistItem*)sender];
    } else if ([segue.identifier isEqualToString:@"Task"]) {
        BHTaskViewController *vc = [segue destinationViewController];
        [vc setProject:_project];
        if ([sender isKindOfClass:[Task class]]){
            [vc setTaskId:[(Task*)sender identifier]];
        }
    } else if ([segue.identifier isEqualToString:@"Report"]) {
        BHReportViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[Report class]]){
            [vc setInitialReportId:[(Report*)sender identifier]];
        }
        [vc setProjectId:_project.identifier];
    } else if ([segue.identifier isEqualToString:@"Activities"]) {
        BHActivitiesViewController *vc = [segue destinationViewController];
        [vc setProject:_project];
        NSOrderedSet *set;
        if ([sender isKindOfClass:[NSOrderedSet class]]){
            set = (NSOrderedSet*)sender;
            if ([set.firstObject isKindOfClass:[Activity class]]){
                [vc setTitle:@"Recent Activity"];
                [vc setActivities:set];
            } else if ([set.firstObject isKindOfClass:[Reminder class]]){
                [vc setTitle:@"Reminders"];
                [vc setReminders:set.mutableCopy];
            } else {
                [vc setTitle:@"Deadlines"];
                [vc setDeadlineItems:_project.upcomingItems];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
}

@end
