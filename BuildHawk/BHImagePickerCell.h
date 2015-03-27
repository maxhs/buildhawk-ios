//
//  BHImagePickerCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/16/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHImagePickerCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;
@end
