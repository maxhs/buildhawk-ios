//
//  BHOverlayView.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHOverlayView.h"

@implementation BHOverlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _tapGesture = [[UITapGestureRecognizer alloc] init];
        _tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:_tapGesture];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setAlpha:0.0];
    }
    return self;
}

-(void)configureText:(NSString*)text atFrame:(CGRect)frame{
    _label = [[UILabel alloc] initWithFrame:frame];
    [_label setText:text];
    [_label setTextAlignment:NSTextAlignmentLeft];
    [_label setFont:[UIFont fontWithName:kMyriadProRegular size:18]];
    _label.layer.shadowColor = [UIColor blackColor].CGColor;
    _label.layer.shadowOpacity = .15f;
    _label.layer.shadowRadius = .25f;
    _label.layer.shadowOffset = CGSizeMake(1, 1);
    [_label setTextColor:[UIColor whiteColor]];
    [_label setNumberOfLines:0];
    [_label setBackgroundColor:[UIColor clearColor]];
    [self addSubview:_label];
}

-(void)configureArrow:(UIImage*)arrow atFrame:(CGRect)frame{
    _arrowImageView = [[UIImageView alloc] initWithFrame:frame];
    [_arrowImageView setImage:arrow];
    [self addSubview:_arrowImageView];
}

@end
