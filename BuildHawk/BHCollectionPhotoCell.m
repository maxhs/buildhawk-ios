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

-(void)configureForPhoto:(Photo*)photo{
    [self.photoButton setBackgroundColor:[UIColor clearColor]];
    [self.photoButton sd_setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal];
    self.photoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.photoButton.imageView.clipsToBounds = YES;
}

@end
