//
//  BHDashboardProjectCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHDashboardProjectCell.h"

@implementation BHDashboardProjectCell {
    CGRect screen;
}

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
    [self.archiveButton setBackgroundColor:[UIColor redColor]];
    [self.scrollView setContentSize:CGSizeMake(screenWidth(), 88)];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x >= 88){
        [self.archiveButton setUserInteractionEnabled:YES];
    } else {
        [self.archiveButton setUserInteractionEnabled:NO];
    }
}

@end
