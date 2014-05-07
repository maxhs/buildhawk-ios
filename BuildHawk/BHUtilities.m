//
//  BHUtilities.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/17/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHUtilities.h"
#import "ChecklistItem+helper.h"
#import "Cat+helper.h"
#import "Comment.h"
#import "Comment+helper.h"

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
        ChecklistItem *item = [ChecklistItem MR_createEntity];
        [item populateFromDictionary:itemDictionary];
        [items addObject:item];
    }
    return items;
}

+ (NSMutableArray *)categoriesFromJSONArray:(NSArray *) array {
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *categoryDictionary in array) {
        Cat *category = [Cat MR_createEntity];
        [category populateFromDictionary:categoryDictionary];
        [categories addObject:category];
    }
    return categories;
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
        //Report *report = [[Report alloc] initWithDictionary:reportDictionary];
        //[reports addObject:report];
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

+ (NSMutableArray *)projectsFromJSONArray:(NSArray *) array {
    NSMutableArray *projects = [NSMutableArray arrayWithCapacity:array.count];
    /*for (NSDictionary *projectDictionary in array) {
        BHProject *project = [[BHProject alloc] initWithDictionary:projectDictionary];
        [projects addObject:project];
    }*/
    return projects;
}

+ (NSMutableArray *)personnelFromJSONArray:(NSArray *) array {
    NSMutableArray *personnel = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *dict in array) {
        if ([dict objectForKey:@"user"]){
            BHUser *user = [[BHUser alloc] initWithDictionary:[dict objectForKey:@"user"]];
            [personnel addObject:user];
        } else if ([dict objectForKey:@"full_name"]) {
            BHUser *user = [[BHUser alloc] initWithDictionary:dict];
            [personnel addObject:user];
        } else if ([dict objectForKey:@"sub"]) {
            /*Sub *sub = [[Sub alloc] :[dict objectForKey:@"sub"]];
            if ([dict objectForKey:@"hours"] && [dict objectForKey:@"hours"] != [NSNull null]) [sub setCount:[[dict objectForKey:@"count"] stringValue]];
            if ([dict objectForKey:@"id"]) [sub setReportSubId:[dict objectForKey:@"id"]];
            [personnel addObject:sub];*/
        } else if ([dict objectForKey:@"count"]) {
            /*Sub *sub = [[Sub alloc] initWithDictionary:dict];
            if ([dict objectForKey:@"count"] && [dict objectForKey:@"count"] != [NSNull null]) [sub setCount:[[dict objectForKey:@"count"] stringValue]];
            [personnel addObject:sub];*/
        }
    }
    return personnel;
}

+ (NSOrderedSet *)commentsFromJSONArray:(NSArray *) array {
    NSMutableOrderedSet *comments = [NSMutableOrderedSet orderedSetWithCapacity:array.count];
    for (NSDictionary *commentDictionary in array) {
        Comment *comment = [Comment MR_createEntity];
        [comment populateFromDictionary:commentDictionary];
        [comments addObject:comment];
    }
    return comments;
}

+ (NSMutableArray *)subcontractorsFromJSONArray:(NSArray *) array {
    NSMutableArray *subcontractors = [NSMutableArray arrayWithCapacity:array.count];
    /*for (NSDictionary *subDictionary in array) {
        Sub *sub = [[Sub alloc] initWithDictionary:subDictionary];
        [subcontractors addObject:sub];
    }*/
    return subcontractors;
}

+ (NSMutableArray *)groupsFromJSONArray:(NSArray *) array {
    NSMutableArray *groups = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *groupDictionary in array) {
        BHProjectGroup *group = [[BHProjectGroup alloc] initWithDictionary:groupDictionary];
        [groups addObject:group];
    }
    return groups;
}

+ (NSMutableArray *)safetyTopicsFromJSONArray:(NSArray *) array {
    NSMutableArray *topics = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *topicDictionary in array) {
        BHSafetyTopic *topic = [[BHSafetyTopic alloc] initWithDictionary:topicDictionary];
        [topics addObject:topic];
    }
    return topics;
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

+ (BOOL)isIpad {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)isIPhone5{
    if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return YES;
    } else {
        return NO;
    }
}

@end
