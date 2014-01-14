//
//  BHAppDelegate.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHAppDelegate.h"
#import "BHUser.h"
#import "BHCompany.h"
#import "BHProject.h"
#import "BHProjectCollection.h"
#import "Constants.h"
#import "BHLoginViewController.h"
#import "CoreData+MagicalRecord.h"
#import "Flurry.h"
#import "NSData+Conversion.h"
#import <Crashlytics/Crashlytics.h>

// Use a class extension to expose access to MagicalRecord's private setter methods
@interface NSManagedObjectContext ()
+ (void)MR_setRootSavingContext:(NSManagedObjectContext *)context;
+ (void)MR_setDefaultContext:(NSManagedObjectContext *)moc;
@end

@implementation BHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MagicalRecord setupCoreDataStack];
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [self customizeAppearance];
    
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:kFlurryKey];
    
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 20;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelNone];
    // Initialize tracker.
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-43601553-1"];
    [Crashlytics startWithAPIKey:@"c52cd9c3cd08f8c9c0de3a248a813118655c8005"];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)customizeAppearance {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0f) {
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackground"] forBarMetrics:UIBarMetricsDefault];
    } else {
        [self.window setTintColor:[UIColor whiteColor]];
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackgroundTall"] forBarMetrics:UIBarMetricsDefault];
    }
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                    NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueMedium size:15],
                         NSForegroundColorAttributeName : [UIColor whiteColor]
                                    }];
    UIImage *empty = [UIImage imageNamed:@"empty"];
    
    [[UIBarButtonItem appearance] setBackgroundImage:empty forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                    NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueLight size:14],
                                    NSForegroundColorAttributeName : [UIColor whiteColor]
     } forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]
     setTitleTextAttributes:@{[UIColor blackColor]:NSForegroundColorAttributeName} forState:UIControlStateNormal];
    
    [[UISearchBar appearance] setBackgroundImage:empty];
    [[UISearchBar appearance] setSearchFieldBackgroundImage:[UIImage imageNamed:@"textField"]forState:UIControlStateNormal];
    
    [[UITabBarItem appearance] setTitleTextAttributes: @{
                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueLight size:13.0],
    } forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{
                 NSForegroundColorAttributeName : [UIColor colorWithWhite:.2 alpha:1.0],
                            NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueMedium size:13.0],
        } forState:UIControlStateSelected];
    [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:@"whiteTabBackground"]];
    [[UITabBar appearance] setTintColor:[UIColor colorWithWhite:.2 alpha:1.0]];
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor colorWithWhite:.2 alpha:1.0]];
    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackground"]];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
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
    [MagicalRecord cleanUp];
}

#pragma mark uncaughtExceptionHandler
void uncaughtExceptionHandler(NSException *exception) {
    //[Flurry logError:exception.name message:exception.description exception:exception];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)pushMessage
{
    [Flurry logEvent:@"Did Receive Remote Notification"];
    NSLog(@"Just received a remote notification: %@",pushMessage);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    [Flurry logEvent:@"Registered For Remote Notifications"];
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kUserDefaultsDeviceToken];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //NSLog(@"device token: %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    [Flurry logEvent:@"Rejected Remote Notifications"];
}

@end
