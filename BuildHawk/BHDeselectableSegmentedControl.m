//
//  BHDeselectableSegmentedControl.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/15/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHDeselectableSegmentedControl.h"

@implementation BHDeselectableSegmentedControl

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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSInteger current = self.selectedSegmentIndex;
    [super touchesBegan:touches withEvent:event];
    if (current == self.selectedSegmentIndex) {
        [super setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }
}

@end
