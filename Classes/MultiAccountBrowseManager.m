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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  MultiAccountBrowseManager.m
//

#import "MultiAccountBrowseManager.h"
#import "RepositoryServices.h"
#import "AccountManager.h"

static MultiAccountBrowseManager *sharedInstance;

@implementation MultiAccountBrowseManager
@synthesize listeners = _listeners;

- (void)dealloc {
    [requestAccountUUID release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if(self) {
        _listeners = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark - private methods
-(void)updateListenersWithType:(MultiAccountUpdateType)type {
    for(id<MultiAccountBrowseListener> listener in self.listeners) {
        if([listener respondsToSelector:@selector(multiAccountBrowseUpdated:forType:)]) {
            [listener multiAccountBrowseUpdated:self forType:type];
        }
    }
}

-(void)failListenersWithType:(MultiAccountUpdateType)type {
    for(id<MultiAccountBrowseListener> listener in self.listeners) {
        if([listener respondsToSelector:@selector(multiAccountBrowseFailed:forType:)]) {
            [listener multiAccountBrowseFailed:self forType:type];
        }
    }
}

#pragma mark - public methods
- (void)addListener:(id<MultiAccountBrowseListener>)listener {
    [self.listeners addObject:listener];
}

- (void)removeListener:(id<MultiAccountBrowseListener>)listener {
    [self.listeners removeObject:listener];
}

- (void)loadSitesForAccountUUID:(NSString *)uuid {
    if([[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:nil] hasResults]) {
        [self updateListenersWithType:MultiAccountSitesUpdate];
    } else {
        [self reloadSitesForAccountUUID:uuid];
    }
}
- (void)reloadSitesForAccountUUID:(NSString *)uuid {
    [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:nil] addListener:self];
    [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:nil] startOperations];
}

- (void)loadNetworksForAccountUUID:(NSString *)uuid {
    CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
    //[serviceManager addListener:self forAccountUuid:uuid];
    [serviceManager addQueueListener:self];
    [serviceManager loadServiceDocumentForAccountUuid:uuid];
    [requestAccountUUID release];
    requestAccountUUID = [uuid copy];
}

- (void)loadSitesForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID {
    if([[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:tenantID] hasResults]) {
        [self updateListenersWithType:MultiAccountNetworkSitesUpdate];
    } else {
        [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:tenantID] addListener:self];
        [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:tenantID] startOperations];
    }
}

- (NSArray *)sitesForAccountUUID:(NSString *)uuid {
    if([[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:nil] hasResults]) {
        return [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:nil] allSites];
    } else {
        return nil;
    }
}

- (NSArray *)networksForAccountUUID:(NSString *)uuid {
    NSArray *networks = [NSArray arrayWithArray:[[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:uuid]];
    if(networks) {
        return networks;
    } else {
        return nil;
    }
}

- (NSArray *)sitesForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID {
    if([[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:tenantID] hasResults]) {
        return [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:tenantID] allSites];
    } else {
        return nil;
    }
}

- (NSArray *)accounts {
    return [[AccountManager sharedManager] allAccounts];
}

#pragma mark - CMISServiceManagerListener

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    NSArray *array = [NSArray arrayWithArray:[[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:requestAccountUUID]];
    if(array) {
        [self updateListenersWithType:MultiAccountNetworksUpdate];
    } else {
        [self failListenersWithType:MultiAccountNetworksUpdate];
    }
    
    [requestAccountUUID release];
    requestAccountUUID = nil;
    [[CMISServiceManager sharedManager] removeQueueListener:self];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [self failListenersWithType:MultiAccountNetworksUpdate];
    [[CMISServiceManager sharedManager] removeQueueListener:self];
}

#pragma mark - SitesMangerService delegate
- (void)siteManagerFinished:(SitesManagerService *)siteManager {
    if([[siteManager tenantID] isEqualToString:kDefaultTenantID]) {
        [self updateListenersWithType:MultiAccountSitesUpdate];
    } else {
        [self updateListenersWithType:MultiAccountNetworkSitesUpdate];
    }
    
    [siteManager removeListener:self];
}
- (void)siteManagerFailed:(SitesManagerService *)siteManager {
    if([[siteManager tenantID] isEqualToString:kDefaultTenantID]) {
        [self failListenersWithType:MultiAccountNetworkSitesUpdate];
    } else {
        [self failListenersWithType:MultiAccountNetworkSitesUpdate];
    }
    
    [siteManager removeListener:self];
}

#pragma mark - Singleton methods
+ (MultiAccountBrowseManager *)sharedManager {
    if(sharedInstance == nil)
        sharedInstance = [[MultiAccountBrowseManager alloc] init];
    
    return sharedInstance;
}
@end