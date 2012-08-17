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
//  TaskItem.m
//

#import "TaskItem.h"
#import "Utility.h"

@implementation TaskItem

@synthesize taskId = _taskId;
@synthesize name = _name;
@synthesize title = _title;
@synthesize description = _description;
@synthesize state = _state;
@synthesize initiator = _initiator;
@synthesize ownerUserName = _owner;
@synthesize startDate = _startDate;
@synthesize dueDate = _dueDate;
@synthesize priority = _priority;
@synthesize ownerFullName = _ownerFullName;
@synthesize documentItems = _documentItems;
@synthesize accountUUID = _accountUUID;
@synthesize tenantId = _tenantId;


- (void)dealloc
{
    [_taskId release];
	[_name release];
	[_title release];
	[_description release];
    [_state release];
    [_initiator release];
    [_owner release];
    [_startDate release];
    [_dueDate release];
    [_priority release];
    [_documentItems release];

    [_ownerFullName release];
    [_accountUUID release];
    [_tenantId release];
    [super dealloc];
}

- (TaskItem *)initWithJsonDictionary:(NSDictionary *)json
{
    self = [super init];
    
    if(self)
    {
        [self setTaskId:[json valueForKey:@"id"]];
        [self setName:[json valueForKey:@"name"]];
        [self setTitle:[json valueForKey:@"title"]];
        [self setDescription:[json valueForKeyPath:@"properties.bpm_description"]];
        [self setStartDate:dateFromIso([json valueForKeyPath:@"workflowInstance.startDate"])];

        if ([[json valueForKeyPath:@"workflowInstance.dueDate"] class] != [NSNull class])
        {
            [self setDueDate:dateFromIso([json valueForKeyPath:@"workflowInstance.dueDate"])];
        }

        [self setPriority:[json valueForKeyPath:@"propertyLabels.bpm_priority"]];
        [self setOwnerUserName:[json valueForKeyPath:@"owner.userName"]];
        [self setOwnerFullName:[NSString stringWithFormat:@"%@ %@", [json valueForKeyPath:@"owner.firstName"], [json valueForKeyPath:@"owner.lastName"]]];
        [self setAccountUUID:[json valueForKey:@"accountUUID"]];
        [self setTenantId:[json valueForKey:@"tenantId"]];
    }
    
    return self;
}

@end