//
//  BHAppDelegate.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHMenuViewController.h"
#import "BHSyncController.h"
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "UIFontDescriptor+Custom.h"
//#import "GAI.h"

@interface BHAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@property (strong, nonatomic) BHMenuViewController *menu;
@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) NSString *bundleName;
@property (strong, nonatomic) BHSyncController *syncController;
@property (strong, nonatomic) BHTabBarViewController *activeTabBarController;
@property BOOL connected;
@property BOOL synching;
@property BOOL loggedIn;

- (UIView*)addOverlayUnderNav:(BOOL)underNav;
- (void)offlineNotification;
- (void)updateLoggedInStatus;
- (void)setDefaultAppearances;
- (void)setToBuildHawkAppearances;
- (void)displayStatusMessage:(NSString*)string;
- (void)showSyncController;
- (void)removeStatusMessage;
- (void)prepareStatusLabelForTab;
- (void)notifyError:(NSError*)error andOperation:(AFHTTPRequestOperation*)operation andObject:(id)object;
@end
