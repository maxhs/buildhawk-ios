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

- (void)awakeFromNib {
    [super awakeFromNib];
    _reportBodyTextView.layer.borderColor = kLightGrayColor.CGColor;
    _reportBodyTextView.layer.borderWidth = .5f;
    _reportBodyTextView.layer.cornerRadius = 2.f;
    _reportBodyTextView.clipsToBounds = YES;
    _labelBackgroundView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _labelBackgroundView.layer.borderWidth = .5f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureCell {
    
}

@end
