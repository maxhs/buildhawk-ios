//
//  BHChecklistItemLinkCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/10/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChecklistItem+helper.h"

@interface BHChecklistItemLinkCell : UITableViewCell
- (void)configureForChecklistItem:(ChecklistItem*)item;
@end
