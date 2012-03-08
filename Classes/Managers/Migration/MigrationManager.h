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
//  MigrationManager.h
//

#import <Foundation/Foundation.h>
@class ProgressAlertView;

@interface MigrationManager : NSObject
{
    NSArray *_migrationCommands;
    ProgressAlertView *_progressAlertView;
}

@property (nonatomic, retain) ProgressAlertView *progressAlertView;

/*
 It initializes the MigrationManager with the desired migration commands we want to run for the migration.
 */
- (id)initWithMigrationCommands:(NSArray *)migrationCommands;
/*
 It will run the migration of all the migration commands that haven't run.
 The previous Versions contains an array of version that have successfully run before. 
 */
- (void)runMigrationWithVersions:(NSArray *)previousVersions;

+ (MigrationManager *)sharedManager;
@end
