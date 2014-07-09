//
//  Folder+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/7/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Folder+helper.h"
#import "Project+helper.h"

@implementation Folder (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"photo helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"project_id"] && [dictionary objectForKey:@"project_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"project_id"]];
        Project *project = [Project MR_findFirstWithPredicate:predicate];
        if (project){
            self.project = project;
        }
    }
}
@end
