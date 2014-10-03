//
//  Notification+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Notification+helper.h"
#import "User.h"
#import "Message+helper.h"

@implementation Notification (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"project helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"notification_type"] && [dictionary objectForKey:@"notification_type"] != [NSNull null]) {
        self.notificationType = [dictionary objectForKey:@"notification_type"];
    }
    if ([dictionary objectForKey:@"user_id"] && [dictionary objectForKey:@"user_id"] != [NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"user_id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (user){
            self.user = user;
        }
    }
    if ([dictionary objectForKey:@"message"] && [dictionary objectForKey:@"message"] != [NSNull null]) {
        NSDictionary *messageDict = [dictionary objectForKey:@"message"];
        Message *message = [Message MR_findFirstByAttribute:@"identifier" withValue:[messageDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!message){
            message = [Message MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [message populateFromDictionary:messageDict];
        self.message = message;
    }
}
@end
