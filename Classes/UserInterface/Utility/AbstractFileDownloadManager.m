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
//  AbstractFileDownloadManager.m
//

#import "AbstractFileDownloadManager.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "DownloadInfo.h"
#import "DownloadMetadata.h"
#import "AccountInfo.h"
#import "AccountManager.h"
#import "SessionKeychainManager.h"
#import "RepositoryServices.h"
#import "ConnectivityManager.h"

NSInteger const kFileDoesNotExpire = 0;
NSInteger const kFileIsExpired = -1;

@implementation AbstractFileDownloadManager

#pragma mark - Public methods

- (NSString *)setDownload:(NSDictionary *)downloadInfo forKey:(NSString *)key withFilePath:(NSString *)tempFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (!tempFile || ![fileManager fileExistsAtPath:[FileUtils pathToTempFile:tempFile]])
    {
        return nil;
    }
    
    NSString *fileID = [key lastPathComponent];
    NSString *md5Id = kUseHash ? fileID.MD5 : fileID;
    NSString *md5Path = key;
    NSDictionary *previousInfo = [[self readMetadata] objectForKey:md5Id];
    
    if (![FileUtils saveTempFile:tempFile withName:md5Path overwriteExisting:self.overwriteExistingDownloads])
    {
        AlfrescoLogDebug(@"Cannot move tempFile: %@ to the downloadFolder, newName: %@", tempFile, md5Path);
        return nil;
    }
    
    // Saving a legacy file or a document sent through document interaction
    if (downloadInfo)
    {
        NSMutableDictionary *tempDownloadInfo = [[downloadInfo mutableCopy] autorelease];
        [tempDownloadInfo setObject:[NSDate date] forKey:@"lastDownloadedDate"];
        [[self readMetadata] setObject:tempDownloadInfo forKey:md5Id];
        if (![self writeMetadata])
        {
            [FileUtils unsave:md5Path];
            [[self readMetadata] setObject:previousInfo forKey:md5Id];
            AlfrescoLogDebug(@"Cannot save the metadata plist");
            return nil;
        }
        else
        {
            NSURL *fileURL = [NSURL fileURLWithPath:[FileUtils pathToSavedFile:md5Path]];
            addSkipBackupAttributeToItemAtURL(fileURL);
        }
    }
    return md5Path;
}

- (void)updateMetadata:(RepositoryItem *)repositoryItem forFilename:(NSString *)filename accountUUID:(NSString *)accountUUID tenantID:(NSString *)tenantID
{
    NSString *fileID = [filename lastPathComponent];
    DownloadInfo *downloadInfo = [[[DownloadInfo alloc] initWithRepositoryItem:repositoryItem] autorelease];
    downloadInfo.selectedAccountUUID = accountUUID;
    downloadInfo.tenantID = tenantID;
    
    NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithDictionary:downloadInfo.downloadMetadata.downloadInfo];
    NSString *newPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[self pathComponentToFile:filename]];
    
    // Set downloaded date to now
    [fileInfo setObject:[NSDate date] forKey:@"lastDownloadedDate"];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[fileInfo objectForKey:@"objectId"], @"objectId",
                              repositoryItem, @"repositoryItem",
                              newPath, @"newPath", nil];
    [[NSNotificationCenter defaultCenter] postDocumentUpdatedNotificationWithUserInfo:userInfo];
    
    [[self readMetadata] setObject:fileInfo forKey:fileID];
    [self writeMetadata];
}

- (void)updateMDMInfo:(NSNumber *)expiresAfter forFileName:(NSString *)fileName
{
    NSDictionary *fileInfo = [[self readMetadata] objectForKey:[fileName lastPathComponent]];
    NSMutableArray *aspects = fileInfo[@"aspects"];
    NSMutableDictionary *metadata = fileInfo[@"metadata"];
    
    if (expiresAfter)
    {
        if (![aspects containsObject:kMDMAspectKey])
        {
            [aspects addObject:kMDMAspectKey];
        }
        
        [metadata setValue:expiresAfter forKey:kFileExpiryKey];
    }
    else
    {
        [aspects removeObject:kMDMAspectKey];
        [metadata removeObjectForKey:kFileExpiryKey];
    }
    
    [self writeMetadata];
}

- (NSString *)setDownload:(NSDictionary *)downloadInfo forKey:(NSString *)key
{
    NSString *fileID = [key lastPathComponent];
    NSString *md5Id = kUseHash ? fileID.MD5 : fileID;
    
    [[self readMetadata] setObject:downloadInfo forKey:md5Id];
    
    if (![self writeMetadata])
    {
        AlfrescoLogDebug(@"Cannot save the metadata plist");
        return nil;
    }
    
    return md5Id;
}

- (NSDictionary *)downloadInfoForKey:(NSString *)key
{
    NSString *fileID = [key lastPathComponent];
    if (kUseHash)
    {
        fileID = [fileID MD5];
    }
    return [self downloadInfoForFilename:fileID];
}

- (NSDictionary *)downloadInfoForDocumentWithID:(NSString *)objectID
{
    NSString *objID = [objectID lastPathComponent];
    
    [self readMetadata];
    
    for (NSString *key in downloadMetadata)
    {
        if ([key hasPrefix:objID])
        {
            return [downloadMetadata objectForKey:key];
        }
    }
    return nil;
}

- (NSDictionary *)downloadInfoForFilename:(NSString *)filename
{
    NSString *fileID = [filename lastPathComponent];
    return [[self readMetadata] objectForKey:fileID];
}

