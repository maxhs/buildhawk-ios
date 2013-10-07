//
//  BHCollectionPhotoCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHPhoto.h"

@interface BHCollectionPhotoCell : UICollectionViewCell

@property (strong,nonatomic) IBOutlet UIImageView *imageView;
-(void)configureForPhoto:(BHPhoto*)photo;
@end
