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

@interface BHActivitiesViewController () {
    AFHTTPRequestOperationManager *manager;
    NSDateFormatter *formatter;
}

@end

@implementation BHActivitiesViewController

@synthesize activities = _activities;
@synthesize reminders = _reminders;

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
    } else {
        return _reminders.count;
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
    } else {
        static NSString *CellIdentifier = @"ReminderCell";
        BHReminderCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReminderCell" owner:self options:nil] lastObject];
        }
        Reminder *reminder = _reminders[indexPath.row];
        [cell.reminderDatetimeLabel setText:[formatter stringFromDate:reminder.reminderDate]];
        [cell configureForReminder:reminder];
        cell.activeButton.tag = indexPath.row;
        [cell.activeButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueMedium size:13]];
        [cell.activeButton addTarget:self action:@selector(reminderButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
}

- (void)reminderButtonTapped:(UIButton*)button{
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
        NSLog(@"Success updating reminder state: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to update remidner: %@",error.description);
    }];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
