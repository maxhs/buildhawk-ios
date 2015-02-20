//
//  BHReportCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHReportCell.h"
#import "Photo+helper.h"
#import "ReportSub+helper.h"
#import "UIButton+WebCache.h"
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

- (void)awakeFromNib {
    [super awakeFromNib];
    [_reportLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadPro] size:0]];
    [_reportLabel setTextColor:[UIColor blackColor]];
    
    [_authorLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadPro] size:0]];
    [_personnelLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadPro] size:0]];
    [_notesLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadPro] size:0]];
    [_photoCountBubble setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
    [_photoCountBubble setTextColor:[UIColor whiteColor]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureReport:(Report *)report {
    [_reportLabel setText:[NSString stringWithFormat:@"%@: %@",report.type,report.dateString]];
    if (report.author.fullname.length){
        [_authorLabel setText:[NSString stringWithFormat:@"Author: %@",report.author.fullname]];
    } else {
        [_authorLabel setText:@"Author: N/A"];
    }
    NSInteger count = report.reportUsers.count;
    for (ReportSub *reportSub in report.reportSubs){
        if (reportSub.count.intValue > 0) count += reportSub.count.intValue;
    }
    [_personnelLabel setText:[NSString stringWithFormat:@"Personnel on-site: %li",(long)count]];
    if (report.body){
        [_notesLabel setText:[NSString stringWithFormat:@"Notes: %@",report.body]];
    } else {
        [_notesLabel setText:@"Notes: N/A"];
    }
    
    if (report.photos.count > 0){
        _photoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        Photo *firstPhoto = (Photo*)report.photos.firstObject;
        if (firstPhoto.image) {
            [_photoButton setImage:firstPhoto.image forState:UIControlStateNormal];
            _photoButton.imageView.layer.shouldRasterize = YES;
            _photoButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        } else if (firstPhoto.urlSmall.length) {
            [_photoButton sd_setImageWithURL:[NSURL URLWithString:firstPhoto.urlSmall] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                _photoButton.imageView.layer.shouldRasterize = YES;
                _photoButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            }];
        }
        _photoCountBubble.layer.cornerRadius = _photoCountBubble.frame.size.height/2;
        _photoCountBubble.layer.backgroundColor = [UIColor clearColor].CGColor;
        [_photoCountBubble setText:[NSString stringWithFormat:@"%lu",(unsigned long)report.photos.count]];
        _photoCountBubble.hidden = NO;
    } else {
        _photoCountBubble.hidden = YES;
        [_photoButton setImage:[UIImage imageNamed:@"whiteIcon"] forState:UIControlStateNormal];
    }
    
    if ([report.type isEqualToString:kDaily]){
        [_colorView setBackgroundColor:kDailyReportColor];
        [_photoCountBubble setBackgroundColor:kDailyReportColor];
    } else if ([report.type isEqualToString:kWeekly]){
        [_colorView setBackgroundColor:kWeeklyReportColor];
        [_photoCountBubble setBackgroundColor:kWeeklyReportColor];
    } else if ([report.type isEqualToString:kSafety]){
        [_colorView setBackgroundColor:kSafetyReportColor];
        [_photoCountBubble setBackgroundColor:kSafetyReportColor];
    }
    
    [_colorView setFrame:CGRectMake(0, 0, 8, self.frame.size.height)];
}
@end
