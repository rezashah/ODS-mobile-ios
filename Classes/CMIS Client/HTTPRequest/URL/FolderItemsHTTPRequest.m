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
//  FolderItemsHTTPRequest.m
//

#import "FolderItemsHTTPRequest.h"
#import "Utility.h"
#import "AlfrescoUtils.h"
#import "CMISMediaTypes.h"
#import "LinkRelationService.h"
#import "NSURL+HTTPURLUtils.h"
#import "CMISConstants.h"
#import "CMISUtils.h"

@implementation FolderItemsHTTPRequest

@synthesize item = _item;
@synthesize children = _children;
@synthesize currentCMISName = _currentCMISName;
@synthesize elementBeingParsed = _elementBeingParsed;
@synthesize context = _context;
@synthesize parentTitle = _parentTitle;
@synthesize valueBuffer = _valueBuffer;
@synthesize currentNamespaceURI = _currentNamespaceURI;
@synthesize currentAspect = _currentAspect;

- (void)dealloc
{
	[_item release];
	[_children release];
    [_currentCMISName release];
	[_elementBeingParsed release];
	[_context release];
	[_parentTitle release];
	[_valueBuffer release];
    [_currentNamespaceURI release];
    [_currentAspect release];
	[super dealloc];
}

- (id)initWithNode:(NSString *)node withAccountUUID:(NSString *)uuid
{
    if (self = [self initWithURL:[[AlfrescoUtils sharedInstanceForAccountUUID:uuid] childrenURLforNode:node] accountUUID:uuid])
    {
        _item = nil;
    }
	
	return self;
}

- (id)initWithAtomFeedUrlString:(NSString *)urlString withAccountUUID:(NSString *)uuid
{
    NSDictionary *paramDictionary = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];
    
    if (self = [self initWithURL:[[NSURL URLWithString:urlString] URLByAppendingParameterDictionary:paramDictionary] accountUUID:uuid])
    {
        _item = nil;
    }
	
	return self;
}

