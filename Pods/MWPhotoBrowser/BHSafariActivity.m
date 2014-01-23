//
//  BHSafariActivity.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 1/23/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHSafariActivity.h"

@implementation BHSafariActivity
{
	NSURL *_URL;
}

- (NSString *)activityType
{
	return NSStringFromClass([self class]);
}

- (NSString *)activityTitle
{
	return NSLocalizedStringFromTable(@"Open image/PDF in Safari", @"TUSafariActivity", nil);
}

- (UIImage *)activityImage
{
	return [UIImage imageNamed:@"Safari"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
			return YES;
		}
	}
	
	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
			_URL = activityItem;
		}
	}
}

- (void)performActivity
{
	BOOL completed = [[UIApplication sharedApplication] openURL:_URL];
	
	[self activityDidFinish:completed];
}

@end

