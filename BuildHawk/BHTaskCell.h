//
//  BHTaskCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/9/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Task+helper.h"

@interface BHTaskCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *itemLabel;
@property (weak, nonatomic) IBOutlet UILabel *ownerLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdLabel;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
- (void)configureForTask:(Task*)task;
@end
