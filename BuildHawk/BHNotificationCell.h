//
//  BHNotificationCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHNotificationCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@end
