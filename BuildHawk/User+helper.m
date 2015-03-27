//
//  User+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "User+helper.h"
#import "Task+helper.h"
#import "Company+helper.h"
#import "Alternate+helper.h"
#import "BHAppDelegate.h"

@implementation User (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"user helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"authentication_token"] && [dictionary objectForKey:@"authentication_token"] != [NSNull null]) {
        self.authToken = [dictionary objectForKey:@"authentication_token"];
    }
    if ([dictionary objectForKey:@"mobile_tokens"] && [dictionary objectForKey:@"mobile_tokens"] != [NSNull null]) {
        for (NSDictionary *tokenDict in [dictionary objectForKey:@"mobile_tokens"]){
            NSNumber *deviceType = [tokenDict objectForKey:@"device_type"];
            if (IDIOM == IPAD){
                if ([deviceType isEqualToNumber:@2]){
                    self.mobileToken = [tokenDict objectForKey:@"token"];
                }
            } else {
                if ([deviceType isEqualToNumber:@1]){
                    self.mobileToken = [tokenDict objectForKey:@"token"];
                }
            }
        }
    }
    if ([dictionary objectForKey:@"full_name"] && [dictionary objectForKey:@"full_name"] != [NSNull null]) {
        self.fullname = [dictionary objectForKey:@"full_name"];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"first_name"] != [NSNull null]) {
        self.firstName = [dictionary objectForKey:@"first_name"];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"last_name"] != [NSNull null]) {
        self.lastName = [dictionary objectForKey:@"last_name"];
    }
    if ([dictionary objectForKey:@"url_medium"] && [dictionary objectForKey:@"url_medium"] != [NSNull null]) {
        self.photoUrlMedium = [dictionary objectForKey:@"url_medium"];
    }
    if ([dictionary objectForKey:@"url_thumb"] && [dictionary objectForKey:@"url_thumb"] != [NSNull null]) {
        self.photoUrlThumb = [dictionary objectForKey:@"url_thumb"];
    }
    if ([dictionary objectForKey:@"url_small"] && [dictionary objectForKey:@"url_small"] != [NSNull null]) {
        self.photoUrlSmall = [dictionary objectForKey:@"url_small"];
    }
    if ([dictionary objectForKey:@"phone"] && [dictionary objectForKey:@"phone"] != [NSNull null]) {
        self.phone = [dictionary objectForKey:@"phone"];
    } else {
        //empty out the phone if it's not part of the response object.
        self.phone = @"";
    }
    if ([dictionary objectForKey:@"formatted_phone"] && [dictionary objectForKey:@"formatted_phone"] != [NSNull null]) {
        self.formattedPhone = [dictionary objectForKey:@"formatted_phone"];
    } else {
        //empty out the phone if it's not part of the response object.
        self.formattedPhone = @"";
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]) {
        self.email = [dictionary objectForKey:@"email"];
    }
    if ([dictionary objectForKey:@"active"] && [dictionary objectForKey:@"active"] != [NSNull null]) {
        self.active = [dictionary objectForKey:@"active"];
    }
    if ([dictionary objectForKey:@"admin"] && [dictionary objectForKey:@"admin"] != [NSNull null]) {
        self.admin = [dictionary objectForKey:@"admin"];
    } else {
        self.admin = @NO;
    }
    if ([dictionary objectForKey:@"company_admin"] && [dictionary objectForKey:@"company_admin"] != [NSNull null]) {
        self.companyAdmin = [dictionary objectForKey:@"company_admin"];
    } else {
        self.companyAdmin = @NO;
    }
    if ([dictionary objectForKey:@"uber_admin"] && [dictionary objectForKey:@"uber_admin"] != [NSNull null]) {
        self.uberAdmin = [dictionary objectForKey:@"uber_admin"];
    } else {
        self.uberAdmin = @NO;
    }
    if ([dictionary objectForKey:@"push_permissions"] && [dictionary objectForKey:@"push_permissions"] != [NSNull null]) {
        self.pushPermissions = [dictionary objectForKey:@"push_permissions"];
    }
    if ([dictionary objectForKey:@"text_permissions"] && [dictionary objectForKey:@"text_permissions"] != [NSNull null]) {
        self.textPermissions = [dictionary objectForKey:@"text_permissions"];
    }
    if ([dictionary objectForKey:@"email_permissions"] && [dictionary objectForKey:@"email_permissions"] != [NSNull null]) {
        self.emailPermissions = [dictionary objectForKey:@"email_permissions"];
    }
    if ([dictionary objectForKey:@"company"] && [dictionary objectForKey:@"company"] != [NSNull null]) {
        NSDictionary *companyDict = [dictionary objectForKey:@"company"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [companyDict objectForKey:@"id"]];
        Company *company = [Company MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (company){
            [company updateFromDictionary:companyDict];
        } else {
            company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [company populateFromDictionary:companyDict];
        }
        self.company = company;
    }
    if ([dictionary objectForKey:@"alternates"] && [dictionary objectForKey:@"alternates"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"alternates"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Alternate *item = [Alternate MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!item){
                item = [Alternate MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [item populateFromDictionary:dict];
            [set addObject:item];
        }
        self.alternates = set;
    }
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"update user helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"mobile_token"] && [dictionary objectForKey:@"mobile_token"] != [NSNull null]) {
        self.mobileToken = [dictionary objectForKey:@"mobile_token"];
    }
    if ([dictionary objectForKey:@"full_name"] && [dictionary objectForKey:@"full_name"] != [NSNull null]) {
        self.fullname = [dictionary objectForKey:@"full_name"];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"first_name"] != [NSNull null]) {
        self.firstName = [dictionary objectForKey:@"first_name"];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"last_name"] != [NSNull null]) {
        self.lastName = [dictionary objectForKey:@"last_name"];
    }
    if ([dictionary objectForKey:@"url_medium"] && [dictionary objectForKey:@"url_medium"] != [NSNull null]) {
        self.photoUrlMedium = [dictionary objectForKey:@"url_medium"];
    }
    if ([dictionary objectForKey:@"url_thumb"] && [dictionary objectForKey:@"url_thumb"] != [NSNull null]) {
        self.photoUrlThumb = [dictionary objectForKey:@"url_thumb"];
    }
    if ([dictionary objectForKey:@"url_small"] && [dictionary objectForKey:@"url_small"] != [NSNull null]) {
        self.photoUrlSmall = [dictionary objectForKey:@"url_small"];
    }
    if ([dictionary objectForKey:@"phone"] && [dictionary objectForKey:@"phone"] != [NSNull null]) {
        self.phone = [dictionary objectForKey:@"phone"];
    } else {
        self.phone = @"";
    }
    if ([dictionary objectForKey:@"formatted_phone"] && [dictionary objectForKey:@"formatted_phone"] != [NSNull null]) {
        self.formattedPhone = [dictionary objectForKey:@"formatted_phone"];
    } else {
        self.formattedPhone = @"";
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]) {
        self.email = [dictionary objectForKey:@"email"];
    }

    if ([dictionary objectForKey:@"company"] && [dictionary objectForKey:@"company"] != [NSNull null]) {
        NSDictionary *companyDict = [dictionary objectForKey:@"company"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [companyDict objectForKey:@"id"]];
        Company *company = [Company MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (company){
            [company updateFromDictionary:companyDict];
        } else {
            company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [company populateFromDictionary:companyDict];
        }
        self.company = company;
    }
    if ([dictionary objectForKey:@"admin"] && [dictionary objectForKey:@"admin"] != [NSNull null]) {
        self.admin = [dictionary objectForKey:@"admin"];
    } else {
        self.admin = @NO;
    }
    if ([dictionary objectForKey:@"company_admin"] && [dictionary objectForKey:@"company_admin"] != [NSNull null]) {
        self.companyAdmin = [dictionary objectForKey:@"company_admin"];
    } else {
        self.companyAdmin = @NO;
    }
    if ([dictionary objectForKey:@"uber_admin"] && [dictionary objectForKey:@"uber_admin"] != [NSNull null]) {
        self.uberAdmin = [dictionary objectForKey:@"uber_admin"];
    } else {
        self.uberAdmin = @NO;
    }
}

