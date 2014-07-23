//
//  BHAppDelegate.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHAppDelegate.h"
#import "User+helper.h"
#import "Project.h"
#import "BHProjectCollection.h"
#import "Constants.h"
#import "BHLoginViewController.h"
#import "CoreData+MagicalRecord.h"
#import "Flurry.h"
#import <Crashlytics/Crashlytics.h>
#import "SDWebImageManager.h"
#import "UIImage+ImageEffects.h"
#import "BHTaskViewController.h"
#import "BHMenuViewController.h"
#import "BHDashboardViewController.h"
#import <RESideMenu/RESideMenu.h>

@interface BHAppDelegate () <RESideMenuDelegate> {
    UIView *overlayView;
    CGRect screen;
}
@end

@implementation BHAppDelegate

@synthesize nav = _nav;
@synthesize menu = _menu;
@synthesize bundleName = _bundleName;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MagicalRecord setupAutoMigratingCoreDataStack];
    [MagicalRecord shouldAutoCreateDefaultPersistentStoreCoordinator];
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
    
    [Crashlytics startWithAPIKey:@"c52cd9c3cd08f8c9c0de3a248a813118655c8005"];
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    [self customizeAppearance];
    
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:kFlurryKey];
    
    // Optional: automatically send uncaught exceptions to Google Analytics.
    /*[GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 20;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelNone];
    // Initialize tracker.
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-43601553-1"];*/
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"Connected");
                _connected = YES;
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                NSLog(@"Not online");
                _connected = NO;
                [self offlineNotification];
                break;
        }
    }];
    _manager = [[AFHTTPRequestOperationManager manager] initWithBaseURL:[NSURL URLWithString:kApiBaseUrl]];
    //_manager.requestSerializer = [AFJSONRequestSerializer serializer];

    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && _currentUser){
        //head straight into the app
        BHDashboardViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Dashboard"];
        _nav = [[UINavigationController alloc] initWithRootViewController:vc];
    } else {
        //show the login UI
        _nav = (UINavigationController*)self.window.rootViewController;
    }
    
    _menu = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    RESideMenu *sideMenuViewController = [[RESideMenu alloc] initWithContentViewController:_nav
                                                                    leftMenuViewController:_menu
                                                                   rightMenuViewController:nil];
    sideMenuViewController.menuPreferredStatusBarStyle = 1; // UIStatusBarStyleLightContent
    sideMenuViewController.delegate = self;
    /*sideMenuViewController.contentViewShadowColor = [UIColor blackColor];
    sideMenuViewController.contentViewShadowOffset = CGSizeMake(0, 0);
    sideMenuViewController.contentViewShadowOpacity = 0.6;
    sideMenuViewController.contentViewShadowRadius = 12;
    sideMenuViewController.contentViewShadowEnabled = YES;*/
    self.window.rootViewController = sideMenuViewController;
    self.window.backgroundColor = [UIColor blackColor];
    
    return YES;
}

- (void)customizeAppearance {
    [self.window setTintColor:[UIColor blackColor]];
    [self setToBuildHawkAppearances];
    
    
    CGFloat tabFontSize;
    if (IDIOM == IPAD){
        tabFontSize = 17;
    } else {
        tabFontSize = 15;
    }
    [[UITabBarItem appearance] setTitleTextAttributes: @{
                                                         NSForegroundColorAttributeName : [UIColor whiteColor],
                                                         NSFontAttributeName : [UIFont fontWithName:kMyriadProRegular size:tabFontSize],
                                                         } forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{
                 NSForegroundColorAttributeName : [UIColor colorWithWhite:0 alpha:1],
                            NSFontAttributeName : [UIFont fontWithName:kMyriadProRegular size:tabFontSize],
                                                        } forState:UIControlStateSelected];
    
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor colorWithWhite:0 alpha:1.0]];
    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackground"]];
    
    [[UISwitch appearance] setOnTintColor:kBlueColor];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kMyriadProRegular size:15]} forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setContentPositionAdjustment:UIOffsetMake(0, 1) forSegmentType:UISegmentedControlSegmentAny barMetrics:UIBarMetricsDefault];
    
    /*for (NSString* family in [UIFont familyNames]){
        NSLog(@"%@", family);
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
            NSLog(@"  %@", name);
    }*/
}

