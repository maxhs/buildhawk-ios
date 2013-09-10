//
//  BHReportSectionCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/5/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHReportSectionCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *reportSectionLabel;
@property (weak, nonatomic) IBOutlet UITextView *reportBodyTextView;

@end
