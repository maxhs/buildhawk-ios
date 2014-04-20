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
    UIBarButtonItem *addButton;
}

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
    self.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"whiteTabBackground"];
    saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveReport)];
    createButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createNewReport)];
    doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEditing)];
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(punchlistSegue)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCreate) name:@"Create" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSave) name:@"Save" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDone) name:@"Done" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remove) name:@"Remove" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCreatePunchlist) name:@"ShowCreatePunchlist" object:nil];
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
- (void) showCreatePunchlist {
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)punchlistSegue {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CreatePunchlistSegue" object:nil];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
