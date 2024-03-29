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
#import "BHSyncTransition.h"
#import <MessageUI/MessageUI.h>

#define MIXPANEL_TOKEN @"2e57104ead72acdd8a77ca963e32e74a"

@interface BHAppDelegate () <RESideMenuDelegate, UIViewControllerTransitioningDelegate> {
    UIView *overlayView;
    CGRect screen;
    UIButton *statusButton;
    BOOL showingSync;
}
@end

@implementation BHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
    [MagicalRecord setupAutoMigratingCoreDataStack];
    [self setupThirdPartyAnalytics];
    [self hackForPreloadingKeyboard];
    self.syncController = [BHSyncController sharedController]; //create the sync controller singleton
    self.connected = YES; //assume we're connected to start
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"Connected via WWAN");
                self.connected = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Connected" object:nil];
                [self.syncController update];
                [self.syncController syncAll];
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"Connected via WIFI");
                self.connected = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Connected" object:nil];
                [self.syncController update];
                [self.syncController syncAll];
                break;
            case AFNetworkReachabilityStatusUnknown:
                NSLog(@"Reachability not known");
                [self offlineNotification];
                self.connected = NO;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"Not online");
                [self offlineNotification];
                self.connected = NO;
                break;
            default:
                break;
        }
    }];
    
    //set up the AFNetworking manager. this one's important!
    _manager = [[AFHTTPRequestOperationManager manager] initWithBaseURL:[NSURL URLWithString:kApiBaseUrl]];
    [_manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"buildhawk_mobile" password:@"aca344dc4b27b82f994094d8c9bab0af"];
    [_manager.requestSerializer setValue:(IDIOM == IPAD) ? @"2" : @"1" forHTTPHeaderField:@"device_type"];
    [self updateLoggedInStatus]; // set the delegate's logged in/logged out flag
    
    self.menu = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    RESideMenu *sideMenuViewController = [[RESideMenu alloc] initWithContentViewController:self.window.rootViewController
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
    CGFloat tabFontSize = IDIOM == IPAD ? 17 : 15;
    
    [[UITabBarItem appearance] setTitleTextAttributes: @{
                                                         //NSForegroundColorAttributeName : [UIColor whiteColor],
                                                         NSFontAttributeName : [UIFont fontWithName:kMyriadPro size:tabFontSize],
                                                         } forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{
                 NSForegroundColorAttributeName : [UIColor colorWithWhite:0 alpha:1],
                            NSFontAttributeName : [UIFont fontWithName:kMyriadPro size:tabFontSize],
                                                        } forState:UIControlStateSelected];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
        [[UITabBar appearance] setBarTintColor:[UIColor whiteColor]];
        [[UITabBar appearance] setSelectedImageTintColor:[UIColor colorWithWhite:0 alpha:1.0]];
    }
    
    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackground"]];
    [[UISwitch appearance] setOnTintColor:kBlueColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]
     setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]} forState:UIControlStateNormal];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kMyriadPro size:15]} forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setContentPositionAdjustment:UIOffsetMake(0, 1) forSegmentType:UISegmentedControlSegmentAny barMetrics:UIBarMetricsDefault];
    
    /*for (NSString* family in [UIFont familyNames]){
        NSLog(@"%@", family);
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
            NSLog(@"  %@", name);
    }*/
}

- (void)updateLoggedInStatus {
    self.loggedIn = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] ? YES : NO;
}

//the next two methods are so the damn message and mail navigation bars don't look like shit
- (void)setDefaultAppearances {
    [[UINavigationBar appearance] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName : [UIFont fontWithName:kMyriadPro size:22],
                                                           NSForegroundColorAttributeName : [UIColor blackColor]
                                                           }];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName : [UIFont fontWithName:kMyriadPro size:16],
                                                           NSForegroundColorAttributeName : [UIColor blackColor]
                                                           } forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)setToBuildHawkAppearances{
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackgroundTall"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName : [UIFont fontWithName:kMyriadPro size:22],
                                                           NSForegroundColorAttributeName : [UIColor whiteColor]
                                                           }];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:1.f forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName : [UIFont fontWithName:kMyriadPro size:16],
                                                           NSForegroundColorAttributeName : [UIColor whiteColor]
                                                           } forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 3) forBarMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]
     setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]} forState:UIControlStateNormal];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
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
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.window.frame.size.width, self.window.frame.size.height), NO, self.window.screen.scale);
    [self.window drawViewHierarchyInRect:CGRectMake(0, -64, self.window.frame.size.width, self.window.frame.size.height) afterScreenUpdates:YES];
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
                        [taskVC setTaskId:item.objectID];
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

