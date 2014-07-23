//
//  BHPhotoPickerCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/10/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHPhotoPickerCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UILabel *bucketLabel;
@property (weak, nonatomic) IBOutlet UILabel *docLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

@end
