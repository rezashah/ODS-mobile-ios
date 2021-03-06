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
//  UserDefaultsMigrationCommand.m
//

#import "UserDefaultsMigrationCommand.h"

@implementation UserDefaultsMigrationCommand

- (NSArray *)userPreferences
{
    NSString *rootPlist = [[NSBundle mainBundle] pathForResource:@"Root" ofType:@"plist"];
    if (!rootPlist)
    {
        AlfrescoLogDebug(@"Could not find Settings.bundle");
        return [NSArray array];
    }
	
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:rootPlist];
    return [settings objectForKey:@"PreferenceSpecifiers"];
}

- (void)migrateKey:(NSString *)key
{
    id currentValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (currentValue)
    {
        [[FDKeychainUserDefaults standardUserDefaults] setObject:currentValue forKey:key];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

- (BOOL)runMigration
{
    NSArray *allPreferences = [self userPreferences];

    // We migrate all settings with the keys in the user preferences
    for (NSDictionary *preference in allPreferences)
    {
        NSString *key = [preference objectForKey:@"Key"];
        if (key)
        {
            [self migrateKey:key];
        }
    }
    
    //Special keys we should save
    NSDictionary *allDefaults = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];

    for (NSString* key in allDefaults) 
    {
        //All of the user default keys used
        if ([key hasPrefix:@"first_launch_"] || [key hasPrefix:@"migration."]) 
        {
            [self migrateKey:key];
        }
    }
    [self migrateKey:@"dataProtectionPrompted"];
    [self migrateKey:@"isFirstLaunch"];
    [self migrateKey:@"MultiAccountSetup"];
    [self migrateKey:@"searchSelectedUUID"];
    [self migrateKey:@"searchSelectedTenantID"];
    [self migrateKey:@"showActivitiesTab"];
    [self migrateKey:@"ShowHomescreen"];
    
    //Deleting all the other user preference to get rid of old user defaults
    //But we need to keep around the WebKitLocalStorageDatabasePathPreferenceKey preference to
    //avoid a bug in iOS 5.1
    //http://stackoverflow.com/questions/9679163/why-does-clearing-nsuserdefaults-cause-exc-crash-later-when-creating-a-uiwebview
    id workaround51Crash = [[NSUserDefaults standardUserDefaults] objectForKey:@"WebKitLocalStorageDatabasePathPreferenceKey"];
    NSDictionary *emptySettings = (workaround51Crash != nil) ? [NSDictionary dictionaryWithObject:workaround51Crash forKey:@"WebKitLocalStorageDatabasePathPreferenceKey"] : [NSDictionary dictionary];
    
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:emptySettings forName:[[NSBundle mainBundle] bundleIdentifier]];
    //We need to keep the setting that tracks the first run of the app
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:kPreferenceApplicationFirstRun];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES; 
}

@end
