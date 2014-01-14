//
//  BHPhotosHeaderView.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHPhotosHeaderView : UICollectionReusableView
@property (strong,nonatomic) IBOutlet UILabel *headerLabel;
-(void)configureForTitle:(NSString*)title;
@end
