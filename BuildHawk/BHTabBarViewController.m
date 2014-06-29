//
//  BHTabBarViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHTabBarViewController.h"
#import "Photo.h"

@interface BHTabBarViewController ()

@end

@implementation BHTabBarViewController

@synthesize project, user;
@synthesize checklistIndexPath = _checklistIndexPath;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.project.name;
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"whiteTabBackground"];
    self.tabBar.clipsToBounds = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
