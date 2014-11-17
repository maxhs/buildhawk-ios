//
//  BHAppDelegate.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHAppDelegate.h"
#import "Project.h"
#import "BHProjectCollection.h"
#import "Constants.h"
#import "BHLoginViewController.h"
#import "UIImage+ImageEffects.h"
#import "BHTaskViewController.h"
#import "BHMenuViewController.h"
#import "BHDashboardViewController.h"
#import "User+helper.h"
#import "Report+helper.h"
#import "Message+helper.h"
#import "CoreData+MagicalRecord.h"
#import <Crashlytics/Crashlytics.h>
#import <SDWebImage/SDWebImageManager.h>
#import <RESideMenu/RESideMenu.h>

#define MIXPANEL_TOKEN @"2e57104ead72acdd8a77ca963e32e74a"

@interface BHAppDelegate () <RESideMenuDelegate> {
    UIView *overlayView;
    CGRect screen;
    UILabel *statusLabel;
}
@end

@implementation BHAppDelegate

@synthesize activeTabBarController = _activeTabBarController;
@synthesize menu = _menu;
@synthesize bundleName = _bundleName;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
    [MagicalRecord setupAutoMigratingCoreDataStack];
    [self setupThirdPartyAnalytics];
    
    //create the sync controller singleton
    _syncController = [BHSyncController sharedController];
    //assume we're connected to start
    _connected = YES;
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"Connected via WWAN");
                _connected = YES;
                if (statusLabel)
                    [self removeStatusMessage];
                [_syncController syncAll];
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"Connected via WIFI");
                _connected = YES;
                if (statusLabel)
                    [self removeStatusMessage];
                [_syncController syncAll];
                break;
            case AFNetworkReachabilityStatusUnknown:
                NSLog(@"Reachability not known");
                [self offlineNotification];
                _connected = NO;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"Not online");
                [self offlineNotification];
                _connected = NO;
                break;
            default:
                break;
                
        }
    }];
    
    //set up the AFNetworking manager. this one's important!
    _manager = [[AFHTTPRequestOperationManager manager] initWithBaseURL:[NSURL URLWithString:kApiBaseUrl]];
    [_manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"buildhawk_mobile" password:@"aca344dc4b27b82f994094d8c9bab0af"];
    [_manager.requestSerializer setValue:(IDIOM == IPAD) ? @"2" : @"1" forHTTPHeaderField:@"device_type"];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    //test to see whether we have a current user
    UINavigationController *nav;
    if (_currentUser){
        //head straight into the app
        BHDashboardViewController *vc = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Dashboard"];
        nav = [[UINavigationController alloc] initWithRootViewController:vc];
    } else {
        //show the login UI
        nav = (UINavigationController*)self.window.rootViewController;
    }
    
    // set the delegate's logged in/logged out flag
    [self updateLoggedInStatus];
    
    _menu = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    RESideMenu *sideMenuViewController = [[RESideMenu alloc] initWithContentViewController:nav
                                                                    leftMenuViewController:_menu
                                                                   rightMenuViewController:nil];
    sideMenuViewController.menuPreferredStatusBarStyle = 1; // UIStatusBarStyleLightContent
    sideMenuViewController.delegate = self;
    self.window.rootViewController = sideMenuViewController;
    self.window.backgroundColor = [UIColor blackColor];
    
    [self customizeAppearance];
    
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
                                                         //NSForegroundColorAttributeName : [UIColor whiteColor],
                                                         NSFontAttributeName : [UIFont fontWithName:kMyriadProRegular size:tabFontSize],
                                                         } forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{
                 NSForegroundColorAttributeName : [UIColor colorWithWhite:0 alpha:1],
                            NSFontAttributeName : [UIFont fontWithName:kMyriadProRegular size:tabFontSize],
                                                        } forState:UIControlStateSelected];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
        [[UITabBar appearance] setBarTintColor:[UIColor whiteColor]];
        [[UITabBar appearance] setSelectedImageTintColor:[UIColor colorWithWhite:0 alpha:1.0]];
    } else {
        
    }
    
    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackground"]];
    [[UISwitch appearance] setOnTintColor:kBlueColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]
     setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]} forState:UIControlStateNormal];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kMyriadProRegular size:15]} forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setContentPositionAdjustment:UIOffsetMake(0, 1) forSegmentType:UISegmentedControlSegmentAny barMetrics:UIBarMetricsDefault];
    
    /*for (NSString* family in [UIFont familyNames]){
        NSLog(@"%@", family);
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
            NSLog(@"  %@", name);
    }*/
}

