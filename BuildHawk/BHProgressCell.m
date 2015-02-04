//
//  BHProgressCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 11/18/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHProgressCell.h"

@implementation BHProgressCell

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
    [_itemLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0]];
    [_progressLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0]];
    [_progressLabel setTextAlignment:NSTextAlignmentCenter];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