- (BOOL)anyAdmin {
    if ([self.admin isEqualToNumber:@YES] || [self.companyAdmin isEqualToNumber:@YES] || [self.uberAdmin isEqualToNumber:@YES]){
        return YES;
    } else {
        return NO;
    }
}

- (void)removeNotification:(Notification*)notification {
    NSMutableOrderedSet *notifications = [NSMutableOrderedSet orderedSetWithOrderedSet:self.notifications];
    [notifications removeObject:notification];
    self.notifications = notifications;
}

- (void)addNotification:(Notification*)notification {
    NSMutableOrderedSet *notifications = [NSMutableOrderedSet orderedSetWithOrderedSet:self.notifications];
    [notifications addObject:notification];
    self.notifications = notifications;
}
- (void)assignTask:(Task*)item {
    NSMutableOrderedSet *orderedItems = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignedTasks];
    [orderedItems addObject:item];
    self.assignedTasks = orderedItems;
}

- (void)addReminder:(Reminder*)reminder {
    NSMutableOrderedSet *reminders = [NSMutableOrderedSet orderedSetWithOrderedSet:self.reminders];
    [reminders addObject:reminder];
    self.reminders = reminders;
}
- (void)removeReminder:(Reminder*)reminder {
    NSMutableOrderedSet *reminders = [NSMutableOrderedSet orderedSetWithOrderedSet:self.reminders];
    [reminders removeObject:reminder];
    self.reminders = reminders;
}

