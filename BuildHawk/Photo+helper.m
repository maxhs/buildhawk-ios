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
    //NSLog(@"project helper dictionary: %@",dictionary);
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
@end
