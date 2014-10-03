//
//  BHDashboardProjectCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project+helper.h"

@interface BHDashboardProjectCell : UITableViewCell <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UIButton *projectButton;
@property (weak, nonatomic) IBOutlet UIButton *progressButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *hideButton;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;

- (void)configureForProject:(Project*)project andUser:(User*)user;
@end
