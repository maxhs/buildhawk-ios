//
//  BHDashboardProjectCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHDashboardProjectCell.h"
#import "Address.h"
#import "Reminder+helper.h"

@implementation BHDashboardProjectCell {
    CGRect screen;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [_scrollView setContentSize:CGSizeMake(screenWidth()+176, 88)];
    [_alertLabel setBackgroundColor:[UIColor redColor]];
    [_alertLabel.layer setBackgroundColor:[UIColor clearColor].CGColor];
    _alertLabel.layer.cornerRadius = 11.f;
    [_alertLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadProSemibold] size:0]];
    
    [_progressButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0]];
    
    // hide button
    CGRect hideRect = _hideButton.frame;
    UIImageView *hideImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hide"]];
    [hideImageView setFrame:CGRectMake(hideRect.size.width/2-9, hideRect.size.height/2-18, 16, 16)];
    [_hideButton addSubview:hideImageView];
    [_hideButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
    [_hideButton.titleLabel setNumberOfLines:0];
    [_hideButton setTitle:@"Hide" forState:UIControlStateNormal];
    [_hideButton setTitleEdgeInsets:UIEdgeInsetsMake(23, 0, 0, 0)];
    [_hideButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_hideButton setBackgroundColor:[UIColor redColor]];
    CGRect localRect = _hideButton.frame;
    
    // local button
    UIImageView *localImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"local"]];
    [localImageView setFrame:CGRectMake(localRect.size.width/2-10, localRect.size.height/2-20, 20, 20)];
    [_localButton addSubview:localImageView];
    [_localButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
    [_localButton.titleLabel setNumberOfLines:0];
    [_localButton setTitle:@"Local" forState:UIControlStateNormal];
    [_localButton setTitleEdgeInsets:UIEdgeInsetsMake(23, 0, 0, 0)];
    _localButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _localButton.contentHorizontalAlignment = UIControlContentVerticalAlignmentCenter;
    [_localButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_localButton setBackgroundColor:kElectricBlue];
}

- (void)configureForProject:(Project*)project andUser:(User*)user {
    [_projectButton setUserInteractionEnabled:YES];
    [_progressButton setHidden:NO];
    [_scrollView setUserInteractionEnabled:YES];
    
    NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:project.name attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0]}];
    
    //don't crash if there's no address
    if (project.address.formattedAddress.length){
        NSAttributedString *addressString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",project.address.formattedAddress] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadProLight] size:0], NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
        [nameString appendAttributedString:addressString];
    }
    [_nameLabel setAttributedText:nameString];
    
    __block int reminderCount = 0;
    [user.pastDueReminders enumerateObjectsUsingBlock:^(Reminder *reminder, NSUInteger idx, BOOL *stop) {
        if (project.identifier && [reminder.pastDueProject.identifier isEqualToNumber:project.identifier]){
            reminderCount ++;
        }
    }];
    
    if (reminderCount > 0){
        [_alertLabel setText:[NSString stringWithFormat:@"%d",reminderCount]];
        [UIView animateWithDuration:.3 animations:^{
            [_alertLabel setAlpha:1.0];
        }];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _hideButton.transform = CGAffineTransformMakeTranslation(-scrollView.contentOffset.x, 0);
    _localButton.transform = CGAffineTransformMakeTranslation(-scrollView.contentOffset.x, 0);
}

@end
