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
//  NSNotificationCenter+CustomNotification.m
//

#import "NSNotificationCenter+CustomNotification.h"
#import "Reachability.h"

@implementation NSNotificationCenter (CustomNotification)

- (void)postAccountListUpdatedNotification:(NSDictionary *)userInfo 
{
    [self postNotificationName:kNotificationAccountListUpdated object:nil userInfo:userInfo];
}
- (void)postBrowseDocumentsNotification:(NSDictionary *)userInfo 
{
    [self postNotificationName:kBrowseDocumentsNotification object:nil userInfo:userInfo];
}
- (void)postDetailViewControllerChangedNotificationWithSender:(id)sender userInfo:(NSDictionary *)userInfo 
{
    [self postNotificationName:kDetailViewControllerChangedNotification object:nil userInfo:userInfo];
}

- (void)postUserPreferencesChangedNotification 
{
    [self postNotificationName:kUserPreferencesChangedNotification object:nil userInfo:nil];
}

- (void)postKeychainUserDefaultsDidChangeNotification 
{
    [self postNotificationName:kKeychainUserDefaultsDidChangeNotification object:nil userInfo:nil];
}

- (void)postUploadFinishedNotificationWithUserInfo:(NSDictionary *)userInfo
{
    [self postNotificationName:kNotificationUploadFinished object:nil userInfo:userInfo];
}

- (void)postUploadFailedNotificationWithUserInfo:(NSDictionary *)userInfo
{
    [self postNotificationName:kNotificationUploadFailed object:nil userInfo:userInfo];
}

- (void)postUploadQueueChangedNotificationWithUserInfo:(NSDictionary *)userInfo
{
    [self postNotificationName:kNotificationUploadQueueChanged object:nil userInfo:userInfo];
}

- (void)postUploadStartedNotificationWithUserInfo:(NSDictionary *)userInfo
{
    [self postNotificationName:kNotificationUploadStarted object:nil userInfo:userInfo];
}

@end
