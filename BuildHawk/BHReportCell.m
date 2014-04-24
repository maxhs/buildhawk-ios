//
//  BHReportCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHReportCell.h"
#import "UIButton+WebCache.h"

@implementation BHReportCell

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

- (void)configureReport:(Report *)report {
    [_reportLabel setText:[NSString stringWithFormat:@"%@ Report - %@",report.type,report.createdDate]];
    [_personnelLabel setText:[NSString stringWithFormat:@"Personnel onsite: %i",(report.subs.count + report.users.count)]];
    if (report.body){
        [_notesLabel setText:[NSString stringWithFormat:@"Notes: %@",report.body]];
    } else {
        [_notesLabel setText:@"Notes: N/A"];
    }
    if ([(NSArray*)report.photos count]){
        [_photoButton setImageWithURL:[NSURL URLWithString:[[(NSArray*)report.photos firstObject] url200]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            
        }];
        [_photoCountBubble setBackgroundColor:[UIColor whiteColor]];
        _photoCountBubble.layer.cornerRadius = _photoCountBubble.frame.size.height/2;
        _photoCountBubble.layer.backgroundColor = [UIColor clearColor].CGColor;
        [_photoCountBubble setText:[NSString stringWithFormat:@"%i",[(NSArray*)report.photos count]]];
        _photoCountBubble.hidden = NO;
    } else {
        _photoCountBubble.hidden = YES;
        [_photoButton setImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"] forState:UIControlStateNormal];
    }
}
@end
