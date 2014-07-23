//
//  BHChooseTopicsViewCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHChooseTopicsViewCell.h"

@implementation BHChooseTopicsViewCell

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
    [_chooseTopicsButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_chooseTopicsButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:17]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
