//
//  BHPersonnelCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/21/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHReportPersonnelCell.h"

@implementation BHReportPersonnelCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [_personLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
    [_personLabel setTextColor:[UIColor blackColor]];
    [_countTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
    [_countTextField setTextColor:[UIColor blackColor]];
    
    if (IDIOM == IPAD){
        
    } else {
        CGFloat differential = 414.f - screenWidth();
        CGRect removeFrame = _removeButton.frame;
        removeFrame.origin.x -= differential;
        [_removeButton setFrame:removeFrame];
        CGRect countFrame = _countTextField.frame;
        countFrame.origin.x -= differential;
        [_countTextField setFrame:countFrame];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
