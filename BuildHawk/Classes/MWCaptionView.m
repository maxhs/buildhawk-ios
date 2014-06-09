//
//  MWCaptionView.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 30/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MWCommon.h"
#import "MWCaptionView.h"
#import "MWPhoto.h"

static const CGFloat labelPadding = 5;

// Private
@interface MWCaptionView () {
    id <MWPhoto> _photo;
    UITextView *_textView;
}
@end

@implementation MWCaptionView

- (id)initWithPhoto:(id<MWPhoto>)photo {
    self = [super initWithFrame:CGRectMake(0, 0, 320, 44)]; // Random initial frame
    if (self) {
        //self.userInteractionEnabled = NO;
        _photo = photo;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7")) {
            // Use iOS 7 blurry goodness
            self.barStyle = UIBarStyleBlackTranslucent;
            self.tintColor = nil;
            self.barTintColor = nil;
            self.barStyle = UIBarStyleBlackTranslucent;
            [self setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        } else {
            // Transparent black with no gloss
            CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
            UIGraphicsBeginImageContext(rect.size);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0 alpha:0.6] CGColor]);
            CGContextFillRect(context, rect);
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [self setBackgroundImage:image forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        }
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [self setupCaption];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    //if (_textView.numberOfLines > 0) maxHeight = _label.font.leading*_label.numberOfLines;
    CGRect textRect = [_textView.text boundingRectWithSize:CGSizeMake(screenWidth()-labelPadding*2, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:nil context:nil];
    return CGSizeMake(size.width, textRect.size.height + labelPadding * 2);
}

- (void)setupCaption {
    _textView = [[UITextView alloc] initWithFrame:CGRectIntegral(CGRectMake(labelPadding, 0,
                                                       self.bounds.size.width-labelPadding*2,
                                                       self.bounds.size.height))];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _textView.opaque = NO;
    _textView.backgroundColor = [UIColor clearColor];
    _textView.textAlignment = NSTextAlignmentLeft;
    _textView.scrollEnabled = YES;
    //_textView.lineBreakMode = NSLineBreakByWordWrapping;
    //_textView.numberOfLines = 0;
    _textView.editable = NO;
    _textView.textColor = [UIColor whiteColor];
    _textView.font = [UIFont systemFontOfSize:16];
    if ([_photo respondsToSelector:@selector(caption)]) {
        _textView.text = [_photo caption] ? [_photo caption] : @" ";
    }
    [self addSubview:_textView];
}


@end
