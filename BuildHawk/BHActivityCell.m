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
#import "Task+helper.h"
#import "Report+helper.h"
#import "Folder+helper.h"

@interface BHActivityCell () {
    CGFloat origX;
    CGFloat origWidth;
}

@end

@implementation BHActivityCell

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
    [_activityLabel setFont:[UIFont fontWithName:kMyriadProRegular size:17]];
    [_timestampLabel setFont:[UIFont fontWithName:kMyriadProRegular size:15]];
    [_separatorView setBackgroundColor:kSeparatorColor];
    if (IDIOM != IPAD){
        origWidth = _activityLabel.frame.size.width;
    }
    origX = _activityLabel.frame.origin.x;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForActivity:(Activity*)activity {
    [self.imageView setImage:nil];
    if ([activity.activityType isEqualToString:kComment]) {
        [_activityLabel setText:[NSString stringWithFormat:@"%@ - %@",activity.body,activity.comment.user.fullname]];
    } else {
        [_activityLabel setText:activity.body];
    }
    CGRect frame = _activityLabel.frame;
    frame.origin.x = 10;
    if (IDIOM != IPAD){
        frame.size.width = screenWidth()-20-_timestampLabel.frame.size.width;
    }
    [_activityLabel setFrame:frame];
}

- (void)configureForComment:(Comment*)comment {
    [self.imageView setImage:nil];
    [_activityLabel setText:[NSString stringWithFormat:@"\"%@\" - %@",comment.body,comment.user.fullname]];
    CGRect frame = _activityLabel.frame;
    frame.origin.x = 10;
    if (IDIOM != IPAD){
        frame.size.width = screenWidth()-20-_timestampLabel.frame.size.width;
    }
    [_activityLabel setFrame:frame];
}

- (void)configureActivityForSynopsis:(Activity *)activity {
    //NSLog(@"Configure for activity synopsis: %@",activity);
    CGRect frame = _activityLabel.frame;
    frame.origin.x = origX;
    if (IDIOM != IPAD){
        frame.size.width = origWidth;
    }
    [_activityLabel setFrame:frame];
    
    if ([activity.activityType isEqualToString:kComment]) {
        [self.imageView setImage:[UIImage imageNamed:@"miniChat_black"]];
        NSString *activityObject;
        if (activity.task){
            if (activity.task.body.length > 25){
                activityObject = [[activity.task.body substringToIndex:25] stringByAppendingString:@"..."];
            } else if (activity.task.body.length) {
                activityObject = activity.task.body;
            } else {
                activityObject = @"an unnamed item";
            }
        } else if (activity.checklistItem){
            if (activity.checklistItem.body.length > 25){
                activityObject = [[activity.checklistItem.body substringToIndex:25] stringByAppendingString:@"..."];
            } else if (activity.checklistItem.body.length) {
                activityObject = activity.checklistItem.body;
            } else {
                activityObject = @"an unnamed item";
            }
        }
        [_activityLabel setText:[NSString stringWithFormat:@"%@ commented on \"%@\": %@.",activity.comment.user.fullname,activityObject,activity.body]];
    } else if ([activity.activityType isEqualToString:kReport]) {
        [self.imageView setImage:[UIImage imageNamed:@"reports"]];
        if ([activity.body rangeOfString:@"create"].location != NSNotFound){
            if (activity.user && activity.user.fullname.length){
                [_activityLabel setText:[NSString stringWithFormat:@"%@ created a %@ report for %@.",activity.user.fullname,activity.report.type,activity.report.dateString]];
            } else {
                [_activityLabel setText:[NSString stringWithFormat:@"A %@ report for %@ was created.",activity.report.type,activity.report.dateString]];
            }
        } else {
            if (activity.user.fullname){
                [_activityLabel setText:[NSString stringWithFormat:@"%@ updated a %@ report for %@.",activity.user.fullname,activity.report.type,activity.report.dateString]];
            } else {
                [_activityLabel setText:[NSString stringWithFormat:@"A %@ report for %@ was updated.",activity.report.type,activity.report.dateString]];
            }
        }
        
    } else if ([activity.activityType isEqualToString:kChecklistItem]) {
        [self.imageView setImage:[UIImage imageNamed:@"checklists"]];
        NSString *activityObject;
        if (activity.checklistItem.body.length > 25){
            activityObject = [[activity.checklistItem.body substringToIndex:25] stringByAppendingString:@"..."];
        } else {
            activityObject = activity.checklistItem.body;
        }
        
        if ([activity.body rangeOfString:@"complete"].location != NSNotFound){
            if (activity.user && activity.user.fullname.length){
                if (activityObject.length == 0){
                    [_activityLabel setText:[NSString stringWithFormat:@"An unnamed item was completed by %@.",activity.user.fullname]];
                } else {
                    [_activityLabel setText:[NSString stringWithFormat:@"\"%@\" was completed by %@.",activityObject,activity.user.fullname]];
                }
            } else {
                [_activityLabel setText:[NSString stringWithFormat:@"\"%@\" was completed.",activityObject]];
            }
            
        } else if ([activity.body rangeOfString:@"complete"].location != NSNotFound){
            NSString *status;
            switch (activity.checklistItem.state.integerValue) {
                case kItemCompleted:
                    status = kcompleted;
                    break;
                case kItemInProgress:
                    status = @"in progress";
                    break;
                case kItemNotApplicable:
                    status = @"not applicable";
                    break;
                    
                default:
                    status = @"in progress";
                    break;
            }
            if (activity.user && activity.user.fullname.length){
                [_activityLabel setText:[NSString stringWithFormat:@"%@ updated the status for \"%@\" to %@.",activity.user.fullname,activityObject,status]];
            } else {
                [_activityLabel setText:[NSString stringWithFormat:@"The status for \"%@\" was updated to %@.",activityObject,status]];
            }
        } else {
            [_activityLabel setText:activity.body];
        }
    } else if ([activity.activityType isEqualToString:kTask]) {
        [self.imageView setImage:[UIImage imageNamed:@"tasks"]];
        NSString *activityObject;
        if (activity.task.body.length > 25){
            activityObject = [[activity.task.body substringToIndex:25] stringByAppendingString:@"..."];
        } else {
            activityObject = activity.task.body;
        }
        
        if ([activity.body rangeOfString:@"complete"].location != NSNotFound){
            if (activityObject.length > 0){
                [_activityLabel setText:[NSString stringWithFormat:@"\"%@\" was completed by %@.",activityObject,activity.user.fullname]];
            } else {
                [_activityLabel setText:[NSString stringWithFormat:@"An unnamed task was completed by %@.",activity.user.fullname]];
            }
        } else {
            if (activityObject.length > 0){
                [_activityLabel setText:[NSString stringWithFormat:@"%@ modified \"%@\".",activity.user.fullname,activityObject]];
            } else {
                [_activityLabel setText:[NSString stringWithFormat:@"%@ modified an unnamed task.",activity.user.fullname]];
            }
        }
    } else if ([activity.activityType isEqualToString:kPhoto]) {
        [self.imageView setImage:[UIImage imageNamed:@"documents"]];
        if (activity.photo.folder.name.length){
            [_activityLabel setText:[NSString stringWithFormat:@"%@ put a document in the \"%@\" folder.",activity.user.fullname,activity.photo.folder.name]];
        } else {
            [_activityLabel setText:activity.body];
        }
    } else if ([activity.activityType isEqualToString:kReminder]) {
        [self.imageView setImage:[UIImage imageNamed:@"reminders"]];
        [_activityLabel setText:activity.body];
    } else {
        [_activityLabel setText:activity.body];
    }
}
@end
