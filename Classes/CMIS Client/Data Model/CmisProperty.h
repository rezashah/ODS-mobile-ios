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
//  CmisProperty.h
//

#import <Foundation/Foundation.h>

@interface CmisProperty : NSObject {
@private
    NSString *type;
    NSString *propertyDefinitionId;
    NSString *displayName;
    NSString *queryName;
    NSString *cmisValue;
}

@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *propertyDefinitionId;
@property (nonatomic, retain) NSString *displayName;
@property (nonatomic, retain) NSString *queryName;
@property (nonatomic, retain) NSString *cmisValue;


- (id)initWithType:(NSString *)propType propertyDefinitionId:(NSString *)propDefId displayName:(NSString *)propDisplayName queryName:(NSString *)propQueryName;
- (id)initWithType:(NSString *)propType usingXmlAttributeDictionary:(NSDictionary *)cmisPropertyAttributes;

@end
