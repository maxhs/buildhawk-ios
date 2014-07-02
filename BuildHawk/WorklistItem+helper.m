//
//  WorklistItem+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "WorklistItem+helper.h"
#import "User+helper.h"
#import "Comment+helper.h"
#import "Worklist+helper.h"
#import "Project+helper.h"
#import "Photo+helper.h"

@implementation WorklistItem (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"worklist item helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"location"] && [dictionary objectForKey:@"location"] != [NSNull null]) {
        self.location = [dictionary objectForKey:@"location"];
    }

    if ([dictionary objectForKey:@"project"] && [dictionary objectForKey:@"project"] != [NSNull null]) {
        NSDictionary *projectDict = [dictionary objectForKey:@"project"];
        NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [projectDict objectForKey:@"id"]];
        Project *project = [Project MR_findFirstWithPredicate:userPredicate];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [project populateFromDictionary:projectDict];
        self.project = project;
    }

    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        NSDictionary *userDict = [dictionary objectForKey:@"user"];
        NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
        User *user = [User MR_findFirstWithPredicate:userPredicate];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDictionary:userDict];
        
        self.user = user;
    }
    if ([dictionary objectForKey:@"assignee"] && [dictionary objectForKey:@"assignee"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        NSDictionary *userDict = [dictionary objectForKey:@"assignee"];
        NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
        User *user = [User MR_findFirstWithPredicate:userPredicate];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDictionary:userDict];
        [user assignWorklistItem:self];
        [orderedUsers addObject:user];
        self.assignees = orderedUsers;
    }
    
    if ([dictionary objectForKey:@"comments"] && [dictionary objectForKey:@"comments"] != [NSNull null]) {
        NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSet];
        //NSLog(@"worklist item comments %@",[dictionary objectForKey:@"comments"]);
        for (id commentDict in [dictionary objectForKey:@"comments"]){
            NSPredicate *commentPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [commentDict objectForKey:@"id"]];
            Comment *comment = [Comment MR_findFirstWithPredicate:commentPredicate];
            if (!comment){
                comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [comment populateFromDictionary:commentDict];
            [orderedComments addObject:comment];
        }
        self.comments = orderedComments;
    }
    
    if ([dictionary objectForKey:@"completed"] && [dictionary objectForKey:@"completed"] != [NSNull null]) {
        self.completed = [dictionary objectForKey:@"completed"];
    }
    if ([dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"completed_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"completed_date"] doubleValue];
        self.completedAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSet];
        for (id photoDict in [dictionary objectForKey:@"photos"]){
            NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [photoDict objectForKey:@"id"]];
            Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate];
            if (!photo){
                photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [photo populateFromDictionary:photoDict];
            [orderedPhotos addObject:photo];
        }
        for (Photo *photo in self.photos) {
            if (![orderedPhotos containsObject:photo]){
                NSLog(@"Deleting a worklist item photo that no longer exists");
                [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.photos = orderedPhotos;
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

-(void)addAssignee:(User *)user {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.assignees];
    [set addObject:user];
    self.assignees = set;
}
-(void)removeAssignee:(User *)user {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.assignees];
    [set removeObject:user];
    self.assignees = set;
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
