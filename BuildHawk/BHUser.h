//
//  BHUser.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHCompany.h"
#import "BHProject.h"
#import "BHPhoto.h"

@interface BHUser : NSObject

@property (nonatomic, strong) NSString *fname;
@property (nonatomic, strong) NSString *lname;
@property (nonatomic, strong) NSString *fullname;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *phone1;
@property (nonatomic, strong) NSString *authToken;
@property (nonatomic, strong) NSArray *deviceTokens;
@property (nonatomic, strong) NSArray *timestamps;
@property (nonatomic, strong) BHPhoto *photo;
@property (nonatomic, strong) BHCompany *company;
@property (nonatomic, strong) BHProject *projects;
@property (nonatomic, strong) NSArray *coworkers;
@property (nonatomic, strong) NSArray *subcontractors;

- (id) initWithDictionary:(NSDictionary*)dictionary;
+ (BHUser*)currentUser;
+ (void)setCurrentUser:(BHUser*)user;
- (void)encodeWithCoder:(NSCoder *)coder;
@end
