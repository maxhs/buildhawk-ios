//
//  Comment+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Comment+helper.h"
#import "User+helper.h"
#import "BHUtilities.h"
#import "BHAppDelegate.h"

@implementation Comment (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"project helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"]!=[NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"]!=[NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"]!=[NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"]!=[NSNull null]) {
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"user"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [user populateFromDictionary:[dictionary objectForKey:@"user"]];
        }
        self.user = user;
    }
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"]!=[NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
}

- (void)synchWithServer:(synchCompletion)complete {
    AFHTTPRequestOperationManager *manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    
    NSMutableDictionary *commentParameters = [NSMutableDictionary dictionary];
    // Standard Stuff //
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [commentParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [commentParameters setObject:self.body forKey:@"body"];
    // *** //
    
    if (self.activity && ![self.activity.identifier isEqualToNumber:@0]){
        [commentParameters setObject:self.report.identifier forKey:@"activity_id"];
    } else if (self.checklistItem && ![self.checklistItem.identifier isEqualToNumber:@0]) {
        [commentParameters setObject:self.checklistItem.identifier forKey:@"checklist_item_id"];
    } else if (self.task && ![self.task.identifier isEqualToNumber:@0]){
        [commentParameters setObject:self.task.identifier forKey:@"task_id"];
    } else if (self.report && ![self.report.identifier isEqualToNumber:@0]){
        [commentParameters setObject:self.report.identifier forKey:@"report_id"];
    }
    
    [manager POST:[NSString stringWithFormat:@"%@/comments",kApiBaseUrl] parameters:@{@"comment":commentParameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success synching a new comment with the API: %@",responseObject);
        Comment *comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [comment populateFromDictionary:[responseObject objectForKey:@"comment"]];
        complete(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        complete(NO);
    }];
}

@end
