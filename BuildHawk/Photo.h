//
//  Photo.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChecklistItem, Project, Report, WorklistItem;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * assignee;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * dateString;
@property (nonatomic, retain) NSString * folder;
@property (nonatomic, retain) NSNumber * folderId;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * original;
@property (nonatomic, retain) NSString * phase;
@property (nonatomic, retain) NSString * photoPhase;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSString * urlLarge;
@property (nonatomic, retain) NSString * urlSmall;
@property (nonatomic, retain) NSString * urlThumb;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Project *recentDocuments;
@property (nonatomic, retain) Report *report;
@property (nonatomic, retain) WorklistItem *worklistItem;

@end
