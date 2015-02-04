//
//  BHProgressCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 11/18/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LDProgressView/LDProgressView.h>

@interface BHProgressCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *itemLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet LDProgressView *progressView;

@end
