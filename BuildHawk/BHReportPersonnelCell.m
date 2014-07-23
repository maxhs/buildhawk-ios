//
//  BHReportPersonnelCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/21/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHReportPersonnelCell.h"

@implementation BHReportPersonnelCell

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

- (void)awakeFromNib {
    [_prefillButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:17]];
    [_prefillButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_choosePersonnelButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:17]];
    [_choosePersonnelButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
}

- (void)buttonTreatment:(UIButton*)button {
    button.layer.cornerRadius = 7.f;
    [button setBackgroundColor:kDarkerGrayColor];
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    button.layer.shadowOpacity =  1.f;
    button.layer.shadowRadius = 2.f;
    button.layer.shadowOffset = CGSizeMake(0, 0);
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

@end
