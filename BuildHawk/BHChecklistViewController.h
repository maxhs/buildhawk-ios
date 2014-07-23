//
//  BHChecklistViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHDeselectableSegmentedControl.h"
//#import "GAITrackedViewController.h"

@interface BHChecklistViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet BHDeselectableSegmentedControl *segmentedControl;
@end
