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
#import "ChecklistItem+helper.h"
#import "Address+helper.h"
#import "Company+helper.h"
#import "Photo+helper.h"
#import "Group+helper.h"
#import "Activity+helper.h"

@implementation Project (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"company"] && [dictionary objectForKey:@"company"] != [NSNull null]) {
        NSDictionary *companyDict = [dictionary objectForKey:@"company"];
        Company *company = [Company MR_findFirstByAttribute:@"identifier" withValue:[companyDict objectForKey:@"id"]];
        if (!company){
            company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [company populateWithDict:companyDict];
        self.company = company;
    }
    
    if ([dictionary objectForKey:@"active"] && [dictionary objectForKey:@"active"] != [NSNull null]) {
        self.active = [NSNumber numberWithBool:[[dictionary objectForKey:@"active"] boolValue]];
    }
    if ([dictionary objectForKey:@"core"] && [dictionary objectForKey:@"core"] != [NSNull null]) {
        self.demo = [NSNumber numberWithBool:[[dictionary objectForKey:@"core"] boolValue]];
    }
    
    if ([dictionary objectForKey:@"users"] && [dictionary objectForKey:@"users"] != [NSNull null]) {
        //NSLog(@"project users: %@",[dictionary objectForKey:@"users"]);
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (id userDict in [dictionary objectForKey:@"users"]){
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate];
            if (!user){
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDictionary:userDict];
            [orderedUsers addObject:user];
        }
        self.users = orderedUsers;
    }
    
    if ([dictionary objectForKey:@"companies"] && [dictionary objectForKey:@"companies"] != [NSNull null]) {
        //NSLog(@"project subs: %@",[dictionary objectForKey:@"subcontractors"]);
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"companies"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Subcontractor *subcontractor = [Subcontractor MR_findFirstWithPredicate:predicate];
            if (!subcontractor){
                subcontractor = [Subcontractor MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [subcontractor populateFromDictionary:dict];
            [set addObject:subcontractor];
        }
        self.subcontractors = set;
    }
    
    if ([dictionary objectForKey:@"address"] && [dictionary objectForKey:@"address"] != [NSNull null]) {
        NSDictionary *addressDict = [dictionary objectForKey:@"address"];
        Address *address = [Address MR_findFirstByAttribute:@"identifier" withValue:[addressDict objectForKey:@"id"]];
        if (!address) {
            address = [Address MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [address populateWithDict:addressDict];
        self.address = address;
    }
    if ([dictionary objectForKey:@"project_group"] && [dictionary objectForKey:@"project_group"] != [NSNull null]) {
        NSDictionary *groupDict = [dictionary objectForKey:@"project_group"];
        Group *group = [Group MR_findFirstByAttribute:@"identifier" withValue:[groupDict objectForKey:@"id"]];
        if (!group) {
            group = [Group MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [group populateWithDict:[dictionary objectForKey:@"project_group"]];
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
                Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate];
                if (!photo){
                    photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [photo populateFromDictionary:photoDict];
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
        NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSet];
        //NSLog(@"project photos %@",[dictionary objectForKey:@"photos"]);
        for (id photoDict in [dictionary objectForKey:@"photos"]){
            if ([photoDict objectForKey:@"id"]){
                NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [photoDict objectForKey:@"id"]];
                Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate];
                if (!photo){
                    photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [photo populateFromDictionary:photoDict];
                [orderedPhotos addObject:photo];
            }
        }
        self.documents = orderedPhotos;
    }
    
    if ([dictionary objectForKey:@"phases"] && [dictionary objectForKey:@"phases"] != [NSNull null]) {
        NSMutableOrderedSet *tmpPhases = [NSMutableOrderedSet orderedSet];
        for (id phaseDict in [dictionary objectForKey:@"phases"]){
            if ([phaseDict objectForKey:@"id"]){
                NSPredicate *phasePredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [phaseDict objectForKey:@"id"]];
                //on the api, we're actually callign a category a "phase"
                Phase *phase = [Phase MR_findFirstWithPredicate:phasePredicate];
                if (phase){
                    [phase populateFromDictionary:phaseDict];
                } else {
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
        NSMutableOrderedSet *tmpUpcoming = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.upcomingItems];
        for (id itemDict in [dictionary objectForKey:@"upcoming_items"]){
            if ([itemDict objectForKey:@"id"]){
                NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [itemDict objectForKey:@"id"]];
                //on the api, we're actually callign a category a "phase"
                ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:itemPredicate];
                if (item){
                    [item populateFromDictionary:itemDict];
                } else {
                    item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [item populateFromDictionary:itemDict];
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
                ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:itemPredicate];
                if (item){
                    [item populateFromDictionary:itemDict];
                } else {
                    item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [item populateFromDictionary:itemDict];
                }
                [item populateFromDictionary:itemDict];
                [tmpRecent addObject:item];
            }
        }
        self.recentItems = tmpRecent;
    }
    
    if ([dictionary objectForKey:@"activities"] && [dictionary objectForKey:@"activities"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        //NSLog(@"project activities %@",[dictionary objectForKey:@"activities"]);
        for (id dict in [dictionary objectForKey:@"activities"]){
            if ([dict objectForKey:@"id"]){
                NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                Activity *activity = [Activity MR_findFirstWithPredicate:photoPredicate];
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
    
    if ([dictionary objectForKey:@"active_reminders"] && [dictionary objectForKey:@"active_reminders"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        //NSLog(@"project activities %@",[dictionary objectForKey:@"activities"]);
        for (id dict in [dictionary objectForKey:@"active_reminders"]){
            if ([dict objectForKey:@"id"]){
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                Reminder *reminder = [Reminder MR_findFirstWithPredicate:predicate];
                if (!reminder){
                    reminder = [Reminder MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [reminder populateFromDictionary:dict];
                [set addObject:reminder];
            }
        }
        for (Reminder *reminder in self.reminders){
            if (![set containsObject:reminder]){
                NSLog(@"Deleting an active reminder that no longer exists.");
                [reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reminders = set;
    }
}

- (void)update:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"company"] && [dictionary objectForKey:@"company"] != [NSNull null]) {
        NSDictionary *companyDict = [dictionary objectForKey:@"company"];
        Company *company = [Company MR_findFirstByAttribute:@"identifier" withValue:[companyDict objectForKey:@"id"]];
        if (company){
        
        } else {
            company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [company populateWithDict:companyDict];
        }
        
        self.company = company;
    }
    
    if ([dictionary objectForKey:@"active"] && [dictionary objectForKey:@"active"] != [NSNull null]) {
        self.active = [NSNumber numberWithBool:[[dictionary objectForKey:@"active"] boolValue]];
    }
    if ([dictionary objectForKey:@"core"] && [dictionary objectForKey:@"core"] != [NSNull null]) {
        self.demo = [NSNumber numberWithBool:[[dictionary objectForKey:@"core"] boolValue]];
    }
    
    if ([dictionary objectForKey:@"users"] && [dictionary objectForKey:@"users"] != [NSNull null]) {
        //NSLog(@"project users: %@",[dictionary objectForKey:@"users"]);
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (id userDict in [dictionary objectForKey:@"users"]){
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate];
            if (user){
                [user update:userDict];
            } else {
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDictionary:userDict];
            [orderedUsers addObject:user];
        }
        self.users = orderedUsers;
    }
    
    if ([dictionary objectForKey:@"companies"] && [dictionary objectForKey:@"companies"] != [NSNull null]) {
        //NSLog(@"project subs: %@",[dictionary objectForKey:@"subcontractors"]);
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"companies"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Subcontractor *subcontractor = [Subcontractor MR_findFirstWithPredicate:predicate];
            if (!subcontractor){
                subcontractor = [Subcontractor MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [subcontractor populateFromDictionary:dict];
            [set addObject:subcontractor];
        }
        self.subcontractors = set;
    }
    
    if ([dictionary objectForKey:@"address"] && [dictionary objectForKey:@"address"] != [NSNull null]) {
        NSDictionary *addressDict = [dictionary objectForKey:@"address"];
        Address *address = [Address MR_findFirstByAttribute:@"identifier" withValue:[addressDict objectForKey:@"id"]];
        if (!address) {
            address = [Address MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [address populateWithDict:addressDict];
        self.address = address;
    }
    if ([dictionary objectForKey:@"project_group"] && [dictionary objectForKey:@"project_group"] != [NSNull null]) {
        NSDictionary *groupDict = [dictionary objectForKey:@"project_group"];
        Group *group = [Group MR_findFirstByAttribute:@"identifier" withValue:[groupDict objectForKey:@"id"]];
        if (!group) {
            group = [Group MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [group populateWithDict:[dictionary objectForKey:@"project_group"]];
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
                Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate];
                if (!photo){
                    photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [photo populateFromDictionary:photoDict];
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
        NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSet];
        //NSLog(@"project photos %@",[dictionary objectForKey:@"photos"]);
        for (id photoDict in [dictionary objectForKey:@"photos"]){
            if ([photoDict objectForKey:@"id"]){
                NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [photoDict objectForKey:@"id"]];
                Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate];
                if (!photo){
                    photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [photo populateFromDictionary:photoDict];
                [orderedPhotos addObject:photo];
            }
        }
        self.documents = orderedPhotos;
    }
    
    if ([dictionary objectForKey:@"phases"] && [dictionary objectForKey:@"phases"] != [NSNull null]) {
        NSMutableOrderedSet *tmpPhases = [NSMutableOrderedSet orderedSet];
        for (id phaseDict in [dictionary objectForKey:@"phases"]){
            if ([phaseDict objectForKey:@"id"]){
                NSPredicate *phasePredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [phaseDict objectForKey:@"id"]];
                //on the api, we're actually callign a category a "phase"
                Phase *phase = [Phase MR_findFirstWithPredicate:phasePredicate];
                if (phase){
                    [phase populateFromDictionary:phaseDict];
                } else {
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
        NSMutableOrderedSet *tmpUpcoming = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.upcomingItems];
        for (id itemDict in [dictionary objectForKey:@"upcoming_items"]){
            if ([itemDict objectForKey:@"id"]){
                NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [itemDict objectForKey:@"id"]];
                //on the api, we're actually callign a category a "phase"
                ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:itemPredicate];
                if (item){
                    [item populateFromDictionary:itemDict];
                } else {
                    item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [item populateFromDictionary:itemDict];
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
                ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:itemPredicate];
                if (item){
                    [item populateFromDictionary:itemDict];
                } else {
                    item = [ChecklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [item populateFromDictionary:itemDict];
                }
                [item populateFromDictionary:itemDict];
                [tmpRecent addObject:item];
            }
        }
        self.recentItems = tmpRecent;
    }
    
    if ([dictionary objectForKey:@"activities"] && [dictionary objectForKey:@"activities"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        //NSLog(@"project activities %@",[dictionary objectForKey:@"activities"]);
        for (id dict in [dictionary objectForKey:@"activities"]){
            if ([dict objectForKey:@"id"]){
                NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                Activity *activity = [Activity MR_findFirstWithPredicate:photoPredicate];
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
    
    if ([dictionary objectForKey:@"active_reminders"] && [dictionary objectForKey:@"active_reminders"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        //NSLog(@"project activities %@",[dictionary objectForKey:@"activities"]);
        for (id dict in [dictionary objectForKey:@"active_reminders"]){
            if ([dict objectForKey:@"id"]){
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                Reminder *reminder = [Reminder MR_findFirstWithPredicate:predicate];
                if (!reminder){
                    reminder = [Reminder MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [reminder populateFromDictionary:dict];
                [set addObject:reminder];
            }
        }
        for (Reminder *reminder in self.reminders){
            if (![set containsObject:reminder]){
                NSLog(@"Deleting an active reminder that no longer exists.");
                [reminder MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reminders = set;
    }
}


- (void)parseDocuments:(NSArray *)array {
    NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSet];
    for (NSDictionary *photoDict in array){
        Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[photoDict objectForKey:@"id"]];
        if (!photo){
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
    [set addObject:report];
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


@end
