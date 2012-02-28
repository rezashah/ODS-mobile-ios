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
//  LinkRelationService.m
//

#import "LinkRelationService.h"
#import "RepositoryServices.h"
#import "CMISMediaTypes.h"
#import "NSDictionary+URLEncoding.h"
#import "NSURL+HTTPURLUtils.h"

static void * volatile instanceObject;

// TODO: Rename class to link relation resolver or something of the sort

@interface LinkRelationService (Private)
- (NSPredicate *)predicateForLinkRelationName:(NSString *)relation;
- (NSPredicate *)predicateForLinkRelationName:(NSString *)relation cmisMediaType:(NSString *)cmisMediaType;
- (NSString *)stringForLinkRelation:(LinkRelation)linkRelation;
@end


@implementation LinkRelationService

#pragma mark Link Relation Resolver Methods
- (NSString *)hrefForLinkRelation:(LinkRelation)linkRelation onCMISObject:(RepositoryItem *)cmisObject
{
	// !!!: Should we check permissions and service availability?
	// !!!: Should we Check if resource is correct?
	
	NSString *linkRelString = [self stringForLinkRelation:linkRelation];
    return [self hrefForLinkRelationString:linkRelString onCMISObject:cmisObject];
	
}

- (NSString *)hrefForLinkRelationString:(NSString *)linkRelationStr onCMISObject:(RepositoryItem *)cmisObject
{
    NSPredicate *predicate = [self predicateForLinkRelationName:linkRelationStr];
	NSArray *result = [[cmisObject linkRelations] filteredArrayUsingPredicate:predicate];
	if ([result count] != 1) {
		NSLog(@"Hierarchy Navigation Link Relation could not be determined for given link relations: %@", [cmisObject linkRelations]);
		return nil;
	}
	
	return [[result objectAtIndex:0] valueForKey:@"href"];
}

- (NSString *)hrefForLinkRelationString:(NSString *)linkRelationStr cmisMediaType:(NSString *)cmisMediaType onCMISObject:(RepositoryItem *)cmisObject;
{
    NSPredicate *predicate = [self predicateForLinkRelationName:linkRelationStr cmisMediaType:cmisMediaType];
	NSArray *result = [[cmisObject linkRelations] filteredArrayUsingPredicate:predicate];
	if ([result count] != 1) {
		NSLog(@"Hierarchy Navigation Link Relation could not be determined for given link relations: %@", [cmisObject linkRelations]);
		return nil;
	}
	
	return [[result objectAtIndex:0] valueForKey:@"href"];
}

- (NSString *)hrefForHierarchyNavigationLinkRelation:(HierarchyNavigationLinkRelation)linkRelation 
										 cmisService:(NSString *)cmisService cmisObject:(RepositoryItem *)cmisObject
{
	// !!!: Should we check permissions and service availability? or just return nil 
	//		(link relation should not be defined if we do not have permissions correct?)
	
	NSString *linkRelationString = ((linkRelation == kUp) ? @"up" : ((linkRelation == kDown) ? @"down" : [NSString string]));
	NSString *mediaType = [NSString string];
	NSString *href = nil;
	switch (linkRelation) {
		case kUp:
		{
			//
			// FIXME: Implement Me
			//
			NSLog(@"Hierarchy Navigation Link Relation Up not yet implemented!");
			break;	
		}
		case kDown:
		{
			//
			// TODO: Should check that the Resource is correct, down only supports CMIS Folder and type objects
			//
			
			mediaType = (([cmisService hasSuffix:@"Children"]) 
						 ? kAtomFeedMediaType
						 : ( ([cmisService hasSuffix:@"Descendants"]) ? kCMISTreeMediaType : nil));
			// TODO: Make above line of code cleaner!!!  Should not pass in cmisService as a String, perhaps as an object or enum
			break;	
		}
		default:
		{
			NSLog(@"Unable to resolve Hierarchy Navigation Link Relation: [%d-%@], %@", linkRelation, linkRelationString, cmisService);
			return nil;
		}
	}
	
	NSPredicate *predicate = [self predicateForLinkRelationName:linkRelationString cmisMediaType:mediaType];
	NSArray *result = [[cmisObject linkRelations] filteredArrayUsingPredicate:predicate];
	if ([result count] != 1) {
		NSLog(@"Hierarchy Navigation Link Relation could not be determined for given link relations: %@", [cmisObject linkRelations]);
		return nil;
	}
	
	href = [[result objectAtIndex:0] valueForKey:@"href"];
	return href;
}

