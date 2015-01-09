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
    [_unhideButton setBackgroundColor:[UIColor redColor]];
    [_unhideButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [_unhideButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProRegular] size:0]];
    [_scrollView setContentSize:CGSizeMake(screenWidth()+88, 88)];

    [_titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0]];
    [_subtitleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProLight] size:0]];

    [_projectButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0]];
    
    //spent a couple of hours before figuring out I hadn't made the button userInteractionEnabled..
    [_unhideButton setUserInteractionEnabled:YES];
}

- (void)scroll{
    if (self.scrollView.contentOffset.x == 0){
        [self.scrollView setContentOffset:CGPointMake(88, 0) animated:YES];
    } else {
        [self.scrollView setContentOffset:CGPointZero animated:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _unhideButton.transform = CGAffineTransformMakeTranslation(-scrollView.contentOffset.x/2, 0);
}
@end
