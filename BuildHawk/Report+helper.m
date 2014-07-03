//
//  BHReport.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "Report+helper.h"
#import "Photo+helper.h"
#import "User+helper.h"
#import "Subcontractor.h"
#import "ReportSub.h"
#import "Activity+helper.h"
#import "SafetyTopic+helper.h"

@implementation Report (helper)

- (void)populateWithDict:(NSDictionary *)dictionary {
    //NSLog(@"report dict: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"report_type"] && [dictionary objectForKey:@"report_type"] != [NSNull null]) {
        self.type = [dictionary objectForKey:@"report_type"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"weather"] && [dictionary objectForKey:@"weather"] != [NSNull null]) {
        self.weather = [dictionary objectForKey:@"weather"];
    }
    if ([dictionary objectForKey:@"temp"] && [dictionary objectForKey:@"temp"] != [NSNull null]) {
        self.temp = [dictionary objectForKey:@"temp"];
    }
    if ([dictionary objectForKey:@"wind"] && [dictionary objectForKey:@"wind"] != [NSNull null]) {
        self.wind = [dictionary objectForKey:@"wind"];
    }
    if ([dictionary objectForKey:@"precip"] && [dictionary objectForKey:@"precip"] != [NSNull null]) {
        self.precip = [dictionary objectForKey:@"precip"];
    }
    if ([dictionary objectForKey:@"humidity"] && [dictionary objectForKey:@"humidity"] != [NSNull null]) {
        self.humidity = [dictionary objectForKey:@"humidity"];
    }
    if ([dictionary objectForKey:@"weather_icon"] && [dictionary objectForKey:@"weather_icon"] != [NSNull null]) {
        self.weatherIcon = [dictionary objectForKey:@"weather_icon"];
    }
    if ([dictionary objectForKey:@"date_string"] && [dictionary objectForKey:@"date_string"] != [NSNull null]) {
        self.dateString = [dictionary objectForKey:@"date_string"];
    }
    if ([dictionary objectForKey:@"report_users"] && [dictionary objectForKey:@"report_users"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (id userDict in [dictionary objectForKey:@"report_users"]){
            if ([userDict objectForKey:@"user"] != [NSNull null]) {
                //NSLog(@"user dict from report users: %@",userDict);
                NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
                ReportUser *reportUser = [ReportUser MR_findFirstWithPredicate:userPredicate];
                if (!reportUser){
                    reportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                if ([userDict objectForKey:@"hours"] && [userDict objectForKey:@"hours"] != [NSNull null]){
                    reportUser.hours = [userDict objectForKey:@"hours"];
                }
                [reportUser populateFromDictionary:[userDict objectForKey:@"user"]];
                reportUser.identifier = [userDict objectForKey:@"id"];
                
                [orderedUsers addObject:reportUser];
            }
        }
        for (ReportUser *reportUser in self.reportUsers){
            if (![orderedUsers containsObject:reportUser]) {
                NSLog(@"Deleting a report user that no longer exists: %@",reportUser.fullname);
                [reportUser MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reportUsers = orderedUsers;
    }
    if ([dictionary objectForKey:@"report_companies"] && [dictionary objectForKey:@"report_companies"] != [NSNull null]) {
        NSMutableOrderedSet *orderedSubs = [NSMutableOrderedSet orderedSet];
        for (id subDict in [dictionary objectForKey:@"report_companies"]){
            //NSLog(@"sub dict from report subs: %@",subDict);
            if ([subDict objectForKey:@"company"] != [NSNull null]) {
                NSPredicate *companyPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [subDict objectForKey:@"id"]];
                ReportSub *reportSub = [ReportSub MR_findFirstWithPredicate:companyPredicate];
                if (!reportSub){
                    reportSub = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    reportSub.identifier = [subDict objectForKey:@"id"];
                }
                reportSub.name = [[subDict objectForKey:@"company"] objectForKey:@"name"];
                reportSub.companyId = [[subDict objectForKey:@"company"] objectForKey:@"id"];
                if ([subDict objectForKey:@"count"] != [NSNull null]) reportSub.count = [subDict objectForKey:@"count"];
                [orderedSubs addObject:reportSub];
            }
        }
        for (ReportSub *reportSub in self.reportSubs){
            if (![orderedSubs containsObject:reportSub]) {
                NSLog(@"Deleting a report sub that no longer exists: %@",reportSub.name);
                [reportSub MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reportSubs = orderedSubs;
    }
    
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"updated_at"] && [dictionary objectForKey:@"updated_at"] != [NSNull null]) {
        self.updatedAt = [BHUtilities parseDate:[dictionary objectForKey:@"updated_at"]];
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
    
    if ([dictionary objectForKey:@"report_topics"] && [dictionary objectForKey:@"report_topics"] != [NSNull null]) {
        NSMutableOrderedSet *orderedTopic = [NSMutableOrderedSet orderedSet];
        for (id topicDict in [dictionary objectForKey:@"report_topics"]){
            //NSLog(@"topic dict: %@",topicDict);
            NSPredicate *topicPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [topicDict objectForKey:@"id"]];
            SafetyTopic *topic = [SafetyTopic MR_findFirstWithPredicate:topicPredicate];
            if (!topic){
                topic = [SafetyTopic MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [topic populateWithDict:topicDict];
            [orderedTopic addObject:topic];
        }
        self.safetyTopics = orderedTopic;
    }
    
    if ([dictionary objectForKey:@"author"] && [dictionary objectForKey:@"author"] != [NSNull null]) {
        User *author = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"author"] objectForKey:@"id"]];
        if (!author){
            author = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [author populateFromDictionary:[dictionary objectForKey:@"author"]];
        self.author = author;
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
}

- (void)update:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"report_type"] && [dictionary objectForKey:@"report_type"] != [NSNull null]) {
        self.type = [dictionary objectForKey:@"report_type"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"weather"] && [dictionary objectForKey:@"weather"] != [NSNull null]) {
        self.weather = [dictionary objectForKey:@"weather"];
    }
    if ([dictionary objectForKey:@"temp"] && [dictionary objectForKey:@"temp"] != [NSNull null]) {
        self.temp = [dictionary objectForKey:@"temp"];
    }
    if ([dictionary objectForKey:@"wind"] && [dictionary objectForKey:@"wind"] != [NSNull null]) {
        self.wind = [dictionary objectForKey:@"wind"];
    }
    if ([dictionary objectForKey:@"precip"] && [dictionary objectForKey:@"precip"] != [NSNull null]) {
        self.precip = [dictionary objectForKey:@"precip"];
    }
    if ([dictionary objectForKey:@"humidity"] && [dictionary objectForKey:@"humidity"] != [NSNull null]) {
        self.humidity = [dictionary objectForKey:@"humidity"];
    }
    if ([dictionary objectForKey:@"weather_icon"] && [dictionary objectForKey:@"weather_icon"] != [NSNull null]) {
        self.weatherIcon = [dictionary objectForKey:@"weather_icon"];
    }
    if ([dictionary objectForKey:@"date_string"] && [dictionary objectForKey:@"date_string"] != [NSNull null]) {
        self.dateString = [dictionary objectForKey:@"date_string"];
    }
    if ([dictionary objectForKey:@"report_users"] && [dictionary objectForKey:@"report_users"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (id userDict in [dictionary objectForKey:@"report_users"]){
            if ([userDict objectForKey:@"user"] != [NSNull null]) {
                //NSLog(@"user dict from report users: %@",userDict);
                NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
                ReportUser *reportUser = [ReportUser MR_findFirstWithPredicate:userPredicate];
                if (!reportUser){
                    reportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [reportUser populateFromDictionary:[userDict objectForKey:@"user"]];
                }
                
                if ([userDict objectForKey:@"hours"] && [userDict objectForKey:@"hours"] != [NSNull null]){
                    reportUser.hours = [userDict objectForKey:@"hours"];
                }
                reportUser.identifier = [userDict objectForKey:@"id"];
                
                [orderedUsers addObject:reportUser];
            }
        }
        for (ReportUser *reportUser in self.reportUsers){
            if (![orderedUsers containsObject:reportUser]) {
                NSLog(@"Deleting a report user that no longer exists: %@",reportUser.fullname);
                [reportUser MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reportUsers = orderedUsers;
    }
    if ([dictionary objectForKey:@"report_companies"] && [dictionary objectForKey:@"report_companies"] != [NSNull null]) {
        NSMutableOrderedSet *orderedSubs = [NSMutableOrderedSet orderedSet];
        for (id subDict in [dictionary objectForKey:@"report_companies"]){
            //NSLog(@"sub dict from report subs: %@",subDict);
            if ([subDict objectForKey:@"company"] != [NSNull null]) {
                NSPredicate *companyPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [subDict objectForKey:@"id"]];
                ReportSub *reportSub = [ReportSub MR_findFirstWithPredicate:companyPredicate];
                if (!reportSub){
                    reportSub = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    reportSub.identifier = [subDict objectForKey:@"id"];
                }
                reportSub.name = [[subDict objectForKey:@"company"] objectForKey:@"name"];
                reportSub.companyId = [[subDict objectForKey:@"company"] objectForKey:@"id"];
                if ([subDict objectForKey:@"count"] != [NSNull null]) reportSub.count = [subDict objectForKey:@"count"];
                [orderedSubs addObject:reportSub];
            }
        }
        for (ReportSub *reportSub in self.reportSubs){
            if (![orderedSubs containsObject:reportSub]) {
                NSLog(@"Deleting a report sub that no longer exists: %@",reportSub.name);
                [reportSub MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reportSubs = orderedSubs;
    }
    
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"updated_at"] && [dictionary objectForKey:@"updated_at"] != [NSNull null]) {
        self.updatedAt = [BHUtilities parseDate:[dictionary objectForKey:@"updated_at"]];
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
    
    if ([dictionary objectForKey:@"report_topics"] && [dictionary objectForKey:@"report_topics"] != [NSNull null]) {
        NSMutableOrderedSet *orderedTopic = [NSMutableOrderedSet orderedSet];
        for (id topicDict in [dictionary objectForKey:@"report_topics"]){
            //NSLog(@"topic dict: %@",topicDict);
            NSPredicate *topicPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [topicDict objectForKey:@"id"]];
            SafetyTopic *topic = [SafetyTopic MR_findFirstWithPredicate:topicPredicate];
            if (!topic){
                topic = [SafetyTopic MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [topic populateWithDict:topicDict];
            [orderedTopic addObject:topic];
        }
        self.safetyTopics = orderedTopic;
    }
    
    if ([dictionary objectForKey:@"author"] && [dictionary objectForKey:@"author"] != [NSNull null]) {
        User *author = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"author"] objectForKey:@"id"]];
        if (!author){
            author = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [author populateFromDictionary:[dictionary objectForKey:@"author"]];
        self.author = author;
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
}

-(void)addSafetyTopic:(SafetyTopic *)topic {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.safetyTopics];
    [set addObject:topic];
    self.safetyTopics = set;
}
-(void)removeSafetyTopic:(SafetyTopic *)topic {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.safetyTopics];
    [set removeObject:topic];
    self.safetyTopics = set;
}

- (void)addReportUser:(ReportUser*)reportUser {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reportUsers];
    [set addObject:reportUser];
    self.reportUsers = set;
}
-(void)removeReportUser:(ReportUser*)reportUser {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reportUsers];
    [set removeObject:reportUser];
    self.reportUsers = set;
}

-(void)clearReportUsers {
    self.reportUsers = nil;
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

- (void)addReportSubcontractor:(ReportSub *)reportSubcontractor {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reportSubs];
    [set addObject:reportSubcontractor];
    self.reportSubs = set;
}
-(void)removeReportSubcontractor:(ReportSub *)reportSubcontractor {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reportSubs];
    [set removeObject:reportSubcontractor];
    self.reportSubs = set;
}
-(void)clearReportSubcontractors {
    self.reportSubs = nil;
}
@end
