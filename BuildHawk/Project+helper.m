//
//  Project+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Project+helper.h"
#import "Phase+helper.h"
#import "Subcontractor+helper.h"
#import "Checklist+helper.h"
#import "ChecklistItem+helper.h"
#import "Address+helper.h"
#import "Company+helper.h"
#import "Photo+helper.h"
#import "Group+helper.h"
#import "Activity+helper.h"
#import "Report+helper.h"
#import "Reminder+helper.h"
#import "Tasklist+helper.h"

@implementation Project (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"project dict: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"company"] && [dictionary objectForKey:@"company"] != [NSNull null]) {
        NSDictionary *companyDict = [dictionary objectForKey:@"company"];
        Company *company = [Company MR_findFirstByAttribute:@"identifier" withValue:[companyDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (company){
            [company updateFromDictionary:companyDict];
        } else {
            company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [company populateFromDictionary:companyDict];
        }
        
        self.company = company;
    }
    
    if ([dictionary objectForKey:@"core"] && [dictionary objectForKey:@"core"] != [NSNull null]) {
        self.demo = [NSNumber numberWithBool:[[dictionary objectForKey:@"core"] boolValue]];
    }
    
    if ([dictionary objectForKey:@"active"] && [dictionary objectForKey:@"active"] != [NSNull null]) {
        self.active = [dictionary objectForKey:@"active"];
    }
    
    //if the project is explicitly set to hidden, it means it should be hidden!
    if ([dictionary objectForKey:@"hidden"] && [dictionary objectForKey:@"hidden"] != [NSNull null]) {
        self.hidden = [dictionary objectForKey:@"hidden"];
    }
    //if a project is marked as visible, it means it isn't hidden
    if ([dictionary objectForKey:@"visible"] && [dictionary objectForKey:@"visible"] != [NSNull null]) {
        self.hidden = @NO;
    }
    
    if ([dictionary objectForKey:@"order_index"] && [dictionary objectForKey:@"order_index"] != [NSNull null]) {
        self.orderIndex = [dictionary objectForKey:@"order_index"];
    }
    
    if ([dictionary objectForKey:@"users"] && [dictionary objectForKey:@"users"] != [NSNull null]) {
        //NSLog(@"project users: %@",[dictionary objectForKey:@"users"]);
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (id userDict in [dictionary objectForKey:@"users"]){
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (user){
                [user updateFromDictionary:userDict];
            } else {
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [user populateFromDictionary:userDict];
            }
            [orderedUsers addObject:user];
        }
        self.users = orderedUsers;
    }
    
    if ([dictionary objectForKey:@"companies"] && [dictionary objectForKey:@"companies"] != [NSNull null]) {
        //NSLog(@"project subs: %@",[dictionary objectForKey:@"subcontractors"]);
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"companies"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Company *company = [Company MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!company){
                company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [company populateFromDictionary:dict];
            [set addObject:company];
        }
        self.companies = set;
    }
    
    if ([dictionary objectForKey:@"address"] && [dictionary objectForKey:@"address"] != [NSNull null]) {
        NSDictionary *addressDict = [dictionary objectForKey:@"address"];
        Address *address = [Address MR_findFirstByAttribute:@"identifier" withValue:[addressDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!address) {
            address = [Address MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [address populateWithDict:addressDict];
        self.address = address;
    }
    if ([dictionary objectForKey:@"project_group"] && [dictionary objectForKey:@"project_group"] != [NSNull null]) {
        NSDictionary *groupDict = [dictionary objectForKey:@"project_group"];
        Group *group = [Group MR_findFirstByAttribute:@"identifier" withValue:[groupDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (group) {
            [group updateWithDictionary:[dictionary objectForKey:@"project_group"]];
        } else {
            group = [Group MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
             [group populateWithDictionary:[dictionary objectForKey:@"project_group"]];
        }
       
        self.group = group;
    }
    
    if ([dictionary objectForKey:@"progress"] && [dictionary objectForKey:@"progress"] != [NSNull null]) {
        self.progressPercentage = [dictionary objectForKey:@"progress"];
    }
    
    if ([dictionary objectForKey:@"recent_documents"] && [dictionary objectForKey:@"recent_documents"] != [NSNull null]) {
        NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSet];
        //NSLog(@"project recent documents %@",[dictionary objectForKey:@"recent_documents"]);
        for (id photoDict in [dictionary objectForKey:@"recent_documents"]){
            if ([photoDict objectForKey:@"id"]){
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
        }
        for (Photo *photo in self.recentDocuments){
            if (![orderedPhotos containsObject:photo]){
                NSLog(@"Deleting a recent document that no longer exists.");
                [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        if (orderedPhotos.count > 0) self.recentDocuments = orderedPhotos;
    }
    
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        [self parseDocuments:[dictionary objectForKey:@"photos"]];
    }
    
    //checklist stuff
    if ([dictionary objectForKey:@"checklist"] && [dictionary objectForKey:@"checklist"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"checklist"];
        Checklist *checklist = [Checklist MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!checklist) {
            checklist = [Checklist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [checklist populateFromDictionary:dict];
        self.checklist = checklist;
    }
    if ([dictionary objectForKey:@"phases"] && [dictionary objectForKey:@"phases"] != [NSNull null]) {
        NSMutableOrderedSet *tmpPhases = [NSMutableOrderedSet orderedSet];
        for (id phaseDict in [dictionary objectForKey:@"phases"]){
            if ([phaseDict objectForKey:@"id"]){
                NSPredicate *phasePredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [phaseDict objectForKey:@"id"]];
                Phase *phase = [Phase MR_findFirstWithPredicate:phasePredicate inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!phase){
                    phase = [Phase MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    phase.name = [phaseDict objectForKey:@"name"];
                }
                [phase populateFromDictionary:phaseDict];
                [tmpPhases addObject:phase];
            }
        }
        self.phases = tmpPhases;
    }
    if ([dictionary objectForKey:@"upcoming_items"] && [dictionary objectForKey:@"upcoming_items"] != [NSNull null]) {
        NSMutableOrderedSet *tmpUpcoming = [NSMutableOrderedSet orderedSet];
        for (id itemDict in [dictionary objectForKey:@"upcoming_items"]){
            if ([itemDict objectForKey:@"id"]){
                NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [itemDict objectForKey:@"id"]];
                ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:itemPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!item){
                    item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [item populateFromDictionary:itemDict];
                [tmpUpcoming addObject:item];
            }
        }
        
        self.upcomingItems = tmpUpcoming;
    }
    if ([dictionary objectForKey:@"recently_completed"] && [dictionary objectForKey:@"recently_completed"] != [NSNull null]) {
        NSMutableOrderedSet *tmpRecent = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.recentItems];
        for (id itemDict in [dictionary objectForKey:@"recently_completed"]){
            if ([itemDict objectForKey:@"id"]){
                NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [itemDict objectForKey:@"id"]];
                ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:itemPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!item){
                    item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [item populateFromDictionary:itemDict];
                [tmpRecent addObject:item];
            }
        }
        self.recentItems = tmpRecent;
    }
    
    if ([dictionary objectForKey:@"recent_activities"] && [dictionary objectForKey:@"recent_activities"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        NSDictionary *recentDict = [dictionary objectForKey:@"recent_activities"];
        //NSLog(@"project activities %@",recentDict);
        for (id dict in recentDict){
            if ([dict objectForKey:@"id"]){
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                Activity *activity = [Activity MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!activity){
                    activity = [Activity MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [activity populateFromDictionary:dict];
                [set addObject:activity];
            }
        }
        for (Activity *activity in self.activities){
            if (![set containsObject:activity]){
                NSLog(@"Deleting an activity that no longer exists.");
                [activity MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.activities = set;
    }
    
    if ([dictionary objectForKey:@"reminders"] && [dictionary objectForKey:@"reminders"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        NSMutableOrderedSet *pastDueSet = [NSMutableOrderedSet orderedSet];
        //NSLog(@"project reminders %@",[dictionary objectForKey:@"reminders"]);
        for (id dict in [dictionary objectForKey:@"reminders"]){
            if ([dict objectForKey:@"id"]){
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                Reminder *reminder = [Reminder MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!reminder){
                    reminder = [Reminder MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [reminder populateFromDictionary:dict];
                if ([reminder.reminderDate compare:[NSDate date]] == NSOrderedAscending){
                    [pastDueSet addObject:reminder];
                } else {
                    [set addObject:reminder];
                }
            }
        }
        for (Reminder *reminder in self.reminders){
            if (![set containsObject:reminder] && ![pastDueSet containsObject:reminder]){
                NSLog(@"Deleting a reminder that no longer exists.");
                [reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.pastDueReminders = pastDueSet;
        self.reminders = set;
    }
    
    if ([dictionary objectForKey:@"reports"] && [dictionary objectForKey:@"reports"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        //NSLog(@"project reports %@",[dictionary objectForKey:@"reports"]);
        for (id dict in [dictionary objectForKey:@"reports"]){
            if ([dict objectForKey:@"id"]){
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                Report *report = [Report MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!report){
                    report = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [report populateFromDictionary:dict];
                [set addObject:report];
            }
        }
        for (Report *report in self.reports){
            if (![set containsObject:report]){
                [report MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reports = set;
    }
    
    if ([dictionary objectForKey:@"tasklists"] && [dictionary objectForKey:@"tasklists"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"tasklists"]){
            if ([dict objectForKey:@"id"]){
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                Tasklist *tasklist = [Tasklist MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!tasklist){
                    tasklist = [Tasklist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [tasklist populateFromDictionary:dict];
                [set addObject:tasklist];
            }
        }
        for (Tasklist *tasklist in self.tasklists){
            if (![set containsObject:tasklist]){
                NSLog(@"Deleting a tasklist that no longer exists.");
                [tasklist MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.tasklists = set;
    }
}

- (void)parseDocuments:(NSArray *)array {
    NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSet];
    for (NSDictionary *photoDict in array){
        Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[photoDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (photo){
            [photo updateFromDictionary:photoDict];
        } else {
            photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [photo populateFromDictionary:photoDict];
        [photos addObject:photo];
    }
    for (Photo *photo in self.documents){
        if (![photos containsObject:photo]){
            NSLog(@"Deleting photo that no longer exists: %@",photo.dateString);
            [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }
    self.documents = photos;
}

-(void)addPhoto:(Photo *)photo {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.documents];
    [set addObject:photo];
    self.documents = set;
}
-(void)removePhoto:(Photo *)photo {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.documents];
    [set removeObject:photo];
    self.documents = set;
}

-(void)addReport:(Report *)report {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reports];
    [set insertObject:report atIndex:0];
    self.reports = set;
}
-(void)removeReport:(Report *)report {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reports];
    [set removeObject:report];
    self.reports = set;
}

- (void)clearReports {
    for (Report *report in self.reports) {
        [report MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    }
}

-(void)addCompany:(Company *)company {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.companies];
    [set addObject:company];
    self.companies = set;
}
-(void)removeCompany:(Company *)company {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.companies];
    [set removeObject:company];
    self.companies = set;
}

- (Tasklist*)tasklist {
    return self.tasklists.firstObject;
}

@end
