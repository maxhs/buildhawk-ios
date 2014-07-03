//
//  BHActivityCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/26/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHActivityCell.h"
#import "Comment+helper.h"
#import "Activity+helper.h"
#import "WorklistItem+helper.h"
#import "Report+helper.h"

@implementation BHActivityCell

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

- (void)configureForActivity:(Activity*)activity {
    if ([activity.activityType isEqualToString:kComment]) {
        [_activityLabel setText:[NSString stringWithFormat:@"%@ - %@",activity.body,activity.comment.user.fullname]];
    } else {
        [_activityLabel setText:activity.body];
    }
}

- (void)configureActivityForSynopsis:(Activity *)activity {
    if ([activity.activityType isEqualToString:kComment]) {
        NSString *activityObject;
        if (activity.task){
            if (activity.task.body.length > 25){
                activityObject = [[activity.task.body substringToIndex:25] stringByAppendingString:@"..."];
            } else {
                activityObject = activity.task.body;
            }
        } else if (activity.checklistItem){
            
            if (activity.checklistItem.body.length > 25){
                activityObject = [[activity.checklistItem.body substringToIndex:25] stringByAppendingString:@"..."];
            } else {
                activityObject = activity.checklistItem.body;
            }
        }
        [_activityLabel setText:[NSString stringWithFormat:@"%@ commented on \"%@\": %@.",activity.comment.user.fullname,activityObject,activity.body]];
    } else if ([activity.activityType isEqualToString:kReport]) {
        if ([activity.body rangeOfString:@"create"].location != NSNotFound){
            [_activityLabel setText:[NSString stringWithFormat:@"%@ created a %@ report for %@.",activity.user.fullname,activity.report.type,activity.report.dateString]];
        } else {
            [_activityLabel setText:[NSString stringWithFormat:@"%@ updated a %@ report for %@.",activity.user.fullname,activity.report.type,activity.report.dateString]];
        }
        
    } else if ([activity.activityType isEqualToString:kChecklistItem]) {
        NSString *activityObject;
        if (activity.checklistItem.body.length > 25){
            activityObject = [[activity.checklistItem.body substringToIndex:25] stringByAppendingString:@"..."];
        } else {
            activityObject = activity.checklistItem.body;
        }
        
        if ([activity.body rangeOfString:@"complete"].location != NSNotFound){
            [_activityLabel setText:[NSString stringWithFormat:@"\"%@\" was completed by %@.",activityObject,activity.user.fullname]];
        } else {
            [_activityLabel setText:activity.body];
        }
        
    } else {
        [_activityLabel setText:activity.body];
    }
}
@end
