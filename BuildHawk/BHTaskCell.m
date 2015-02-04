//
//  BHTaskCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/9/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHTaskCell.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "Constants.h"

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

- (void)configureForTask:(Task *)task {
    [_itemLabel setText:task.body];
    if (task.assignees.count && task.user){
        NSString *assigneeString = task.assignees.count == 1 ? [(User*)task.assignees.firstObject fullname] : [NSString stringWithFormat:@"%lu assignees",(unsigned long)task.assignees.count];
        [_ownerLabel setText:[NSString stringWithFormat:@"%@ \u2794 %@",task.user.fullname,assigneeString]];
        
    } else if (task.user) {
        [_ownerLabel setText:task.user.fullname];
    } else {
        [_ownerLabel setText:@""];
    }
    
    if (task.photos.count) {
        if ([(Photo*)[task.photos firstObject] image]){
            [_photoButton setImage:[(Photo*)[task.photos firstObject] image] forState:UIControlStateNormal];
        } else {
            [_photoButton sd_setImageWithURL:[NSURL URLWithString:[[task.photos firstObject] urlSmall]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"]];
        }
    } else {
        [_photoButton setImage:[UIImage imageNamed:@"whiteIcon"] forState:UIControlStateNormal];
    }
    [_photoButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    _photoButton.imageView.layer.shouldRasterize = YES;
    _photoButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    if ([task.completed isEqualToNumber:@YES]){
        [self setBackgroundColor:kCompletedTasksColor];
    } else {
        [self setBackgroundColor:kActiveTasksColor];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
