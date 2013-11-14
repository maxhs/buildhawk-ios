//
//  BHReportSectionCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/5/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHReportSectionCell.h"

@implementation BHReportSectionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureCell {
    self.labelBackgroundView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.labelBackgroundView.layer.borderWidth = .5f;
}

@end
