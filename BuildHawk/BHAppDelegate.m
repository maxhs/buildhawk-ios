//
//  BHAppDelegate.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHAppDelegate.h"
#import <RestKit/RestKit.h>
#import "BHUser.h"
#import "BHCompany.h"
#import "BHProject.h"
#import "BHProjectCollection.h"
#import "Constants.h"

@implementation BHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //let AFNetworking manage the activity indicator
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // Initialize HTTPClient
    NSURL *baseURL = [NSURL URLWithString:@"http://www.buildhawk.com/api/v1"];
    AFHTTPClient* client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    
    //we want to work with JSON-Data
    [client setDefaultHeader:@"Accept" value:RKMIMETypeJSON];
    
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
    
    // Setup our object mappings
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[BHUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{
     @"_id":@"identifier"
     }];
    
    RKObjectMapping *projectMapping = [RKObjectMapping mappingForClass:[BHProject class]];
    [projectMapping addAttributeMappingsFromDictionary:@{
     @"id" : @"statusID",
     @"created_at" : @"createdAt",
     @"text" : @"text",
     @"url" : @"urlString",
     @"in_reply_to_screen_name" : @"inReplyToScreenName",
     @"favorited" : @"isFavorited",
     }];
    RKRelationshipMapping* relationShipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"user"
                                                                                             toKeyPath:@"user"
                                                                                           withMapping:userMapping];
    [projectMapping addPropertyMapping:relationShipMapping];
    
    // Update date format so that we can parse Twitter dates properly
    // Wed Sep 29 15:31:08 +0000 2010
    [RKObjectMapping addDefaultDateFormatterForString:@"E MMM d HH:mm:ss Z y" inTimeZone:nil];
    
    // Register our mappings with the provider using a response descriptor
    /*RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:projectMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"/project/:id"
                                                                                           keyPath:nil
                                                                                       statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];*/
    
    [self customizeAppearance];
    [self.window makeKeyAndVisible];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
        UIStoryboard *iphoneStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        UIViewController *revealVC = [iphoneStoryboard instantiateViewControllerWithIdentifier:@"Reveal"];
        UINavigationController *navigationController = (UINavigationController *)revealVC;
        self.window.rootViewController = navigationController;
    }
    return YES;
}

- (void)customizeAppearance {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackground"] forBarMetrics:UIBarMetricsDefault];
    UIImage *empty = [UIImage imageNamed:@"empty"];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:empty forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:empty forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                    NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueLight size:14],
                         NSForegroundColorAttributeName : [UIColor clearColor],
                               NSForegroundColorAttributeName : [UIColor blackColor],
     } forState:UIControlStateNormal];
    [[UISearchBar appearance] setBackgroundImage:empty];
    [[UISearchBar appearance] setSearchFieldBackgroundImage:[UIImage imageNamed:@"textField"]forState:UIControlStateNormal];
    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"tabBarBackground"]];
    [[UITabBarItem appearance] setTitleTextAttributes: @{
                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueLight size:12.0],
    } forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{
                 NSForegroundColorAttributeName : [UIColor blackColor],
                            NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueLight size:12.0],
        } forState:UIControlStateSelected];
    [[UITabBar appearance] setTintColor:[UIColor blackColor]];
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor blackColor]];
    [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:@"whiteTabBackground"]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
