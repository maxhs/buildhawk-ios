//
//  BHActivityCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/26/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHActivityCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@end
