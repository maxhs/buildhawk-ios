//
//  BHCollectionPhotoCell.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHCollectionPhotoCell.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation BHCollectionPhotoCell

@synthesize imageView;

- (id)initWithFrame:(CGRect)frame
{
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

-(void)configureForPhoto:(BHPhoto*)photo{
    [self.imageView setImageWithURL:[NSURL URLWithString:photo.url200]];
}

@end
