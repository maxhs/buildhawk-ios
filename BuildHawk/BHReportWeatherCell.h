//
//  BHReportWeatherCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 1/31/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHReportWeatherCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *dailySummaryTextView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@end
