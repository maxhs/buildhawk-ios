//
//  Activity+helper.m
//  
//
//  Created by Max Haines-Stiles on 6/26/14.
//
//

#import "Activity+helper.h"
#import "ChecklistItem+helper.h"
#import "Task+helper.h"
#import "Report+helper.h"
#import "Tasklist.h"
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
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"activity_type"] && [dictionary objectForKey:@"activity_type"] != [NSNull null]) {
        self.activityType = [dictionary objectForKey:@"activity_type"];
    }
    if ([dictionary objectForKey:@"project_id"] && [dictionary objectForKey:@"project_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"project_id"]];
        Project *project = [Project MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            project.identifier = [dictionary objectForKey:@"project_id"];
        }
        self.project = project;
    }
    
#pragma mark - Populate Checklist
    if ([dictionary objectForKey:@"checklist_id"] && [dictionary objectForKey:@"checklist_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"checklist_id"]];
        Checklist *checklist = [Checklist MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!checklist){
            checklist = [Checklist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            checklist.identifier = [dictionary objectForKey:@"checklist_id"];
        }
        
        //ensure that, since this is a checklist item activity, we attach it to a checklist (and that the checklist also has a project reference)
        if (self.project)
            checklist.project = self.project;
        
        //assign the checklist to self
        self.checklist = checklist;
    }
    if ([dictionary objectForKey:@"checklist_item"] && [dictionary objectForKey:@"checklist_item"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"checklist_item"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (item){
            [item updateFromDictionary:dict];
        } else {
            item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [item populateFromDictionary:dict];
        }
        self.checklistItem = item;
    } else if ([dictionary objectForKey:@"checklist_item_id"] && [dictionary objectForKey:@"checklist_item_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"checklist_item_id"]];
        ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!item){
            item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            item.identifier = [dictionary objectForKey:@"checklist_item_id"];
        }
        self.checklistItem = item;
    }

#pragma mark - Populate Task
    if ([dictionary objectForKey:@"tasklist_id"] && [dictionary objectForKey:@"tasklist_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"tasklist_id"]];
        Tasklist *tasklist = [Tasklist MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!tasklist){
            tasklist = [Tasklist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            tasklist.identifier = [dictionary objectForKey:@"tasklist_id"];
        }
        
        //ensure that, since this is a task activity, we attach it to a tasklist (and that the task also has a project reference)
        if (self.project)
            tasklist.project = self.project;
        
        self.tasklist = tasklist;
    }
    if ([dictionary objectForKey:@"task"] && [dictionary objectForKey:@"task"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"task"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Task *task = [Task MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!task){
            task = [Task MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [task populateFromDictionary:dict];
        self.task = task;
    } else if ([dictionary objectForKey:@"task_id"] && [dictionary objectForKey:@"task_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"task_id"]];
        Task *task = [Task MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!task){
            task = [Task MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            task.identifier = [dictionary objectForKey:@"task_id"];
        }
        self.task = task;
    }
    
#pragma mark - Populate Photos / Documents
    if ([dictionary objectForKey:@"photo"] && [dictionary objectForKey:@"photo"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"photo"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Photo *photo = [Photo MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (photo){
            [photo updateFromDictionary:dict];
        } else {
            photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [photo populateFromDictionary:dict];
        }
        self.photo = photo;
    }
    
#pragma mark - Populate Report
    if ([dictionary objectForKey:@"report"] && [dictionary objectForKey:@"report"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"report"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Report *report = [Report MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!report){
            report = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [report populateWithDict:dict];
        self.report = report;
    } else if ([dictionary objectForKey:@"report_id"] && [dictionary objectForKey:@"report_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"report_id"]];
        Report *report = [Report MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!report){
            report = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            report.identifier = [dictionary objectForKey:@"report_id"];
        }
        self.report = report;
    }
    
#pragma mark - Populate Comment
    if ([dictionary objectForKey:@"comment"] && [dictionary objectForKey:@"comment"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"comment"] objectForKey:@"id" ]];
        Comment *comment = [Comment MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (comment){
            [comment updateFromDictionary:[dictionary objectForKey:@"comment"]];
        } else {
            comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [comment populateFromDictionary:[dictionary objectForKey:@"comment"]];
        }
        self.comment = comment;
    }
    if ([dictionary objectForKey:@"user_id"] && [dictionary objectForKey:@"user_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"user_id"]];
        User *user = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            user.identifier = [dictionary objectForKey:@"user_id"];
        }
        self.user = user;
    }
}
@end
