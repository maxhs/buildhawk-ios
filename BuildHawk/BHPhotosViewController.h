//
//  BHPhotosViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHPhoto.h"

@interface BHPhotosViewController : UICollectionViewController
@property (strong, nonatomic) NSMutableArray *photosArray;

@end
