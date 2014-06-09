//
//  BHDatePicker.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/8/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHDatePicker.h"

const NSUInteger NUM_COMPONENTS = 5;
typedef enum {
    kBHDatePickerInvalid = 0,
    kBHDatePickerYear,
    kBHDatePickerMonth,
    kBHDatePickerDay,
    kBHDatePickerHour,
    kBHDatePickerMinute
} BHDatePickerComponent;


@interface BHDatePicker () <UIPickerViewDataSource, UIPickerViewDelegate> {
    BHDatePickerComponent _components[NUM_COMPONENTS];
}

@property (nonatomic, retain, readwrite) NSCalendar *calendar;
@property (nonatomic, retain, readwrite) NSDateFormatter *dateFormatter;
@property (nonatomic, retain, readwrite) NSDateComponents *currentDateComponents;
@property (nonatomic, retain, readwrite) UIFont *font;

@end

@implementation BHDatePicker

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (!self) return nil;
    
    [self commonInit];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)commonInit {
    self.tintColor = [UIColor whiteColor];
    self.font = [UIFont fontWithName:kHelveticaNeueRegular size:17];
    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [self setLocale:[NSLocale currentLocale]];
    self.picker = [[UIPickerView alloc] initWithFrame:self.bounds];
    self.picker.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.picker.dataSource = self;
    self.picker.delegate = self;
    [self.picker setBackgroundColor:[UIColor clearColor]];
    self.picker.tintColor = [UIColor whiteColor];
    self.date = [NSDate date];
    
    [self addSubview:self.picker];
    [self setBackgroundColor:[UIColor clearColor]];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(320.0f, 216.0f);
}

#pragma mark - Setup

- (void)setMinimumDate:(NSDate *)minimumDate {
    _minimumDate = minimumDate;
    [self updateComponents];
}

- (void)setMaximumDate:(NSDate *)maximumDate {
    
    _maximumDate = maximumDate;
    [self updateComponents];
}

- (void)setDate:(NSDate *)date {
    [self setDate:date animated:NO];
}

- (void)setDate:(NSDate *)date animated:(BOOL)animated {
    self.currentDateComponents = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit)
                                                  fromDate:date];
    
    [self.picker reloadAllComponents];
    [self setIndicesAnimated:YES];
}

- (NSDate *)date {
    return [self.calendar dateFromComponents:self.currentDateComponents];
}

- (void)setLocale:(NSLocale *)locale {
    self.calendar.locale = locale;
    [self updateComponents];
}

- (BHDatePickerComponent)componentFromLetter:(NSString *)letter {
    NSLog(@"letter: %@",letter);
    if ([letter isEqualToString:@"y"]) {
        return kBHDatePickerYear;
    }
    else if ([letter isEqualToString:@"M"]) {
        return kBHDatePickerMonth;
    }
    else if ([letter isEqualToString:@"d"]) {
        return kBHDatePickerDay;
    }
    else if ([letter isEqualToString:@"h"]) {
        return kBHDatePickerHour;
    }
    else if ([letter isEqualToString:@"m"]) {
        return kBHDatePickerMinute;
    }
    else if ([letter isEqualToString:@"a"] || [letter isEqualToString:@"p"]) {
        NSLog(@"invalid letter: %@",letter);
        return kBHDatePickerMinute;
    }
    else {
        return kBHDatePickerInvalid;
    }
}

- (BHDatePickerComponent)thirdComponentFromFirstComponent:(BHDatePickerComponent)component1
                                       andSecondComponent:(BHDatePickerComponent)component2 {
    
    NSMutableIndexSet *set = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(kBHDatePickerInvalid + 1, NUM_COMPONENTS)];
    [set removeIndex:component1];
    [set removeIndex:component2];
    
    return (BHDatePickerComponent) [set firstIndex];
}

- (void)updateComponents {
    NSString *componentsOrdering = [NSDateFormatter dateFormatFromTemplate:@"MMM dd hh:mm y" options:0 locale:self.calendar.locale];
    componentsOrdering = [componentsOrdering lowercaseString];
    
    /*NSString *firstLetter = [componentsOrdering substringToIndex:1];
     NSString *lastLetter = [componentsOrdering substringFromIndex:(componentsOrdering.length - 1)];
     _components[0] = [self componentFromLetter:firstLetter];
     _components[2] = [self componentFromLetter:lastLetter];
     _components[1] = [self thirdComponentFromFirstComponent:_components[0] andSecondComponent:_components[2]];*/
    _components[0] = kBHDatePickerMonth;
    _components[1] = kBHDatePickerDay;
    _components[2] = kBHDatePickerHour;
    _components[3] = kBHDatePickerMinute;
    _components[4] = kBHDatePickerYear;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.calendar = self.calendar;
    self.dateFormatter.locale = self.calendar.locale;
    
    [self.picker reloadAllComponents];
    
    [self setIndicesAnimated:NO];
}

