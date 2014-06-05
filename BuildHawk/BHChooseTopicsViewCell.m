//
//  BHChooseTopicsViewCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/14/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHChooseTopicsViewCell.h"

@implementation BHChooseTopicsViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureCell {
    [_chooseTopicsButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    /*self.chooseTopicsButton.layer.cornerRadius = 8.f;
    [self.chooseTopicsButton setBackgroundColor:kDarkerGrayColor];
    [self.chooseTopicsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.chooseTopicsButton.layer.borderColor = kDarkerGrayColor.CGColor;
    self.chooseTopicsButton.layer.borderWidth = .5f;
    self.chooseTopicsButton.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.chooseTopicsButton.layer.shadowOpacity =  1.f;
    self.chooseTopicsButton.layer.shadowRadius = 2.f;
    self.chooseTopicsButton.layer.shadowOffset = CGSizeMake(0, 0);
    self.chooseTopicsButton.layer.shouldRasterize = YES;
    self.chooseTopicsButton.layer.rasterizationScale = [UIScreen mainScreen].scale;*/
}

@end
