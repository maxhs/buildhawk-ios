//
//  BHLocationsViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/12/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Task+helper.h"
@protocol BHLocationsDelegate <NSObject>
- (void)locationAdded:(Location*)location;
- (void)locationRemoved:(Location*)location;
@end


@interface BHLocationsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSNumber *taskId;
@property (strong, nonatomic) NSNumber *projectId;
@property (weak, nonatomic) id<BHLocationsDelegate>locationsDelegate;

@end
