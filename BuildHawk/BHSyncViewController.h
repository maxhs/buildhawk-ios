//
//  BHSyncViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface BHSyncViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableOrderedSet *itemsToSync;
@property (strong, nonatomic) UIBarButtonItem *cancelAllButton;
- (void)dismiss;
@end
