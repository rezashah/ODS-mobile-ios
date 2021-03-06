/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  ThemeProperties.m
//

#import "ThemeProperties.h"
#import "UIColor+Theme.h"

@interface ThemeProperties ()
+ (UIColor*)colorFromArray:(NSArray *) colors;
+ (UIColor*)colorFromSelector:(NSString *) selectorName;
@end

static NSDictionary *plist = nil;
NSString * const kThemeFile = @"Theme";
NSString * const kToolbarColorKey = @"toolbarColor";
NSString * const kBrowseHeaderColorKey = @"browse.headerColor";
NSString * const kBrowseHeaderTextColorKey = @"browse.sectionHeaderTextColor";
NSString * const kBrowseFooterColorKey = @"browse.footerColor";
NSString * const kBrowseFooterTextColorKey = @"browse.sectionFooterTextColor";
NSString * const kPullToRefreshTextColor = @"pullToRefreshTextColor";
NSString * const kColorRGBPrefix = @"colorRGB:";
NSString * const kColorMethodPrefix = @"colorMethod:";

NSString * const kIpadDetailGradientStartColor = @"ipad.detailGradient.startColor";
NSString * const kIpadDetailGradientEndColor = @"ipad.detailGradient.endColor";

NSString * const kRootSegmentedControlColor = @"root.segmentedControlColor";
NSString * const kRootSegmentedControlBkgColor = @"root.segmentedControlBkgColor";
NSString * const kSelectedSegmentColor = @"root.selectedSegmentColor";

@implementation ThemeProperties

+(void) initialize
{
    if (!plist) {
        NSString* path = [[NSBundle mainBundle] pathForResource:kThemeFile ofType:@"plist"];
        plist = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
}

+ (UIColor *)toolbarColor 
{
    NSArray *propValue = [plist objectForKey:kToolbarColorKey];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor *)browseHeaderColor 
{
    NSArray *propValue = [plist objectForKey:kBrowseHeaderColorKey];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor *)browseHeaderTextColor 
{
    NSArray *propValue = [plist objectForKey:kBrowseHeaderTextColorKey];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor *)browseFooterColor 
{
    NSArray *propValue = [plist objectForKey:kBrowseFooterColorKey];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor *)browseFooterTextColor 
{
    NSArray *propValue = [plist objectForKey:kBrowseFooterTextColorKey];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor *)ipadDetailGradientStartColor 
{
    NSArray *propValue = [plist objectForKey:kIpadDetailGradientStartColor];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor *)ipadDetailGradientEndColor 
{
    NSArray *propValue = [plist objectForKey:kIpadDetailGradientEndColor];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor *)segmentedControlColor 
{
    NSArray *propValue = [plist objectForKey:kRootSegmentedControlColor];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor *)segmentedControlBkgColor 
{
    NSArray *propValue = [plist objectForKey:kRootSegmentedControlBkgColor];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor *)selectedSegmentColor 
{
    NSArray *propValue = [plist objectForKey:kSelectedSegmentColor];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor *)pullToRefreshTextColor 
{
    NSArray *propValue = [plist objectForKey:kPullToRefreshTextColor];
    return [ThemeProperties colorFromArray:propValue];
}

+ (UIColor*)colorFromArray:(NSArray *) colors 
{
    return [UIColor colorWithHexRed:[[colors objectAtIndex:0] floatValue] 
                              green:[[colors objectAtIndex:1] floatValue] 
                               blue:[[colors objectAtIndex:2] floatValue] 
                  alphaTransparency:[[colors objectAtIndex:3] floatValue]];
}

+ (UIColor*) colorFromSelector:(NSString *) selectorName 
{
    SEL selector = NSSelectorFromString(selectorName);
    
    if([UIColor instancesRespondToSelector:selector]) 
    {
        return [UIColor performSelector:selector];
    } 
    else 
    {
        AlfrescoLogError(@"ERROR: UIColor doesn't respond to the %@ selector. Check the %@ plist file",selectorName,kThemeFile);
        return [UIColor whiteColor];
    }
}

@end
