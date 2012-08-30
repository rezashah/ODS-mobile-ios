//
//  AbstractFileDownloadManager.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 30/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "AbstractFileDownloadManager.h"

@interface AbstractFileDownloadManager (PrivateMethods)

@end

BOOL reload;
NSMutableDictionary *downloadMetadata;

@implementation AbstractFileDownloadManager

//AbstractFileDownloadManager *sharedInstance = nil;

- (void) dealloc {
	[super dealloc];
}

#pragma mark -
#pragma mark Singleton methods

+ (id)allocWithZone:(NSZone *)zone {
    
        return [super allocWithZone:zone];
            
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
	return self;
}

- (NSUInteger)retainCount
{
	return NSUIntegerMax;
}

- (oneway void)release
{
}

- (id)autorelease
{
	return self;
}

#pragma mark -
#pragma mark Public methods
- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key withFilePath: (NSString *) tempFile {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(!tempFile || ![fileManager fileExistsAtPath:[FileUtils pathToTempFile:tempFile]])
    {
        return nil;
    }
    
    NSString * fileID = [key lastPathComponent];
    
    NSString *md5Id;
    NSString *md5Path;
    
    if(kUseHash) {
        md5Id = [fileID MD5];
        md5Path = [key MD5];
    } else {
        md5Id = fileID;
        md5Path = key;
    }
    
    NSLog(@"====  File lcoation: %@ -------- %@", md5Id, md5Path);
    NSDictionary *previousInfo = [[self readMetadata] objectForKey:md5Id];
    
    if(![FileUtils saveTempFile:tempFile withName:md5Path]) {
        NSLog(@"Cannot move tempFile: %@ to the dowloadFolder, newName: %@", tempFile, md5Path);
        return nil;
    }
    
    // Saving a legacy file or a document sent through document interaction
    if(downloadInfo) {
        NSMutableDictionary *tempDownloadInfo = [[downloadInfo mutableCopy] autorelease];
        [tempDownloadInfo setObject:[NSDate date] forKey:@"lastDownloadedDate"];
        [[self readMetadata] setObject:tempDownloadInfo forKey:md5Id];
        NSLog(@"====  File Data: %@", downloadMetadata);
        if(![self writeMetadata]) {
            [FileUtils unsave:md5Path];
            [[self readMetadata] setObject:previousInfo forKey:md5Id];
            NSLog(@"Cannot save the metadata plist");
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

- (BOOL) updateDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key withFilePath: (NSString *) path
{
    NSString * result = [self setDownload:downloadInfo forKey:key withFilePath:path];
    
    if(result == nil)
        return NO;
    else 
        return YES;
}

-(void) updateLastDownloadDateForFilename:(NSString *) filename
{
    NSString * fileID = [filename lastPathComponent];
    
    NSMutableDictionary * fileInfo = [[self downloadInfoForFilename:fileID] mutableCopy];
    
    [fileInfo setObject:[NSDate date] forKey:@"lastDownloadedDate"]; 
    
    [[self readMetadata] setObject:fileInfo forKey:fileID];
    
    [self writeMetadata]; 
    
    [fileInfo release];
}

- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key {

    NSString * fileID = [key lastPathComponent];
    
    NSString *md5Id;
    
    if(kUseHash) {
        md5Id = [fileID MD5];
    } else {
        md5Id = fileID;
    }
    [[self readMetadata] setObject:downloadInfo forKey:md5Id];
    
    if(![self writeMetadata]) {
        NSLog(@"Cannot save the metadata plist");
        return nil;
    }
    
    return md5Id;
}

- (NSDictionary *) downloadInfoForKey:(NSString *) key {
    
    NSString * fileID = [key lastPathComponent];
    if(kUseHash) {
        fileID = [fileID MD5];
    } 
    return [self downloadInfoForFilename:fileID];
}

- (NSDictionary *) downloadInfoForFilename:(NSString *) filename {
    
    NSString * fileID = [filename lastPathComponent];
    return [[self readMetadata] objectForKey:fileID];
}

- (BOOL) removeDownloadInfoForFilename:(NSString *) filename {
    
    NSString * fileID = [filename lastPathComponent];
    
    NSDictionary *previousInfo = [[self readMetadata] objectForKey:fileID];
    
    NSLog(@" ------ File Id : %@ ----- %@", fileID, [self readMetadata]);
    
    if(previousInfo) {
        [[self readMetadata] removeObjectForKey:fileID];
        
        if(![self writeMetadata]) {
            NSLog(@"Cannot delete the metadata in the plist");
            return NO;
        }
    }
    
    if(![FileUtils unsave:filename]) {
        if(previousInfo) {
            [[self readMetadata] setObject:previousInfo forKey:fileID];
            // We assume this will not fail since we already wrote it
            [self writeMetadata];
        }
        
        NSLog(@"Cannot delete the file: %@", fileID);
        return NO;
    }
    
    return YES;
}

- (void) removeDownloadInfoForAllFiles
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void) reloadInfo {
    reload = YES;
}

- (void) deleteDownloadInfo {
    NSString *path = [self metadataPath];
    NSError *error;
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
}

- (BOOL) downloadExistsForKey: (NSString *) key {
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:key]];
}

#pragma mark -
#pragma mark PrivateMethods
- (NSMutableDictionary *) readMetadata {
    /*
    if(downloadMetadata && !reload) {
        return downloadMetadata;
    }
    */
    reload = NO;
    NSString *path = [self metadataPath];
    NSLog(@"Pathssssss: %@", path);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // We create an empty NSMutableDictionary if the file doesn't exists otherwise
    // we create it from the file
    if ([fileManager fileExistsAtPath: path])
    {
        //downloadMetadata = [[NSMutableDictionary alloc] initWithContentsOfFile: path];
        NSPropertyListFormat format;  
        NSString *error;  
        NSData *plistData = [NSData dataWithContentsOfFile:path];   
        
        //We assume the stored data must be a dictionary
        [downloadMetadata release];
        downloadMetadata = [[NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListMutableContainers format:&format errorDescription:&error] retain]; 
        
        if (!downloadMetadata) {  
            NSLog(@"Error reading plist from file '%s', error = '%s'", [path UTF8String], [error UTF8String]);  
            [error release];
        } 
    } else {
        downloadMetadata = [[NSMutableDictionary alloc] init];
    }
    
    return downloadMetadata;
}

- (BOOL) writeMetadata {
    NSString *path = [self metadataPath];
    NSLog(@"Pathssssss: %@", path);
    //[downloadMetadata writeToFile:path atomically:YES];
    NSData *binaryData;  
    NSString *error;
    
    NSDictionary *downloadPlist = [self readMetadata];
    binaryData = [NSPropertyListSerialization dataFromPropertyList:downloadPlist format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];  
    if (binaryData) {  
        [binaryData writeToFile:path atomically:YES];
        //Complete protection in metadata since the file is always read one time and we write it when the application is active
        [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:path];
    } else {  
        NSLog(@"Error writing plist to file '%s', error = '%s'", [path UTF8String], [error UTF8String]);  
        [error release];
        return NO;
    }  
    return YES;
}

- (NSString *)oldMetadataPath {
    
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString *)metadataPath {
    
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(NSString *) pathComponentToFile:(NSString *) fileName
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(NSString *) pathToFileDirectory:(NSString*) fileName
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end

