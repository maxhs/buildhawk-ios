//
//  BHChecklistViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RATreeView/RATreeView.h>
#import <RATreeView/RATreeNodeInfo.h>
#import "GAITrackedViewController.h"

@interface BHChecklistViewController : GAITrackedViewController
@property (weak, nonatomic) IBOutlet RATreeView *treeView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) NSString *projectId;
@end
