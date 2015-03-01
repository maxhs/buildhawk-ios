//
//  BHCompaniesViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/12/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project+helper.h"
@protocol BHCompaniesDelegate <NSObject>
- (void)addedCompanyWithId:(NSNumber*)companyId;
@end
@interface BHCompaniesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *searchTerm;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) NSArray *searchResults;
@property (weak, nonatomic) id<BHCompaniesDelegate>companiesDelegate;

@end
