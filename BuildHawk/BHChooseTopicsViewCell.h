//
//  BHChooseTopicsViewCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHChooseTopicsViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *chooseTopicsButton;
- (void)configureCell;
@end