- (void)requestFinishedWithSuccessResponse
{
	// create an array to hold the folder items
	NSMutableArray *c = [[NSMutableArray alloc] init];
	self.children = c;
	[c release];
	
	// create a parser and parse the xml
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:[self responseData]] autorelease];
	[parser setShouldProcessNamespaces:YES];
	[parser setDelegate:self];
	[parser parse];
	
	// if the user has selected the preference to hide "dot" files, then filter those from the list
	if (!userPrefShowHiddenFiles())
    {
		for (int i = [self.children count] - 1; i >= 0; i--)
        {
			RepositoryItem *ritem = [self.children objectAtIndex:i];
			if ([ritem.title hasPrefix:@"."])
            {
				[self.children removeObjectAtIndex:i];
			}
		}
	}

	// sort the docs & folders by title
	//[self.children sortUsingSelector:@selector(compareTitles:)];  //TODO:sorted by server?
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	// if this is a new entry, create a repository item and add it to the list
	if ([elementName isEqualToString:@"entry"] &&  [CMISUtils isAtomNamespace:namespaceURI])
    {
		RepositoryItem *ritem = [[RepositoryItem alloc] init];
		
		NSMutableDictionary *md = [[NSMutableDictionary alloc] init];
		ritem.metadata = md;
		[md release];
        
        NSMutableArray *aspects = [[NSMutableArray alloc] init];
		ritem.aspects = aspects;
		[aspects release];
		
		[self.children addObject:ritem];
		[ritem release];
	}
	
	if ([elementName isEqualToString:@"content"] && [CMISUtils isAtomNamespace:namespaceURI])
    {
		[[self.children lastObject] setContentLocation: [attributeDict objectForKey:@"src"]];
	}
	
	// TODO: check comprehensive list of property element names
	if ([elementName hasPrefix:@"property"] && [CMISUtils isCmisNamespace:namespaceURI])
    {
		self.currentCMISName = [attributeDict objectForKey:kCMISPropertyDefinitionIdPropertyName];
	}
	
	//<ns3:link type="application/atom+xml;type=feed" rel="down" href="http://ibmcmis.dnsdojo.com:8080/p8cmis/resources/TestOS2/ContentFlat/idf_2360E61A-04F9-4DB7-BB87-54446A3F8AF3"/>
	if ([elementName isEqualToString:@"link"] && 
		[(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"down"] &&
		[(NSString *)[attributeDict objectForKey:@"type"] isEqualToString:kAtomFeedMediaType])
	{
		[[self.children lastObject] setIdentLink: [attributeDict objectForKey:@"href"]];
	}
	
	//<link rel="describedby" href="https://dms.xwave.ch:443/alfresco/service/cmis/type/F:st:sites"/>
	if ([elementName isEqualToString:@"link"] && 
		[(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"describedby"])
	{
		[[self.children lastObject] setDescribedByURL:[attributeDict objectForKey:@"href"]];
	}
	
	// <link rel="self" href="https://dms.xwave.ch:443/alfresco/service/cmis/s/workspace:SpacesStore/i/0874d76c-0369-4d99-9c54-72be3d59389c"/>
	if ([elementName isEqualToString:@"link"])
	{
		if ([(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"self"])
        {
			[[self.children lastObject] setSelfURL:[attributeDict objectForKey:@"href"]];
		}
		
		if ([self.children lastObject])
        {
			[[[self.children lastObject] linkRelations] addObject:attributeDict];
		}
	}
		
	self.elementBeingParsed = elementName;
    [self setCurrentNamespaceURI:namespaceURI];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	RepositoryItem *currentItem = [self.children lastObject];
	
	// TODO: check comprehensive list of property element names
	if ([elementName hasPrefix:@"property"] && [CMISUtils isCmisNamespace:namespaceURI])
    {
		if ([self.currentCMISName isEqualToString:kCMISLastModifiedPropertyName])
        {
			currentItem.lastModifiedBy = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:kCMISLastModificationDatePropertyName])
        {
			currentItem.lastModifiedDate = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:kCMISBaseTypeIdPropertyName])
        {
			currentItem.fileType = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:kCMISObjectIdPropertyName])
        {
			currentItem.guid = self.valueBuffer;
		} 
		else if ([self.currentCMISName isEqualToString:kCMISContentStreamLengthPropertyName])
        {
			currentItem.contentStreamLengthString = self.valueBuffer;
		}
        else if ([self.currentCMISName isEqualToString:kCMISVersionSeriesIdPropertyName])
        {
			currentItem.versionSeriesId = self.valueBuffer;
		}

		if (self.currentCMISName)
        {
			NSString *value = self.valueBuffer ? self.valueBuffer : @"";
			NSString *key = self.currentCMISName;
			[currentItem.metadata setValue:value forKey:key];
		}
		self.currentCMISName = nil;
		self.valueBuffer = nil;
	}
    else if ([elementName hasPrefix:@"appliedAspects"])
    {
        if ([self.currentAspect length] > 0)
        {
            [currentItem.aspects addObject:self.currentAspect];
        }
    }
    
    
	self.elementBeingParsed = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	RepositoryItem *currentItem = [self.children lastObject];

    if ([self.elementBeingParsed isEqualToString:@"title"] && [CMISUtils isAtomNamespace:self.currentNamespaceURI])
    {
		currentItem.title = currentItem.title ? [currentItem.title stringByAppendingString:string] : string;
	}
    else if ([self.elementBeingParsed isEqualToString:@"canCreateFolder"])
    {
		currentItem.canCreateFolder = [string isEqualToString:@"true"];
	}
    else if ([self.elementBeingParsed isEqualToString:@"canMoveObject"])
    {
		currentItem.canMoveObject = [string isEqualToString:@"true"];
	}
    else if ([self.elementBeingParsed isEqualToString:@"canCreateDocument"])
    {
		currentItem.canCreateDocument = [string isEqualToString:@"true"];
	}
    else if ([self.elementBeingParsed isEqualToString:@"canDeleteObject"])
    {
		currentItem.canDeleteObject = [string isEqualToString:@"true"];
    }
    else if ([self.elementBeingParsed isEqualToString:@"canSetContentStream"])
    {
		currentItem.canSetContentStream = [string isEqualToString:@"true"];
	}
    else if ([self.elementBeingParsed isEqualToString:@"value"])
    {
		self.valueBuffer = self.valueBuffer ? [self.valueBuffer stringByAppendingString:string] : string;
	}
    else if ([self.elementBeingParsed isEqualToString:@"appliedAspects"])
    {
        if ([string hasPrefix:kCMISAlfrescoAspectNamePrefix])
        {
            self.currentAspect = [string substringFromIndex:kCMISAlfrescoAspectNamePrefix.length];
        }
        else
        {
            self.currentAspect = string;
        }
	}
}

#pragma mark -  NSKeyValueCoding Protocol Methods

- (id)valueForUndefinedKey:(NSString *)key
{
    AlfrescoLogDebug(@"Undefined Key: %@", key);
    return nil;
}

@end
