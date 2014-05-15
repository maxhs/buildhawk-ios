//
//  BHChecklistCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/28/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChecklistItem+helper.h"
#import "ChecklistItem.h"

@interface BHChecklistCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemBody;
@property (weak, nonatomic) IBOutlet UILabel *progressPercentage;
@property (strong, nonatomic) NSNumber *level;
@property (strong, nonatomic) ChecklistItem *item;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;
@end
