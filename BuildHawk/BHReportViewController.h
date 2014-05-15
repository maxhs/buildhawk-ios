//
//  BHReportViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Report+helper.h"

@interface BHReportViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *activeTableView;
@property (weak, nonatomic) IBOutlet UITableView *beforeTableView;
@property (weak, nonatomic) IBOutlet UITableView *afterTableView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) Report *report;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) NSMutableArray *reports;
@property (strong, nonatomic) NSString *reportType;
@end
