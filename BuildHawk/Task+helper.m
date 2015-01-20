//
//  Task+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Task+helper.h"
#import "User+helper.h"
#import "Comment+helper.h"
#import "Tasklist+helper.h"
#import "Project+helper.h"
#import "Photo+helper.h"
#import "BHAppDelegate.h"

@implementation Task (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"task helper dictionary: %@",dictionary);
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [projectDict objectForKey:@"id"]];
        Project *project = [Project MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [project populateFromDictionary:projectDict];
        self.project = project;
    }
    if ([dictionary objectForKey:@"project_id"] && [dictionary objectForKey:@"project_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"project_id"]];
        Project *project = [Project MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        project.identifier = [dictionary objectForKey:@"project_id"];
        self.project = project;
    }
    
    if ([dictionary objectForKey:@"tasklist_id"] && [dictionary objectForKey:@"tasklist_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"tasklist_id"]];
        Tasklist *tasklist = [Tasklist MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!tasklist){
            tasklist = [Tasklist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        tasklist.project = self.project;
        self.tasklist = tasklist;
    }

    if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]) {
        NSDictionary *userDict = [dictionary objectForKey:@"user"];
        NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
        User *user = [User MR_findFirstWithPredicate:userPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDictionary:userDict];
        
        self.user = user;
    }
    if ([dictionary objectForKey:@"assignees"] && [dictionary objectForKey:@"assignees"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (id userDict in [dictionary objectForKey:@"assignees"]) {
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (user){
                [user updateFromDictionary:userDict];
            } else {
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [user populateFromDictionary:userDict];
            }
            [user assignTask:self];
            [orderedUsers addObject:user];
        }
        self.assignees = orderedUsers;
    }
    
    if ([dictionary objectForKey:@"comments"] && [dictionary objectForKey:@"comments"] != [NSNull null]) {
        NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSet];
        //NSLog(@"task comments %@",[dictionary objectForKey:@"comments"]);
        for (id commentDict in [dictionary objectForKey:@"comments"]){
            NSPredicate *commentPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [commentDict objectForKey:@"id"]];
            Comment *comment = [Comment MR_findFirstWithPredicate:commentPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!comment){
                comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [comment populateFromDictionary:commentDict];
            [orderedComments addObject:comment];
        }
        self.comments = orderedComments;
    }
    
    if ([dictionary objectForKey:@"activities"] && [dictionary objectForKey:@"activities"] != [NSNull null]) {
        NSMutableOrderedSet *orderedActivities = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"activities"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Activity *activity = [Activity MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!activity){
                activity = [Activity MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [activity populateFromDictionary:dict];
            if (![activity.activityType isEqualToString:@"Comment"])
                [orderedActivities addObject:activity];
        }
        for (Activity *activity in self.activities) {
            if (![orderedActivities containsObject:activity]){
                [activity MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.activities = orderedActivities;
    }
    
    if ([dictionary objectForKey:@"completed"] && [dictionary objectForKey:@"completed"] != [NSNull null]) {
        self.completed = [dictionary objectForKey:@"completed"];
    }
    if ([dictionary objectForKey:@"approved"] && [dictionary objectForKey:@"approved"] != [NSNull null]) {
        self.approved = [dictionary objectForKey:@"approved"];
    }
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
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
            Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (photo){
                [photo updateFromDictionary:photoDict];
            } else {
                photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [photo populateFromDictionary:photoDict];
            }
            
            [orderedPhotos addObject:photo];
        }
        for (Photo *photo in self.photos) {
            if (![orderedPhotos containsObject:photo]){
                //NSLog(@"Deleting a task photo that no longer exists");
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

-(void)addActivity:(Activity *)activity {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.activities];
    [set addObject:activity];
    self.activities = set;
}
-(void)removeActivity:(Activity *)activity {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.activities];
    [set removeObject:activity];
    self.activities = set;
}

- (void)synchWithServer:(synchCompletion)complete {
    if (self && self.body){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        BHAppDelegate *delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
        
        [parameters setObject:self.body forKey:@"body"];
        if (self.location.length){
            NSLog(@"what's self.location? %@",self.location);
            [parameters setObject:self.location forKey:@"location"];
        }
        if (self.assignees.count){
            NSMutableArray *assigneeIds = [NSMutableArray arrayWithCapacity:self.assignees.count];
            [self.assignees enumerateObjectsUsingBlock:^(User *assignee, NSUInteger idx, BOOL *stop) {
                if ([assignee.identifier isEqualToNumber:@0]){
                    [assignee MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                } else {
                    [assigneeIds addObject:assignee.identifier];
                }
            }];
            [parameters setObject:[assigneeIds componentsJoinedByString:@","] forKey:@"assignee_ids"];
        }
        if ([self.completed isEqualToNumber:@YES]){
            [parameters setObject:@YES forKey:@"completed"];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"completed_by_user_id"];
        } else {
            [parameters setObject:@NO forKey:@"completed"];
        }
        
        [delegate.manager PATCH:[NSString stringWithFormat:@"%@/tasks/%@", kApiBaseUrl, self.identifier] parameters:@{@"task":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success synching task: %@",responseObject);
            if ([responseObject objectForKey:@"message"] && [[responseObject objectForKey:@"message"] isEqualToString:kNoTask]){
                [self MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            } else {
                [self populateFromDictionary:[responseObject objectForKey:@"task"]];
                [self setSaved:@YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadTask" object:nil userInfo:@{@"task":self}];
            }
            complete(YES);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
            if (!delegate.connected){
                //only mark as unsaved if the failure is connectivity related
                [self setSaved:@NO];
            }
            complete(NO);
            NSLog(@"Failed to synch task: %@",error.description);
        }];
    }
}

@end
