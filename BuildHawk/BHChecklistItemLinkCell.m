//
//  BHChecklistItemLinkCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/10/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import "BHChecklistItemLinkCell.h"
#import "Constants.h"

@implementation BHChecklistItemLinkCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProItalic] size:0]];
    [self.textLabel setTextAlignment:NSTextAlignmentCenter];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForChecklistItem:(ChecklistItem *)item {
    self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    if (item.linkTitle.length){
        [self.textLabel setText:item.linkTitle];
    } else if (item.link.length){
        [self.textLabel setText:item.link];
    } else {
        [self.textLabel setText:@"A link"];
    }
}

@end
