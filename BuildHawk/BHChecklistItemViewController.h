//
//  BHChecklistItemViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHChecklistItem.h"
#import "BHComment.h"
#import "BHPhoto.h"

@interface BHChecklistItemViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) BHChecklistItem *item;

@end