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
    if ([dictionary objectForKey:@"report_users"] && [dictionary objectForKey:@"report_users"] != [NSNull null]) {
        if ([dictionary objectForKey:@"report_users"] != [NSNull null]) {
            NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSetWithOrderedSet:self.reportUsers];
            //NSLog(@"report photos %@",[dictionary objectForKey:@"report_users"]);
            for (id userDict in [dictionary objectForKey:@"report_users"]){
                NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
                User *user = [User MR_findFirstWithPredicate:userPredicate];
                if (!user){
                    user = [User MR_createEntity];
                    NSLog(@"couldn't find saved report user, created a new one: %@",user.fullname);
                }
                [user populateFromDictionary:userDict];
                [orderedUsers addObject:user];
            }
            self.reportUsers = orderedUsers;
            //if (self.reportUsers.count > 0) NSLog(@"report users: %@",self.reportUsers);
        }
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        self.createdDate = [dictionary objectForKey:@"created_date"];
    }
    if ([dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"updated_at"]) {
        self.updatedAt = [BHUtilities parseDate:[dictionary objectForKey:@"updated_at"]];
    }
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        if ([dictionary objectForKey:@"photos"] != [NSNull null]) {
            NSMutableOrderedSet *orderedPhotos = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
            for (id photoDict in [dictionary objectForKey:@"photos"]){
                NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [photoDict objectForKey:@"id"]];
                Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate];
                if (!photo){
                    photo = [Photo MR_createEntity];
                }
                [photo populateFromDictionary:photoDict];
                [orderedPhotos addObject:photo];
            }
            self.photos = orderedPhotos;
        }
    }
    if ([dictionary objectForKey:@"possible_topics"]) {
        self.possibleTopics = [BHUtilities safetyTopicsFromJSONArray:[dictionary objectForKey:@"possible_topics"]];
    }
}

-(void)addSafetyTopic:(BHSafetyTopic *)topic {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.safetyTopics];
    [set addObject:topic];
    self.safetyTopics = set;
}

- (void)addReportUser:(User*)reportUser {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reportUsers];
    [set addObject:reportUser];
    self.reportUsers = set;
}
-(void)removeReportUser:(User*)reportUser {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reportUsers];
    [set removeObject:reportUser];
    self.reportUsers = set;
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
@end
