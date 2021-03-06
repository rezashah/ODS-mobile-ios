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
//  SearchViewController.h
//

#import <UIKit/UIKit.h>
#import "DownloadProgressBar.h"
#import "SelectSiteViewController.h"
#import "CMISServiceManager.h"
#import "AlfrescoMDMLite.h"

@class BaseHTTPRequest;
@class ObjectByIdRequest;
@class SearchPreviewManagerDelegate;
@class ServiceDocumentRequest;

@interface SearchViewController : UIViewController <
    AlfrescoMDMLiteDelegate,
    AlfrescoMDMServiceManagerDelegate,
    ASIHTTPRequestDelegate,
    CMISServiceManagerListener,
    SelectSiteDelegate,
    UISearchBarDelegate,
    UITableViewDataSource,
    UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UISearchBar *search;
@property (nonatomic, retain) IBOutlet UITableView *table;
@property (nonatomic, retain) NSMutableArray *results;
@property (nonatomic, retain) BaseHTTPRequest *searchDownload;
@property (nonatomic, retain) ServiceDocumentRequest *serviceDocumentRequest;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) TableViewNode *selectedSearchNode;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *savedTenantID;
@property (nonatomic, retain) SearchPreviewManagerDelegate *previewDelegate;
@property (nonatomic, retain) ObjectByIdRequest *metadataDownloader;

@end
