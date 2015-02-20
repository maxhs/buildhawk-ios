//
//  BHLocationCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/12/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Location+helper.h"

@interface BHLocationCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
- (void)configureForLocation:(Location*)location;
- (void)configureToAdd:(NSString *)searchText;

@end
