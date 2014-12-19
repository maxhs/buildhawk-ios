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
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @39,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @38,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @37,
                                  UIContentSizeCategoryAccessibilityLarge: @36,
                                  UIContentSizeCategoryAccessibilityMedium: @35,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @34,
                                  UIContentSizeCategoryExtraExtraLarge: @33,
                                  UIContentSizeCategoryExtraLarge: @32,
                                  UIContentSizeCategoryLarge: @31,
                                  UIContentSizeCategoryMedium: @30,
                                  UIContentSizeCategorySmall: @29,
                                  UIContentSizeCategoryExtraSmall: @28},
                          
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
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @25,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @24,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @23,
                                  UIContentSizeCategoryAccessibilityLarge: @23,
                                  UIContentSizeCategoryAccessibilityMedium: @22,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @22,
                                  UIContentSizeCategoryExtraExtraLarge: @21,
                                  UIContentSizeCategoryExtraLarge: @20,
                                  UIContentSizeCategoryLarge: @19,
                                  UIContentSizeCategoryMedium: @18,
                                  UIContentSizeCategorySmall: @17,
                                  UIContentSizeCategoryExtraSmall: @16},
                          
                          UIFontTextStyleCaption1: @{
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
                                  UIContentSizeCategoryExtraSmall: @13},
                          
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