#pragma mark -
#pragma mark CMIS Collections (AtomPub) - Folder Children Collection
- (NSURL *)getChildrenURLForCMISFolder:(RepositoryItem *)cmisFolder withOptionalArguments:(NSDictionary *)optionalArgumentsDictionary
{
	NSString *linkHref = [self hrefForHierarchyNavigationLinkRelation:kDown cmisService:@"getChildren" cmisObject:cmisFolder];
	
	if (nil == linkHref) {
		NSLog(@"getChildren link destination could not be found for given link relations: %@", [cmisFolder linkRelations]);
		return nil;
	}
	
	NSString *httpParameterString = [optionalArgumentsDictionary urlEncodedParameterString];
	NSURL *getChildrenURL = [[NSURL URLWithString:linkHref] URLByAppendingParameterString:httpParameterString];
	return getChildrenURL;
}

- (NSDictionary *)optionalArgumentsForFolderChildrenCollectionWithMaxItems:(NSNumber *)maxItemsOrNil
																 skipCount:(NSNumber *)skipCountOrNil 
																	filter:(NSString *)filterOrNil 
												   includeAllowableActions:(BOOL)includeAllowableActions 
													  includeRelationships:(BOOL)includeRelationships 
														   renditionFilter:(NSString *)renditionFilterOrNil 
																   orderBy:(NSString *)orderByOrNil 
														includePathSegment:(BOOL)includePathSegment
{
	NSMutableDictionary *optionalArguments = [NSMutableDictionary dictionary];
	if (maxItemsOrNil != nil) [optionalArguments setObject:[maxItemsOrNil stringValue] forKey:@"maxItems"];
	if (skipCountOrNil != nil) [optionalArguments setObject:[skipCountOrNil stringValue] forKey:@"skipCount"];
	if (filterOrNil != nil) [optionalArguments setObject:filterOrNil forKey:@"filter"];
	if (includeAllowableActions) [optionalArguments setObject:@"true" forKey:@"includeAllowableActions"];
	if (includeRelationships) [optionalArguments setObject:@"true" forKey:@"includeRelationships"];
	if (renditionFilterOrNil != nil) [optionalArguments setObject:renditionFilterOrNil forKey:@"renditionFilter"];
	if (orderByOrNil != nil) [optionalArguments setObject:orderByOrNil forKey:@"orderBy"];
	if (includePathSegment) [optionalArguments setObject:@"true" forKey:@"includePathSegment"];
	return optionalArguments;
}

//#pragma mark CMIS Collections (AtomPub) - Relationships Collection
//#pragma mark CMIS Collections (AtomPub) - Policies Collection

- (NSDictionary *)defaultOptionalArgumentsForFolderChildrenCollection
{
	return [self optionalArgumentsForFolderChildrenCollectionWithMaxItems:nil skipCount:nil filter:nil 
												  includeAllowableActions:YES includeRelationships:NO 
														  renditionFilter:nil orderBy:nil includePathSegment:NO];
}

#pragma mark -
#pragma mark Private Methods
- (NSPredicate *)predicateForLinkRelationName:(NSString *)relation
{
	return [NSPredicate predicateWithFormat:@"rel == %@", relation];
}

- (NSPredicate *)predicateForLinkRelationName:(NSString *)relation cmisMediaType:(NSString *)cmisMediaType
{
	return [NSPredicate predicateWithFormat:@"(rel == %@) && (type == %@)" 
							  argumentArray:[NSArray arrayWithObjects:relation, cmisMediaType, nil]];
}

- (NSString *)stringForLinkRelation:(LinkRelation)linkRelation
{
	//
	// TODO: refactor strings into static constants
	//
	
	switch (linkRelation) {
		case kSelfLinkRelation:
			return @"self";
		case kServiceLinkRelation:
			return @"service";
		case kDescribedByLinkRelation:
			return @"describedby";
		case kViaLinkRelation:
			return @"via";
		case kEditMediaLinkRelation:
			return @"edit-media";
		case kEditLinkRelation:
			return @"edit";
		case kAlternateLinkRelation:
			return @"alternate";
		case kPagingFirstLinkRelation:
			return @"first";
		case kPagingPreviousLinkRelation:
			return @"previous";
		case kPagingNextLinkRelation:
			return @"next";
		case kPagingLastLinkRelation:
			return @"last";
		default:
			return nil;
	}
}


#pragma mark -
#pragma mark Singleton Methods
+ (id)shared
{
	@synchronized(self) 
	{
		if (instanceObject == nil)
			instanceObject = [[LinkRelationService alloc] init];
	}	
	return instanceObject;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (instanceObject == nil) {
            instanceObject = [super allocWithZone:zone];
            return instanceObject;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
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

@end