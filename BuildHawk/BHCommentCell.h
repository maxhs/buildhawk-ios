//
//  BHCommentCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHCommentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
- (void)configureCell;
@end
