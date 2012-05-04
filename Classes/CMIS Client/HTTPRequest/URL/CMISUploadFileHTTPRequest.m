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
//  CMISUploadFileHTTPRequest.m
//

#import "CMISUploadFileHTTPRequest.h"
#import "UploadInfo.h"
#import "CMISMediaTypes.h"
#import "NSString+Utils.h"
#import "FileUtils.h"
#import "UploadsManager.h"

@implementation CMISUploadFileHTTPRequest
@synthesize uploadInfo = _uploadInfo;

- (void)dealloc
{
    [_uploadInfo release];
    [super dealloc];
}

//Overriding to assign a last minute name for multiuploads
- (void)start
{
    /*if(![self.uploadInfo.filename isNotEmpty])
    {
        NSDate *now = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH.mm.ss"];
        NSString *timestamp = [dateFormatter stringFromDate:now];
        [dateFormatter release];
        
        NSString *mediaType = [self.uploadInfo typeDescriptionWithPlural:NO];
        NSArray *existingDocumets = [[UploadsManager sharedManager] existingDocumentsForUplinkRelation:self.uploadInfo.upLinkRelation];
        NSString *newName = [NSString stringWithFormat:@"%@ %@", mediaType, timestamp];
        [self.uploadInfo setFilename:newName];
        
        newName = [FileUtils nextFilename:[self.uploadInfo completeFileName] inNodeWithDocumentNames:existingDocumets];
        if(![newName isEqualToCaseInsensitiveString:[self.uploadInfo completeFileName]])
        {
            [self.uploadInfo setFilename:[newName stringByDeletingPathExtension]];
        }
    }
    
    NSString *uploadBody  = [self.uploadInfo postBody];
    [self setPostBody:[NSMutableData dataWithData:[uploadBody
                                                      dataUsingEncoding:NSUTF8StringEncoding]]];
    [self setContentLength:[uploadBody length]];*/
    [super start];
}

+ (CMISUploadFileHTTPRequest *)cmisUploadRequestWithUploadInfo:(UploadInfo *)uploadInfo
{
    CMISUploadFileHTTPRequest *request = [CMISUploadFileHTTPRequest requestWithURL:[uploadInfo uploadURL] accountUUID:[uploadInfo selectedAccountUUID]];
    [request setRequestMethod:@"POST"];
    [request addRequestHeader:@"Content-Type" value:kAtomEntryMediaType];
    [request setShouldContinueWhenAppEntersBackground:YES];
    [request setSuppressAllErrors:YES];
    [request setUploadInfo:uploadInfo];
    NSArray *existingDocumets = [[UploadsManager sharedManager] existingDocumentsForUplinkRelation:uploadInfo.upLinkRelation];
    
    if(![uploadInfo.filename isNotEmpty])
    {
        NSDate *now = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH.mm.ss"];
        NSString *timestamp = [dateFormatter stringFromDate:now];
        [dateFormatter release];
        
        NSString *mediaType = [uploadInfo typeDescriptionWithPlural:NO];
        
        NSString *newName = [NSString stringWithFormat:@"%@ %@", mediaType, timestamp];
        [uploadInfo setFilename:newName];
        
        newName = [FileUtils nextFilename:[uploadInfo completeFileName] inNodeWithDocumentNames:existingDocumets];
        if(![newName isEqualToCaseInsensitiveString:[uploadInfo completeFileName]])
        {
            [uploadInfo setFilename:[newName stringByDeletingPathExtension]];
        }
    }
    
    // Adding the file name to the existing documents array
    // TODO: What if the repositoryNode updates this? the 
    NSMutableArray *updatedDocuments = [NSMutableArray arrayWithArray:existingDocumets];
    [updatedDocuments addObject:[uploadInfo completeFileName]];
    [[UploadsManager sharedManager] setExistingDocuments:updatedDocuments forUpLinkRelation:uploadInfo.upLinkRelation];
    
    NSString *uploadBody  = [uploadInfo postBody];
    [request setPostBody:[NSMutableData dataWithData:[uploadBody
                                                   dataUsingEncoding:NSUTF8StringEncoding]]];
    [request setContentLength:[uploadBody length]];
    return request;
}
@end
