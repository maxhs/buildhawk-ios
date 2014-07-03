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
    if ([dictionary objectForKey:@"checklist_item_id"] && [dictionary objectForKey:@"checklist_item_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"checklist_item_id"]];
        ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:predicate];
        if (item){
            self.checklistItem = item;
            self.checklist = item.checklist;
        }
    }
    if ([dictionary objectForKey:@"project_id"] && [dictionary objectForKey:@"project_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"project_id"]];
        Project *project = [Project MR_findFirstWithPredicate:predicate];
        if (project){
            self.project = project;
        }
    }
    if ([dictionary objectForKey:@"worklist_item_id"] && [dictionary objectForKey:@"worklist_item_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"worklist_item_id"]];
        WorklistItem *task = [WorklistItem MR_findFirstWithPredicate:predicate];
        if (task){
            self.task = task;
        }
    }
    if ([dictionary objectForKey:@"report_id"] && [dictionary objectForKey:@"report_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"report_id"]];
        Report *report = [Report MR_findFirstWithPredicate:predicate];
        if (report){
            self.report = report;
        }
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
