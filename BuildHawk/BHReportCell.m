//
//  BHReportCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHReportCell.h"

@implementation BHReportCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureReport:(Report *)report {
    [self.reportLabel setText:[NSString stringWithFormat:@"%@ Report - %@",report.type,report.createdDate]];
    [self.personnelLabel setText:[NSString stringWithFormat:@"Personnel onsite: %i",(report.subs.count + report.users.count)]];
    [self.notesLabel setText:[NSString stringWithFormat:@"Notes: %@",report.body]];
}
@end
