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

@implementation ChecklistItem (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"checklist item helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
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
    if ([dictionary objectForKey:@"status"] && [dictionary objectForKey:@"status"] != [NSNull null]) {
        self.status = [dictionary objectForKey:@"status"];
    }
    if ([dictionary objectForKey:@"photos_count"] && [dictionary objectForKey:@"photos_count"] != [NSNull null]) {
        self.photosCount = [dictionary objectForKey:@"photos_count"];
    }
    if ([dictionary objectForKey:@"critical_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"critical_date"] doubleValue];
        self.criticalDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"completed_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"completed_date"] doubleValue];
        self.completedDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"comments"] && [dictionary objectForKey:@"comments"] != [NSNull null]) {
        NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSetWithOrderedSet:self.comments];
        //NSLog(@"checklist item comments %@",[dictionary objectForKey:@"comments"]);
        for (id commentDict in [dictionary objectForKey:@"comments"]){
            NSPredicate *commentPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [commentDict objectForKey:@"id"]];
            Comment *comment = [Comment MR_findFirstWithPredicate:commentPredicate];
            if (!comment){
                comment = [Comment MR_createEntity];
            }
            [comment populateFromDictionary:commentDict];
            [orderedComments addObject:comment];
        }
        self.comments = orderedComments;
    }
    if ([dictionary objectForKey:@"photos"] != [NSNull null]) {
        NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
        for (id photoDict in [dictionary objectForKey:@"photos"]){
            NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [photoDict objectForKey:@"id"]];
            Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate];
            if (!photo){
                photo = [Photo MR_createEntity];
                NSLog(@"couldn't find saved checklist item photo, created a new one: %@",photo.createdDate);
            }
            [photo populateFromDictionary:photoDict];
            [orderedPhotos addObject:photo];
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

/*- (void)setValue:(id)value forKey:(NSString *)key {
 if ([key isEqualToString:@"id"]) {
 self.identifier = value;
 } else if ([key isEqualToString:@"category_name"]) {
 self.category = value;
 } else if ([key isEqualToString:@"subcategory_name"]) {
 self.subcategory = value;
 } else if ([key isEqualToString:@"body"]) {
 self.body = value;
 } else if ([key isEqualToString:@"item_type"]) {
 self.type = value;
 } else if ([key isEqualToString:@"status"]) {
 self.status = value;
 } else if ([key isEqualToString:@"photos_count"]) {
 if (value != [NSNull null] && value != nil) {
 self.photosCount = value;
 }
 } else if ([key isEqualToString:@"comments_count"]) {
 if (value != [NSNull null] && value != nil) {
 self.commentsCount = value;
 }
 } else if ([key isEqualToString:@"completed_date"] && value != [NSNull null]) {
 if ([self.status isEqualToString:kCompleted]) self.completed = YES;
 } else if ([key isEqualToString:@"photos"]) {
 self.photos = [BHUtilities photosFromJSONArray:value];
 } else if ([key isEqualToString:@"comments"]) {
 self.comments = [BHUtilities commentsFromJSONArray:value];
 } else if ([key isEqualToString:@"project_id"]) {
 self.projectId = value;
 }
 }*/

@end
