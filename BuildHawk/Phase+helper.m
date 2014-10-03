//
//  Phase+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Phase+helper.h"
#import "Checklist+helper.h"
#import "Phase.h"
#import "BHUtilities.h"

@implementation Phase (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"category helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"checklist_id"] && [dictionary objectForKey:@"checklist_id"] != [NSNull null]) {
        Checklist *checklist = [Checklist MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"checklist_id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!checklist){
            checklist = [Checklist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            checklist.identifier = [dictionary objectForKey:@"checklist_id"];
        }
        self.checklist = checklist;
    }
    
    if ([dictionary objectForKey:@"item_count"] && [dictionary objectForKey:@"item_count"] != [NSNull null]) {
        self.itemCount = [dictionary objectForKey:@"item_count"];
    }
    if ([dictionary objectForKey:@"progress_count"] && [dictionary objectForKey:@"progress_count"] != [NSNull null]) {
        self.progressCount = [dictionary objectForKey:@"progress_count"];
    }
    if ([dictionary objectForKey:@"order_index"] && [dictionary objectForKey:@"order_index"] != [NSNull null]) {
        self.orderIndex = [dictionary objectForKey:@"order_index"];
    }
    if ([dictionary objectForKey:@"milestone_date"] && [dictionary objectForKey:@"milestone_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"milestone_date"] doubleValue];
        self.milestoneDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    } else {
        self.milestoneDate = nil;
    }
    
    if ([dictionary objectForKey:@"completed_date"] && [dictionary objectForKey:@"completed_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"completed_date"] doubleValue];
        self.completedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    } else {
        self.completedDate = nil;
    }
    
    if ([dictionary objectForKey:@"categories"] && [dictionary objectForKey:@"categories"] != [NSNull null]) {
        NSMutableOrderedSet *categories = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *categoryDict in [dictionary objectForKey:@"categories"]) {
            Cat *category = [Cat MR_findFirstByAttribute:@"identifier" withValue:[categoryDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (category){
                [category updateFromDictionary:categoryDict];
            } else {
                category = [Cat MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [category populateFromDictionary:categoryDict];
            }
            [categories addObject:category];
        }
        self.categories = categories;
        [self calculateProgress];
    }
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {

    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"item_count"] && [dictionary objectForKey:@"item_count"] != [NSNull null]) {
        self.itemCount = [dictionary objectForKey:@"item_count"];
    }
    if ([dictionary objectForKey:@"progress_count"] && [dictionary objectForKey:@"progress_count"] != [NSNull null]) {
        self.progressCount = [dictionary objectForKey:@"progress_count"];
    }
    if ([dictionary objectForKey:@"order_index"] && [dictionary objectForKey:@"order_index"] != [NSNull null]) {
        self.orderIndex = [dictionary objectForKey:@"order_index"];
    }
    if ([dictionary objectForKey:@"milestone_date"] && [dictionary objectForKey:@"milestone_date"] != [NSNull null]) {
        self.milestoneDate = [BHUtilities parseDate:[dictionary objectForKey:@"milestone_date"]];
    }
    if ([dictionary objectForKey:@"completed_date"] && [dictionary objectForKey:@"completed_date"] != [NSNull null]) {
        self.completedDate = [BHUtilities parseDate:[dictionary objectForKey:@"completed_date"]];
    }
    if ([dictionary objectForKey:@"categories"] && [dictionary objectForKey:@"categories"] != [NSNull null]) {
        NSMutableOrderedSet *categories = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *categoryDict in [dictionary objectForKey:@"categories"]) {
            Cat *category = [Cat MR_findFirstByAttribute:@"identifier" withValue:[categoryDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (category){
                [category updateFromDictionary:categoryDict];
            } else {
                category = [Cat MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [category populateFromDictionary:categoryDict];
            }
            
            [categories addObject:category];
        }
        self.categories = categories;
        [self calculateProgress];
    }
}

- (void)calculateProgress{
    __block int completedCount = 0;
    __block int notApplicableCount = 0;
    [self.categories enumerateObjectsUsingBlock:^(Cat *category, NSUInteger idx, BOOL *stop) {
        completedCount += category.completedCount.intValue;
        notApplicableCount += category.notApplicableCount.intValue;
    }];
    self.completedCount = [NSNumber numberWithInteger:completedCount];
    self.notApplicableCount = [NSNumber numberWithInteger:notApplicableCount];
    //NSLog(@"phase %@ with %@ complete and %@ not applicable",self.name,self.completedCount,self.notApplicableCount);
}

- (void)addCategory:(Cat *)category{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.categories];
    [set addObject:category];
    self.categories = set;
}
- (void)removeCategory:(Cat *)category{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.categories];
    [set removeObject:category];
    self.categories = set;
}

@end
