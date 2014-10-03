//
//  BHAddCommentCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHAddCommentCell.h"

@implementation BHAddCommentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _messageTextView.layer.cornerRadius = 2.f;
    _messageTextView.layer.borderColor = kLightGrayColor.CGColor;
    _messageTextView.layer.borderWidth = .5f;
    _messageTextView.clipsToBounds = YES;
}

- (void)configure{
    [_messageTextView setText:kAddCommentPlaceholder];
    [_doneButton setBackgroundColor:kSelectBlueColor];
    _doneButton.layer.cornerRadius = 3.f;
    _doneButton.clipsToBounds = YES;
}

@end
