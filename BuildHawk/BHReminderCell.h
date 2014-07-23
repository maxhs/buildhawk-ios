//
//  BHReminderCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/2/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reminder+helper.h"

@interface BHReminderCell : UITableViewCell <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *reminderDatetimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *reminderLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *reminderButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
- (void)configureForReminder:(Reminder*)reminder;
- (void)swipeScrollView;
@end
