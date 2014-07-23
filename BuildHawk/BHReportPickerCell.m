//
//  BHReportPickerCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/5/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHReportPickerCell.h"
#import "Constants.h"

@implementation BHReportPickerCell

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

-(void)configure {
    [self.datePickerButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [_datePickerButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_typePickerButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_datePickerButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:18]];
    [_typePickerButton.titleLabel setFont:[UIFont fontWithName:kMyriadProRegular size:18]];
}

- (void)buttonTreatment:(UIButton*)button {
    button.layer.cornerRadius = 8.f;
    [button setBackgroundColor:kDarkerGrayColor];
    //button.layer.borderColor = kLighterGrayColor.CGColor;
    //button.layer.borderWidth = .5f;
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    button.layer.shadowOpacity =  .75f;
    button.layer.shadowRadius = 2.f;
    button.layer.shadowOffset = CGSizeMake(0, 0);
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

@end
