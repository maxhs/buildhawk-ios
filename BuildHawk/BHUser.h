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

@interface BHUser : NSObject

@property (nonatomic, copy) NSString *fname;
@property (nonatomic, copy) NSString *lname;
@property (nonatomic, copy) NSString *fullname;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *phone1;
@property (nonatomic, copy) NSString *authToken;
@property (nonatomic, copy) NSArray *deviceTokens;
@property (nonatomic, copy) NSArray *timestamps;
@property (nonatomic, copy) NSArray *photo;
@property (nonatomic, copy) BHCompany *company;
@property (nonatomic, copy) BHProject *projects;

@end
