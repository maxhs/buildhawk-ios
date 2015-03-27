//
//  Photo+helper.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/30/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Photo+helper.h"
#import "Project+helper.h"
#import "Folder+helper.h"
#import "BHAppDelegate.h"
#import "Report+helper.h"
#import "ChecklistItem+helper.h"
#import "Task+helper.h"

@implementation Photo (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"populate photo dictionary: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if (!self.localFilePath && [dictionary objectForKey:@"image_content_type"] && [dictionary objectForKey:@"image_content_type"] != [NSNull null]) {
        if ([[dictionary objectForKey:@"image_content_type"] rangeOfString:@"pdf"].location != NSNotFound && [dictionary objectForKey:@"image_file_name"]){
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //Get path directory
            NSString *resourceDocPath = [paths objectAtIndex:0];
            NSString *filePath = [resourceDocPath stringByAppendingPathComponent:[dictionary objectForKey:@"image_file_name"]];
            self.localFilePath = filePath;
            dispatch_queue_t queue = dispatch_queue_create("com.buildhawk.pdfqueue", NULL);
            dispatch_async(queue, ^{
                NSLog(@"dispatching a pdf save to the background on initial update");
                NSData *pdfData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[dictionary objectForKey:@"original"]]];
                [pdfData writeToFile:filePath atomically:NO];
            });
        }
    }
    if ([dictionary objectForKey:@"image_file_name"] && [dictionary objectForKey:@"image_file_name"] != [NSNull null]) {
        self.fileName = [dictionary objectForKey:@"image_file_name"];
    }
    if ([dictionary objectForKey:@"url_small"] && [dictionary objectForKey:@"url_small"] != [NSNull null]) {
        self.urlSmall = [dictionary objectForKey:@"url_small"];
    }
    if ([dictionary objectForKey:@"url_large"] && [dictionary objectForKey:@"url_large"] != [NSNull null]) {
        self.urlLarge = [dictionary objectForKey:@"url_large"];
    }
    if ([dictionary objectForKey:@"original"] && [dictionary objectForKey:@"original"] != [NSNull null]) {
        self.original = [dictionary objectForKey:@"original"];
    }
    if ([dictionary objectForKey:@"date_string"] && [dictionary objectForKey:@"date_string"] != [NSNull null]) {
        self.dateString = [dictionary objectForKey:@"date_string"];
    }
    if ([dictionary objectForKey:@"source"] && [dictionary objectForKey:@"source"] != [NSNull null]) {
        self.source = [dictionary objectForKey:@"source"];
    }
    if ([dictionary objectForKey:@"phase"] && [dictionary objectForKey:@"phase"] != [NSNull null]) {
        self.photoPhase = [dictionary objectForKey:@"phase"];
    }
    if ([dictionary objectForKey:@"user_name"] && [dictionary objectForKey:@"user_name"] !=[NSNull null]) {
        self.userName = [dictionary objectForKey:@"user_name"];
    }
    if ([dictionary objectForKey:@"description"] && [dictionary objectForKey:@"description"] != [NSNull null]) {
        self.caption = [dictionary objectForKey:@"description"];
    }
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"epoch_taken"] && [dictionary objectForKey:@"epoch_taken"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_taken"] doubleValue];
        self.takenAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"project_id"] && [dictionary objectForKey:@"project_id"] != [NSNull null]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"project_id"]];
        Project *project = [Project MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!project){
            project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [project setIdentifier:[dictionary objectForKey:@"project_id"]];
        self.project = project;
    }
    if ([dictionary objectForKey:@"folder"] && [dictionary objectForKey:@"folder"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"folder"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Folder *folder = [Folder MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!folder){
            folder = [Folder MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [folder populateFromDictionary:dict];
        self.folder = folder;
    }
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"update photo dict: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"image_content_type"] && [dictionary objectForKey:@"image_content_type"] != [NSNull null]) {
        if (!self.localFilePath.length && [[dictionary objectForKey:@"image_content_type"] rangeOfString:@"pdf"].location != NSNotFound){
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //Get path directory
            NSString *resourceDocPath = [paths objectAtIndex:0];
            NSString *filePath = [resourceDocPath stringByAppendingPathComponent:[dictionary objectForKey:@"image_file_name"]];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSData *pdfData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[dictionary objectForKey:@"original"]]];
                NSLog(@"dispatching a pdf save to the background");
                [pdfData writeToFile:filePath atomically:YES];
            });
            self.localFilePath = filePath;
        }
    }
    if ([dictionary objectForKey:@"image_file_name"] && [dictionary objectForKey:@"image_file_name"] != [NSNull null]) {
        self.fileName = [dictionary objectForKey:@"image_file_name"];
    }
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"epoch_taken"] && [dictionary objectForKey:@"epoch_taken"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_taken"] doubleValue];
        self.takenAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"url_small"] && [dictionary objectForKey:@"url_small"] != [NSNull null]) {
        self.urlSmall = [dictionary objectForKey:@"url_small"];
    }
    if ([dictionary objectForKey:@"url_large"] && [dictionary objectForKey:@"url_large"] != [NSNull null]) {
        self.urlLarge = [dictionary objectForKey:@"url_large"];
    }
    if ([dictionary objectForKey:@"original"] && [dictionary objectForKey:@"original"] != [NSNull null]) {
        self.original = [dictionary objectForKey:@"original"];
    }
    if ([dictionary objectForKey:@"date_string"] && [dictionary objectForKey:@"date_string"] != [NSNull null]) {
        self.dateString = [dictionary objectForKey:@"date_string"];
    }
    if ([dictionary objectForKey:@"source"] && [dictionary objectForKey:@"source"] != [NSNull null]) {
        self.source = [dictionary objectForKey:@"source"];
    }
    if ([dictionary objectForKey:@"phase"] && [dictionary objectForKey:@"phase"] != [NSNull null]) {
        self.photoPhase = [dictionary objectForKey:@"phase"];
    }
    if ([dictionary objectForKey:@"folder"] && [dictionary objectForKey:@"folder"] != [NSNull null]) {
        NSDictionary *dict = [dictionary objectForKey:@"folder"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Folder *folder = [Folder MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!folder){
            folder = [Folder MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [folder populateFromDictionary:dict];
        self.folder = folder;
    }
//    if ([dictionary objectForKey:@"description"] && [dictionary objectForKey:@"description"] != [NSNull null]) {
//        self.caption = [dictionary objectForKey:@"description"];
//    }
}

- (void)synchWithServer:(synchCompletion)complete {
    if (self.image && [self.saved isEqualToNumber:@NO]){
        NSData *imageData = UIImageJPEGRepresentation(self.image, .5);
        NSMutableDictionary *photoParameters = [NSMutableDictionary dictionary];
        [photoParameters setObject:@YES forKey:@"mobile"];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
            [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        }
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]){
            [photoParameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"company_id"];
        }
        if (self.project && self.project.identifier){
            [photoParameters setObject:self.project.identifier forKey:@"project_id"];
        }
        [photoParameters setObject:[NSNumber numberWithDouble:[self.takenAt timeIntervalSince1970]] forKey:@"taken_at"];
        
        if (self.report && ![self.report.identifier isEqualToNumber:@0]){
            [photoParameters setObject:self.report.identifier forKey:@"report_id"];
            [photoParameters setObject:kReports forKey:@"source"];
        } else if (self.checklistItem && ![self.checklistItem.identifier isEqualToNumber:@0]) {
            [photoParameters setObject:self.checklistItem.identifier forKey:@"checklist_item_id"];
            [photoParameters setObject:kChecklist forKey:@"source"];
        } else if (self.task && ![self.task.identifier isEqualToNumber:@0]){
            [photoParameters setObject:self.task.identifier forKey:@"task_id"];
            [photoParameters setObject:kTasklist forKey:@"source"];
        } else if (self.folder && ![self.folder.identifier isEqualToNumber:@0]){
            [photoParameters setObject:self.folder.identifier forKey:@"folder_id"];
            [photoParameters setObject:kFolder forKey:@"source"];
        }
        
        BHAppDelegate *delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
        [delegate.manager POST:[NSString stringWithFormat:@"%@/photos",kApiBaseUrl] parameters:@{@"photo":photoParameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:self.fileName mimeType:@"image/jpg"];
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success synching image with API: %@",responseObject);
            Photo *photo = [self MR_inContext:[NSManagedObjectContext MR_defaultContext]];
            [photo populateFromDictionary:[responseObject objectForKey:@"photo"]];
            [photo setSaved:@YES];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            complete(YES);
            [delegate.syncController update];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure synching image with API: %@",error.description);
            complete(NO);
        }];
    }
}

@end
