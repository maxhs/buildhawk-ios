//
//  UIFontDescriptor+MyriadPro.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/17/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFontDescriptor (MyriadPro)

+ (UIFontDescriptor *)preferredMyriadProFontForTextStyle:(NSString *)textStyle forFont:(NSString *)font;

@end