- (void)applicationWillResignActive:(UIApplication *)application {
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

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [MagicalRecord cleanUp];
}

- (void)offlineNotification {
    if (_connected) {
        [[[UIAlertView alloc] initWithTitle:@"Device Offline" message:@"You can continue to work offline, although not all data may display properly. Changes will be synchronized when you reconnect." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }

    [ProgressHUD dismiss];
    [self displayStatusMessage:kDeviceOfflineMessage];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceOffline" object:nil];
}

- (void)displayStatusMessage:(NSString*)string {
    if (!statusButton){
        statusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [statusButton setFrame:CGRectMake(0, screenHeight(), screenWidth(), kOfflineStatusHeight)];
        [statusButton setBackgroundColor:kDarkerGrayColor];
        [statusButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [statusButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [statusButton.titleLabel setFont:[UIFont fontWithName:kMyriadPro size:14]];
        [statusButton addTarget:self action:@selector(showSyncController) forControlEvents:UIControlEventTouchUpInside];
        
        [self.window addSubview:statusButton];
    }
    [statusButton setTitle:string forState:UIControlStateNormal];
    
    UINavigationController *nav = (UINavigationController*)[(RESideMenu*)self.window.rootViewController contentViewController];
    CGRect tabFrame = _activeTabBarController.tabBar.frame;
    tabFrame.origin.y = screenHeight() - tabFrame.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - nav.navigationBar.frame.size.height - kOfflineStatusHeight;
    
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [statusButton setFrame:CGRectMake(0, screenHeight()-kOfflineStatusHeight, screenWidth(), kOfflineStatusHeight)];
        [_activeTabBarController.tabBar setFrame:tabFrame];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)showSyncController {
    if (self.syncController.synchCount > 0 && !showingSync){
        UINavigationController *nav = (UINavigationController*)[(RESideMenu*)self.window.rootViewController contentViewController];
        self.synchViewController = [nav.storyboard instantiateViewControllerWithIdentifier:@"SynchView"];
        NSMutableOrderedSet *itemsToSynch = [NSMutableOrderedSet orderedSetWithArray:_syncController.tasks];
        [itemsToSynch addObjectsFromArray:_syncController.reports];
        [itemsToSynch addObjectsFromArray:_syncController.checklistItems];
        [itemsToSynch addObjectsFromArray:_syncController.tasks];
        [itemsToSynch addObjectsFromArray:_syncController.users];
        [itemsToSynch addObjectsFromArray:_syncController.comments];
        [itemsToSynch addObjectsFromArray:_syncController.reminders];
        [itemsToSynch addObjectsFromArray:_syncController.projects];
        [self.synchViewController setItemsToSync:itemsToSynch];
        UINavigationController *newNav = [[UINavigationController alloc] initWithRootViewController:self.synchViewController];
        newNav.transitioningDelegate = self;
        newNav.modalPresentationStyle = UIModalPresentationCustom;
        [nav.viewControllers.lastObject presentViewController:newNav animated:YES completion:^{
            
        }];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    BHSyncTransition *animator = [BHSyncTransition new];
    animator.presenting = YES;
    showingSync = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    BHSyncTransition *animator = [BHSyncTransition new];
    showingSync = NO;
    return animator;
}

- (void)hideSyncController {
    UINavigationController *nav = (UINavigationController*)[(RESideMenu*)self.window.rootViewController contentViewController];
    [nav.viewControllers.lastObject dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)prepareStatusLabelForTab {
    CGFloat statusHeight = kOfflineStatusHeight;
    UINavigationController *nav = (UINavigationController*)[(RESideMenu*)self.window.rootViewController contentViewController];
    CGRect tabFrame = self.activeTabBarController.tabBar.frame;
    tabFrame.origin.y = screenHeight() - tabFrame.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - nav.navigationBar.frame.size.height - statusHeight;
    [self.activeTabBarController.tabBar setFrame:tabFrame];
    [_syncController syncAll];
}

- (void)removeStatusMessage{
    UINavigationController *nav = (UINavigationController*)[(RESideMenu*)self.window.rootViewController contentViewController];
    CGRect tabFrame = _activeTabBarController.tabBar.frame;
    tabFrame.origin.y = screenHeight() - tabFrame.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - nav.navigationBar.frame.size.height;
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [statusButton setFrame:CGRectMake(0, screenHeight(), screenWidth(), kOfflineStatusHeight)];
        [_activeTabBarController.tabBar setFrame:tabFrame];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)pushMessage {
    [[Mixpanel sharedInstance] trackPushNotification:pushMessage];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    //NSLog(@"didRegisterUserNotificationSettings: %@",notificationSettings);
    //NSLog(@"Current user notification cettings: %@",[[UIApplication sharedApplication] currentUserNotificationSettings]);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kUserDefaultsDeviceToken];
    [[NSUserDefaults standardUserDefaults] synchronize];
//    if (_connected && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
//        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
//        [parameters setObject:deviceToken forKey:@"token"];
//        [_manager DELETE:[NSString stringWithFormat:@"%@/users/%@/remove_push_token",kApiBaseUrl,[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            //NSLog(@"Success with removing push token: %@",responseObject);
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            NSLog(@"Failed to remove push token: %@",error.description);
//        }];
//    }
    //NSLog(@"device token: %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    
}

- (void)notifyError:(NSError*)error andOperation:(AFHTTPRequestOperation *)operation andObject:(id)object {
//    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
//    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
//        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
//    }
//    if (error){
//        [parameters setObject:error.localizedDescription forKey:@"body"];
//    }
//    if (operation){
//        [parameters setObject:[NSNumber numberWithInteger:operation.response.statusCode] forKey:@"status_code"];
//    }
//    if (object){
//        if ([object isKindOfClass:[Photo class]] && [(Photo*)object identifier]){
//            [parameters setObject:[(Photo*)object identifier] forKey:@"photo"];
//        } else if ([object isKindOfClass:[Report class]] && [(Report*)object identifier]){
//            [parameters setObject:[(Report*)object identifier] forKey:@"report_id"];
//        } else if ([object isKindOfClass:[ChecklistItem class]] && [(ChecklistItem*)object identifier]) {
//            [parameters setObject:[(ChecklistItem*)object identifier] forKey:@"checklist_item"];
//        } else if ([object isKindOfClass:[Task class]] && [(Task*)object identifier]){
//            [parameters setObject:[(Task*)object identifier] forKey:@"task"];
//        } else if ([object isKindOfClass:[Message class]] && [(Message*)object identifier]) {
//            [parameters setObject:[(Message*)object identifier] forKey:@"message"];
//        }
//    }
//    
//    if (parameters.count){
//        [_manager POST:[NSString stringWithFormat:@"%@/errors",kApiBaseUrl] parameters:@{@"error":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            NSLog(@"Success creating an error log: %@",responseObject);
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            NSLog(@"Error creating an error :( %@", error.description);
//        }];
//    }
}

- (void)hackForPreloadingKeyboard {
    UITextField *lagFreeField = [[UITextField alloc] init];
    [self.window addSubview:lagFreeField];
    [lagFreeField becomeFirstResponder];
    [lagFreeField resignFirstResponder];
    [lagFreeField removeFromSuperview];
}

- (void)setupThirdPartyAnalytics {
    //[NewRelicAgent startWithApplicationToken:@"AA3d665c20df063e38a87cd6eac85c866368d682c1"];
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
