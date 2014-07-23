//
//  Reminder+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/26/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Reminder+helper.h"
#import "ChecklistItem+helper.h"
#import "User+helper.h"

@implementation Reminder (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"reminder helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"active"] && [dictionary objectForKey:@"active"] != [NSNull null]) {
        self.active = [dictionary objectForKey:@"active"];
    }
    if ([dictionary objectForKey:@"reminder_date"] && [dictionary objectForKey:@"reminder_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"reminder_date"] doubleValue];
        self.reminderDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"checklist_item"] && [dictionary objectForKey:@"checklist_item"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"checklist_item"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (item){
            [item update:dict];
        } else {
            item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [item populateFromDictionary:dict];
        }
        self.checklistItem = item;
    }
    
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        if ([[[dictionary objectForKey:@"user"] objectForKey:@"id"] isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
            User *currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (currentUser){
                if ([self.reminderDate compare:[NSDate date]] == NSOrderedAscending){
                    [currentUser addPastDueReminder:self];
                } else {
                    [currentUser addReminder:self];
                }
            }
            self.user = currentUser;
        } else {
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"user"] objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (user){
                [user update:[dictionary objectForKey:@"user"]];
            } else {
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [user populateFromDictionary:[dictionary objectForKey:@"user"]];
            }
            self.user = user;
        }
    }
}
@end
