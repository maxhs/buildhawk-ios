//
//  BHPhoto.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface BHPhoto : NSObject

@property (nonatomic, strong) NSString *url200;
@property (nonatomic, strong) NSString *url100;
@property (nonatomic, strong) NSString *urlLarge;
@property (nonatomic, strong) NSString *orig;
@property (nonatomic, strong) NSString *source;
@property (nonatomic, strong) NSString *folder;
@property (nonatomic, strong) NSString *folderId;
@property (nonatomic, strong) NSString *phase;
@property (nonatomic, strong) NSNumber *filesize;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *mimetype;
@property (nonatomic, strong) NSString *photoSize;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *assignee;
@property (strong, nonatomic) NSDate *createdOn;
@property (strong, nonatomic) NSString *createdDate;
@property (nonatomic, strong) UIImage *image;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
