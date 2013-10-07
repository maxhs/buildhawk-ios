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
#import "BHLoginViewController.h"
#import "CoreData+MagicalRecord.h"

// Use a class extension to expose access to MagicalRecord's private setter methods
@interface NSManagedObjectContext ()
+ (void)MR_setRootSavingContext:(NSManagedObjectContext *)context;
+ (void)MR_setDefaultContext:(NSManagedObjectContext *)moc;
@end

@implementation BHAppDelegate
@synthesize window = _window;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
//        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
//        splitViewController.delegate = (id)navigationController.topViewController;
//        
//        UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
//        BHLoginViewController *controller = (BHLoginViewController *)masterNavigationController.topViewController;
//        controller.managedObjectContext = self.managedObjectContext;
//    } else {
//        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
//        BHLoginViewController *controller = (BHLoginViewController *)navigationController.topViewController;
//        controller.managedObjectContext = self.managedObjectContext;
//    }

    
    // Configure RestKit's Core Data stack
    NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"BuildHawkModel" ofType:@"momd"]];
    NSManagedObjectModel *managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] mutableCopy];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"BuildHawkModel.sqlite"];
    NSError *error = nil;
    [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    [managedObjectStore createManagedObjectContexts];
    
    // Configure MagicalRecord to use RestKit's Core Data stack
    [NSPersistentStoreCoordinator MR_setDefaultStoreCoordinator:managedObjectStore.persistentStoreCoordinator];
    [NSManagedObjectContext MR_setRootSavingContext:managedObjectStore.persistentStoreManagedObjectContext];
    [NSManagedObjectContext MR_setDefaultContext:managedObjectStore.mainQueueManagedObjectContext];
    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://www.buildhawk.com/api/v1"]];
    [objectManager setAcceptHeaderWithMIMEType:RKMIMETypeJSON];
    objectManager.managedObjectStore = managedObjectStore;
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    
    RKEntityMapping *userMapping = [RKEntityMapping mappingForEntityForName:@"User" inManagedObjectStore:managedObjectStore];
    // If source and destination key path are the same, we can simply add a string to the array
    [userMapping addAttributeMappingsFromDictionary:@{
                                                      @"_id": @"identifier",
                                                      @"fullname": @"fullname",
                                                      }];
    
    
    RKEntityMapping *projectMapping = [RKEntityMapping mappingForEntityForName:@"Project" inManagedObjectStore:managedObjectStore];
    [projectMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [projectMapping addAttributeMappingsFromDictionary:@{
                                                       @"_id": @"identifier",
                                                       }];
    [projectMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"user" toKeyPath:@"user" withMapping:userMapping]];
    

    [self customizeAppearance];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
        UIStoryboard *iphoneStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        UIViewController *revealVC = [iphoneStoryboard instantiateViewControllerWithIdentifier:@"Reveal"];
        UINavigationController *navigationController = (UINavigationController *)revealVC;
        self.window.rootViewController = navigationController;
    } else {
        [self.window makeKeyAndVisible];
    }
    return YES;
}

- (void)customizeAppearance {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0f) {
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackground"] forBarMetrics:UIBarMetricsDefault];
    } else {
        [self.window setTintColor:[UIColor whiteColor]];
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navBarBackgroundTall"] forBarMetrics:UIBarMetricsDefault];
    }
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                    NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueMedium size:16],
                         NSForegroundColorAttributeName : [UIColor whiteColor]
                                    }];
    UIImage *empty = [UIImage imageNamed:@"empty"];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:empty forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:empty forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                    NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueLight size:14],
                                    NSForegroundColorAttributeName : [UIColor whiteColor]
     } forState:UIControlStateNormal];
    
    [[UISearchBar appearance] setBackgroundImage:empty];
    [[UISearchBar appearance] setSearchFieldBackgroundImage:[UIImage imageNamed:@"textField"]forState:UIControlStateNormal];
    
    [[UITabBarItem appearance] setTitleTextAttributes: @{
                    NSForegroundColorAttributeName : [UIColor lightGrayColor],
                                NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueLight size:12.0],
    } forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{
                 NSForegroundColorAttributeName : kBlueColor,
                            NSFontAttributeName : [UIFont fontWithName:kHelveticaNeueMedium size:12.0],
        } forState:UIControlStateSelected];
    [[UITabBar appearance] setTintColor:kBlueColor];
    [[UITabBar appearance] setSelectedImageTintColor:kBlueColor];
    //[[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"tabBarBackground"]];
    //[[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:@"whiteTabBackground"]];
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

//#pragma mark - Core Data Stack
//
//- (NSManagedObjectContext *)managedObjectContext {
//    if (_managedObjectContext != nil) {
//        return _managedObjectContext;
//    }
//    
//    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
//    if (coordinator != nil){
//        _managedObjectContext = [[NSManagedObjectContext alloc] init];
//        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
//    }
//    return  _managedObjectContext;
//}
//
//- (NSManagedObjectModel *)managedObjectModel {
//    if (_managedObjectModel != nil) {
//        return _managedObjectModel;
//    }
//    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BuildHawkModel" withExtension:@"momd"];
//    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
//    return _managedObjectModel;
//}
//
//- (NSPersistentStoreCoordinator*)persistentStoreCoordinator {
//    if (_persistentStoreCoordinator != nil) {
//        return _persistentStoreCoordinator;
//    }
//    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"BuildHawkModel.sqlite"];
//    NSError *error = nil;
//    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    
//    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
//        NSLog(@"error with persistent store coordinator: %@",error.description);
//        abort();
//    }
//    return _persistentStoreCoordinator;
//}
//
//- (void)saveContext {
//    NSError *error = nil;
//    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
//    if (managedObjectContext != nil) {
//        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]){
//            //error
//        }
//    }
//}
//
//- (NSURL*)applicationDocumentsDirectory {
//    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentationDirectory inDomains:NSUserDomainMask] lastObject];
//}

@end
