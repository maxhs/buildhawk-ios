//
//  BHPersonnelPickerViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Company.h"
#import "Project.h"
#import "Task.h"
#import "Report+helper.h"
#import "ReportSub+helper.h"

@protocol BHPersonnelPickerDelegate <NSObject>

@optional
- (void)userAdded:(User*)user;
- (void)userRemoved:(User*)user;
- (void)removeAllTaskAssignees;
- (void)reportSubAdded:(ReportSub*)reportSub;
- (void)reportSubRemoved:(ReportSub*)reportSub;
- (void)reportUserAdded:(ReportUser*)reportUser;
- (void)reportUserRemoved:(ReportUser*)reportUser;
- (void)sendEmail:(NSString*)email;
- (void)sendText:(NSString*)phoneNumber;
- (void)placeCall:(NSString*)phoneNumber;
@end

@interface BHPersonnelPickerViewController : UIViewController <UITableViewDataSource,UITableViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSNumber *companyId;
@property (strong, nonatomic) NSNumber *projectId;
@property (strong, nonatomic) NSNumber *taskId;
@property (strong, nonatomic) NSNumber *reportId;
@property (weak, nonatomic) id<BHPersonnelPickerDelegate>personnelDelegate;
@property BOOL email;
@property BOOL text;
@property BOOL companyMode;

@end
