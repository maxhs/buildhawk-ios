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
    [self buttonTreatment:self.datePickerButton];
    [self buttonTreatment:self.typePickerButton];
}

- (void)buttonTreatment:(UIButton*)button {
    button.layer.cornerRadius = 3.f;
    [button setBackgroundColor:[UIColor clearColor]];
    [button.layer setBackgroundColor:kDarkShade3.CGColor];
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    button.layer.shadowOpacity =  .5;
    button.layer.shadowRadius = .5f;
    button.layer.shadowOffset = CGSizeMake(0, 0);
    [button.titleLabel setTextColor:[UIColor whiteColor]];
}
@end
