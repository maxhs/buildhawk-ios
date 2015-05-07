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

- (void)awakeFromNib {
    [super awakeFromNib];
    self.photoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.photoButton.imageView.clipsToBounds = YES;
    [self.photoButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.photoButton setImage:nil forState:UIControlStateNormal];
}

- (void)configureForPhoto:(Photo*)photo{
    [self.photoButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal placeholderImage:nil options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
    }];
}

@end
