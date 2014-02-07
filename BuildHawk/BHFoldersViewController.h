//
//  BHFoldersViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 1/31/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHFoldersViewController : UIViewController

@property (strong, nonatomic) NSSet *photoSet;
@property (strong, nonatomic) NSMutableArray *photosArray;
@property (strong, nonatomic) NSArray *sectionTitles;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
