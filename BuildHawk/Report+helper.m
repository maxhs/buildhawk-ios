//
//  BHReport.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "Report+helper.h"
#import "Photo+helper.h"
#import "User+helper.h"
#import "Subcontractor.h"
#import "ReportSub+helper.h"
#import "Activity+helper.h"
#import "SafetyTopic+helper.h"
#import "Comment+helper.h"
#import "BHUtilities.h"
#import "BHAppDelegate.h"

@implementation Report (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"report dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"created_at"] && [dictionary objectForKey:@"created_at"] != [NSNull null]) {
        self.createdAt = [BHUtilities parseDateTime:[dictionary objectForKey:@"created_at"]];
    }
    if ([dictionary objectForKey:@"updated_at"] && [dictionary objectForKey:@"updated_at"] != [NSNull null]) {
        self.updatedAt = [BHUtilities parseDateTime:[dictionary objectForKey:@"updated_at"]];
    }
    if ([dictionary objectForKey:@"report_date"] && [dictionary objectForKey:@"report_date"] != [NSNull null]) {
        self.reportDate = [BHUtilities parseDate:[dictionary objectForKey:@"report_date"]];
    }
    if ([dictionary objectForKey:@"report_type"] && [dictionary objectForKey:@"report_type"] != [NSNull null]) {
        self.type = [dictionary objectForKey:@"report_type"];
    }
    if ([dictionary objectForKey:@"date_string"] && [dictionary objectForKey:@"date_string"] != [NSNull null]) {
        self.dateString = [dictionary objectForKey:@"date_string"];
    }
    if ([dictionary objectForKey:@"body"] && [dictionary objectForKey:@"body"] != [NSNull null]) {
        self.body = [dictionary objectForKey:@"body"];
    }
    if ([dictionary objectForKey:@"weather"] && [dictionary objectForKey:@"weather"] != [NSNull null]) {
        self.weather = [dictionary objectForKey:@"weather"];
    }
    if ([dictionary objectForKey:@"temp"] && [dictionary objectForKey:@"temp"] != [NSNull null]) {
        self.temp = [dictionary objectForKey:@"temp"];
    }
    if ([dictionary objectForKey:@"wind"] && [dictionary objectForKey:@"wind"] != [NSNull null]) {
        self.wind = [dictionary objectForKey:@"wind"];
    }
    if ([dictionary objectForKey:@"precip"] && [dictionary objectForKey:@"precip"] != [NSNull null]) {
        self.precip = [dictionary objectForKey:@"precip"];
    }
    if ([dictionary objectForKey:@"humidity"] && [dictionary objectForKey:@"humidity"] != [NSNull null]) {
        self.humidity = [dictionary objectForKey:@"humidity"];
    }
    if ([dictionary objectForKey:@"weather_icon"] && [dictionary objectForKey:@"weather_icon"] != [NSNull null]) {
        self.weatherIcon = [dictionary objectForKey:@"weather_icon"];
    }
    
    if ([dictionary objectForKey:@"report_users"] && [dictionary objectForKey:@"report_users"] != [NSNull null]) {
        NSMutableOrderedSet *orderedUsers = [NSMutableOrderedSet orderedSet];
        for (id userDict in [dictionary objectForKey:@"report_users"]){
            //NSLog(@"user dict from report users: %@",userDict);
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [userDict objectForKey:@"id"]];
            ReportUser *reportUser = [ReportUser MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (reportUser){
                [reportUser updateFromDict:userDict];
            } else {
                reportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [reportUser populateFromDict:userDict];
            }
            
            [orderedUsers addObject:reportUser];
        }
        for (ReportUser *reportUser in self.reportUsers){
            if (![orderedUsers containsObject:reportUser]) {
                NSLog(@"Deleting a report user that no longer exists: %@, report_user id: %@, user_id: %@",reportUser.fullname, reportUser.identifier, reportUser.userId);
                [reportUser MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reportUsers = orderedUsers;
    }
    if ([dictionary objectForKey:@"report_companies"] && [dictionary objectForKey:@"report_companies"] != [NSNull null]) {
        NSMutableOrderedSet *orderedSubs = [NSMutableOrderedSet orderedSet];
        for (id subDict in [dictionary objectForKey:@"report_companies"]){
            //NSLog(@"sub dict from report subs: %@",subDict);
            if ([subDict objectForKey:@"company"] != [NSNull null]) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [subDict objectForKey:@"id"]];
                ReportSub *reportSub = [ReportSub MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
                if (reportSub){
                    
                } else {
                    reportSub = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    reportSub.identifier = [subDict objectForKey:@"id"];
                    reportSub.companyId = [[subDict objectForKey:@"company"] objectForKey:@"id"];
                }
                
                reportSub.name = [[subDict objectForKey:@"company"] objectForKey:@"name"];
                if ([subDict objectForKey:@"count"] != [NSNull null]) reportSub.count = [subDict objectForKey:@"count"];
                
                [orderedSubs addObject:reportSub];
            }
        }
        for (ReportSub *reportSub in self.reportSubs){
            if (![orderedSubs containsObject:reportSub]) {
                NSLog(@"Deleting a report sub that no longer exists: %@",reportSub.name);
                [reportSub MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.reportSubs = orderedSubs;
    }

    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]) {
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id photoDict in [dictionary objectForKey:@"photos"]){
            NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [photoDict objectForKey:@"id"]];
            Photo *photo = [Photo MR_findFirstWithPredicate:photoPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!photo){
                photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            
            [photo populateFromDictionary:photoDict];
            [set addObject:photo];
        }
        for (Photo *photo in self.photos) {
            if (![set containsObject:photo]){
                [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.photos = set;
    }
    
    if ([dictionary objectForKey:@"report_topics"] && [dictionary objectForKey:@"report_topics"] != [NSNull null]) {
        NSMutableOrderedSet *orderedTopics = [NSMutableOrderedSet orderedSet];
        for (id topicDict in [dictionary objectForKey:@"report_topics"]){
            //NSLog(@"topic dict: %@",topicDict);
            NSPredicate *topicPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [topicDict objectForKey:@"id"]];
            SafetyTopic *topic = [SafetyTopic MR_findFirstWithPredicate:topicPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!topic){
                topic = [SafetyTopic MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [topic populateWithDict:topicDict];
            [orderedTopics addObject:topic];
        }

        self.safetyTopics = orderedTopics;
    }
    
    if ([dictionary objectForKey:@"author"] && [dictionary objectForKey:@"author"] != [NSNull null]) {
        User *author = [User MR_findFirstByAttribute:@"identifier" withValue:[[dictionary objectForKey:@"author"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!author){
            author = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [author populateFromDictionary:[dictionary objectForKey:@"author"]];
        self.author = author;
    }
    if ([dictionary objectForKey:@"project_id"] && [dictionary objectForKey:@"project_id"] != [NSNull null]) {
        Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"project_id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        project.identifier = [dictionary objectForKey:@"project_id"];
        self.project = project;
    }
    
    if ([self.type isEqualToString:kDaily]){
        if ([dictionary objectForKey:@"daily_activities"] && [dictionary objectForKey:@"daily_activities"] != [NSNull null]) {
            NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
            for (id dict in [dictionary objectForKey:@"daily_activities"]){
                if (dict != [NSNull null] && [dict objectForKey:@"id"]){
                    NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                    Activity *activity = [Activity MR_findFirstWithPredicate:photoPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
                    if (!activity){
                        activity = [Activity MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [activity populateFromDictionary:dict];
                    if (![activity.activityType isEqualToString:@"Comment"])
                        [set addObject:activity];
                }
            }
            self.dailyActivities = set;
        }
    } else {
        if ([dictionary objectForKey:@"activities"] && [dictionary objectForKey:@"activities"] != [NSNull null]) {
            NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
            //NSLog(@"report activities %@",[dictionary objectForKey:@"activities"]);
            for (id dict in [dictionary objectForKey:@"activities"]){
                if ([dict objectForKey:@"id"]){
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                    Activity *activity = [Activity MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
                    if (!activity){
                        activity = [Activity MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [activity populateFromDictionary:dict];
                    if (![activity.activityType isEqualToString:@"Comment"])
                        [set addObject:activity];
                }
            }
            for (Activity *activity in self.activities){
                if (![set containsObject:activity]){
                    [activity MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                }
            }
            self.activities = set;
        }
    }
    if ([dictionary objectForKey:@"comments"] && [dictionary objectForKey:@"comments"] != [NSNull null]) {
        NSMutableOrderedSet *orderedComments = [NSMutableOrderedSet orderedSet];
        for (id commentDict in [dictionary objectForKey:@"comments"]){
            NSPredicate *commentPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", [commentDict objectForKey:@"id"]];
            Comment *comment = [Comment MR_findFirstWithPredicate:commentPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!comment){
                comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [comment populateFromDictionary:commentDict];
            [orderedComments addObject:comment];
        }
        for (Comment *comment in self.comments){
            if (![orderedComments containsObject:comment]) {
                NSLog(@"Deleting a comment that no longer exists for %@", self.dateString);
                [comment MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.comments = orderedComments;
    }
}

-(void)addSafetyTopic:(SafetyTopic *)topic {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.safetyTopics];
    [set addObject:topic];
    self.safetyTopics = set;
}

-(void)removeSafetyTopic:(SafetyTopic *)topic {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.safetyTopics];
    [set removeObject:topic];
    self.safetyTopics = set;
}

- (void)addReportUser:(ReportUser*)reportUser {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reportUsers];
    [set addObject:reportUser];
    self.reportUsers = set;
}

-(void)removeReportUser:(ReportUser*)reportUser {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reportUsers];
    [set removeObject:reportUser];
    self.reportUsers = set;
}

-(void)clearReportUsers {
    self.reportUsers = nil;
}

-(void)addPhoto:(Photo *)photo {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.photos];
    [set addObject:photo];
    self.photos = set;
}

-(void)removePhoto:(Photo *)photo {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.photos];
    [set removeObject:photo];
    self.photos = set;
}

-(void)addComment:(Comment *)comment {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.comments];
    [set insertObject:comment atIndex:0];
    self.comments = set;
}

-(void)removeComment:(Comment *)comment {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.comments];
    [set removeObject:comment];
    self.comments = set;
}

- (void)addReportSubcontractor:(ReportSub *)reportSubcontractor {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reportSubs];
    [set addObject:reportSubcontractor];
    self.reportSubs = set;
}

-(void)removeReportSubcontractor:(ReportSub *)reportSubcontractor {
    NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.reportSubs];
    [set removeObject:reportSubcontractor];
    self.reportSubs = set;
}

-(void)clearReportSubcontractors {
    self.reportSubs = nil;
}

- (void)synchWithServer:(synchCompletion)complete{
    if (self.project.identifier){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:self.project.identifier forKey:@"project_id"];
        if (self.weather.length) [parameters setObject:self.weather forKey:@"weather"];
        if (self.dateString.length) [parameters setObject:self.dateString forKey:@"date_string"];
        if (self.type.length) [parameters setObject:self.type forKey:@"report_type"];
        if (self.precip.length) [parameters setObject:self.precip forKey:@"precip"];
        if (self.humidity.length) [parameters setObject:self.humidity forKey:@"humidity"];
        if (self.wind.length) [parameters setObject:self.wind forKey:@"wind"];
        if (self.temp.length) [parameters setObject:self.temp forKey:@"temp"];
        if (self.weatherIcon.length) [parameters setObject:self.weatherIcon forKey:@"weather_icon"];
        if (self.body.length){
            [parameters setObject:self.body forKey:@"body"];
        }
        
        NSMutableArray *userArray = [NSMutableArray array];
        for (ReportUser *reportUser in self.reportUsers) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            if (![reportUser.userId isEqualToNumber:[NSNumber numberWithInt:0]]) {
                [dict setObject:reportUser.userId forKey:@"id"];
            }
            if (reportUser.fullname.length) {
                [dict setObject:reportUser.fullname forKey:@"full_name"];
            }
            if (reportUser.hours) {
                [dict setObject:reportUser.hours forKey:@"hours"];
            }
            [userArray addObject:dict];
        }
        [parameters setObject:userArray forKey:@"report_users"];
        
        NSMutableArray *subArray = [NSMutableArray array];
        for (ReportSub *reportSub in self.reportSubs) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            if (![reportSub.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) [dict setObject:reportSub.identifier forKey:@"id"];
            if (reportSub.name.length) [dict setObject:reportSub.name forKey:@"name"];
            if (reportSub.count) [dict setObject:reportSub.count forKey:@"count"];
            [subArray addObject:dict];
            
        }
        [parameters setObject:subArray forKey:@"report_companies"];
        
        NSMutableArray *topicsArray = [NSMutableArray array];
        for (SafetyTopic *topic in self.safetyTopics) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            if (![topic.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) [dict setObject:topic.identifier forKey:@"id"];
            if (![topic.topicId isEqualToNumber:[NSNumber numberWithInt:0]]) [dict setObject:topic.topicId forKey:@"topic_id"];
            if (topic.title.length) [dict setObject:topic.title forKey:@"title"];
            [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"company_id"];
            [topicsArray addObject:dict];
        }
        [parameters setObject:topicsArray forKey:@"safety_topics"];
        
        BHAppDelegate *delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
        AFHTTPRequestOperationManager *manager = [delegate manager];
        
        if ([self.identifier isEqualToNumber:@0]){
            NSMutableOrderedSet *imageSet = [NSMutableOrderedSet orderedSetWithCapacity:self.photos.count];
            [self.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
                if (photo.image){
                    [imageSet addObject:photo.image];
                }
            }];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"author_id"]; //assign an author
            [manager POST:[NSString stringWithFormat:@"%@/reports",kApiBaseUrl] parameters:@{@"report":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"Success creating report: %@",responseObject);
                if ([responseObject objectForKey:@"duplicate"]){
                    [[[UIAlertView alloc] initWithTitle:@"Report Duplicate" message:@"A report for this date already exists." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    [ProgressHUD dismiss];
                    complete(NO);
                } else {
                    Report *report = [self MR_inContext:[NSManagedObjectContext MR_defaultContext]];
                    [report populateFromDictionary:[responseObject objectForKey:@"report"]];
                    [report setSaved:@YES];
                    [self synchImages:imageSet];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                    complete(YES);
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while synching this report. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                NSLog(@"Failure creating report: %@",error.description);
                complete(NO);
            }];
        } else {
            [manager PATCH:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,self.identifier] parameters:@{@"report":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"Success synching report: %@",responseObject);
                Report *report = [self MR_inContext:[NSManagedObjectContext MR_defaultContext]];
                
                if ([responseObject objectForKey:@"message"] && [[responseObject objectForKey:@"message"] isEqualToString:kNoReport]){
                    [report MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                } else {
                    [report populateFromDictionary:[responseObject objectForKey:@"report"]];
                    [report setSaved:@YES];
                }
                complete(YES);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failure synching report: %@",error.description);
                complete(NO);
            }];
        }
    }
}

- (void)synchImages:(NSMutableOrderedSet*)imageSet{
    BHAppDelegate *delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableDictionary *photoParameters = [NSMutableDictionary dictionary];
    [photoParameters setObject:self.identifier forKey:@"report_id"];
    [photoParameters setObject:@YES forKey:@"mobile"];
    [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    [photoParameters setObject:kReports forKey:@"source"];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]){
        [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"company_id"];
    }
    if (self.project.identifier){
        [photoParameters setObject:self.project.identifier forKey:@"project_id"];
    }
    
    for (UIImage *image in imageSet){
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        [delegate.manager POST:[NSString stringWithFormat:@"%@/photos",kApiBaseUrl] parameters:@{@"photo":photoParameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success posting photo for report: %@",responseObject);
            [self populateFromDictionary:[responseObject objectForKey:@"task"]];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //NSLog(@"Failure posting new task image to API: %@",error.description);
        }];
    }
}

@end
