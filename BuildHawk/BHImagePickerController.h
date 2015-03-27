//
//  BHImagePickerController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/16/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol BHImagePickerControllerDelegate <NSObject>

@required
- (void)didFinishPickingPhotos:(NSMutableArray*)selectedPhotos;
@end

@interface BHImagePickerController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) ALAssetsGroup *assetsGroup;
@property (weak, nonatomic) id<BHImagePickerControllerDelegate> delegate;


@end
