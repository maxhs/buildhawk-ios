//
//  BHPhotosHeaderView.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPhotosHeaderView.h"

@implementation BHPhotosHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void) configureForTitle:(NSString *)title {
    [self.headerLabel setText:title];
    [self.headerLabel setFont:[UIFont fontWithName:kMyriadPro size:18]];
}
@end
