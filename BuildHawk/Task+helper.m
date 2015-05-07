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
#import "NSArray+toSentence.h"

@implementation Task (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"task helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"assignee_name"] && [dictionary objectForKey:@"assignee_name"] != [NSNull null]) {
        self.assigneeName = [dictionary objectForKey:@"assignee_name"];
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
    } else {
        self.assignees = [NSOrderedSet orderedSet];
    }
    
    if ([dictionary objectForKey:@"locations"] && [dictionary objectForKey:@"locations"] != [NSNull null]) {
        NSMutableOrderedSet *orderedLocations = [NSMutableOrderedSet orderedSet];
        //NSLog(@"task locations %@",[dictionary objectForKey:@"locations"]);
        for (id dict in [dictionary objectForKey:@"locations"]){
            NSPredicate *locationPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Location *location = [Location MR_findFirstWithPredicate:locationPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!location){
                location = [Location MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [location populateFromDictionary:dict];
            [orderedLocations addObject:location];
        }
        self.locations = orderedLocations;
    } else {
        self.locations = [NSOrderedSet orderedSet];
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
    } else {
        self.comments = [NSOrderedSet orderedSet];
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
    } else {
        self.activities = [NSOrderedSet orderedSet];
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
    [set insertObject:comment atIndex:0];
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

- (NSString *)assigneesToSentence {
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.assignees.count];
    [self.assignees enumerateObjectsUsingBlock:^(User *assignee, NSUInteger idx, BOOL *stop) {
        [names addObject:assignee.fullname];
    }];
    if (self.assigneeName.length){
        [names addObject:self.assigneeName];
    }
    return [names toSentence];
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

-(void)addLocation:(Location *)location {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.locations];
    [set addObject:location];
    self.locations = set;
}

-(void)removeLocation:(Location *)location {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.locations];
    [set removeObject:location];
    self.locations = set;
}

- (NSString *)locationsToSentence {
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.locations.count];
    [self.locations enumerateObjectsUsingBlock:^(Location *location, NSUInteger idx, BOOL *stop) {
        [names addObject:location.name];
    }];
    return [names toSentence];
}

- (void)synchWithServer:(synchCompletion)complete {
    if (!self.body.length) {
        return;
    }
    
    BHAppDelegate *delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:self.body forKey:@"body"];
    NSMutableArray *locationIds = [NSMutableArray arrayWithCapacity:self.locations.count];
    [self.locations enumerateObjectsUsingBlock:^(Location *location, NSUInteger idx, BOOL *stop) {
        if (![location.identifier isEqualToNumber:@0]){
            [locationIds addObject:location.identifier];
        }
    }];
    [parameters setObject:locationIds forKey:@"location_ids"];
    
    NSMutableArray *assigneeIds = [NSMutableArray arrayWithCapacity:self.assignees.count];
    [self.assignees enumerateObjectsUsingBlock:^(User *assignee, NSUInteger idx, BOOL *stop) {
        if ([assignee.identifier isEqualToNumber:@0]){
            [assignee MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        } else {
            [assigneeIds addObject:assignee.identifier];
        }
    }];
    [parameters setObject:assigneeIds forKey:@"assignee_ids"];
    
    if (self.assigneeName.length){
        [parameters setObject:self.assigneeName forKey:@"assignee_name"];
    }
    
    if ([self.completed isEqualToNumber:@YES]){
        [parameters setObject:@YES forKey:@"completed"];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"completed_by_user_id"];
    } else {
        [parameters setObject:@NO forKey:@"completed"];
    }
    NSMutableOrderedSet *imageSet = [NSMutableOrderedSet orderedSetWithCapacity:self.photos.count];
    [self.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
        if (photo.image){
            [imageSet addObject:photo.image];
        }
    }];
    if ([self.identifier isEqualToNumber:@0] && self.project.identifier){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [delegate.manager POST:@"tasks" parameters:@{@"task":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"project_id":self.project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success synching task: %@",responseObject);
            [self populateFromDictionary:[responseObject objectForKey:@"task"]];
            [self setSaved:@YES];
            [self synchImages:imageSet];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            complete(YES);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (!delegate.connected){
                [self setSaved:@NO]; //only mark as unsaved if the failure is connectivity related
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            }
            complete(NO);
            NSLog(@"Failed to synch-create task: %@",error.description);
        }];
    } else {
        [delegate.manager PATCH:[NSString stringWithFormat:@"tasks/%@", self.identifier] parameters:@{@"task":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success synching task: %@",responseObject);
            if ([responseObject objectForKey:@"message"] && [[responseObject objectForKey:@"message"] isEqualToString:kNoTask]){
                [self MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            } else {
                [self populateFromDictionary:[responseObject objectForKey:@"task"]];
                [self setSaved:@YES];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            }
            complete(YES);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (!delegate.connected){
                [self setSaved:@NO]; //only mark as unsaved if the failure is connectivity related
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            }
            complete(NO);
            NSLog(@"Failed to synch-update task: %@",error.description);
        }];
    }
}

- (void)synchImages:(NSMutableOrderedSet*)imageSet{
    BHAppDelegate *delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableDictionary *photoParameters = [NSMutableDictionary dictionary];
    [photoParameters setObject:self.identifier forKey:@"task_id"];
    [photoParameters setObject:@YES forKey:@"mobile"];
    [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    [photoParameters setObject:kTasklist forKey:@"source"];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]){
        [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"company_id"];
    }
    if (self.project.identifier){
        [photoParameters setObject:self.project.identifier forKey:@"project_id"];
    }
    
    for (UIImage *image in imageSet){
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        [delegate.manager POST:[NSString stringWithFormat:@"%@/photos",kApiBaseUrl] parameters:@{@"photo":photoParameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success posting photo for new task: %@",responseObject);
            [self populateFromDictionary:[responseObject objectForKey:@"task"]];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //NSLog(@"Failure posting new task image to API: %@",error.description);
        }];
    }
}

@end
