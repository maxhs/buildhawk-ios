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

@interface BHTabBarViewController () {
    UIBarButtonItem *saveButton;
    UIBarButtonItem *createButton;
    UIBarButtonItem *doneButton;
}

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
    //self.title = self.project.name;
    //[self loadproject];
    self.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"whiteTabBackground"];
    saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveReport)];
    createButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(createNewReport)];
    doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEditing)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCreate) name:@"Create" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSave) name:@"Save" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDone) name:@"Done" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remove) name:@"Remove" object:nil];
}

- (void) showCreate{
    self.navigationItem.rightBarButtonItem = createButton;
}
- (void) showSave{
    self.navigationItem.rightBarButtonItem = saveButton;
}
- (void) showDone{
    self.navigationItem.rightBarButtonItem = doneButton;
}
- (void) remove {
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)createNewReport {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateReport" object:nil];
}

- (void)saveReport {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SaveReport" object:nil];
}

- (void) doneEditing {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DoneEditing" object:nil];
}

- (void)loadproject {
    [SVProgressHUD showWithStatus:@"Fetching project..."];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[NSString stringWithFormat:@"%@/projects/%@",kApiBaseUrl,self.project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
