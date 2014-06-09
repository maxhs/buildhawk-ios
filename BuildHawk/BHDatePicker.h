//
//  BHDatePicker.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHDatePicker : UIControl
@property (nonatomic, retain, readwrite) NSDate *minimumDate;
@property (nonatomic, retain, readwrite) NSDate *maximumDate;
@property (nonatomic, assign, readwrite) NSDate *date;
@property (strong, nonatomic) UIPickerView *picker;

- (void)setDate:(NSDate *)date animated:(BOOL)animated;
@end
