//
//  BHPunchlistViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHPunchlistViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *punchlists;
@property (weak, nonatomic) IBOutlet UIView *segmentContainerView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@end
