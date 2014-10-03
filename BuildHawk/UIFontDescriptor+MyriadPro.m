//
//  UIFontDescriptor+MyriadPro.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/17/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "UIFontDescriptor+MyriadPro.h"

@implementation UIFontDescriptor (MyriadPro)

NSString *const ANUIFontTextStyleCaption3 = @"ANUIFontTextStyleCaption3";
NSString *const ANUIFontTextStyleCaption4 = @"ANUIFontTextStyleCaption4";

+ (UIFontDescriptor *)preferredMyriadProFontForTextStyle:(NSString *)textStyle forFont:(NSString*)font {
    
    static dispatch_once_t onceToken;
    static NSDictionary *fontSizeTable;
    dispatch_once(&onceToken, ^{
        fontSizeTable = @{
                          UIFontTextStyleHeadline: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @38,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @37,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @36,
                                  UIContentSizeCategoryAccessibilityLarge: @35,
                                  UIContentSizeCategoryAccessibilityMedium: @34,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @33,
                                  UIContentSizeCategoryExtraExtraLarge: @32,
                                  UIContentSizeCategoryExtraLarge: @31,
                                  UIContentSizeCategoryLarge: @30,
                                  UIContentSizeCategoryMedium: @29,
                                  UIContentSizeCategorySmall: @28,
                                  UIContentSizeCategoryExtraSmall: @27},
                          
                          UIFontTextStyleSubheadline: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @30,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @29,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @28,
                                  UIContentSizeCategoryAccessibilityLarge: @27,
                                  UIContentSizeCategoryAccessibilityMedium: @25,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @24,
                                  UIContentSizeCategoryExtraExtraLarge: @23,
                                  UIContentSizeCategoryExtraLarge: @22,
                                  UIContentSizeCategoryLarge: @21,
                                  UIContentSizeCategoryMedium: @20,
                                  UIContentSizeCategorySmall: @18,
                                  UIContentSizeCategoryExtraSmall: @17},
                          
                          UIFontTextStyleBody: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @22,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @21,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @20,
                                  UIContentSizeCategoryAccessibilityLarge: @20,
                                  UIContentSizeCategoryAccessibilityMedium: @19,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @19,
                                  UIContentSizeCategoryExtraExtraLarge: @18,
                                  UIContentSizeCategoryExtraLarge: @17,
                                  UIContentSizeCategoryLarge: @16,
                                  UIContentSizeCategoryMedium: @15,
                                  UIContentSizeCategorySmall: @14,
                                  UIContentSizeCategoryExtraSmall: @13,},
                          
                          UIFontTextStyleCaption1: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @19,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @18,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @17,
                                  UIContentSizeCategoryAccessibilityLarge: @17,
                                  UIContentSizeCategoryAccessibilityMedium: @16,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @16,
                                  UIContentSizeCategoryExtraExtraLarge: @16,
                                  UIContentSizeCategoryExtraLarge: @15,
                                  UIContentSizeCategoryLarge: @14,
                                  UIContentSizeCategoryMedium: @13,
                                  UIContentSizeCategorySmall: @12,
                                  UIContentSizeCategoryExtraSmall: @12,},
                          
                          UIFontTextStyleCaption2: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @18,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @17,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @16,
                                  UIContentSizeCategoryAccessibilityLarge: @16,
                                  UIContentSizeCategoryAccessibilityMedium: @15,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @15,
                                  UIContentSizeCategoryExtraExtraLarge: @14,
                                  UIContentSizeCategoryExtraLarge: @14,
                                  UIContentSizeCategoryLarge: @13,
                                  UIContentSizeCategoryMedium: @12,
                                  UIContentSizeCategorySmall: @12,
                                  UIContentSizeCategoryExtraSmall: @11,},
                          
                          ANUIFontTextStyleCaption3: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @17,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @16,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @15,
                                  UIContentSizeCategoryAccessibilityLarge: @15,
                                  UIContentSizeCategoryAccessibilityMedium: @14,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @14,
                                  UIContentSizeCategoryExtraExtraLarge: @13,
                                  UIContentSizeCategoryExtraLarge: @12,
                                  UIContentSizeCategoryLarge: @12,
                                  UIContentSizeCategoryMedium: @12,
                                  UIContentSizeCategorySmall: @11,
                                  UIContentSizeCategoryExtraSmall: @10,},
                          
                          UIFontTextStyleFootnote: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @16,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @15,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @14,
                                  UIContentSizeCategoryAccessibilityLarge: @14,
                                  UIContentSizeCategoryAccessibilityMedium: @13,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @13,
                                  UIContentSizeCategoryExtraExtraLarge: @12,
                                  UIContentSizeCategoryExtraLarge: @12,
                                  UIContentSizeCategoryLarge: @11,
                                  UIContentSizeCategoryMedium: @11,
                                  UIContentSizeCategorySmall: @10,
                                  UIContentSizeCategoryExtraSmall: @10,},
                          
                          ANUIFontTextStyleCaption4: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @15,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @14,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @13,
                                  UIContentSizeCategoryAccessibilityLarge: @13,
                                  UIContentSizeCategoryAccessibilityMedium: @12,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @12,
                                  UIContentSizeCategoryExtraExtraLarge: @11,
                                  UIContentSizeCategoryExtraLarge: @11,
                                  UIContentSizeCategoryLarge: @10,
                                  UIContentSizeCategoryMedium: @10,
                                  UIContentSizeCategorySmall: @9,
                                  UIContentSizeCategoryExtraSmall: @9,},
                          };
    });
    
    NSString *contentSize = [UIApplication sharedApplication].preferredContentSizeCategory;
    return [UIFontDescriptor fontDescriptorWithName:font size:((NSNumber *)fontSizeTable[textStyle][contentSize]).floatValue];
}

@end
