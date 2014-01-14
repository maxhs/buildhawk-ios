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

- (void)configureCell {
    [self buttonTreatment:self.pickFromListButton];
    self.prefillButton.layer.cornerRadius = 8.f;
    /*self.prefillButton.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.prefillButton.layer.shadowOpacity =  1.f;
    self.prefillButton.layer.shadowRadius = 2.f;
    self.prefillButton.layer.shadowOffset = CGSizeMake(0, 0);*/
    [self.prefillButton setTitleColor:kDarkerGrayColor forState:UIControlStateNormal];
    self.prefillButton.layer.borderColor = kDarkerGrayColor.CGColor;
    self.prefillButton.layer.borderWidth = .5f;
    self.prefillButton.layer.shouldRasterize = YES;
    self.prefillButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)buttonTreatment:(UIButton*)button {
    button.layer.cornerRadius = 8.f;
    [button setBackgroundColor:kDarkerGrayColor];
    //button.layer.borderColor = kLighterGrayColor.CGColor;
    //button.layer.borderWidth = .5f;
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    button.layer.shadowOpacity =  1.f;
    button.layer.shadowRadius = 2.f;
    button.layer.shadowOffset = CGSizeMake(0, 0);
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

@end
