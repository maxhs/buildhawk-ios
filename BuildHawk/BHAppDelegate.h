//
//  BHAppDelegate.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHMenuViewController.h"
//#import "GAI.h"

@interface BHAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@property (strong, nonatomic) UINavigationController *nav;
@property (strong, nonatomic) BHMenuViewController *menu;
@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) NSString *bundleName;
@property BOOL connected;

- (UIView*)addOverlayUnderNav:(BOOL)underNav;
- (void)offlineNotification;
- (void)setDefaultAppearances;
- (void)setToBuildHawkAppearances;
@end
