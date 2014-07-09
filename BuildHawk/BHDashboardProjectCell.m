//
//  BHDashboardProjectCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHDashboardProjectCell.h"
#import "Address.h"
#import "Reminder+helper.h"

@implementation BHDashboardProjectCell {
    CGRect screen;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)awakeFromNib {
    [_archiveButton setBackgroundColor:[UIColor redColor]];
    [_scrollView setContentSize:CGSizeMake(screenWidth(), 88)];
    [_alertLabel setBackgroundColor:[UIColor redColor]];
    [_alertLabel.layer setBackgroundColor:[UIColor clearColor].CGColor];
    _alertLabel.layer.cornerRadius = 11.f;
}

- (void)configureForProject:(Project*)project andUser:(User*)user {
    [_titleLabel setText:[project name]];
    if (project.address.formattedAddress){
        [_subtitleLabel setText:project.address.formattedAddress];
        [_subtitleLabel sizeToFit];
    } else {
        //[_subtitleLabel setText:project.company.name];
    }
    
    __block int reminderCount = 0;
    [user.reminders enumerateObjectsUsingBlock:^(Reminder *reminder, NSUInteger idx, BOOL *stop) {
        if ([reminder.project.identifier isEqualToNumber:project.identifier] && [reminder.active isEqualToNumber:[NSNumber numberWithBool:YES]]){
            reminderCount ++;
        }
        if (idx == user.reminders.count - 1 && reminderCount > 0){
            [_alertLabel setText:[NSString stringWithFormat:@"%d",reminderCount]];
            [UIView animateWithDuration:.3 animations:^{
                [_alertLabel setAlpha:1.0];
            }];
        }
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x >= 88){
        [_archiveButton setUserInteractionEnabled:YES];
    } else {
        [_archiveButton setUserInteractionEnabled:NO];
    }
}

@end
