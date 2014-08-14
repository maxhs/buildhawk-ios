//
//  NSString+EmailAddresses.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (EmailAddresses)
- (NSString *)stringByCorrectingEmailTypos;
- (BOOL)isValidEmailAddress;
@end
