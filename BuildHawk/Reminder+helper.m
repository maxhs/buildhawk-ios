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
#import "BHAppDelegate.h"

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
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"checklist_item"] && [dictionary objectForKey:@"checklist_item"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"checklist_item"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (item){
            [item updateFromDictionary:dict];
        } else {
            item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [item populateFromDictionary:dict];
        }
        self.checklistItem = item;
    }
    
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [[[dictionary objectForKey:@"user"] objectForKey:@"id"] isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
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
                [user updateFromDictionary:[dictionary objectForKey:@"user"]];
            } else {
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [user populateFromDictionary:[dictionary objectForKey:@"user"]];
            }
            self.user = user;
        }
    }
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"update reminder helper dictionary: %@",dictionary);
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
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
}

- (void)synchWithServer:(synchCompletion)completed {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (self.checklistItem && ![self.checklistItem.identifier isEqualToNumber:@0]) {
        [parameters setObject:self.checklistItem.identifier forKey:@"checklist_item_id"];
    }
    if (self.project && ![self.project.identifier isEqualToNumber:@0]){
        [parameters setObject:self.project.identifier forKey:@"project_id"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] POST:[NSString stringWithFormat:@"%@/reminders",kApiBaseUrl] parameters:@{@"reminder":parameters,@"date":[NSNumber numberWithDouble:[self.reminderDate timeIntervalSince1970]]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success creating a reminder: %@",responseObject);
        if ([responseObject objectForKey:@"failure"]){
            NSLog(@"Failed to create/synch checklist item: %@",responseObject);
            completed(NO);
        } else {
            [self updateFromDictionary:[responseObject objectForKey:@"reminder"]];
            completed(YES);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completed(NO);
        NSLog(@"Error creating a checklist item reminder: %@",error.description);
    }];
}

@end
