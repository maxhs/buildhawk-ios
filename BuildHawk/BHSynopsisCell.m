//
//  BHSynopsisCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/5/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHSynopsisCell.h"

@implementation BHSynopsisCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [_deadlineTextLabel setFont:[UIFont fontWithName:kMyriadPro size:17]];
    [_deadlineTimeLabel setFont:[UIFont fontWithName:kMyriadProItalic size:16]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
