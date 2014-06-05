//
//  BHSafetyTopicViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SafetyTopic+helper.h"

@interface BHSafetyTopicViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) SafetyTopic *safetyTopic;
@end
