//
//  BHReportCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Report.h"

@interface BHReportCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *reportLabel;
@property (weak, nonatomic) IBOutlet UILabel *personnelLabel;
@property (weak, nonatomic) IBOutlet UILabel *notesLabel;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;

- (void)configureReport:(Report*)report;
@end
