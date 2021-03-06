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
//  UploadFormTableViewController.h
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "IFGenericTableViewController.h"
#import "ASIHTTPRequestDelegate.h"
#import "MBProgressHUD.h"
#import "ModalViewControllerProtocol.h"
#import "UploadHelper.h"
#import "UploadInfo.h"

@class UploadFormTableViewController;
@class IFTextCellController;
@class UploadInfo;
@class IFChoiceCellController;

@interface UploadFormTableViewController : IFGenericTableViewController <UIAlertViewDelegate, ASIHTTPRequestDelegate, MBProgressHUDDelegate, ModalViewControllerProtocol> 
{
    UITextField *createTagTextField;
    NSMutableArray *availableTagsArray;
    
	SEL updateAction;
	id updateTarget;
    
    MBProgressHUD *HUD;
    
    NSArray *existingDocumentNameArray;
    BOOL presentedAsModal;
    id<UploadHelper> uploadHelper;
    UploadInfo *uploadInfo;
    NSArray *multiUploadItems;
    UploadFormType uploadType;
    NSString *selectedAccountUUID;
    NSString *tenantID;
    IFTextCellController *textCellController;
    BOOL shouldSetResponder;
    BOOL hasFetchedTags;
    BOOL addTagWasSelected;
}

@property (nonatomic, retain) UITextField *createTagTextField;
@property (nonatomic, retain) NSMutableArray *availableTagsArray;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, retain) NSArray *existingDocumentNameArray;
@property (nonatomic, retain) id<UploadHelper> uploadHelper;
@property (nonatomic, retain) UploadInfo *uploadInfo;
@property (nonatomic, retain) NSArray *multiUploadItems;
@property (nonatomic, assign) UploadFormType uploadType;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, retain) IFTextCellController *textCellController;
@property (nonatomic, retain) IFChoiceCellController *tagsCellController;
@property (nonatomic, retain) MBProgressHUD *HUD;

@property (nonatomic, retain) NSMutableArray *asyncRequests;
@property (nonatomic, retain) NSIndexPath *tagsCellIndexPath;

- (void)cancelButtonPressed;
- (void)saveButtonPressed;
- (void)addNewTagButtonPressed;
- (void)dismissViewControllerWithBlock:(void(^)(void))block;
- (void)addAndSelectNewTag:(NSString *)newTag;
@end
