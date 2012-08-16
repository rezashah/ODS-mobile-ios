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
//  DocumentItem.h
//
// Representation of document details (not its content) of documents associated with a task.
//

#import <Foundation/Foundation.h>

@interface DocumentItem : NSObject

@property (nonatomic, retain) NSString *nodeRef;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *itemDescription;
@property (nonatomic, retain) NSDate *modifiedDate;
@property (nonatomic, retain) NSString *modifiedBy;

// Creates a new DocumentItem using a json response received from the server.
- (DocumentItem *) initWithJsonDictionary:(NSDictionary *) json;

@end
