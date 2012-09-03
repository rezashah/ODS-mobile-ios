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
//  FavoriteFileDownloadManager.m
//

#import "FavoriteFileDownloadManager.h"
#import "RepositoryItem.h"

@implementation FavoriteFileDownloadManager
NSString * const FavoriteMetadataFileName = @"FavoriteFilesMetadata";
NSString * const FavoriteMetadataFileExtension = @"plist";

#pragma mark - Singleton methods

+ (FavoriteFileDownloadManager *)sharedInstance
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

-(BOOL) string:(NSString*)string existsIn:(NSArray*)array
{
    for(id item in array)
    {
        if ([item isEqualToString:string])
        {
            return YES;
        }
    }
    
    return NO;
}

-(void) deleteUnFavoritedItems:(NSArray*)favorites excludingItemsFromAccounts:(NSArray*) failedAccounts
{   
    NSDictionary * favoritesMetaData = [self readMetadata];
    NSMutableArray *favoritesKeys = [[NSMutableArray alloc] init];
    NSArray *temp = [favoritesMetaData allKeys];
    
    for (int  i =0; i < [temp count]; i++)
    {
        NSString * accountUDIDForDoc = [[favoritesMetaData objectForKey:[temp objectAtIndex:i]] objectForKey:@"accountUUID"];
        
        if([self string:accountUDIDForDoc existsIn:failedAccounts] == NO)
        {
            [favoritesKeys addObject:[temp objectAtIndex:i]];
        }
        
    }
    
    NSMutableArray *itemsToBeDeleted = [favoritesKeys mutableCopy];
    
    for(NSString * item in favoritesKeys)
    {
        for (RepositoryItem *repos in favorites)
        {
            if([item hasPrefix:[repos.guid lastPathComponent]])
            {
                [itemsToBeDeleted removeObject:item];
                
            }
        }
    }
    
    for (NSString *item in itemsToBeDeleted)
    {
        NSLog(@"Removing Item: %@", item);
        [self removeDownloadInfoForFilename:item];
    }
    
    [itemsToBeDeleted release];
    
    [favoritesKeys release];
}

- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key withFilePath: (NSString *) tempFile 
{
    return [super setDownload:downloadInfo forKey:[self pathComponentToFile:key] withFilePath:tempFile];
}

- (BOOL) updateDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key withFilePath: (NSString *) path
{
    return [super updateDownload:downloadInfo forKey:[self pathComponentToFile:key] withFilePath:path];
}

-(void) updateLastModifiedDate:(NSString *) lastModificationDate  andLastDownloadDateForFilename:(NSString *) filename
{
    [super updateLastModifiedDate:lastModificationDate andLastDownloadDateForFilename:[self pathComponentToFile:filename]];
}

- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key 
{
    return [super setDownload:downloadInfo forKey:[self pathComponentToFile:key]];
}

- (NSDictionary *) downloadInfoForKey:(NSString *) key
{
    return [super downloadInfoForKey:[self pathComponentToFile:key]];
}

- (NSDictionary *) downloadInfoForFilename:(NSString *) filename 
{
    return [super downloadInfoForFilename:[self pathComponentToFile:filename]];
}

- (BOOL) removeDownloadInfoForFilename:(NSString *) filename
{
    return [super removeDownloadInfoForFilename:[self pathComponentToFile:filename]];
}

- (BOOL) downloadExistsForKey: (NSString *) key
{
    return [super downloadExistsForKey:[self pathComponentToFile:key]];
}

- (void) removeDownloadInfoForAllFiles
{
    NSArray *favFiles = [[FileUtils listSyncedFiles] copy];
    
    for(int i =0; i < [favFiles count]; i++)
    {
        [self removeDownloadInfoForFilename:[favFiles objectAtIndex:i]];
    }
    [favFiles release];
}

// Override base class behaviour
- (BOOL)overwriteExistingDownloads
{
    return YES;
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
    
    return [configPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", FavoriteMetadataFileName, FavoriteMetadataFileExtension]];
}

- (NSString *)metadataPath
{
    NSString *filename = [NSString stringWithFormat:@"%@.%@", FavoriteMetadataFileName, FavoriteMetadataFileExtension];
    return [FileUtils pathToConfigFile:filename];
}

- (NSString *)pathComponentToFile:(NSString *)fileName
{
    return [kSyncedFilesDirectory stringByAppendingPathComponent:fileName];
}

- (NSString *)pathToFileDirectory:(NSString*)fileName
{
    return [FileUtils pathToSavedFile:[self pathComponentToFile:fileName]];
}

- (NSString *)generatedNameForFile:(NSString *)fileName withObjectID:(NSString *)objectID
{
    NSString *newName = @"";
    
    NSString *fileExtension = [fileName pathExtension];
    
    if (fileExtension == nil || [fileExtension isEqualToString:@""])
    {
        newName = [objectID lastPathComponent];
    }
    else
    {
        newName = [NSMutableString stringWithFormat:@"%@.%@", [objectID lastPathComponent], fileExtension];
    }
    
    return newName;
}

@end

