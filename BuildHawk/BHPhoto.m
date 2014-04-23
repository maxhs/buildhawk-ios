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
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"original"]) {
        self.orig = value;
    } else if ([key isEqualToString:@"url_large"]) {
        self.urlLarge = value;
    } else if ([key isEqualToString:@"url200"]) {
        self.url200 = value;
    } else if ([key isEqualToString:@"url100"]) {
        self.url100 = value;
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
    }
}

- (NSDate*)parseDateTime:(id)value {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *theDate;
    NSError *error;
    if (![dateFormat getObjectValue:&theDate forString:value range:nil error:&error]) {
        NSLog(@"Date '%@' could not be parsed: %@", value, error);
    }
    return theDate;
}

- (NSDate*)parseDate:(id)value {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
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
        self.phase = [decoder decodeObjectForKey:@"phase"];
        self.createdDate = [decoder decodeObjectForKey:@"createdDate"];
        self.url100 = [decoder decodeObjectForKey:@"url100"];
        self.url200 = [decoder decodeObjectForKey:@"url200"];
        self.urlLarge = [decoder decodeObjectForKey:@"urlLarge"];
        self.orig = [decoder decodeObjectForKey:@"orig"];
        self.createdOn = [decoder decodeObjectForKey:@"createdOn"];
        self.source = [decoder decodeObjectForKey:@"source"];
        self.userName = [decoder decodeObjectForKey:@"userName"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.createdDate forKey:@"createdDate"];
    [coder encodeObject:self.phase forKey:@"phase"];
    [coder encodeObject:self.url100 forKey:@"url100"];
    [coder encodeObject:self.url200 forKey:@"url200"];
    [coder encodeObject:self.urlLarge forKey:@"urlLarge"];
    [coder encodeObject:self.orig forKey:@"orig"];
    [coder encodeObject:self.createdOn forKey:@"createdOn"];
    [coder encodeObject:self.source forKey:@"source"];
    [coder encodeObject:self.userName forKey:@"userName"];
}

@end
