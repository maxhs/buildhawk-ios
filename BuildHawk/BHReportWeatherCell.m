//
//  BHReportWeatherCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 1/31/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHReportWeatherCell.h"

@implementation BHReportWeatherCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [_windLabel setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
    [_windTextField setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
    [_precipLabel setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
    [_precipTextField setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
    [_humidityLabel setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
    [_humidityTextField setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
    [_tempLabel setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
    [_tempTextField setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
    [_dailySummaryTextView setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
