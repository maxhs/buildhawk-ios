//
//  BHTabBarViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHTabBarViewController.h"
#import <RestKit/RestKit.h>
#import "BHPhoto.h"
#import "BHUser.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface BHTabBarViewController ()

@end

@implementation BHTabBarViewController

@synthesize project;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadproject];
}

- (void)loadproject {
    RKObjectManager *manager = [RKObjectManager sharedManager];
    
    RKObjectMapping *photosMapping = [RKObjectMapping mappingForClass:[BHPhoto class]];
    [photosMapping addAttributeMappingsFromDictionary:@{
                                                        @"urls.200x200":@"url200",
                                                        @"urls.100x100":@"url100"
                                                        }];
    
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[BHUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"email",@"phone1",@"fname",@"lname",@"fullname"]];
    [userMapping addAttributeMappingsFromDictionary:@{@"_id":@"identifier"}];
    
    
    RKObjectMapping *projectMapping = [RKObjectMapping mappingForClass:[BHProject class]];

    [projectMapping addAttributeMappingsFromArray:@[@"name", @"location"]];
    [projectMapping addAttributeMappingsFromDictionary:@{
                                                           @"_id" : @"identifier",
                                                           @"created.createdOn" : @"createdOn"
                                                           }];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"created.photos"
                                                                                             toKeyPath:@"photos"
                                                                                           withMapping:photosMapping];
    
    RKRelationshipMapping *moreRelationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"users"
                                                                                             toKeyPath:@"users"
                                                                                           withMapping:userMapping];
    
    [projectMapping addPropertyMapping:relationshipMapping];
    [projectMapping addPropertyMapping:moreRelationshipMapping];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *projectsDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:projectMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:statusCodes];
    
    // For any object of class Article, serialize into an NSMutableDictionary using the given mapping and nest
    // under the 'article' key path
    //RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:projectMapping objectClass:[BHProject class] rootKeyPath:nil method:RKRequestMethodAny];
    
    //[manager addRequestDescriptor:requestDescriptor];
    [SVProgressHUD showWithStatus:@"Fetching project..."];
    [manager addResponseDescriptor:projectsDescriptor];
    [manager getObjectsAtPath:@"project" parameters:@{@"_id":self.project.identifier} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [SVProgressHUD dismiss];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get project from tab bar: %@",error.description);
        [SVProgressHUD dismiss];
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if ([item.title isEqualToString:@"Reports"]) {

    }
}

- (void)viewDidDisappear:(BOOL)animated{
    NSLog(@"BHTabBarVC did disappear");
    self.project = nil;
}

@end
