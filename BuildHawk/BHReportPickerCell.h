//
//  BHReportPickerCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/5/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHReportPickerCell : UITableViewCell <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIButton *typePickerButton;
@property (weak, nonatomic) IBOutlet UIButton *datePickerButton;
@property (weak, nonatomic) IBOutlet UIView *weatherContainerView;
@property (weak, nonatomic) IBOutlet UITextView *dailySummaryTextView;
@property (weak, nonatomic) IBOutlet UITextField *windTextField;
@property (weak, nonatomic) IBOutlet UITextField *precipTextField;
@property (weak, nonatomic) IBOutlet UITextField *tempTextField;
@property (weak, nonatomic) IBOutlet UIImageView *weatherImageView;
-(void)configure;
@end
