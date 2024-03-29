//
//  BHReportPersonnelCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/21/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHPersonnelCountTextField.h"

@interface BHReportPersonnelCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *personLabel;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) IBOutlet BHPersonnelCountTextField *countTextField;
@end
