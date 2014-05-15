//
//  BHCollectionPhotoCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"

@interface BHCollectionPhotoCell : UICollectionViewCell

@property (strong,nonatomic) IBOutlet UIButton *photoButton;
-(void)configureForPhoto:(Photo*)photo;
@end
