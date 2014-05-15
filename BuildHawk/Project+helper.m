//
//  Project+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Project+helper.h"
#import "Phase+helper.h"
#import "ChecklistItem+helper.h"
#import "Address.h"
#import "Company+helper.h"
#import "Photo+helper.h"

@implementation Project (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"project helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"company"]) {
        NSDictionary *companyDict = [dictionary objectForKey:@"company"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [companyDict objectForKey:@"id"]];
        Company *company = [Company MR_findFirstWithPredicate:predicate];
        if (company){
            //NSLog(@"MR_found company: %@",self.company.identifier);
        } else {
            company = [Company MR_createEntity];
            //NSLog(@"Couldn't find the company. Creating a new one: %@",self.company.identifier);
        }
        [company populateWithDict:companyDict];
        self.company = company;
    }
    
    if ([dictionary objectForKey:@"active"]) {
        self.active = [NSNumber numberWithBool:[[dictionary objectForKey:@"active"] boolValue]];
    }
    
    if ([dictionary objectForKey:@"core"]) {
        self.demo = [NSNumber numberWithBool:[[dictionary objectForKey:@"core"] boolValue]];
    }
    
    if ([dictionary objectForKey:@"users"] && [dictionary objectForKey:@"users"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSetWithOrderedSet:self.users];
        for (id userDict in [dictionary objectForKey:@"users"]){
            NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:userPredicate];
            if (!user){
                user = [User MR_createEntity];
                NSLog(@"couldn't find saved user, created a new one: %@",user.fullname);
            }
            [user populateFromDictionary:userDict];
            [orderedUsers addObject:user];
        }
        self.users = orderedUsers;
    }
    
    if ([dictionary objectForKey:@"address"]) {
        self.address = [Address MR_createEntity];
        if ([dictionary objectForKey:@"address"] != [NSNull null]){
            self.address.formattedAddress = [[dictionary objectForKey:@"address"] objectForKey:@"formatted_address"];
        }
    }
    
    if ([dictionary objectForKey:@"progress"]) {
        self.progressPercentage = [dictionary objectForKey:@"progress"];
    }
    
    if ([dictionary objectForKey:@"recent_documents"] && [dictionary objectForKey:@"recent_documents"] != [NSNull null]) {
        NSMutableOrderedSet *orderedPhotos = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.recentDocuments];
        //NSLog(@"project recent documents %@",[dictionary objectForKey:@"recent_documents"]);
        for (id photoDict in [dictionary objectForKey:@"recent_documents"]){
            if ([photoDict objectForKey:@"id"]){
                NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [photoDict objectForKey:@"id"]];
                Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate];
                if (!photo){
                    photo = [Photo MR_createEntity];
                    NSLog(@"couldn't find saved recent document, created a new one: %@",photo.createdDate);
                }
                [photo populateFromDictionary:photoDict];
                [orderedPhotos addObject:photo];
            }
        }
        if (orderedPhotos.count > 0) self.recentDocuments = orderedPhotos;
    }
    
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        NSMutableOrderedSet *orderedPhotos = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.documents];
        //NSLog(@"project photos %@",[dictionary objectForKey:@"photos"]);
        for (id photoDict in [dictionary objectForKey:@"photos"]){
            if ([photoDict objectForKey:@"id"]){
                NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [photoDict objectForKey:@"id"]];
                Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate];
                if (!photo){
                    photo = [Photo MR_createEntity];
                    NSLog(@"couldn't find saved punchlist item photo, created a new one: %@",photo.createdDate);
                }
                [photo populateFromDictionary:photoDict];
                [orderedPhotos addObject:photo];
            }
        }
        self.documents = orderedPhotos;
    }
    
    if ([dictionary objectForKey:@"categories"]) {
        NSMutableOrderedSet *tmpPhases = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.phases];
        for (id phaseDict in [dictionary objectForKey:@"phases"]){
            if ([phaseDict objectForKey:@"id"]){
                NSPredicate *phasePredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [phaseDict objectForKey:@"id"]];
                //on the api, we're actually callign a category a "phase"
                Phase *phase = [Phase MR_findFirstWithPredicate:phasePredicate];
                if (phase){
                    [phase populateFromDictionary:phaseDict];
                } else {
                    phase = [Phase MR_createEntity];
                    phase.name = [phaseDict objectForKey:@"name"];
                }
                [phase populateFromDictionary:phaseDict];
                [tmpPhases addObject:phase];
            }
        }
        self.phases = tmpPhases;
    }
    if ([dictionary objectForKey:@"upcoming_items"]) {
        NSMutableOrderedSet *tmpUpcoming = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.upcomingItems];
        for (id itemDict in [dictionary objectForKey:@"upcoming_items"]){
            if ([itemDict objectForKey:@"id"]){
                NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [itemDict objectForKey:@"id"]];
                //on the api, we're actually callign a category a "phase"
                ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:itemPredicate];
                if (item){
                    [item populateFromDictionary:itemDict];
                } else {
                    item = [ChecklistItem MR_createEntity];
                    [item populateFromDictionary:itemDict];
                }
                [item populateFromDictionary:itemDict];
                [tmpUpcoming addObject:item];
            }
        }
        self.upcomingItems = tmpUpcoming;
    }
    if ([dictionary objectForKey:@"recently_completed"]) {
        NSMutableOrderedSet *tmpRecent = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.recentItems];
        for (id itemDict in [dictionary objectForKey:@"recently_completed"]){
            if ([itemDict objectForKey:@"id"]){
                NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [itemDict objectForKey:@"id"]];
                ChecklistItem *item = [ChecklistItem MR_findFirstWithPredicate:itemPredicate];
                if (item){
                    [item populateFromDictionary:itemDict];
                } else {
                    item = [ChecklistItem MR_createEntity];
                    [item populateFromDictionary:itemDict];
                }
                [item populateFromDictionary:itemDict];
                [tmpRecent addObject:item];
            }
        }
        self.recentItems = tmpRecent;
    }

}

