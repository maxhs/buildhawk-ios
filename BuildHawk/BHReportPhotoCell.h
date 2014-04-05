//
//  BHReportPhotoCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/16/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHReportPhotoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UIButton *libraryButton;
@property (weak, nonatomic) IBOutlet UIView *photoButtonContainerView;
@property (weak, nonatomic) IBOutlet UIScrollView *photoScrollView;
- (void)configureCell;
@end
