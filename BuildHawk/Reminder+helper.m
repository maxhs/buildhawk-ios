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
    
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null] && [[dictionary objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *userDict = [dictionary objectForKey:@"user"];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [[userDict objectForKey:@"id"] isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
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
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (user){
                [user updateFromDictionary:userDict];
            } else {
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [user populateFromDictionary:userDict];
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
    BHAppDelegate *delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    if ([self.identifier isEqualToNumber:@0]){
        [delegate.manager POST:@"reminders" parameters:@{@"reminder":parameters,@"date":[NSNumber numberWithDouble:[self.reminderDate timeIntervalSince1970]]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success creating a reminder: %@",responseObject);
            if ([responseObject objectForKey:@"failure"]){
                completed(NO);
            } else {
                Reminder *reminder = [self MR_inContext:[NSManagedObjectContext MR_defaultContext]];
                [reminder updateFromDictionary:[responseObject objectForKey:@"reminder"]];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                completed(YES);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            completed(NO);
            if (delegate.connected) NSLog(@"Error creating a checklist item reminder: %@",error.description);
        }];
    } else {
        [delegate.manager PATCH:[NSString stringWithFormat:@"reminders/%@",self.identifier] parameters:@{@"reminder":parameters,@"date":[NSNumber numberWithDouble:[self.reminderDate timeIntervalSince1970]]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success updating a reminder: %@",responseObject);
            if ([responseObject objectForKey:@"failure"]){
                completed(NO);
            } else {
                Reminder *reminder = [self MR_inContext:[NSManagedObjectContext MR_defaultContext]];
                [reminder updateFromDictionary:[responseObject objectForKey:@"reminder"]];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                completed(YES);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            completed(NO);
            if (delegate.connected) NSLog(@"Error creating a checklist item reminder: %@",error.description);
        }];
    }
}

@end
