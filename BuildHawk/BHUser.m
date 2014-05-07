//
//  BHUser.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHUser.h"

@implementation BHUser
static BHUser *currentUser;

+ (BHUser*)currentUser {
    return currentUser;
}

+ (void)setCurrentUser:(BHUser*)user {
    currentUser = user;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"email"]) {
        self.email = value;
    } else if ([key isEqualToString:@"first_name"]) {
        self.fname = value;
    } else if ([key isEqualToString:@"last_name"]) {
        self.lname = value;
    } else if ([key isEqualToString:@"full_name"]) {
        self.fullname = value;
    } else if ([key isEqualToString:@"authentication_token"]) {
        self.authToken = value;
    } else if ([key isEqualToString:@"phone_number"]) {
        self.phone = value;
    } else if ([key isEqualToString:@"formatted_phone"]) {
        self.formatted_phone = value;
    } else if ([key isEqualToString:@"company"]) {
        self.company = [[BHCompany alloc] initWithDictionary:value];
    } else if ([key isEqualToString:@"coworkers"]) {
        self.coworkers = [BHUtilities coworkersFromJSONArray:value];
    } else if ([key isEqualToString:@"subcontractors"]) {
        self.subcontractors = [BHUtilities subcontractorsFromJSONArray:value];
    } else if ([key isEqualToString:@"admin"]) {
        self.admin = [value boolValue];
    } else if ([key isEqualToString:@"copmany_admin"]) {
        self.companyAdmin = [value boolValue];
    } else if ([key isEqualToString:@"uber_admin"]) {
        self.uberAdmin = [value boolValue];
    } else if ([key isEqualToString:@"url100"]) {
        if (value != [NSNull null]) {
            self.photo = [[BHPhoto alloc] init];
            [self.photo setUrl100:value];
        }
    }
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
        self.email = [decoder decodeObjectForKey:@"email"];
        self.fname = [decoder decodeObjectForKey:@"fname"];
        self.lname = [decoder decodeObjectForKey:@"lname"];
        self.fullname = [decoder decodeObjectForKey:@"fullname"];
        self.authToken = [decoder decodeObjectForKey:@"authToken"];
        self.phone = [decoder decodeObjectForKey:@"phone"];
        self.formatted_phone = [decoder decodeObjectForKey:@"formatted_phone"];
        self.company = [decoder decodeObjectForKey:@"company"];
        self.coworkers = [decoder decodeObjectForKey:@"coworkers"];
        self.photo = [decoder decodeObjectForKey:@"photo"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.email forKey:@"email"];
    [coder encodeObject:self.fname forKey:@"fname"];
    [coder encodeObject:self.lname forKey:@"lname"];
    [coder encodeObject:self.fullname forKey:@"fullname"];
    [coder encodeObject:self.authToken forKey:@"authToken"];
    [coder encodeObject:self.phone forKey:@"phone"];
    [coder encodeObject:self.formatted_phone forKey:@"formatted_phone"];
    [coder encodeObject:self.company forKey:@"company"];
    [coder encodeObject:self.coworkers forKey:@"coworkers"];
    [coder encodeObject:self.photo forKey:@"photo"];
}


@end
