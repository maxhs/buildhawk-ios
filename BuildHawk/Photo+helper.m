//
//  Photo+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Photo+helper.h"

@implementation Photo (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"photo helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"url_small"] && [dictionary objectForKey:@"url_small"] != [NSNull null]) {
        self.urlSmall = [dictionary objectForKey:@"url_small"];
    }
    if ([dictionary objectForKey:@"url_large"] && [dictionary objectForKey:@"url_large"] != [NSNull null]) {
        self.urlLarge = [dictionary objectForKey:@"url_large"];
    }
    if ([dictionary objectForKey:@"url_thumb"] && [dictionary objectForKey:@"url_thumb"] != [NSNull null]) {
        self.urlThumb = [dictionary objectForKey:@"url_thumb"];
    }
    if ([dictionary objectForKey:@"original"] && [dictionary objectForKey:@"original"] != [NSNull null]) {
        self.original = [dictionary objectForKey:@"original"];
    }
    if ([dictionary objectForKey:@"created_date"] && [dictionary objectForKey:@"created_date"] != [NSNull null]) {
        self.createdDate = [dictionary objectForKey:@"created_date"];
    }
    if ([dictionary objectForKey:@"source"] && [dictionary objectForKey:@"source"] != [NSNull null]) {
        self.source = [dictionary objectForKey:@"source"];
    }
    if ([dictionary objectForKey:@"phase"] && [dictionary objectForKey:@"phase"] != [NSNull null]) {
        self.photoPhase = [dictionary objectForKey:@"phase"];
    }
    if ([dictionary objectForKey:@"assignee"] && [dictionary objectForKey:@"assignee"] != [NSNull null]) {
        self.assignee = [dictionary objectForKey:@"assignee"];
    }
    if ([dictionary objectForKey:@"folder_name"] != [NSNull null]) {
        self.folder = [dictionary objectForKey:@"folder_name"];
    }
    if ([dictionary objectForKey:@"folder_id"] != [NSNull null]) {
        self.folderId = [dictionary objectForKey:@"folder_id"];
    }
    if ([dictionary objectForKey:@"user_name"] !=[NSNull null]) {
        self.userName = [dictionary objectForKey:@"user_name"];
    }
    if ([dictionary objectForKey:@"description"] && [dictionary objectForKey:@"description"] != [NSNull null]) {
        self.caption = [dictionary objectForKey:@"description"];
    }
    if ([dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
}

@end
