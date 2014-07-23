//
//  BHActivitiesViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/2/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHActivitiesViewController.h"
#import "Activity+helper.h"
#import "BHActivityCell.h"
#import "BHAppDelegate.h"
#import "BHReminderCell.h"
#import "Reminder+helper.h"
#import "ChecklistItem+helper.h"
#import "BHSynopsisCell.h"
#import "BHChecklistItemViewController.h"
#import "MWPhotoBrowser.h"
#import "BHReportViewController.h"
#import "BHTaskViewController.h"

@interface BHActivitiesViewController () <MWPhotoBrowserDelegate> {
    AFHTTPRequestOperationManager *manager;
    NSDateFormatter *formatter;
    NSMutableArray *browserPhotos;
    NSIndexPath *indexPathForReminderDeletion;
}

@end

@implementation BHActivitiesViewController

@synthesize project = _project;
@synthesize activities = _activities;
@synthesize reminders = _reminders;
@synthesize deadlineItems = _deadlineItems;

- (void)viewDidLoad
{
    [super viewDidLoad];
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    self.tableView.rowHeight = 80;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_activities && _activities.count){
        return _activities.count;
    } else if (_reminders && _reminders.count) {
        return _reminders.count;
    } else {
        return _deadlineItems.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_activities && _activities.count){
        static NSString *CellIdentifier = @"ActivityCell";
        BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
        }
        Activity *activity = _activities[indexPath.row];
        [cell configureActivityForSynopsis:activity];
        [cell.timestampLabel setText:[formatter stringFromDate:activity.createdDate]];
        
        return cell;
    } else if (_reminders && _reminders.count) {
        static NSString *CellIdentifier = @"ReminderCell";
        BHReminderCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReminderCell" owner:self options:nil] lastObject];
        }
        Reminder *reminder = _reminders[indexPath.row];
        [cell.reminderDatetimeLabel setText:[formatter stringFromDate:reminder.reminderDate]];
        [cell configureForReminder:reminder];
        cell.reminderButton.tag = indexPath.row;
        [cell.reminderButton addTarget:self action:@selector(goToReminder:) forControlEvents:UIControlEventTouchUpInside];
        cell.deleteButton.tag = indexPath.row;
        [cell.deleteButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
        [cell.deleteButton addTarget:self action:@selector(confirmDeleteReminder:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    } else {
        static NSString *CellIdentifier = @"ItemCell";
        BHSynopsisCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil){
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHSynopsisCell" owner:self options:nil] lastObject];
        }
        ChecklistItem *checklistItem = [_deadlineItems objectAtIndex:indexPath.row];
        [cell.textLabel setText:checklistItem.body];
        if (checklistItem.criticalDate) {
            [cell.deadlineLabel setText:[NSString stringWithFormat:@"Deadline: %@",[formatter stringFromDate:checklistItem.criticalDate]]];
            [cell.deadlineLabel setTextColor:[UIColor blackColor]];
        } else {
            [cell.deadlineLabel setText:@"No critical date listed"];
            [cell.deadlineLabel setTextColor:[UIColor lightGrayColor]];
        }
        if ([checklistItem.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
            [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        }
        if ([[checklistItem type] isEqualToString:@"Com"]) {
            [cell.imageView setImage:[UIImage imageNamed:@"communicateOutlineDark"]];
        } else if ([[checklistItem type] isEqualToString:@"S&C"]) {
            [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutlineDark"]];
        } else {
            [cell.imageView setImage:[UIImage imageNamed:@"documentsOutlineDark"]];
        }
        cell.textLabel.numberOfLines = 0;
        [cell.textLabel setFont:[UIFont systemFontOfSize:16]];
        return cell;
    }
}

- (void)goToReminder:(UIButton*)button{
    Reminder *reminder = _reminders[button.tag];
    if (reminder.checklistItem){
        [self performSegueWithIdentifier:@"ChecklistItem" sender:reminder.checklistItem];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_deadlineItems && _deadlineItems.count){
        ChecklistItem *item = [_deadlineItems objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ChecklistItem" sender:item];
    } else if (_activities && _activities.count){
        Activity *activity = _activities[indexPath.row];
        if (activity.report){
            [self performSegueWithIdentifier:@"Report" sender:activity.report];
        } else if (activity.checklistItem) {
            [self performSegueWithIdentifier:@"ChecklistItem" sender:activity.checklistItem];
        } else if (activity.task) {
            [self performSegueWithIdentifier:@"Task" sender:activity.task];
        } else if (activity.photo) {
            [self showPhotoDetail:activity.photo];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showPhotoDetail:(Photo*)photo {
    browserPhotos = [NSMutableArray array];
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
    Reminder *reminder = [_reminders objectAtIndex:indexPathForReminderDeletion.row];
    [manager DELETE:[NSString stringWithFormat:@"%@/reminders/%@",kApiBaseUrl,reminder.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success deleting this reminder: %@",responseObject);
        
        [_reminders removeObject:reminder];
        [_reminders removeObject:reminder];
        [reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        
        [self.tableView beginUpdates];
        if (_reminders.count){
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForReminderDeletion] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.tableView endUpdates];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failured deleting this reminder: %@",error.description);
    }];
}

/*- (void)reminderButtonTapped:(UIButton*)button{
    Reminder *reminder = _reminders[button.tag];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([reminder.active isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [parameters setObject:@NO forKey:@"active"];
        [reminder setActive:[NSNumber numberWithBool:NO]];
    } else {
        [parameters setObject:@YES forKey:@"active"];
        [reminder setActive:[NSNumber numberWithBool:YES]];
    }
    
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    
    [manager PATCH:[NSString stringWithFormat:@"%@/reminders/%@",kApiBaseUrl,reminder.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success updating reminder state: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to update reminder: %@",error.description);
    }];
}*/
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ChecklistItem"]){
        ChecklistItem *item = (ChecklistItem*)sender;
        BHChecklistItemViewController *vc = [segue destinationViewController];
        [vc setItem:item];
    } else if ([segue.identifier isEqualToString:@"Task"]) {
        BHTaskViewController *vc = [segue destinationViewController];
        [vc setProject:_project];
        if ([sender isKindOfClass:[WorklistItem class]]){
            [vc setTask:(WorklistItem*)sender];
        }
    } else if ([segue.identifier isEqualToString:@"Report"]) {
        BHReportViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[Report class]]){
            [vc setReport:(Report*)sender];
        }
        [vc setProject:_project];
    }
}
@end
