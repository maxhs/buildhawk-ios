//
//  BHHiddenProjectCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHHiddenProjectCell.h"

@implementation BHHiddenProjectCell {
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
    [super awakeFromNib];
    screen = [UIScreen mainScreen].bounds;
    [self.unhideButton setBackgroundColor:[UIColor redColor]];
    [self.scrollView setContentSize:CGSizeMake(screen.size.width, 88)];
    [self.unhideButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    if (IDIOM == IPAD) {
        [_titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0]];
        [_subtitleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProLight] size:0]];
    } else {
        [_titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0]];
        [_subtitleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProLight] size:0]];
    }
    [_projectButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0]];
    
    [_unhideButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProRegular] size:0]];
    [_unhideButton setBackgroundColor:[UIColor redColor]];
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
        [self.unhideButton setUserInteractionEnabled:YES];
    } else {
        [self.unhideButton setUserInteractionEnabled:NO];
    }
}
@end
