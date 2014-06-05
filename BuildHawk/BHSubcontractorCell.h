//
//  BHSubcontractorCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/25/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHPersonnelCountTextField.h"

@interface BHSubcontractorCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *personLabel;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) IBOutlet BHPersonnelCountTextField *countTextField;
@end
