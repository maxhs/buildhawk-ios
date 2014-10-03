//
//  Checklist+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Checklist+helper.h"
#import "Phase+helper.h"

@implementation Checklist (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"checklist helper dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"project_id"] && [dictionary objectForKey:@"project_id"] != [NSNull null]) {
        Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"project_id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            project.identifier = [dictionary objectForKey:@"project_id"];
        }
        self.project = project;
    }
    if ([dictionary objectForKey:@"phases"] && [dictionary objectForKey:@"phases"] != [NSNull null]) {
        NSMutableOrderedSet *phases = [NSMutableOrderedSet orderedSet];
        for (id phaseDict in [dictionary objectForKey:@"phases"]) {
            Phase *phase = [Phase MR_findFirstByAttribute:@"identifier" withValue:[phaseDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (phase){
                [phase updateFromDictionary:phaseDict];
            } else {
                phase = [Phase MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [phase populateFromDictionary:phaseDict];
            }
            [phases addObject:phase];
        }
        self.phases = phases;
    }
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }

    if ([dictionary objectForKey:@"phases"] && [dictionary objectForKey:@"phases"] != [NSNull null]) {
        NSMutableOrderedSet *phases = [NSMutableOrderedSet orderedSet];
        for (id phaseDict in [dictionary objectForKey:@"phases"]) {
            Phase *phase = [Phase MR_findFirstByAttribute:@"identifier" withValue:[phaseDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (phase){
                [phase updateFromDictionary:phaseDict];
            } else {
                phase = [Phase MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [phase populateFromDictionary:phaseDict];
            }
            [phases addObject:phase];
        }
        self.phases = phases;
    }
}

- (void)removePhase:(Phase *)phase{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:self.phases];
    [set removeObject:phase];
    self.phases = set;
}
@end
