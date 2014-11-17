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
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"url_small"] && [dictionary objectForKey:@"url_small"] != [NSNull null]) {
        self.urlSmall = [dictionary objectForKey:@"url_small"];
    }
    if ([dictionary objectForKey:@"url_large"] && [dictionary objectForKey:@"url_large"] != [NSNull null]) {
        self.urlLarge = [dictionary objectForKey:@"url_large"];
    }
    if ([dictionary objectForKey:@"url_thumb"] && [dictionary objectForKey:@"url_thumb"] != [NSNull null]) {
        self.urlThumb = [dictionary objectForKey:@"url_thumb"];
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
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"update photo dict: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"epoch_time"] && [dictionary objectForKey:@"epoch_time"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_time"] doubleValue];
        self.createdAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"epoch_taken"] && [dictionary objectForKey:@"epoch_taken"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"epoch_taken"] doubleValue];
        self.takenAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"url_small"] && [dictionary objectForKey:@"url_small"] != [NSNull null]) {
        self.urlSmall = [dictionary objectForKey:@"url_small"];
    }
    if ([dictionary objectForKey:@"url_large"] && [dictionary objectForKey:@"url_large"] != [NSNull null]) {
        self.urlLarge = [dictionary objectForKey:@"url_large"];
    }
    if ([dictionary objectForKey:@"url_thumb"] && [dictionary objectForKey:@"url_thumb"] != [NSNull null]) {
        self.urlThumb = [dictionary objectForKey:@"url_thumb"];
    }
    if ([dictionary objectForKey:@"original"] && [dictionary objectForKey:@"original"] != [NSNull null]) {
        self.original = [dictionary objectForKey:@"original"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]) {
        self.name = [dictionary objectForKey:@"name"];
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
    if ([dictionary objectForKey:@"description"] && [dictionary objectForKey:@"description"] != [NSNull null]) {
        self.caption = [dictionary objectForKey:@"description"];
    }
}

- (void)synchWithServer:(synchCompletion)complete {
    
    //only need to synch if it's a new image, i.e. its identifier is 0
    if (self.image && [self.identifier isEqualToNumber:@0]){
        NSData *imageData = UIImageJPEGRepresentation(self.image, 1);
        NSMutableDictionary *photoParameters = [NSMutableDictionary dictionary];
        [photoParameters setObject:@YES forKey:@"mobile"];
        
        // Standard Stuff //
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
        // *** //
        
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

        [[delegate manager] POST:[NSString stringWithFormat:@"%@/photos",kApiBaseUrl] parameters:@{@"photo":photoParameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success synching image with API: %@",responseObject);
            //[self populateFromDictionary:[responseObject objectForKey:@"photo"]];
            Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[[responseObject objectForKey:@"photo"] objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            [photo updateFromDictionary:[responseObject objectForKey:@"photo"]];
            [photo setSaved:@YES];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                complete(YES);
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure synching image with API: %@",error.description);
            complete(NO);
            [delegate notifyError:error andOperation:operation andObject:self];
        }];
    }
}

@end
