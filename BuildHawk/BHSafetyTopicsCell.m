//
//  BHSafetyTopicsCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHSafetyTopicsCell.h"

@implementation BHSafetyTopicsCell

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
    [_titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureTopic:(SafetyTopic*)topic{
    [self.titleLabel setText:topic.title];
}
@end
