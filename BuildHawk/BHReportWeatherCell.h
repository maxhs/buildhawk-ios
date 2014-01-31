//
//  BHReportWeatherCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 1/31/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHReportWeatherCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *weatherContainerView;
@property (weak, nonatomic) IBOutlet UITextView *dailySummaryTextView;
@property (weak, nonatomic) IBOutlet UITextField *windTextField;
@property (weak, nonatomic) IBOutlet UITextField *precipTextField;
@property (weak, nonatomic) IBOutlet UITextField *tempTextField;
@property (weak, nonatomic) IBOutlet UITextField *humidityTextField;
@property (weak, nonatomic) IBOutlet UIImageView *weatherImageView;
@end
