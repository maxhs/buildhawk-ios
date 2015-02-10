//
//  UIFontDescriptor+Custom.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/17/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "UIFontDescriptor+Custom.h"
#import "Constants.h"

@implementation UIFontDescriptor (Custom)

+ (UIFontDescriptor *)preferredCustomFontForTextStyle:(NSString *)textStyle forFont:(NSString*)font {
    
    static dispatch_once_t onceToken;
    static NSDictionary *fontSizeTable;
    dispatch_once(&onceToken, ^{
        fontSizeTable = @{
                          UIFontTextStyleHeadline: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @37,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @36,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @35,
                                  UIContentSizeCategoryAccessibilityLarge: @34,
                                  UIContentSizeCategoryAccessibilityMedium: @33,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @31,
                                  UIContentSizeCategoryExtraExtraLarge: @30,
                                  UIContentSizeCategoryExtraLarge: @29,
                                  UIContentSizeCategoryLarge: @28,
                                  UIContentSizeCategoryMedium: @27,
                                  UIContentSizeCategorySmall: @26,
                                  UIContentSizeCategoryExtraSmall: @25},
                          
                          UIFontTextStyleSubheadline: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @32,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @31,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @30,
                                  UIContentSizeCategoryAccessibilityLarge: @29,
                                  UIContentSizeCategoryAccessibilityMedium: @27,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @26,
                                  UIContentSizeCategoryExtraExtraLarge: @25,
                                  UIContentSizeCategoryExtraLarge: @24,
                                  UIContentSizeCategoryLarge: @23,
                                  UIContentSizeCategoryMedium: @22,
                                  UIContentSizeCategorySmall: @20,
                                  UIContentSizeCategoryExtraSmall: @19},
                          
                          UIFontTextStyleBody: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @27,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @26,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @25,
                                  UIContentSizeCategoryAccessibilityLarge: @25,
                                  UIContentSizeCategoryAccessibilityMedium: @24,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @24,
                                  UIContentSizeCategoryExtraExtraLarge: @23,
                                  UIContentSizeCategoryExtraLarge: @22,
                                  UIContentSizeCategoryLarge: @21,
                                  UIContentSizeCategoryMedium: @20,
                                  UIContentSizeCategorySmall: @19,
                                  UIContentSizeCategoryExtraSmall: @18},
                          
                          UIFontTextStyleCaption1: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @23,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @22,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @21,
                                  UIContentSizeCategoryAccessibilityLarge: @21,
                                  UIContentSizeCategoryAccessibilityMedium: @20,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @21,
                                  UIContentSizeCategoryExtraExtraLarge: @20,
                                  UIContentSizeCategoryExtraLarge: @19,
                                  UIContentSizeCategoryLarge: @18,
                                  UIContentSizeCategoryMedium: @17,
                                  UIContentSizeCategorySmall: @16,
                                  UIContentSizeCategoryExtraSmall: @15},
                          
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
                                  UIContentSizeCategoryExtraSmall: @11},
                          
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
