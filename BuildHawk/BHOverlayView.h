//
//  BHOverlayView.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHOverlayView : UIView
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UIImageView *arrowImageView;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
-(void)configureText:(NSString*)text atFrame:(CGRect)frame;
-(void)configureArrow:(UIImage*)arrow atFrame:(CGRect)frame;
@end
