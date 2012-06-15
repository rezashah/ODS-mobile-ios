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
//  Constants.h
//
//  This class has been include in the precompiled class header (FreshDocs.pch)
//  and therefore does not need to be included in any class files.
//

//
// General Notification Types
//
extern NSString * const kDetailViewControllerChangedNotification;
extern NSString * const kUserPreferencesChangedNotification;
extern NSString * const kKeychainUserDefaultsDidChangeNotification;

//
// Repo/AccountList Notification Types
//
extern NSString * const kNotificationAccountWasUpdated;
extern NSString * const kNotificationAccountListUpdated;

//
// Uploads Notification Types
//
extern NSString * const kNotificationUploadFinished;
extern NSString * const kNotificationUploadFailed;
extern NSString * const kNotificationUploadQueueChanged;
extern NSString * const kNotificationUploadStarted;

//
// Downloads Notification Types
//
extern NSString * const kNotificationDownloadFinished;
extern NSString * const kNotificationDownloadFailed;
extern NSString * const kNotificationDownloadQueueChanged;
extern NSString * const kNotificationDownloadStarted;

//
// Account Notification Types
//
extern NSString * const kAccountUpdateNotificationEdit;
extern NSString * const kAccountUpdateNotificationDelete;
extern NSString * const kAccountUpdateNotificationAdd;
extern NSString * const kAccountUpdateNotificationAllAccounts;
extern NSString * const kBrowseDocumentsNotification;
extern NSString * const kLastAccountDetailsNotification;

//
// General Purpose Constants
//
extern NSString * const kFDDocumentViewController_NibName;
extern NSString * const kFDRootViewController_NibName;
extern NSString * const kFDHTTP_Protocol;
extern NSString * const kFDHTTPS_Protocol;
extern NSString * const kFDHTTP_DefaultPort;
extern NSString * const kFDHTTPS_DefaultPort;
extern NSString * const kFDAlfresco_RepositoryVendorName;

extern NSTimeInterval const kNetworkProgressDialogGraceTime;
extern NSTimeInterval const kDocumentFadeInTime;
extern NSTimeInterval const kHUDMinShowTime;
extern NSTimeInterval const KHUDGraceTime;

extern NSString * const kDefaultTenantID;

extern NSString * const kAboutMoreIcon_ImageName;
extern NSString * const kAccountsMoreIcon_ImageName;
extern NSString * const kCloudIcon_ImageName;
extern NSString * const kHelpGuideIcon_ImageName;
extern NSString * const kHelpMoreIcon_ImageName;
extern NSString * const kNetworkIcon_ImageName;
extern NSString * const kServerIcon_ImageName;
extern NSString * const kSettingsMoreIcon_ImageName;
extern NSString * const kTwisterClosedIcon_ImageName;
extern NSString * const kTwisterOpenIcon_ImageName;


extern NSString * const kFDLibraryConfigFolderName;

extern CGFloat const kDefaultTableCellHeight;
extern CGFloat const kTableCellTextLeftPadding;

extern NSString * const kDefaultAccountsPlist_FileName;

//
// User Preferences name constants
// Search
extern NSString * const kFDSearchSelectedUUID;
extern NSString * const kFDSearchSelectedTenantID;

@interface Constants : NSObject
@end
