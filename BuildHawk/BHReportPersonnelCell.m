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
    self.labelBackgroundView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.labelBackgroundView.layer.borderWidth = .5f;
    [self buttonTreatment:self.pickFromListButton];
}

- (void)buttonTreatment:(UIButton*)button {
    button.layer.cornerRadius = button.frame.size.height/2;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor clearColor]];
    [button.layer setBackgroundColor:kDarkShade3.CGColor];
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.layer.shadowColor = [UIColor whiteColor].CGColor;
    button.layer.shadowOpacity =  .2;
    button.layer.shadowRadius = 3.f;
    button.layer.shadowOffset = CGSizeMake(0, 0);
    //[button.titleLabel setTextColor:[UIColor darkGrayColor]];
}

@end
