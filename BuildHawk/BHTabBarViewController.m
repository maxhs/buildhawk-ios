//
//  BHTabBarViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHTabBarViewController.h"
#import "Photo.h"
#import "BHAppDelegate.h"

@interface BHTabBarViewController () {
    BHAppDelegate *delegate;
}

@end

@implementation BHTabBarViewController

@synthesize project;
@synthesize checklistIndexPath = _checklistIndexPath;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.project.name;
    self.automaticallyAdjustsScrollViewInsets = YES;
    if (IDIOM == IPAD){
        self.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"whiteTabBackgroundIPAD"];
    } else {
        self.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"whiteTabBackground"];
    }
    self.tabBar.clipsToBounds = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate setActiveTabBarController:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [delegate.syncController update];
    if (delegate.syncController.synchCount > 0 || !delegate.connected){
        NSLog(@"synch count now? %lu",(unsigned long)delegate.syncController.synchCount);
        [delegate prepareStatusLabelForTab];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
