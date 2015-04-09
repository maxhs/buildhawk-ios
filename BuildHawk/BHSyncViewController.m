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
#import "Reminder+helper.h"
#import "BHUtilities.h"

@implementation BHSyncViewController {
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    NSArray *tasks;
    UIBarButtonItem *dismissButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = [UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    self.cancelAllButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel All" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAll)];
    self.navigationItem.rightBarButtonItem = self.cancelAllButton;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationItem setTitle:[NSString stringWithFormat:@"Synching %lu items",(unsigned long)_itemsToSync.count]];
    
    self.tableView.rowHeight = 54.f;
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.14]];
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [backgroundToolbar setTranslucent:YES];
    [self.tableView setBackgroundView:backgroundToolbar];
    
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)cancelAll {
    [delegate.syncController cancelSynch];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _itemsToSync.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SyncCell";
    BHSyncCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    id object = self.itemsToSync[indexPath.row];
    if ([object isKindOfClass:[Report class]]){
        Report *r = (Report*)object;
        [cell.textLabel setText:[NSString stringWithFormat:@"%@ Report – %@",r.type,r.dateString]];
    } else if ([object isKindOfClass:[Comment class]]) {
        Comment *c = (Comment*)object;
        [cell.textLabel setText:[NSString stringWithFormat:@"\"%@\"",c.body]];
    } else if ([object isKindOfClass:[ChecklistItem class]]) {
        ChecklistItem *c = (ChecklistItem*)object;
        [cell.textLabel setText:[NSString stringWithFormat:@"Checklist Item: \"%@\"",c.body]];
    } else if ([object isKindOfClass:[Task class]]) {
        Task *t = (Task*)object;
        [cell.textLabel setText:[NSString stringWithFormat:@"Task: \"%@\"",t.body]];
    } else if ([object isKindOfClass:[Task class]]) {
        Reminder *r = (Reminder*)object;
        [cell.textLabel setText:[NSString stringWithFormat:@"%@ reminder for: \"%@\"",[BHUtilities parseDateReturnString:r.reminderDate],r.checklistItem.body]];
    } else if ([object isKindOfClass:[Project class]]) {
        Project *p = (Project*)object;
        [cell.textLabel setText:[NSString stringWithFormat:@"%@",p.name]];
    } else {
        [cell.textLabel setText:@"Synchronizing...."];
    }
    [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProLight] size:0]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        id object = self.itemsToSync[indexPath.row];
        if ([object isKindOfClass:[Report class]]){
            Report *r = (Report*)object;
            [r setSaved:@YES];
        } else if ([object isKindOfClass:[Comment class]]) {
            Comment *c = (Comment*)object;
            [c setSaved:@YES];
        } else if ([object isKindOfClass:[ChecklistItem class]]) {
            ChecklistItem *c = (ChecklistItem*)object;
            [c setSaved:@YES];
        } else if ([object isKindOfClass:[Task class]]) {
            Task *t = (Task*)object;
            [t setSaved:@YES];
        } else if ([object isKindOfClass:[Task class]]) {
            Reminder *r = (Reminder*)object;
            [r setSaved:@YES];
        } else if ([object isKindOfClass:[Project class]]) {
            Project *p = (Project*)object;
            [p setSaved:@YES];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        [self.tableView beginUpdates];
        [self.itemsToSync removeObject:object];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
        [delegate.syncController update];
        [self.navigationItem setTitle:[NSString stringWithFormat:@"Synching %lu items",(unsigned long)_itemsToSync.count]];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [ProgressHUD dismiss];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
