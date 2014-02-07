//
//  BHProjectDocsViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/6/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>

@interface BHProjectDocsViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,MWPhotoBrowserDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *photosArray;

@end
