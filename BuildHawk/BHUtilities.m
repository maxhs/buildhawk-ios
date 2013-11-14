//
//  BHUtilities.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/17/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHUtilities.h"

@implementation BHUtilities

+ (NSMutableArray *)coworkersFromJSONArray:(NSArray *) array {
    NSMutableArray *coworkers = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *userDictionary in array) {
        BHUser *user = [[BHUser alloc] initWithDictionary:userDictionary];
        [coworkers addObject:user];
    }
    return coworkers;
}

+ (NSMutableArray *)checklistItemsFromJSONArray:(NSArray *) array {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *itemDictionary in array) {
        BHChecklistItem *item = [[BHChecklistItem alloc] initWithDictionary:itemDictionary];
        [items addObject:item];
    }
    return items;
}

+ (NSMutableArray *)punchlistItemsFromJSONArray:(NSArray *) array {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *itemDictionary in array) {
        BHPunchlistItem *item = [[BHPunchlistItem alloc] initWithDictionary:itemDictionary];
        [items addObject:item];
    }
    return items;
}

+ (NSMutableArray *)photosFromJSONArray:(NSArray *) array {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *photoDictionary in array) {
        BHPhoto *photo = [[BHPhoto alloc] initWithDictionary:photoDictionary];
        [photos addObject:photo];
    }
    return photos;
}

+ (NSMutableArray *)reportsFromJSONArray:(NSArray *) array {
    NSMutableArray *reports = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *reportDictionary in array) {
        BHReport *report = [[BHReport alloc] initWithDictionary:reportDictionary];
        [reports addObject:report];
    }
    return reports;
}

+ (NSMutableArray *)usersFromJSONArray:(NSArray *) array {
    NSMutableArray *users = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *userDictionary in array) {
        BHUser *user = [[BHUser alloc] initWithDictionary:userDictionary];
        [users addObject:user];
    }
    return users;
}

+ (NSMutableArray *)commentsFromJSONArray:(NSArray *) array {
    NSMutableArray *comments = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *commentDictionary in array) {
        BHComment *comment = [[BHComment alloc] initWithDictionary:commentDictionary];
        [comments addObject:comment];
    }
    return comments;
}

+ (NSMutableArray *)subcontractorsFromJSONArray:(NSArray *) array {
    NSMutableArray *subcontractors = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *subcontractorDictionary in array) {
        BHSubcontractor *subcontractor = [[BHSubcontractor alloc] initWithDictionary:subcontractorDictionary];
        [subcontractors addObject:subcontractor];
    }
    return subcontractors;
}

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

@end
