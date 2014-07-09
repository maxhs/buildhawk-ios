//
//  ChecklistItem+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "ChecklistItem+helper.h"
#import "Comment+helper.h"
#import "Photo+helper.h"
#import "Phase+helper.h"
#import "Checklist+helper.h"
#import "Project+helper.h"
#import "Activity+helper.h"
#import "Reminder+helper.h"

@implementation ChecklistItem (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"checklist item helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"order_index"] && [dictionary objectForKey:@"order_index"] != [NSNull null]) {
        self.orderIndex = [dictionary objectForKey:@"order_index"];
    }
    if ([dictionary objectForKey:@"item_type"] && [dictionary objectForKey:@"item_type"] != [NSNull null]) {
        self.type = [dictionary objectForKey:@"item_type"];
    }
    if ([dictionary objectForKey:@"state"] && [dictionary objectForKey:@"state"] != [NSNull null]) {
        self.state = [dictionary objectForKey:@"state"];
    } else {
        self.state = nil;
    }
    if ([dictionary objectForKey:@"photos_count"] && [dictionary objectForKey:@"photos_count"] != [NSNull null]) {
        self.photosCount = [dictionary objectForKey:@"photos_count"];
    }
    if ([dictionary objectForKey:@"critical_date"] && [dictionary objectForKey:@"critical_date"] != [NSNull null]) {
        self.criticalDate = [BHUtilities parseDate:[dictionary objectForKey:@"critical_date"]];
    }
    if ([dictionary objectForKey:@"completed_date"] && [dictionary objectForKey:@"completed_date"] != [NSNull null]) {
        self.completedDate = [BHUtilities parseDate:[dictionary objectForKey:@"completed_date"]];
    }
    if ([dictionary objectForKey:@"comments_count"] && [dictionary objectForKey:@"comments_count"] != [NSNull null]) {
        self.commentsCount = [dictionary objectForKey:@"comments_count"];
    }
    if ([dictionary objectForKey:@"project_id"] && [dictionary objectForKey:@"project_id"] != [NSNull null]) {
        Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"project_id"]];
        if (project){
            self.project = project;
        }
    }
    if ([dictionary objectForKey:@"checklist_id"] && [dictionary objectForKey:@"checklist_id"] != [NSNull null]) {
        Checklist *checklist = [Checklist MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"checklist_id"]];
        if (checklist){
            self.checklist = checklist;
        }
    }
    if ([dictionary objectForKey:@"comments"] && [dictionary objectForKey:@"comments"] != [NSNull null]) {
        NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSet];
        //NSLog(@"checklist item comments %@",[dictionary objectForKey:@"comments"]);
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
    
    if ([dictionary objectForKey:@"reminders"] && [dictionary objectForKey:@"reminders"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        //NSLog(@"checklist item reminders %@",[dictionary objectForKey:@"reminders"]);
        for (id dict in [dictionary objectForKey:@"reminders"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Reminder *reminder = [Reminder MR_findFirstWithPredicate:predicate];
            if (!reminder){
                reminder = [Reminder MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [reminder populateFromDictionary:dict];
            [set addObject:reminder];
        }
        for (Reminder *reminder in self.reminders) {
            if (![set containsObject:reminder]){
                NSLog(@"Deleting a reminder that no longer exists for checklist item: %@",self.identifier);
                [reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reminders = set;
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
                [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.photos = orderedPhotos;
    }
    
    if ([dictionary objectForKey:@"activities"] && [dictionary objectForKey:@"activities"] != [NSNull null]) {
        NSMutableOrderedSet *orderedActivities = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"activities"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Activity *activity = [Activity MR_findFirstWithPredicate:predicate];
            if (!activity){
                activity = [Activity MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [activity populateFromDictionary:dict];
            [orderedActivities addObject:activity];
        }
        for (Activity *activity in self.activities) {
            if (![orderedActivities containsObject:activity]){
                [activity MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.activities = orderedActivities;
    }
}

- (void)update:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"order_index"] && [dictionary objectForKey:@"order_index"] != [NSNull null]) {
        self.orderIndex = [dictionary objectForKey:@"order_index"];
    }
    if ([dictionary objectForKey:@"item_type"] && [dictionary objectForKey:@"item_type"] != [NSNull null]) {
        self.type = [dictionary objectForKey:@"item_type"];
    }
    if ([dictionary objectForKey:@"state"] && [dictionary objectForKey:@"state"] != [NSNull null]) {
        self.state = [dictionary objectForKey:@"state"];
    } else {
        self.state = nil;
    }
    if ([dictionary objectForKey:@"photos_count"] && [dictionary objectForKey:@"photos_count"] != [NSNull null]) {
        self.photosCount = [dictionary objectForKey:@"photos_count"];
    }
    if ([dictionary objectForKey:@"critical_date"] && [dictionary objectForKey:@"critical_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"critical_date"] doubleValue];
        self.criticalDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"completed_date"] && [dictionary objectForKey:@"completed_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"completed_date"] doubleValue];
        self.completedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"comments_count"] && [dictionary objectForKey:@"comments_count"] != [NSNull null]) {
        self.commentsCount = [dictionary objectForKey:@"comments_count"];
    }
    if ([dictionary objectForKey:@"comments"] && [dictionary objectForKey:@"comments"] != [NSNull null]) {
        NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSet];
        //NSLog(@"checklist item comments %@",[dictionary objectForKey:@"comments"]);
        for (id commentDict in [dictionary objectForKey:@"comments"]){
            NSPredicate *commentPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [commentDict objectForKey:@"id"]];
            Comment *comment = [Comment MR_findFirstWithPredicate:commentPredicate];
            if (comment){
                [comment update:commentDict];
            } else {
                comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [comment populateFromDictionary:commentDict];
            }
            
            [orderedComments addObject:comment];
        }
        self.comments = orderedComments;
    }
    
    if ([dictionary objectForKey:@"reminders"] && [dictionary objectForKey:@"reminders"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        //NSLog(@"checklist item reminders %@",[dictionary objectForKey:@"reminders"]);
        for (id dict in [dictionary objectForKey:@"reminders"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Reminder *reminder = [Reminder MR_findFirstWithPredicate:predicate];
            if (!reminder){
                reminder = [Reminder MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [reminder populateFromDictionary:dict];
            [set addObject:reminder];
        }
        for (Reminder *reminder in self.reminders) {
            if (![set containsObject:reminder]){
                NSLog(@"Deleting a reminder that no longer exists for checklist item: %@",self.identifier);
                [reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reminders = set;
    }
    
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSet];
        for (id photoDict in [dictionary objectForKey:@"photos"]){
            NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [photoDict objectForKey:@"id"]];
            Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate];
            if (photo){
                [photo update:photoDict];
            } else {
                photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [photo populateFromDictionary:photoDict];
            }
            
            [orderedPhotos addObject:photo];
        }
        for (Photo *photo in self.photos) {
            if (![orderedPhotos containsObject:photo]){
                [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.photos = orderedPhotos;
    }
    
    if ([dictionary objectForKey:@"activities"] && [dictionary objectForKey:@"activities"] != [NSNull null]) {
        NSMutableOrderedSet *orderedActivities = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"activities"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Activity *activity = [Activity MR_findFirstWithPredicate:predicate];
            if (!activity){
                activity = [Activity MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [activity populateFromDictionary:dict];
            [orderedActivities addObject:activity];
        }
        for (Activity *activity in self.activities) {
            if (![orderedActivities containsObject:activity]){
                [activity MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.activities = orderedActivities;
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

-(void)addReminder:(Reminder *)reminder {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reminders];
    [set addObject:reminder];
    self.reminders = set;
}
-(void)removeReminder:(Reminder *)reminder {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reminders];
    [set removeObject:reminder];
    self.reminders = set;
}

@end
