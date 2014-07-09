//
//  Activity+helper.m
//  
//
//  Created by Max Haines-Stiles on 6/26/14.
//
//

#import "Activity+helper.h"
#import "ChecklistItem+helper.h"
#import "WorklistItem+helper.h"
#import "Report+helper.h"
#import "Worklist.h"
#import "Comment+helper.h"

@implementation Activity (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"Activity dict: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_date"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"activity_type"] && [dictionary objectForKey:@"activity_type"] != [NSNull null]) {
        self.activityType = [dictionary objectForKey:@"activity_type"];
    }
    if ([dictionary objectForKey:@"checklist_item"] && [dictionary objectForKey:@"checklist_item"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"checklist_item"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:predicate];
        if (item){
            [item update:dict];
        } else {
            item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [item populateFromDictionary:dict];
        }
        self.checklistItem = item;
    }
    
    if ([dictionary objectForKey:@"photo"] && [dictionary objectForKey:@"photo"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"photo"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Photo *photo = [Photo MR_findFirstWithPredicate:predicate];
        if (photo){
            [photo update:dict];
        } else {
            photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [photo populateFromDictionary:dict];
        }
        self.photo = photo;
    }
    
    if ([dictionary objectForKey:@"checklist_id"] && [dictionary objectForKey:@"checklist_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"checklist_id"]];
        Checklist *checklist = [Checklist MR_findFirstWithPredicate:predicate];
        if (checklist){
            self.checklist = checklist;
        }
    }
    
    if ([dictionary objectForKey:@"project_id"] && [dictionary objectForKey:@"project_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"project_id"]];
        Project *project = [Project MR_findFirstWithPredicate:predicate];
        if (project){
            self.project = project;
        }
    }
    if ([dictionary objectForKey:@"worklist_item"] && [dictionary objectForKey:@"worklist_item"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"worklist_item"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        WorklistItem *task = [WorklistItem MR_findFirstWithPredicate:predicate];
        if (!task){
            task = [WorklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [task populateFromDictionary:dict];
        self.task = task;
    }
    if ([dictionary objectForKey:@"worklist_id"] && [dictionary objectForKey:@"worklist_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"worklist_id"]];
        Worklist *worklist = [Worklist MR_findFirstWithPredicate:predicate];
        if (worklist){
            self.worklist = worklist;
        }
    }
    if ([dictionary objectForKey:@"report"] && [dictionary objectForKey:@"report"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"report"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Report *report = [Report MR_findFirstWithPredicate:predicate];
        if (!report){
            report = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [report populateWithDict:dict];
        self.report = report;
    }
    if ([dictionary objectForKey:@"comment"] && [dictionary objectForKey:@"comment"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"comment"] objectForKey:@"id" ]];
        Comment *comment = [Comment MR_findFirstWithPredicate:predicate];
        if (comment){
            [comment update:[dictionary objectForKey:@"comment"]];
        } else {
            comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [comment populateFromDictionary:[dictionary objectForKey:@"comment"]];
        }
        self.comment = comment;
    }
    if ([dictionary objectForKey:@"user_id"] && [dictionary objectForKey:@"user_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"user_id"]];
        User *user = [User MR_findFirstWithPredicate:predicate];
        if (user){
            self.user = user;
        }
    }
}
@end
