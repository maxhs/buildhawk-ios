//
//  BHActivityCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/26/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Activity.h"

@interface BHActivityCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
- (void)configureForActivity:(Activity*)activity;
- (void)configureForComment:(Comment*)comment;
- (void)configureActivityForSynopsis:(Activity*)activity;
@end
