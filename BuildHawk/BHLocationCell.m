//
//  BHLocationCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/12/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import "BHLocationCell.h"

@implementation BHLocationCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForLocation:(Location *)location {
    [self.textLabel setText:location.name];
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
    [self.textLabel setTextColor:[UIColor blackColor]];
}

- (void)configureToAdd:(NSString *)searchText {
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProItalic] size:0]];
    [self.textLabel setTextColor:[UIColor lightGrayColor]];
    [self.textLabel setText:[NSString stringWithFormat:@"add \"%@\"",searchText]];
}

@end
