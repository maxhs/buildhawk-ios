//
//  BHItemReminderCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHItemReminderCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *reminderButton;
@property (weak, nonatomic) IBOutlet UILabel *reminderLabel;
@end
