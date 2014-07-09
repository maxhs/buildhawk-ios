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
#import "WorklistItem.h"

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
    // Initialization code
    [_activeButton setBackgroundColor:[UIColor redColor]];
    
    [_reminderButton setBackgroundColor:[UIColor colorWithWhite:.925 alpha:1]];
    [_reminderButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueMedium size:14]];
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
        [_scrollView setContentSize:CGSizeMake(screenWidth()*1.5, 80)];
    } else {
        [_scrollView setContentSize:CGSizeMake(screenWidth()*1.25, 80)];
    }
    
    [_reminderDatetimeLabel setFont:[UIFont boldSystemFontOfSize:15]];
    if ([reminder.reminderDate compare:[NSDate date]] == NSOrderedAscending){
        [_reminderDatetimeLabel setTextColor:[UIColor redColor]];
        [_statusLabel setText:@"Past Due"];
        [_statusLabel setTextColor:[UIColor redColor]];
    } else {
        [_reminderDatetimeLabel setTextColor:[UIColor blackColor]];
        if ([reminder.active isEqualToNumber:[NSNumber numberWithBool:YES]]){
            [_statusLabel setText:@"Active"];
            [_statusLabel setTextColor:[UIColor blackColor]];
        }
    }
    
    if ([reminder.active isEqualToNumber:[NSNumber numberWithBool:NO]]){
        [_statusLabel setText:@"Hidden"];
        [_statusLabel setTextColor:[UIColor lightGrayColor]];
    }
    
    if (reminder.checklistItem){
        [_reminderLabel setText:reminder.checklistItem.body];
    } else if (reminder.worklistItem) {
        [_reminderLabel setText:reminder.worklistItem.body];
    } else {
        [_reminderLabel setText:@""];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [reminder.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [_activeButton setHidden:NO];
        [_scrollView setScrollEnabled:YES];
        if ([reminder.active isEqualToNumber:[NSNumber numberWithBool:YES]]){
            [_activeButton setTitle:@"Hide" forState:UIControlStateNormal];
        } else {
            [_activeButton setTitle:@"Enable" forState:UIControlStateNormal];
        }
    } else {
        [_scrollView setScrollEnabled:NO];
        [_activeButton setHidden:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    CGRect hideFrame = _activeButton.frame;
    hideFrame.origin.x = 400.f ;
    [_activeButton setFrame:hideFrame];
    
    CGRect reminderFrame = _reminderButton.frame;
    reminderFrame.origin.x = 320.f ;
    [_reminderButton setFrame:reminderFrame];
    
    if (x == 160.f){
        [_activeButton setUserInteractionEnabled:YES];
        [_reminderButton setUserInteractionEnabled:YES];
    } else if (_activeButton.userInteractionEnabled) {
        [_activeButton setUserInteractionEnabled:NO];
        [_reminderButton setUserInteractionEnabled:NO];
    }
}

- (void)swipeScrollView {
    if (_scrollView.contentOffset.x == 160.f){
        [_scrollView setContentOffset:CGPointZero animated:YES];
        [_activeButton setUserInteractionEnabled:NO];
        [_reminderButton setUserInteractionEnabled:NO];
    } else {
        [_scrollView setContentOffset:CGPointMake(160.f, 0) animated:YES];
        [_activeButton setUserInteractionEnabled:YES];
        [_reminderButton setUserInteractionEnabled:YES];
    }
}

@end
