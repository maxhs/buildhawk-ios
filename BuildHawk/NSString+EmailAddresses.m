//
//  NSString+EmailAddresses.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "NSString+EmailAddresses.h"

// These are the correct versions of the domain names.
static const NSString *gmailDomain        = @"gmail.com";
static const NSString *googleMailDomain   = @"googlemail.com";
static const NSString *hotmailDomain      = @"hotmail.com";
static const NSString *yahooDomain        = @"yahoo.com";
static const NSString *yahooMailDomain    = @"ymail.com";

@implementation NSString (EmailAddresses)

- (NSString *)stringByCorrectingEmailTypos
{
    if (![self isValidEmailAddress]) {
        NSLog(@"%@ is not a valid email address.", self);
        return self;
    }
    
    // Start with a lower-cased version of the original string.
    __block NSString *correctedEmailAddress = [self lowercaseString];
    
    // First replace a ".con" suffix with ".com".
    if ([correctedEmailAddress hasSuffix:@".con"]) {
        NSRange range = NSMakeRange(correctedEmailAddress.length - 4, 4);
        correctedEmailAddress = [correctedEmailAddress stringByReplacingOccurrencesOfString:@".con"
                                                                                 withString:@".com"
                                                                                    options:NSBackwardsSearch|NSAnchoredSearch
                                                                                      range:range];
    }
    
    // Now iterate through the bad domain names to find common typos.
    // Feel free to add to the dictionary below.
    // I got the original list from http://getintheinbox.com/2013/02/25/typo-traps/
    NSDictionary *typos = @{@"gogglemail.com":  googleMailDomain,
                            @"googlmail.com":   googleMailDomain,
                            @"goglemail.com":   googleMailDomain,
                            @"hotmial.com":     hotmailDomain,
                            @"hotmal.com":      hotmailDomain,
                            @"hoitmail.com":    hotmailDomain,
                            @"homail.com":      hotmailDomain,
                            @"hotnail.com":     hotmailDomain,
                            @"hotrmail.com":    hotmailDomain,
                            @"hotmil.com":      hotmailDomain,
                            @"hotmaill.com":    hotmailDomain,
                            @"yaho.com":        yahooDomain,
                            @"uahoo.com":       yahooDomain,
                            @"ayhoo.com":       yahooDomain,
                            @"ymial.com":       yahooMailDomain,
                            @"ymaill.com":      yahooMailDomain,
                            @"gmal.com":        gmailDomain,
                            @"gnail.com":       gmailDomain,
                            @"gmaill.com":      gmailDomain,
                            @"gmial.com":       gmailDomain,
                            };
    
    [typos enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        NSString *domainIncludingAtSymbol = [NSString stringWithFormat:@"@%@", key];
        if ([correctedEmailAddress hasSuffix:domainIncludingAtSymbol]) {
            // Found a bad domain.
            correctedEmailAddress = [correctedEmailAddress stringByReplacingOccurrencesOfString:key withString:object];
            *stop = YES;
        }
    }];
    
    return correctedEmailAddress;
}

- (BOOL)isValidEmailAddress
{
    // http://stackoverflow.com/questions/3139619/check-that-an-email-address-is-valid-on-ios
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

@end
