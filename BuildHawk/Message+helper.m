//
//  Message+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/13/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Message+helper.h"
#import "User+helper.h"

@implementation Message (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"project helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
//    if ([dictionary objectForKey:@"user"] != [NSNull null]) {
//        NSDictionary *userDict = [dictionary objectForKey:@"user"];
//        NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
//        User *user = [User MR_findFirstWithPredicate:userPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
//        if (!user){
//            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
//        }
//        [user populateFromDictionary:userDict];
//        
//        self.user = user;
//    }
}
@end