- (void)parseDocuments:(NSArray *)array {
    NSMutableOrderedSet *photos = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.documents];
    for (NSDictionary *photoDict in array){
        Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[photoDict objectForKey:@"id"]];
        if (!photo){
            photo = [Photo MR_createEntity];
        }
        [photo populateFromDictionary:photoDict];
        [photos addObject:photo];
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

/*- (void)setValue:(id)value forKey:(NSString *)key {
 if ([key isEqualToString:@"id"]) {
 self.identifier = value;
 } else if ([key isEqualToString:@"name"]) {
 self.name = value;
 } else if ([key isEqualToString:@"company"]) {
 self.company = [[BHCompany alloc] initWithDictionary:value];
 } else if ([key isEqualToString:@"active"]) {
 self.active = [value boolValue];
 } else if ([key isEqualToString:@"core"]) {
 self.demo = [value boolValue];
 } else if ([key isEqualToString:@"address"]) {
 self.address = [[BHAddress alloc] initWithDictionary:value];
 } else if ([key isEqualToString:@"users"]) {
 self.users = [BHUtilities usersFromJSONArray:value];
 } else if ([key isEqualToString:@"subs"]) {
 self.subs = [BHUtilities subcontractorsFromJSONArray:value];
 } else if ([key isEqualToString:@"project_group"]) {
 self.group = [[BHProjectGroup alloc] initWithDictionary:value];
 } else if ([key isEqualToString:@"recent_documents"]) {
 self.recentDocuments = [BHUtilities photosFromJSONArray:value];
 } else if ([key isEqualToString:@"categories"]) {
 self.checklistCategories = [BHUtilities categoriesFromJSONArray:value];
 } else if ([key isEqualToString:@"upcoming_items"]) {
 self.upcomingItems = [BHUtilities checklistItemsFromJSONArray:value];
 } else if ([key isEqualToString:@"recently_completed"]) {
 self.recentItems = [BHUtilities checklistItemsFromJSONArray:value];
 } else if ([key isEqualToString:@"progress"]) {
 self.progressPercentage = value;
 }
 }*/

@end
