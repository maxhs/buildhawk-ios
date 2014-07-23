//
//  BHTaskCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/9/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHTaskCell.h"

@implementation BHTaskCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [_itemLabel setFont:[UIFont fontWithName:kMyriadProSemibold size:19]];
    [_createdLabel setFont:[UIFont fontWithName:kMyriadProRegular size:16]];
    [_ownerLabel setFont:[UIFont fontWithName:kMyriadProRegular size:16]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
