//
//  BHReport.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "Report+helper.h"

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
    if ([dictionary objectForKey:@"personnel"] && [dictionary objectForKey:@"personnel"] != [NSNull null]) {
        self.personnel = [BHUtilities personnelFromJSONArray:[dictionary objectForKey:@"personnel"]];
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        self.createdDate = [dictionary objectForKey:@"created_date"];
    }
    if ([dictionary objectForKey:@"created_at"]) {
        self.createdAt = [BHUtilities parseDate:[dictionary objectForKey:@"created_at"]];
    }
    if ([dictionary objectForKey:@"updated_at"]) {
        self.updatedAt = [BHUtilities parseDate:[dictionary objectForKey:@"updated_at"]];
    }
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        self.photos = [BHUtilities photosFromJSONArray:[dictionary objectForKey:@"photos"]];
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


@end