- (BOOL)removeDownloadInfoForFilename:(NSString *)filename
{
    NSString *fileID = [filename lastPathComponent];
    NSDictionary *previousInfo = [[self readMetadata] objectForKey:fileID];
    
    if ([FileUtils moveFileToTemporaryFolder:[FileUtils pathToSavedFile:[self pathComponentToFile:filename]]])
    {
        // If we can get an objectId, then notify interested parties that the file has moved
        NSString *objectId = [previousInfo objectForKey:@"objectId"];
        if (objectId)
        {
            NSDictionary *userInfo = @{@"objectId": objectId,
                                       @"newPath": [FileUtils pathToTempFile:filename]
                                       };
            [[NSNotificationCenter defaultCenter] postDocumentUpdatedNotificationWithUserInfo:userInfo];
        }
        
        if (previousInfo)
        {
            [[self readMetadata] removeObjectForKey:fileID];
            
            if (![self writeMetadata])
            {
                AlfrescoLogDebug(@"Cannot delete the metadata in the plist");
                return NO;
            }
        }
        
        return YES;
    }
    
    return NO;
}

- (void)removeDownloadInfoForAllFiles
{
    // No-op
}

- (void)reloadInfo
{
    reload = YES;
}

- (void)deleteDownloadInfo
{
    NSString *path = [self metadataPath];
    NSError *error = nil;
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
}

- (BOOL)downloadExistsForKey:(NSString *)key
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:[self pathComponentToFile:key]]];
}

- (BOOL)isFileRestricted:(NSString *)fileName
{
    NSDictionary * downloadInfo = [self downloadInfoForFilename:fileName];
    
    return [[downloadInfo objectForKey:@"aspects"] containsObject:kMDMAspectKey];
}

- (BOOL)isFileExpired:(NSString *)fileName
{
    return kFileIsExpired == [self calculateTimeRemainingToExpireForFile:fileName];
}

- (NSArray *)getExpiredFilesList
{
    [self readMetadata];
    NSMutableArray *expiredFiles = [[NSMutableArray alloc] init];
    
    
    for(NSString *obj in [downloadMetadata allKeys])
    {
        if([self isFileRestricted:obj] && [self isFileExpired:obj])
        {
            [expiredFiles addObject:obj];
        }
    }
    
    return [expiredFiles autorelease];
}

- (NSTimeInterval)calculateTimeRemainingToExpireForFile:(NSString *)fileName
{
    NSDictionary *downloadInfo = [self downloadInfoForFilename:fileName];
    RepositoryInfo *repositoryInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:downloadInfo[@"accountUUID"] tenantID:nil];
    
    if (!repositoryInfo.hasValidSession || ![[ConnectivityManager sharedManager] hasInternetConnection])
    {
        AccountInfo *info = [[AccountManager sharedManager] accountInfoForUUID:downloadInfo[@"accountUUID"]];
        NSDate *lastSuccessfulLogin = [NSDate dateWithTimeIntervalSince1970:[info.accountStatusInfo successTimestamp]];
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:lastSuccessfulLogin];
        
        // Expiry time property is stored in milliseconds
        NSTimeInterval expiresAfter = [downloadInfo[@"metadata"][kFileExpiryKey] doubleValue] / 1000.;
        
        if (expiresAfter > 0)
        {
            return MAX(expiresAfter - interval, kFileIsExpired);
        }
    }
    
    return kFileDoesNotExpire;
}

#pragma mark - PrivateMethods

- (NSMutableDictionary *)readMetadata
{
    if (downloadMetadata && !reload)
    {
        return downloadMetadata;
    }
    
    reload = NO;
    NSString *path = [self metadataPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // We create an empty NSMutableDictionary if the file doesn't exists otherwise
    // we create it from the file
    if ([fileManager fileExistsAtPath:path])
    {
        NSError *error = nil;
        NSData *plistData = [NSData dataWithContentsOfFile:path];
        
        //We assume the stored data must be a dictionary
        [downloadMetadata release];
        downloadMetadata = [[NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainers format:NULL error:&error] retain];
        
        if (!downloadMetadata)
        {
            AlfrescoLogDebug(@"Error reading plist from file '%@', error = '%@'", path, error.localizedDescription);
        }
    }
    else
    {
        downloadMetadata = [[NSMutableDictionary alloc] init];
    }
    
    return downloadMetadata;
}

- (BOOL)writeMetadata
{
    NSString *path = [self metadataPath];
    NSError *error = nil;
    NSDictionary *downloadPlist = [self readMetadata];
    NSData *binaryData = [NSPropertyListSerialization dataWithPropertyList:downloadPlist format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (binaryData)
    {
        [binaryData writeToFile:path atomically:YES];
        //Complete protection in metadata since the file is always read one time and we write it when the application is active
        [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:path];
    }
    else
    {
        AlfrescoLogDebug(@"Error writing plist to file '%@', error = '%@'", path, error.localizedDescription);
        return NO;
    }
    return YES;
}

- (NSString *)pathComponentToFile:(NSString *)fileName
{
    return fileName;
}

- (NSString *)pathToFileDirectory:(NSString *)fileName
{
    return [FileUtils pathToSavedFile:[self pathComponentToFile:fileName]];
}

- (NSString *)oldMetadataPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *configPath = [documentsDirectory stringByAppendingPathComponent:@"config"];
    NSError *error;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:configPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:configPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    }
    
    return [configPath stringByAppendingPathComponent:self.metadataConfigFileName];
}

- (NSString *)metadataPath
{
    return [FileUtils pathToConfigFile:self.metadataConfigFileName];
}

@end
