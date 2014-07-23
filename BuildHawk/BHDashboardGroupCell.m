//
//  BHDashboardGroupCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/15/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHDashboardGroupCell.h"

@implementation BHDashboardGroupCell

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
    if (IDIOM == IPAD) {
        [_nameLabel setFont:[UIFont fontWithName:kMyriadProLight size:27]];
        [_groupCountLabel setFont:[UIFont fontWithName:kMyriadProLight size:18]];
    } else {
        [_nameLabel setFont:[UIFont fontWithName:kMyriadProLight size:23]];
        [_groupCountLabel setFont:[UIFont fontWithName:kMyriadProLight size:17]];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
