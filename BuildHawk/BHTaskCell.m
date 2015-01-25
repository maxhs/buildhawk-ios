//
//  BHTaskCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/9/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHTaskCell.h"

@implementation BHTaskCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([UIScreen mainScreen].bounds.size.width > 320.f){
        [_itemLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProRegular] size:0]];
    } else {
        [_itemLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
    }
    _itemLabel.minimumScaleFactor = 10.0;
    _itemLabel.adjustsFontSizeToFitWidth = YES;
    _itemLabel.numberOfLines = 1;
    
    [_createdLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadProRegular] size:0]];
    [_ownerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadProRegular] size:0]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