- (void)setIndexForComponentIndex:(NSUInteger)componentIndex animated:(BOOL)animated {
    BHDatePickerComponent component = [self componentForIndex:componentIndex];
    NSRange unitRange = [self rangeForComponent:component];
    
    NSInteger value;
    
    if (component == kBHDatePickerYear) {
        value = self.currentDateComponents.year;
    }
    else if (component == kBHDatePickerMonth) {
        value = self.currentDateComponents.month;
    }
    else if (component == kBHDatePickerDay) {
        value = self.currentDateComponents.day;
    }
    else if (component == kBHDatePickerHour) {
        value = self.currentDateComponents.hour;
    }
    else if (component == kBHDatePickerMinute) {
        value = self.currentDateComponents.minute;
    }
    else {
        value = self.currentDateComponents.minute;
        //assert(NO);
    }
    
    NSInteger index = (value - unitRange.location);
    NSInteger middleIndex = (INT16_MAX / 2) - (INT16_MAX / 2) % unitRange.length + index;
    
    [self.picker selectRow:middleIndex inComponent:componentIndex animated:animated];
}

- (void)setIndicesAnimated:(BOOL)animated {
    for (NSUInteger componentIndex = 0; componentIndex < NUM_COMPONENTS; componentIndex++) {
        [self setIndexForComponentIndex:componentIndex animated:animated];
    }
}

- (BHDatePickerComponent)componentForIndex:(NSInteger)componentIndex {
    return _components[componentIndex];
}

- (NSCalendarUnit)unitForComponent:(BHDatePickerComponent)component {
    if (component == kBHDatePickerYear) {
        return NSYearCalendarUnit;
    }
    else if (component == kBHDatePickerMonth) {
        return NSMonthCalendarUnit;
    }
    else if (component == kBHDatePickerDay) {
        return NSDayCalendarUnit;
    }
    else if (component == kBHDatePickerHour) {
        return NSHourCalendarUnit;
    }
    else if (component == kBHDatePickerMinute) {
        return NSMinuteCalendarUnit;
    }
    else {
        return NSMinuteCalendarUnit;
        assert(NO);
    }
}

- (NSRange)rangeForComponent:(BHDatePickerComponent)component {
    NSCalendarUnit unit = [self unitForComponent:component];
    return [self.calendar maximumRangeOfUnit:unit];
}

#pragma mark - Data source


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 5;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)componentIndex {
    return INT16_MAX;
}

#pragma mark - Delegate

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)componentIndex {
    BHDatePickerComponent component = [self componentForIndex:componentIndex];
    
    if (component == kBHDatePickerYear) {
        CGSize size = [@"0000" sizeWithAttributes:@{NSFontAttributeName : self.font}];
        
        return size.width + 0.0f;
    }
    else if (component == kBHDatePickerMonth) {
        CGFloat maxWidth = 0.0f;
        
        for (NSString *monthName in self.dateFormatter.monthSymbols) {
            CGFloat monthWidth = [monthName sizeWithAttributes:@{NSFontAttributeName : self.font}].width;
            
            maxWidth = MAX(monthWidth, maxWidth);
        }
        
        return maxWidth + 10.f;
    }
    else if (component == kBHDatePickerDay) {
        CGSize size = [@"00" sizeWithAttributes:@{NSFontAttributeName : self.font}];
        
        return size.width + 30.0f;
    }
    else if (component == kBHDatePickerHour) {
        CGSize size = [@"00 : " sizeWithAttributes:@{NSFontAttributeName : self.font}];
        
        return size.width + 0.0f;
    }
    else if (component == kBHDatePickerMinute) {
        CGSize size = [@"00" sizeWithAttributes:@{NSFontAttributeName : self.font}];
        
        return size.width + 0.0f;
    }
    else {
        return 0.01f;
    }
}

