//
//  BHChooseReportPersonnelCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/21/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHChooseReportPersonnelCell.h"
#import "UIFontDescriptor+Custom.h"
#import "Constants.h"

@implementation BHChooseReportPersonnelCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
    if (IDIOM == IPAD){
        [self.textLabel setTextAlignment:NSTextAlignmentCenter];
    }
}

@end
