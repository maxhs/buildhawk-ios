//
//  PunchlistItem+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "PunchlistItem+helper.h"
#import "User+helper.h"
#import "Comment+helper.h"

@implementation PunchlistItem (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"project helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"assignee"] && [dictionary objectForKey:@"assignee"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSetWithOrderedSet:self.userAssignees];
        NSLog(@"punchlist item asignee %@", [dictionary objectForKey:@"assignee"]);
        for (id userDict in [dictionary objectForKey:@"users"]){
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate];
            if (user){
                NSLog(@"found user for punchlist item: %@",user.fullname);
            } else {
                user = [User MR_createEntity];
                NSLog(@"couldn't find saved user, created a new one: %@",user.fullname);
            }
            [user populateFromDictionary:userDict];
            [orderedUsers addObject:user];
        }
        self.userAssignees = orderedUsers;
    }
    if ([dictionary objectForKey:@"sub_assignee"] && [dictionary objectForKey:@"sub_assignee"] != [NSNull null]) {
        NSMutableOrderedSet *orderedSubs = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subAssignees];
        NSLog(@"punchlist item sub assignees %@",[dictionary objectForKey:@"sub_assignee"]);
        for (id subDict in [dictionary objectForKey:@"subs"]){
            NSPredicate *subPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [subDict objectForKey:@"id"]];
            Sub *sub = [Sub MR_findFirstWithPredicate:subPredicate];
            if (sub){
                NSLog(@"found saved sub: %@",sub.name);
            } else {
                sub = [Sub MR_createEntity];
                NSLog(@"couldn't find saved sub, created a new one: %@",sub.name);
            }
            [sub populateFromDictionary:subDict];
            [orderedSubs addObject:sub];
        }
        self.subAssignees = orderedSubs;
    }
    
    if ([dictionary objectForKey:@"comments"] && [dictionary objectForKey:@"comments"] != [NSNull null]) {
        NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSetWithOrderedSet:self.comments];
        NSLog(@"punchlist item comments %@",[dictionary objectForKey:@"comments"]);
        for (id commentDict in [dictionary objectForKey:@"comments"]){
            NSPredicate *commentPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [commentDict objectForKey:@"id"]];
            Comment *comment = [Comment MR_findFirstWithPredicate:commentPredicate];
            if (comment){
                NSLog(@"found saved sub: %@",comment.body);
            } else {
                comment = [Comment MR_createEntity];
                NSLog(@"couldn't find saved comment, created a new one: %@",comment.body);
            }
            [comment populateFromDictionary:commentDict];
            [orderedComments addObject:comment];
        }
        self.comments = orderedComments;
    }
    
    if ([dictionary objectForKey:@"completed"]) {
        self.completed = [dictionary objectForKey:@"completed"];
    }
    if ([dictionary objectForKey:@"critical_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"critical_date"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"completed_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"completed_date"] doubleValue];
        self.completedAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
}

-(void)addComment:(Comment *)comment {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.comments];
    [set addObject:comment];
    self.comments = set;
}
-(void)removeComment:(Comment *)comment {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.comments];
    [set removeObject:comment];
    self.comments = set;
}
-(void)addPhoto:(Photo *)photo {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.photos];
    [set addObject:photo];
    self.photos = set;
}
-(void)removePhoto:(Photo *)photo {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.photos];
    [set removeObject:photo];
    self.photos = set;
}


/*   
 @property (nonatomic, strong) NSNumber *identifier;
 @property (nonatomic, strong) NSString *body;
 @property (nonatomic, strong) NSString *location;
 @property (nonatomic, strong) NSString *createdOn;
 @property (nonatomic, strong) NSString *completedOn;
 @property (nonatomic, strong) Project *project;
 @property BOOL completed;
 @property (nonatomic, strong) BHUser *completedByUser;
 @property (nonatomic, strong) NSMutableArray *photos;
 @property (nonatomic, strong) NSMutableArray *comments;
 @property (nonatomic, strong) NSMutableArray *assignees;
 
 
 if ([key isEqualToString:@"id"]) {
 self.identifier = value;
 } else if ([key isEqualToString:@"body"]) {
 if (value != [NSNull null] && value != nil) self.body = value;
 } else if ([key isEqualToString:@"location"]) {
 self.location = value;
 } else if ([key isEqualToString:@"created_at"]) {
 self.createdOn = [BHUtilities parseDateTimeReturnString:value];
 } else if ([key isEqualToString:@"completed_at"]) {
 if (value != [NSNull null] && value != nil) self.completedOn = [BHUtilities parseDateReturnString:value];
 } else if ([key isEqualToString:@"completed"]) {
 self.completed = [value boolValue];
 } else if ([key isEqualToString:@"assignee"] && value != nil && value != [NSNull null]) {
 if (!self.assignees) self.assignees = [NSMutableArray array];
 [self.assignees addObject:[[BHUser alloc] initWithDictionary:value]];
 } else if ([key isEqualToString:@"sub_assignee"] && value != nil && value != [NSNull null]) {
 if (!self.assignees) self.assignees = [NSMutableArray array];
 [self.assignees addObject:[[BHSub alloc] initWithDictionary:value]];
 } else if ([key isEqualToString:@"photos"]) {
     self.photos = [BHUtilities photosFromJSONArray:value];
 } else if ([key isEqualToString:@"comments"]) {
     self.comments = [BHUtilities commentsFromJSONArray:value];
 }*/
@end
