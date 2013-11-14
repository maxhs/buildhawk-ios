//
//  BHTabBarViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHTabBarViewController.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHPhoto.h"
#import "BHUser.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface BHTabBarViewController ()

@end

@implementation BHTabBarViewController

@synthesize project, user;

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
    [self loadproject];
    self.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"whiteTabBackground"];
}

- (void)loadproject {
    [SVProgressHUD showWithStatus:@"Fetching project..."];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[NSString stringWithFormat:@"%@/project",kApiBaseUrl] parameters:@{@"pid":self.project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"project response from tab bar vc: %@", responseObject);
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
