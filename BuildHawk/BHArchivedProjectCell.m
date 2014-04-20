//
//  BHArchivedProjectCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHArchivedProjectCell.h"

@implementation BHArchivedProjectCell {
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
    screen = [UIScreen mainScreen].bounds;
    [self.unarchiveButton setBackgroundColor:[UIColor redColor]];
    [self.scrollView setContentSize:CGSizeMake(screen.size.width, 88)];
    [self.unarchiveButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
}

- (void)scroll{
    if (self.scrollView.contentOffset.x == 0){
        [self.scrollView setContentOffset:CGPointMake(88, 0) animated:YES];
    } else {
        [self.scrollView setContentOffset:CGPointZero animated:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x >= 88){
        [self.unarchiveButton setUserInteractionEnabled:YES];
    } else {
        [self.unarchiveButton setUserInteractionEnabled:NO];
    }
}
@end
