//
//  BHAssetGroupPickerCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/16/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import "BHAssetGroupPickerCell.h"
#import "Constants.h"
@implementation BHAssetGroupPickerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadPro] size:0]];
    [self.textLabel setTextColor:[UIColor whiteColor]];
    [self setBackgroundColor:[UIColor clearColor]];
    
    UIView *selectedView = [[UIView alloc] initWithFrame:self.frame];
    [selectedView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
    self.selectedBackgroundView = selectedView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
