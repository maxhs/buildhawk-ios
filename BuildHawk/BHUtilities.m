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

+ (NSMutableArray *)checklistItemsFromJSONArray:(NSArray *) array {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *itemDictionary in array) {
        ChecklistItem *item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [item populateFromDictionary:itemDictionary];
        [items addObject:item];
    }
    return items;
}

+ (NSMutableArray *)categoriesFromJSONArray:(NSArray *) array {
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *categoryDictionary in array) {
        Cat *category = [Cat MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [category populateFromDictionary:categoryDictionary];
        [categories addObject:category];
    }
    return categories;
}

+ (NSMutableArray *)projectsFromJSONArray:(NSArray *) array {
    NSMutableArray *projects = [NSMutableArray arrayWithCapacity:array.count];
    /*for (NSDictionary *projectDictionary in array) {
        BHProject *project = [[BHProject alloc] initWithDictionary:projectDictionary];
        [projects addObject:project];
    }*/
    return projects;
}

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

+ (NSOrderedSet *)commentsFromJSONArray:(NSArray *) array {
    NSMutableOrderedSet *comments = [NSMutableOrderedSet orderedSetWithCapacity:array.count];
    for (NSDictionary *commentDictionary in array) {
        Comment *comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
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
