//
//  BHTasklistConnectCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHTasklistConnectCell.h"

@implementation BHTasklistConnectCell

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
    if (IDIOM == IPAD) {
        [_companyNameLabel setFont:[UIFont fontWithName:kMyriadProLight size:27]];
        [_projectsLabel setFont:[UIFont fontWithName:kMyriadProLight size:18]];
    } else {
        [_companyNameLabel setFont:[UIFont fontWithName:kMyriadProLight size:23]];
        [_projectsLabel setFont:[UIFont fontWithName:kMyriadProLight size:17]];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