- (void)updateLoggedInStatus {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        self.loggedIn = YES;
    } else {
        self.loggedIn = NO;
    }
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
     setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]} forState:UIControlStateNormal];
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
                UINavigationController *nav = (UINavigationController*)[(RESideMenu*)self.window.rootViewController contentViewController];
                for (UIViewController *vc in [nav viewControllers]) {
                    if ([vc isKindOfClass:[BHDashboardViewController class]]){
                        dashboard = (BHDashboardViewController*)vc;
                        break;
                    }
                }
                if (dashboard) {
                    [nav popToViewController:dashboard animated:NO];
                    [_manager GET:[NSString stringWithFormat:@"%@/tasks/%@",kApiBaseUrl,[urlDict objectForKey:@"task_id"]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        //NSLog(@"success getting task: %@",responseObject);
                        Task *item = [Task MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"task"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                        if (!item){
                            item = [Task MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                        }
                        [item populateFromDictionary:[responseObject objectForKey:@"task"]];
                        BHTaskViewController *taskVC = [nav.storyboard instantiateViewControllerWithIdentifier:@"Task"];
                        [taskVC setProject:item.project];
                        [taskVC setTask:item];
                        [nav pushViewController:taskVC animated:YES];
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        //NSLog(@"Failed to load task: %@",error.description);
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
    if (_connected)
        [[[UIAlertView alloc] initWithTitle:@"Device Offline" message:@"You can continue to work offline, although not all data may display properly. Changes will be synchronized when you reconnect." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];

    [ProgressHUD dismiss];
    [self displayStatusMessage:@"Your device is currently offline"];
}

- (void)displayStatusMessage:(NSString*)string {
    CGFloat statusHeight = kOfflineStatusHeight;
    if (!statusLabel){
        statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, screenHeight(), screenWidth(), statusHeight)];
        [statusLabel setBackgroundColor:kDarkerGrayColor];
        [statusLabel setTextAlignment:NSTextAlignmentCenter];
        [statusLabel setTextColor:[UIColor whiteColor]];
        [statusLabel setFont:[UIFont fontWithName:kMyriadProRegular size:14]];
        [self.window addSubview:statusLabel];
    }
    [statusLabel setText:string];
    
    UINavigationController *nav = (UINavigationController*)[(RESideMenu*)self.window.rootViewController contentViewController];
    CGRect tabFrame = _activeTabBarController.tabBar.frame;
    tabFrame.origin.y = screenHeight() - tabFrame.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - nav.navigationBar.frame.size.height - statusHeight;
    
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [statusLabel setFrame:CGRectMake(0, screenHeight()-statusHeight, screenWidth(), statusHeight)];
        [_activeTabBarController.tabBar setFrame:tabFrame];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)prepareStatusLabelForTab {
    CGFloat statusHeight = kOfflineStatusHeight;
    UINavigationController *nav = (UINavigationController*)[(RESideMenu*)self.window.rootViewController contentViewController];
    CGRect tabFrame = _activeTabBarController.tabBar.frame;
    tabFrame.origin.y = screenHeight() - tabFrame.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - nav.navigationBar.frame.size.height - statusHeight;
    [_activeTabBarController.tabBar setFrame:tabFrame];
}

- (void)removeStatusMessage{
    CGFloat statusHeight = kOfflineStatusHeight;
    UINavigationController *nav = (UINavigationController*)[(RESideMenu*)self.window.rootViewController contentViewController];
    CGRect tabFrame = _activeTabBarController.tabBar.frame;
    tabFrame.origin.y = screenHeight() - tabFrame.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - nav.navigationBar.frame.size.height;
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [statusLabel setFrame:CGRectMake(0, screenHeight(), screenWidth(), statusHeight)];
        [_activeTabBarController.tabBar setFrame:tabFrame];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)pushMessage
{
    [[Mixpanel sharedInstance] trackPushNotification:pushMessage];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    //NSLog(@"didRegisterUserNotificationSettings: %@",notificationSettings);
    //NSLog(@"Current user notification cettings: %@",[[UIApplication sharedApplication] currentUserNotificationSettings]);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kUserDefaultsDeviceToken];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (_connected && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:deviceToken forKey:@"token"];
        [_manager DELETE:[NSString stringWithFormat:@"%@/users/%@/remove_push_token",kApiBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success with removing push token: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to remove push token: %@",error.description);
        }];
    }
    //NSLog(@"device token: %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    
}

- (void)notifyError:(NSError*)error andOperation:(AFHTTPRequestOperation *)operation andObject:(id)object {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    if (error){
        [parameters setObject:error.localizedDescription forKey:@"body"];
    }
    if (operation){
        [parameters setObject:[NSNumber numberWithInteger:operation.response.statusCode] forKey:@"status_code"];
    }
    if (object){
        if ([object isKindOfClass:[Photo class]] && [(Photo*)object identifier]){
            [parameters setObject:[(Photo*)object identifier] forKey:@"photo"];
        } else if ([object isKindOfClass:[Report class]] && [(Report*)object identifier]){
            [parameters setObject:[(Report*)object identifier] forKey:@"report_id"];
        } else if ([object isKindOfClass:[ChecklistItem class]] && [(ChecklistItem*)object identifier]) {
            [parameters setObject:[(ChecklistItem*)object identifier] forKey:@"checklist_item"];
        } else if ([object isKindOfClass:[Task class]] && [(Task*)object identifier]){
            [parameters setObject:[(Task*)object identifier] forKey:@"task"];
        } else if ([object isKindOfClass:[Message class]] && [(Message*)object identifier]) {
            [parameters setObject:[(Message*)object identifier] forKey:@"message"];
        }
    }
    
    if (parameters.count){
        [_manager POST:[NSString stringWithFormat:@"%@/errors",kApiBaseUrl] parameters:@{@"error":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success creating an error log: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating an error :( %@", error.description);
        }];
    }
}

- (void)setupThirdPartyAnalytics {
    [NewRelicAgent startWithApplicationToken:@"AA3d665c20df063e38a87cd6eac85c866368d682c1"];
    [Crashlytics startWithAPIKey:@"c52cd9c3cd08f8c9c0de3a248a813118655c8005"];
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Launch"];
    
//    // Optional: automatically send uncaught exceptions to Google Analytics.
//    [GAI sharedInstance].trackUncaughtExceptions = YES;
//    [GAI sharedInstance].dispatchInterval = 20;
//    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelNone];
//    // Initialize tracker.
//    [[GAI sharedInstance] trackerWithTrackingId:@"UA-43601553-1"];
}

@end
