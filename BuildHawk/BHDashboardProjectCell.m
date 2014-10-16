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
    [super awakeFromNib];
    [_scrollView setContentSize:CGSizeMake(screenWidth(), 88)];
    [_alertLabel setBackgroundColor:[UIColor redColor]];
    [_alertLabel.layer setBackgroundColor:[UIColor clearColor].CGColor];
    _alertLabel.layer.cornerRadius = 11.f;
    
    if (IDIOM == IPAD) {
        [_nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0]];
    } else {
        [_nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0]];
    }
    
    [_addressLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProLight] size:0]];
    [_progressButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0]];
    [_alertLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
    
    [_hideButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProRegular] size:0]];
    [_hideButton setBackgroundColor:[UIColor redColor]];
}

- (void)configureForProject:(Project*)project andUser:(User*)user {
    [_projectButton setUserInteractionEnabled:YES];
    [_progressButton setHidden:NO];
    [_scrollView setUserInteractionEnabled:YES];
    
    [_nameLabel setText:[project name]];
    if (project.address.formattedAddress){
        [_addressLabel setText:project.address.formattedAddress];
        [_addressLabel sizeToFit];
    }
    
    __block int reminderCount = 0;
    [user.pastDueReminders enumerateObjectsUsingBlock:^(Reminder *reminder, NSUInteger idx, BOOL *stop) {
        if (project.identifier && [reminder.pastDueProject.identifier isEqualToNumber:project.identifier]){
            reminderCount ++;
        }
    }];
    
    if (reminderCount > 0){
        [_alertLabel setText:[NSString stringWithFormat:@"%d",reminderCount]];
        [UIView animateWithDuration:.3 animations:^{
            [_alertLabel setAlpha:1.0];
        }];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x >= 88){
        [_hideButton setUserInteractionEnabled:YES];
    } else {
        [_hideButton setUserInteractionEnabled:NO];
    }
}

@end
