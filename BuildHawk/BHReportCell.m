//
//  BHReportCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHReportCell.h"
#import "Photo+helper.h"
#import "ReportSub.h"
#import "UIButton+WebCache.h"
#import "Report+helper.h"
#import "User+helper.h"

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
    [_separatorView setBackgroundColor:kSeparatorColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureReport:(Report *)report {
    [_reportLabel setText:[NSString stringWithFormat:@"%@ Report - %@",report.type,report.dateString]];
    if (report.author.fullname.length){
        [_authorLabel setText:[NSString stringWithFormat:@"Author: %@",report.author.fullname]];
    } else {
        [_authorLabel setText:@""];
    }
    int count = report.reportUsers.count;
    for (ReportSub *reportSub in report.reportSubs){
        if (reportSub.count.intValue > 0) count += reportSub.count.intValue;
    }
    [_personnelLabel setText:[NSString stringWithFormat:@"Personnel onsite: %i",count]];
    if (report.body){
        [_notesLabel setText:[NSString stringWithFormat:@"Notes: %@",report.body]];
    } else {
        [_notesLabel setText:@"Notes: N/A"];
    }
    if (report.photos.count > 0){
        [_photoButton setImageWithURL:[NSURL URLWithString:[(Photo*)report.photos.firstObject urlSmall]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            
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
