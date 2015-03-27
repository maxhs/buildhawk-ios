//
//  BHAlert.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/3/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHAlert : UIView

+ (BHAlert *)shared;

+ (void)dismiss;
+ (void)show:(NSString *)status withTime:(CGFloat)time persist:(BOOL)persist;
+ (void)show:(NSString *)status withTime:(CGFloat)time andOffset:(CGPoint)centerOffset;
+ (void)showSuccess:(NSString *)status;
+ (void)showError:(NSString *)status;

@property (atomic, strong) UIWindow *window;
@property (atomic, strong) UIImageView *background;
@property (atomic, strong) UILabel *label;

@end
