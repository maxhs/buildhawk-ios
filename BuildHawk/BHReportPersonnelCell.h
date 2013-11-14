//
//  BHReportPersonnelCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/21/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHReportPersonnelCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *pickFromListButton;
@property (weak, nonatomic) IBOutlet UILabel *reportSectionLabel;
@property (weak, nonatomic) IBOutlet UIView *labelBackgroundView;
- (void)configureCell;
@end
