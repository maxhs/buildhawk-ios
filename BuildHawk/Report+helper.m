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
#import "SafetyTopic+helper.h"

@implementation Report (helper)

- (void)populateWithDict:(NSDictionary *)dictionary {
    //NSLog(@"dict: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
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
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        self.createdDate = [dictionary objectForKey:@"created_date"];
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
                NSLog(@"deleting a report user that no longer exists: %@",reportUser.fullname);
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
                ReportSub *subcontractor = [ReportSub MR_findFirstWithPredicate:companyPredicate];
                if (!subcontractor){
                    subcontractor = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    subcontractor.identifier = [subDict objectForKey:@"id"];
                }
                subcontractor.name = [[subDict objectForKey:@"company"] objectForKey:@"name"];
                subcontractor.companyId = [[subDict objectForKey:@"company"] objectForKey:@"id"];
                if ([subDict objectForKey:@"count"] != [NSNull null]) subcontractor.count = [subDict objectForKey:@"count"];
                [orderedSubs addObject:subcontractor];
            }
        }
        for (ReportSub *reportSub in self.reportSubs){
            if (![orderedSubs containsObject:reportSub]) {
                NSLog(@"deleting a report sub that no longer exists: %@",reportSub.name);
                [reportSub MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reportSubs = orderedSubs;
    }
    
    if ([dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"updated_at"]) {
        self.updatedAt = [BHUtilities parseDate:[dictionary objectForKey:@"updated_at"]];
    }
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        [BHUtilities vacuumLocalPhotos:self];
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
        self.photos = orderedPhotos;
    }
    if ([dictionary objectForKey:@"report_topics"] && [dictionary objectForKey:@"report_topics"] != [NSNull null]) {
        NSMutableOrderedSet *orderedTopic = [NSMutableOrderedSet orderedSet];
        for (id topicDict in [dictionary objectForKey:@"report_topics"]){
            NSLog(@"topic dict: %@",topicDict);
            NSPredicate *topicPredicate = [NSPredicate predicateWithFormat:@"topicId == %@", [topicDict objectForKey:@"safety_topic_id"]];
            SafetyTopic *topic = [SafetyTopic MR_findFirstWithPredicate:topicPredicate];
            if (!topic){
                NSLog(@"creating a new safety topic");
                topic = [SafetyTopic MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [topic populateWithDict:topicDict];
            [orderedTopic addObject:topic];
        }
        self.safetyTopics = orderedTopic;
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