- (void)addPastDueReminder:(Reminder*)reminder {
    NSMutableOrderedSet *pastDueReminders = [NSMutableOrderedSet orderedSetWithOrderedSet:self.pastDueReminders];
    [pastDueReminders addObject:reminder];
    self.pastDueReminders = pastDueReminders;
}
- (void)removePastDueReminder:(Reminder*)reminder {
    NSMutableOrderedSet *pastDueReminders = [NSMutableOrderedSet orderedSetWithOrderedSet:self.pastDueReminders];
    [pastDueReminders removeObject:reminder];
    self.pastDueReminders = pastDueReminders;
}

- (void)hideProject:(Project *)project {
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.hiddenProjects];
    [set addObject:project];
    self.hiddenProjects= set;
}
- (void)activateProject:(Project *)project {
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.hiddenProjects];
    [set removeObject:project];
    [self addProject:project];
    self.hiddenProjects = set;
}
- (void)addProject:(Project *)project {
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.projects];
    [set addObject:project];
    self.projects = set;
}
- (void)removeProject:(Project *)project {
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.projects];
    [set removeObject:project];
    self.projects = set;
}

- (void)synchWithServer:(synchCompletion)complete {
    BHAppDelegate *delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:self.emailPermissions forKey:@"email_permissions"];
    [parameters setObject:self.textPermissions forKey:@"text_permissions"];
    [parameters setObject:self.pushPermissions forKey:@"push_permissions"];
    [parameters setObject:self.firstName forKey:@"first_name"];
    [parameters setObject:self.lastName forKey:@"last_name"];
    [parameters setObject:self.phone forKey:@"phone"];
    [parameters setObject:self.email forKey:@"email"];

    [delegate.manager PATCH:[NSString stringWithFormat:@"users/%@", self.identifier] parameters:@{@"user":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success synching user: %@",responseObject);
        [self populateFromDictionary:[responseObject objectForKey:@"user"]];
        [self setSaved:@YES];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            complete(YES);
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (!delegate.connected){
            [self setSaved:@NO]; //only mark as unsaved if the failure is connectivity related
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        }
        complete(NO);
        NSLog(@"Failed to synch-update user: %@",error.description);
    }];

}


@end
