//
//  BHPhotosViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "Photo.h"
#import "Project.h"

@interface BHPhotosViewController : UICollectionViewController
@property (strong, nonatomic) NSMutableArray *photosArray;
@property (strong, nonatomic) NSMutableArray *phasePhotosArray;
@property (strong, nonatomic) NSArray *sectionTitles;
@property (strong, nonatomic) NSArray *userNames;
@property (strong, nonatomic) NSArray *dates;
@property (strong, nonatomic) Project *project;
@property NSInteger numberOfSections;
@property BOOL documentsBool;
@property BOOL checklistsBool;
@property BOOL reportsBool;
@property BOOL tasklistsBool;
@end
