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
    [super awakeFromNib];
    [_reportLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProSemibold] size:0]];
    [_authorLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
    [_personnelLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
    [_notesLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
    
    [_separatorView setBackgroundColor:kSeparatorColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureReport:(Report *)report {
    [_reportLabel setText:[NSString stringWithFormat:@"%@: %@",report.type,report.dateString]];
    if (report.author.fullname.length){
        [_authorLabel setText:[NSString stringWithFormat:@"Author: %@",report.author.fullname]];
    } else {
        [_authorLabel setText:@""];
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
    if ([report.dateString isEqualToString:@"10/11/2014"]){
        NSLog(@"how many photos do we have? %d",report.photos.count);
    }
    
    if (report.photos.count > 0){
        _photoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        _photoButton.imageView.layer.cornerRadius = 2.0;
        [_photoButton.imageView setBackgroundColor:[UIColor clearColor]];
        [_photoButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        
        if ([report.dateString isEqualToString:@"10/11/2014"]){
            NSLog(@"the actual photos %@",report.photos);
        }
        Photo *firstPhoto = (Photo*)report.photos.firstObject;
        if (firstPhoto.image) {
            if ([report.dateString isEqualToString:@"10/11/2014"]){
                NSLog(@"first photo had an image");
            }
            [_photoButton setImage:firstPhoto.image forState:UIControlStateNormal];
            _photoButton.imageView.layer.shouldRasterize = YES;
            _photoButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        } else if (firstPhoto.urlSmall.length) {
            [_photoButton sd_setImageWithURL:[NSURL URLWithString:firstPhoto.urlSmall] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"whiteIcon"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                _photoButton.imageView.layer.shouldRasterize = YES;
                _photoButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            }];
        }
        [_photoCountBubble setBackgroundColor:[UIColor whiteColor]];
        _photoCountBubble.layer.cornerRadius = _photoCountBubble.frame.size.height/2;
        _photoCountBubble.layer.backgroundColor = [UIColor clearColor].CGColor;
        [_photoCountBubble setText:[NSString stringWithFormat:@"%lu",(unsigned long)report.photos.count]];
        [_photoCountBubble setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
        _photoCountBubble.hidden = NO;
    } else {
        _photoCountBubble.hidden = YES;
        [_photoButton setImage:[UIImage imageNamed:@"whiteIcon"] forState:UIControlStateNormal];
    }
}
@end
