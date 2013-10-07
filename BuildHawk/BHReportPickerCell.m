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
    button.layer.cornerRadius = 5.f;
    button.clipsToBounds = YES;
    [button setBackgroundColor:kBlueTransparentColor];
    button.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    button.layer.shadowRadius = 4.0f;
    button.layer.shadowOpacity =  .75;
    [button.titleLabel setTextColor:[UIColor whiteColor]];
}
@end
