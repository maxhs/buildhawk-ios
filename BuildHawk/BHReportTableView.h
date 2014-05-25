//
//  BHReportTableView.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/19/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Report+helper.h"

@interface BHReportTableView : UITableView
@property (strong, nonatomic) Report *report;
@end
