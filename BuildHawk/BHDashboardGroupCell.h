//
//  BHDashboardGroupCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/15/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHDashboardGroupCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *groupCountLabel;
@end
