//
//  BHCollectionPhotoCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHCollectionPhotoCell.h"
#import "UIButton+WebCache.h"
#import "Photo+helper.h"

@implementation BHCollectionPhotoCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.photoButton setAlpha:0.f];
    [self.photoButton setImage:nil forState:UIControlStateNormal];
}

- (void)configureForPhoto:(Photo*)photo{
    [self.photoButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    [UIView animateWithDuration:.23 animations:^{
        [self.photoButton setAlpha:1.0];
    }];
    self.photoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.photoButton.imageView.clipsToBounds = YES;
    
    [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:photo.urlSmall] options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        [UIView transitionWithView:self.photoButton duration:.23 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self.photoButton setImage:image forState:UIControlStateNormal];
        } completion:^(BOOL finished) {
            
        }];
    }];
}

@end
