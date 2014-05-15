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
    if ([dictionary objectForKey:@"name"]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"url_small"]) {
        self.urlSmall = [dictionary objectForKey:@"url_small"];
    }
    if ([dictionary objectForKey:@"url_large"]) {
        self.urlLarge = [dictionary objectForKey:@"url_large"];
    }
    if ([dictionary objectForKey:@"url_thumb"]) {
        self.urlThumb = [dictionary objectForKey:@"url_thumb"];
    }
    if ([dictionary objectForKey:@"original"]) {
        self.original = [dictionary objectForKey:@"original"];
    }
    if ([dictionary objectForKey:@"created_date"]) {
        self.createdDate = [dictionary objectForKey:@"created_date"];
    }
    if ([dictionary objectForKey:@"source"]) {
        self.source = [dictionary objectForKey:@"source"];
    }
    if ([dictionary objectForKey:@"phase"] && [dictionary objectForKey:@"phase"] != [NSNull null]) {
        self.photoPhase = [dictionary objectForKey:@"phase"];
    }
    if ([dictionary objectForKey:@"assignee"] && [dictionary objectForKey:@"assignee"] != [NSNull null]) {
        self.assignee = [dictionary objectForKey:@"assignee"];
    }
    if ([dictionary objectForKey:@"folder_name"]) {
        self.folder = [dictionary objectForKey:@"folder_name"];
    }
    if ([dictionary objectForKey:@"folder_id"]) {
        self.folderId = [dictionary objectForKey:@"folder_id"];
    }
    if ([dictionary objectForKey:@"user_name"] && [dictionary objectForKey:@"user_name"]!=[NSNull null]) {
        self.userName = [dictionary objectForKey:@"user_name"];
    }
    if ([dictionary objectForKey:@"created_date"]) {
        self.createdDate = [dictionary objectForKey:@"created_date"];
    }
    if ([dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    /*if ([dictionary objectForKey:@"comments"] && [dictionary objectForKey:@"comments"] != [NSNull null]) {
        NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSetWithOrderedSet:self.comments];
        NSLog(@"punchlist item comments %@",[dictionary objectForKey:@"comments"]);
        for (id commentDict in [dictionary objectForKey:@"comments"]){
            NSPredicate *commentPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [commentDict objectForKey:@"id"]];
            Comment *comment = [Comment MR_findFirstWithPredicate:commentPredicate];
            if (comment){
                NSLog(@"found saved sub: %@",comment.body);
            } else {
                comment = [Comment MR_createEntity];
                NSLog(@"couldn't find saved comment, created a new one: %@",comment.body);
            }
            [comment populateFromDictionary:commentDict];
            [orderedComments addObject:comment];
        }
        self.comments = orderedComments;
    }*/
}

/*if ([key isEqualToString:@"id"]) {
 self.identifier = value;
 } else if ([key isEqualToString:@"original"]) {
 self.orig = value;
 } else if ([key isEqualToString:@"url_large"]) {
 self.urlLarge = value;
 } else if ([key isEqualToString:@"urlSmall"]) {
 self.urlSmall = value;
 } else if ([key isEqualToString:@"urlThumb"]) {
 self.urlThumb = value;
 } else if ([key isEqualToString:@"created_at"]) {
 self.createdOn = [self parseDateTime:value];
 } else if ([key isEqualToString:@"created_date"]) {
 self.createdDate = value;
 } else if ([key isEqualToString:@"id"]) {
 self.identifier = value;
 } else if ([key isEqualToString:@"source"]) {
 if (value != [NSNull null]) self.source = value;
 } else if ([key isEqualToString:@"user_name"]) {
 if (value != [NSNull null]) self.userName = value;
 } else if ([key isEqualToString:@"image_file_size"]) {
 if (value != [NSNull null]) self.filesize = value;
 } else if ([key isEqualToString:@"image_content_type"]) {
 if (value != [NSNull null]) self.mimetype = value;
 } else if ([key isEqualToString:@"phase"]) {
 if (value != [NSNull null] && value != nil) self.phase = value;
 } else if ([key isEqualToString:@"assignee"]) {
 self.assignee = value;
 } else if ([key isEqualToString:@"folder_name"]) {
 self.folder = value;
 } else if ([key isEqualToString:@"folder_id"]) {
 self.folderId = value;
 } else if ([key isEqualToString:@"name"]) {
 self.name = value;
 }*/

@end
