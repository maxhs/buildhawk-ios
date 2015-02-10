//
//  BHReminderCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/2/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHReminderCell.h"
#import "User+helper.h"
#import "ChecklistItem.h"
#import "Task.h"
#import "BHAppDelegate.h"

@interface BHReminderCell () {
    CGFloat offsetAmount;
}

@end
@implementation BHReminderCell
@synthesize tapGesture = _tapGesture;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    [_deleteButton setBackgroundColor:[UIColor redColor]];
    [_reminderButton setBackgroundColor:[UIColor colorWithWhite:.925 alpha:1]];
    [_reminderDatetimeLabel setFont:[UIFont fontWithName:kMyriadPro size:16]];
    [_statusLabel setFont:[UIFont fontWithName:kMyriadPro size:16]];
    [_reminderLabel setFont:[UIFont fontWithName:kMyriadPro size:17]];
    
    [_reminderButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:16]];
    [_deleteButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:16]];
    
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(swipeScrollView)];
    _tapGesture.numberOfTapsRequired = 1;
    [_scrollView addGestureRecognizer:_tapGesture];
    
    [_statusLabel setTextColor:[UIColor lightGrayColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForReminder:(Reminder*)reminder{

    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [reminder.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        if (IDIOM == IPAD){
            offsetAmount = 160.f;
        } else {
            offsetAmount = screenWidth()/2;
        }
    } else {
        if (IDIOM == IPAD){
            offsetAmount = 80.f;
        } else {
            offsetAmount = screenWidth()/4;
        }
    }
    [_scrollView setContentSize:CGSizeMake(screenWidth()+offsetAmount, 80)];
    
    if ([reminder.reminderDate compare:[NSDate date]] == NSOrderedAscending){
        [_reminderDatetimeLabel setTextColor:[UIColor redColor]];
        [_statusLabel setText:@"Past Due"];
        [_statusLabel setTextColor:[UIColor redColor]];
    } else {
        [_reminderDatetimeLabel setTextColor:[UIColor blackColor]];
        if ([reminder.active isEqualToNumber:@YES]){
            [_statusLabel setText:@"Active"];
            [_statusLabel setTextColor:[UIColor blackColor]];
        }
    }
    
    if ([reminder.active isEqualToNumber:@NO]){
        [_statusLabel setText:@"Off"];
        [_statusLabel setTextColor:[UIColor lightGrayColor]];
    }
    
    if (reminder.checklistItem){
        [_reminderLabel setText:reminder.checklistItem.body];
    } else if (reminder.task) {
        [_reminderLabel setText:reminder.task.body];
    } else {
        [_reminderLabel setText:@""];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [reminder.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [_deleteButton setHidden:NO];
        [_scrollView setScrollEnabled:YES];
        if ([reminder.active isEqualToNumber:@YES]){
            [_deleteButton setTitle:@"Remove" forState:UIControlStateNormal];
            _deleteButton.titleLabel.numberOfLines = 0;
            [_deleteButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        } else {
            [_deleteButton setTitle:@"Enable" forState:UIControlStateNormal];
        }
    } else {
        [_scrollView setScrollEnabled:YES];
        [_deleteButton setHidden:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    CGRect hideFrame = _deleteButton.frame;
    hideFrame.origin.x = screenWidth()+_deleteButton.frame.size.width;
    [_deleteButton setFrame:hideFrame];
    
    CGRect reminderFrame = _reminderButton.frame;
    reminderFrame.origin.x = screenWidth();
    [_reminderButton setFrame:reminderFrame];
    
    if (x == offsetAmount){
        [_deleteButton setUserInteractionEnabled:YES];
        [_reminderButton setUserInteractionEnabled:YES];
    } else if (_deleteButton.userInteractionEnabled) {
        [_deleteButton setUserInteractionEnabled:NO];
        [_reminderButton setUserInteractionEnabled:NO];
    }
}

- (void)swipeScrollView {
    if (_scrollView.contentOffset.x == offsetAmount){
        [_scrollView setContentOffset:CGPointZero animated:YES];
        [_deleteButton setUserInteractionEnabled:NO];
        [_reminderButton setUserInteractionEnabled:NO];
    } else {
        [_scrollView setContentOffset:CGPointMake(offsetAmount, 0) animated:YES];
        [_deleteButton setUserInteractionEnabled:YES];
        [_reminderButton setUserInteractionEnabled:YES];
    }
}

@end
