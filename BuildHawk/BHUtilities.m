//
//  BHUtilities.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/17/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHUtilities.h"

@implementation BHUtilities

/*+ (NSMutableArray *)personnelFromJSONArray:(NSArray *) array {
    NSMutableArray *personnel = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *dict in array) {
        if ([dict objectForKey:@"user"]){
            User *user = [[User alloc] initWithDictionary:[dict objectForKey:@"user"]];
            [personnel addObject:user];
        } else if ([dict objectForKey:@"full_name"]) {
            User *user = [[User alloc] initWithDictionary:dict];
            [personnel addObject:user];
        } else if ([dict objectForKey:@"sub"]) {
            Sub *sub = [[Sub alloc] :[dict objectForKey:@"sub"]];
            if ([dict objectForKey:@"hours"] && [dict objectForKey:@"hours"] != [NSNull null]) [sub setCount:[[dict objectForKey:@"count"] stringValue]];
            if ([dict objectForKey:@"id"]) [sub setReportSubId:[dict objectForKey:@"id"]];
            [personnel addObject:sub];
        } else if ([dict objectForKey:@"count"]) {
            Sub *sub = [[Sub alloc] initWithDictionary:dict];
            if ([dict objectForKey:@"count"] && [dict objectForKey:@"count"] != [NSNull null]) [sub setCount:[[dict objectForKey:@"count"] stringValue]];
            [personnel addObject:sub];
        }
    }
    return personnel;
}*/

+ (NSDate*)parseDate:(id)value {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *theDate;
    NSError *error;
    if (![dateFormat getObjectValue:&theDate forString:value range:nil error:&error]) {
        NSLog(@"Date '%@' could not be parsed: %@", value, error);
    }
    return theDate;
}

+ (NSString*)parseDateReturnString:(id)value {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *theDate;
    NSError *error;
    if (![dateFormat getObjectValue:&theDate forString:value range:nil error:&error]) {
        NSLog(@"Date '%@' could not be parsed: %@", value, error);
    }
    NSDateFormatter *stringFormatter = [[NSDateFormatter alloc] init];
    [stringFormatter setDateStyle:NSDateFormatterMediumStyle];

    return [stringFormatter stringFromDate:theDate];
}

+ (NSString*)parseDateTimeReturnString:(id)value {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *theDate;
    NSError *error;
    if (![dateFormat getObjectValue:&theDate forString:value range:nil error:&error]) {
        NSLog(@"Date '%@' could not be parsed: %@", value, error);
    }
    NSDateFormatter *stringFormatter = [[NSDateFormatter alloc] init];
    [stringFormatter setDateStyle:NSDateFormatterShortStyle];
    [stringFormatter setTimeStyle:NSDateFormatterShortStyle];
    return [stringFormatter stringFromDate:theDate];
}

+ (BOOL)isIPhone5{
    if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return YES;
    } else {
        return NO;
    }
}

@end
