//
//  BHItemContactCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHItemContactCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *textButton;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@end
