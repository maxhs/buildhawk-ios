//
//  BHSafetyTopicsCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHSafetyTopic.h"

@interface BHSafetyTopicsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;

- (void)configureTopic:(BHSafetyTopic*)topic;
@end
