//
//  BHLoginViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWRevealViewController/SWRevealViewController.h>

@interface BHLoginViewController : UIViewController
@property (strong, nonatomic) SWRevealViewController *revealViewController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
-(void)adjustLoginContainer;
@end
