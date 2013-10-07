//
//  BHChecklistMessageCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHChecklistMessageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *textButton;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@end
