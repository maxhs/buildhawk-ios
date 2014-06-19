//
//  BHChoosePersonnelCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/29/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHChoosePersonnelCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectDetail;
@property (weak, nonatomic) IBOutlet UITextField *hoursTextField;
@end
