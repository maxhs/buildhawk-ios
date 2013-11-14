//
//  BHPhoto.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPhoto.h"
#import "BHUser.h"

@implementation BHPhoto

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"photo"]) {
        self.url100 = [value valueForKeyPath:@"urls.100x100"];
        if ([value valueForKeyPath:@"urls.200x200"]){
            self.url200 = [value valueForKeyPath:@"urls.200x200"];
        }
        if ([value valueForKeyPath:@"urls.640x640"]){
            self.url640 = [value valueForKeyPath:@"urls.640x640"];
        }
    } else if ([key isEqualToString:@"urls"]) {
        self.url100 = [value objectForKey:@"100x100"];
        if ([value objectForKey:@"200x200"]){
            self.url200 = [value objectForKey:@"200x200"];
        }
        if ([value objectForKey:@"640x640"]){
            self.url640 = [value objectForKey:@"640x640"];
        }
        if ([value objectForKey:@"orig"]){
            self.orig = [value objectForKey:@"orig"];
        }
    } else if ([key isEqualToString:@"createdOn"]) {
        self.createdOn = [self parseDate:value];
    } else if ([key isEqualToString:@"_id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"source"]) {
        self.source = value;
    } else if ([key isEqualToString:@"user"]) {
        self.userName = [value objectForKey:@"fullname"];
    }
}

- (NSDate*)parseDate:(id)value {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *theDate;
    NSError *error;
    if (![dateFormat getObjectValue:&theDate forString:value range:nil error:&error]) {
        NSLog(@"Date '%@' could not be parsed: %@", value, error);
    }
    return theDate;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}

- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues {
    [super setValuesForKeysWithDictionary:keyedValues];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.url = [decoder decodeObjectForKey:@"url"];
        self.url100 = [decoder decodeObjectForKey:@"url100"];
        self.url200 = [decoder decodeObjectForKey:@"url200"];
        self.url640 = [decoder decodeObjectForKey:@"url640"];
        self.orig = [decoder decodeObjectForKey:@"orig"];
        self.createdOn = [decoder decodeObjectForKey:@"createdOn"];
        self.source = [decoder decodeObjectForKey:@"source"];
        self.userName = [decoder decodeObjectForKey:@"userName"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.url forKey:@"url"];
    [coder encodeObject:self.url100 forKey:@"url100"];
    [coder encodeObject:self.url200 forKey:@"url200"];
    [coder encodeObject:self.url640 forKey:@"url640"];
    [coder encodeObject:self.orig forKey:@"orig"];
    [coder encodeObject:self.createdOn forKey:@"createdOn"];
    [coder encodeObject:self.source forKey:@"source"];
    [coder encodeObject:self.userName forKey:@"userName"];
}

@end
