//
//  BHSyncViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHSyncViewController.h"
#import "BHAppDelegate.h"
#import "BHSyncCell.h"
#import "Task+helper.h"
#import "Checklist+helper.h"
#import "Report+helper.h"
#import "BHSyncController.h"

@implementation BHSyncViewController {
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    NSArray *tasks;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = [UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SyncCell";
    BHSyncCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    return cell;
}

- (void)viewWillDisappear:(BOOL)animated {
    [ProgressHUD dismiss];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
