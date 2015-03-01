//
//  BHChooseReportPersonnelCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/21/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHChooseReportPersonnelCell.h"
#import "UIFontDescriptor+Custom.h"
#import "Constants.h"

@implementation BHChooseReportPersonnelCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [_prefillButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadProSemibold] size:0]];
    [_prefillButton setTitle:kPrefillPersonnelPlaceholder forState:UIControlStateNormal];
    [_prefillButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_choosePersonnelButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadProSemibold] size:0]];
    [_choosePersonnelButton setTitle:kChoosePersonnelPlaceholder forState:UIControlStateNormal];
    [_choosePersonnelButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
}

- (void)buttonTreatment:(UIButton*)button {
    button.layer.cornerRadius = 7.f;
    [button setBackgroundColor:kDarkerGrayColor];
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    button.layer.shadowOpacity = 1.f;
    button.layer.shadowRadius = 2.f;
    button.layer.shadowOffset = CGSizeMake(0, 0);
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

@end