- (NSString *)titleForRow:(NSInteger)row forComponent:(BHDatePickerComponent)component {
    NSRange unitRange = [self rangeForComponent:component];
    NSInteger value = unitRange.location + (row % unitRange.length);
    
    if (component == kBHDatePickerYear) {
        
        return [NSString stringWithFormat:@"%li", (long) value];
    }
    else if (component == kBHDatePickerMonth) {
        return [self.dateFormatter.monthSymbols objectAtIndex:(value - 1)];
    }
    else if (component == kBHDatePickerDay) {
        return [NSString stringWithFormat:@"%li", (long) value];
    }
    else if (component == kBHDatePickerHour) {
        return [NSString stringWithFormat:@"%li :", (long) value];
    }
    else if (component == kBHDatePickerMinute) {
        return [NSString stringWithFormat:@"%li", (long) value];
    }
    else {
        return @"";
    }
}

- (NSInteger)valueForRow:(NSInteger)row andComponent:(BHDatePickerComponent)component {
    NSRange unitRange = [self rangeForComponent:component];
    
    return (row % unitRange.length) + unitRange.location;
}

- (BOOL)isEnabledRow:(NSInteger)row forComponent:(NSInteger)componentIndex {
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = self.currentDateComponents.year;
    dateComponents.month = self.currentDateComponents.month;
    dateComponents.day = self.currentDateComponents.day;
    dateComponents.hour = self.currentDateComponents.hour;
    dateComponents.minute = self.currentDateComponents.minute;
    BHDatePickerComponent component = [self componentForIndex:componentIndex];
    NSInteger value = [self valueForRow:row andComponent:component];
    
    if (component == kBHDatePickerYear) {
        dateComponents.year = value;
    }
    else if (component == kBHDatePickerMonth) {
        dateComponents.month = value;
    }
    else if (component == kBHDatePickerDay) {
        dateComponents.day = value;
    }
    else if (component == kBHDatePickerHour) {
        dateComponents.day = value;
    }
    else if (component == kBHDatePickerMinute) {
        dateComponents.day = value;
    }
    
    NSDate *rowDate = [self.calendar dateFromComponents:dateComponents];
    
    if (self.minimumDate != nil && [self.minimumDate compare:rowDate] == NSOrderedDescending) {
        return NO;
    }
    else if (self.maximumDate != nil && [rowDate compare:self.maximumDate] == NSOrderedDescending) {
        return NO;
    }
    
    return YES;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)componentIndex reusingView:(UIView *)view {
    UILabel *label;
    
    if ([view isKindOfClass:[UILabel class]]) {
        label = (UILabel *) view;
    }
    else {
        label = [[UILabel alloc] init];
        label.font = self.font;
    }
    
    BHDatePickerComponent component = [self componentForIndex:componentIndex];
    NSString *title = [self titleForRow:row forComponent:component];
    
    UIColor *color;
    
    BOOL enabled = [self isEnabledRow:row forComponent:componentIndex];
    
    if (enabled) {
        color = [UIColor whiteColor];
    }
    else {
        color = [UIColor colorWithWhite:0.0f alpha:0.5f];
    }
    
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    label.attributedText = attributedTitle;
    
    if (component == kBHDatePickerMonth || component == kBHDatePickerMinute) {
        label.textAlignment = NSTextAlignmentLeft;
    } else if (component == kBHDatePickerYear || component == kBHDatePickerHour) {
        label.textAlignment = NSTextAlignmentRight;
    } else {
        label.textAlignment = NSTextAlignmentCenter;
    }
    
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)componentIndex {
    BHDatePickerComponent component = [self componentForIndex:componentIndex];
    NSInteger value = [self valueForRow:row andComponent:component];
    
    if (component == kBHDatePickerYear) {
        self.currentDateComponents.year = value;
    }
    else if (component == kBHDatePickerMonth) {
        self.currentDateComponents.month = value;
    }
    else if (component == kBHDatePickerDay) {
        self.currentDateComponents.day = value;
    }
    else if (component == kBHDatePickerHour) {
        self.currentDateComponents.hour = value;
    }
    else if (component == kBHDatePickerMinute) {
        self.currentDateComponents.minute = value;
    }
    else {
        assert(NO);
    }
    
    [self setIndexForComponentIndex:componentIndex animated:NO];
    
    NSDate *datePicked = self.date;
    
    if (self.minimumDate != nil && [datePicked compare:self.minimumDate] == NSOrderedAscending) {
        [self setDate:self.minimumDate animated:YES];
    }
    else if (self.maximumDate != nil && [datePicked compare:self.maximumDate] == NSOrderedDescending) {
        [self setDate:self.maximumDate animated:YES];
    }
    else {
        [self.picker reloadAllComponents];
    }
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
@end