//the next two methods are so the damn message and mail navigation bars don't look like shit
- (void)setDefaultAppearances {
    [[UINavigationBar appearance] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName : [UIFont fontWithName:kMyriadProRegular size:22],
                                                           NSForegroundColorAttributeName : [UIColor blackColor]
                                                           }];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName : [UIFont fontWithName:kMyriadProRegular size:16],
                                                           NSForegroundColorAttributeName : [UIColor blackColor]
                                                           } forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
}

- (void)setToBuildHawkAppearances{
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackgroundTall"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName : [UIFont fontWithName:kMyriadProRegular size:22],
                                                           NSForegroundColorAttributeName : [UIColor whiteColor]
                                                           }];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:1.f forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName : [UIFont fontWithName:kMyriadProRegular size:16],
                                                           NSForegroundColorAttributeName : [UIColor whiteColor]
                                                           } forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 3) forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]
     setTitleTextAttributes:@{[UIColor blackColor]:NSForegroundColorAttributeName} forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]    setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]} forState:UIControlStateNormal];
    
}

- (UIView*)addOverlayUnderNav:(BOOL)underNav {
    screen = [UIScreen mainScreen].bounds;
    if (!overlayView) {
        overlayView = [[UIView alloc] initWithFrame:screen];
    }
    
    if (underNav){
        [overlayView setBackgroundColor:[UIColor colorWithPatternImage:[self blurredSnapshotNav]]];
    } else {
        [overlayView setBackgroundColor:[UIColor colorWithPatternImage:[self blurredSnapshot]]];
    }
    /*UITapGestureRecognizer *overlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeOverlay)];
    overlayTap.numberOfTapsRequired = 1;
    [overlayView addGestureRecognizer:overlayTap];*/
    [overlayView setAlpha:0.0];
    [self.window addSubview:overlayView];
    
    [UIView animateWithDuration:.25 animations:^{
        [overlayView setAlpha:1.0];
    }];
    return overlayView;
}

-(UIImage *)blurredSnapshot {
    UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.window.screen.scale);
    [self.window drawViewHierarchyInRect:self.window.frame afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

-(UIImage *)blurredSnapshotNav {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.window.frame.size.width, self.window.frame.size.height-64), NO, self.window.screen.scale);
    [self.window drawViewHierarchyInRect:CGRectMake(0, -64, self.window.frame.size.width, self.window.frame.size.height-64) afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)removeOverlay {
    [UIView animateWithDuration:.25 animations:^{
        [overlayView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [overlayView removeFromSuperview];
    }];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    //NSLog(@"url: %@",url);
    if ([[url scheme] isEqualToString:kUrlScheme]) {
        if ([[url query] length]) {
            NSDictionary *urlDict = [self parseQueryString:[url query]];
            if ([urlDict objectForKey:@"task_id"] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
                BHDashboardViewController *dashboard = nil;
                for (UIViewController *vc in [_nav viewControllers]) {
                    if ([vc isKindOfClass:[BHDashboardViewController class]]){
                        dashboard = (BHDashboardViewController*)vc;
                        break;
                    }
                }
                if (dashboard) {
                    [_nav popToViewController:dashboard animated:NO];
                    [_manager GET:[NSString stringWithFormat:@"%@/worklist_items/%@",kApiBaseUrl,[urlDict objectForKey:@"task_id"]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        //NSLog(@"success getting task: %@",responseObject);
                        WorklistItem *item = [WorklistItem MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"worklist_item"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                        if (!item){
                            item = [WorklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                        }
                        [item populateFromDictionary:[responseObject objectForKey:@"worklist_item"]];
                        BHTaskViewController *taskVC = [_nav.storyboard instantiateViewControllerWithIdentifier:@"Task"];
                        [taskVC setProject:item.project];
                        [taskVC setTask:item];
                        [_nav pushViewController:taskVC animated:YES];
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"Failed to load task: %@",error.description);
                    }];
                    
                }
            }
        }

    }
    return YES;
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [dict setObject:val forKey:key];
    }
    //NSLog(@"parsed query dict: %@",dict);
    return dict;
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
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [MagicalRecord cleanUp];
}

- (void)offlineNotification {
    [[[UIAlertView alloc] initWithTitle:@"Offline" message:@"Your device appears to be offline." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}

#pragma mark uncaughtExceptionHandler
void uncaughtExceptionHandler(NSException *exception) {
    //[Flurry logError:exception.name message:exception.description exception:exception];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)pushMessage
{
    [Flurry logEvent:@"Did Receive Remote Notification"];
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
