//
//  BHCommentCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHCommentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *person;
@property (weak, nonatomic) IBOutlet UITextView *message;

@end
