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
//  NewCloudAccountActions.m
//

#import "NewCloudAccountActions.h"
#import "DictionaryModel.h"
#import "NSString+Utils.h"
#import "AccountViewController.h"
#import "Utility.h"
#import "NewCloudAccountHTTPRequest.h"
#import "AccountUtils.h"
#import "AccountManager.h"

static NSString * const kDefaultCloudValuesKey = @"kDefaultCloudAccountValues";
static NSString * const kPlistExtension = @"plist";

@interface NewCloudAccountActions (private)
- (NSString *)validateData:(NSDictionary *)datasource;
@end

@implementation NewCloudAccountActions
@synthesize signupRequest =_signupRequest;
@synthesize controller = _controller;

- (void)dealloc
{
    [_signupRequest release];
    [_controller release];
    [super dealloc];
}

// There's only one row that we can select, the "Sign Up" button
- (void)rowWasSelectedAtIndexPath:(NSIndexPath *)indexPath withDatasource:(NSDictionary *)datasource andController:(FDGenericTableViewController *)controller
{
    NSString *errorMessage = [self validateData:datasource];
    //Validate returns nil if the form is valid
    if(!errorMessage)
    {
        [self setController:(NewCloudAccountViewController *)controller];
        DictionaryModel *model = [datasource objectForKey:@"model"];
        NSDictionary *accountDict =  [model dictionary];
        AccountInfo *accountInfo = [AccountUtils accountFromDictionary:accountDict];
        //Set the default values for alfresco cloud
        NSString *path = [[NSBundle mainBundle] pathForResource:kDefaultAccountsPlist_FileName ofType:kPlistExtension];
        NSDictionary *defaultAccountsPlist = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
        
        //Default cloud account values
        NSDictionary *defaultCloudValues = [defaultAccountsPlist objectForKey:kDefaultCloudValuesKey];
        [accountInfo setVendor:[defaultCloudValues objectForKey:@"Vendor"]];
        [accountInfo setProtocol:[defaultCloudValues objectForKey:@"Protocol"]];
        [accountInfo setHostname:[defaultCloudValues objectForKey:@"Hostname"]];
        [accountInfo setPort:[defaultCloudValues objectForKey:@"Port"]];
        [accountInfo setServiceDocumentRequestPath:[defaultCloudValues objectForKey:@"ServiceDocumentRequestPath"]];
        [accountInfo setMultitenant:[defaultCloudValues objectForKey:@"Multitenant"]];
        
        //Cloud Signup values
        [accountInfo setAccountStatus:FDAccountStatusAwaitingVerification];
        [accountInfo setDescription:[NSString stringWithFormat:@"Alfresco Cloud - %@", [accountInfo username]]]; 
        //TODO call the webservice that posts the user information, and sends the email.
        // NewCloudAccountHTTPRequest it is only a stub that calls the didFinish selector in the startAsynchronous method
        NewCloudAccountHTTPRequest *request = [NewCloudAccountHTTPRequest cloudSignupRequestWithAccount:accountInfo];
        [request setDelegate:self];
        [request startAsynchronous];
    }
    else
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"cloudsignup.alert.title", @"Alfresco Cloud Sign Up") message:errorMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
        [errorAlert show];
        [errorAlert release];
    }
}

// If the datasource is valid, which means all fields are not empty and also valid we enable the Save button
// Not active code, configure the righ button if the Save button is needed
- (void)datasourceChanged:(NSDictionary *)datasource inController:(FDGenericTableViewController *)controller notification:(NSNotification *)notification
{
    /*
    UIBarButtonItem *saveButton = controller.navigationItem.rightBarButtonItem;
    styleButtonAsDefaultAction(saveButton);
    [saveButton setEnabled:![self validateData:datasource]];*/
}

- (NSString *)validateData:(NSDictionary *)datasource
{
    DictionaryModel *model = [datasource objectForKey:@"model"];
    
    NSString *firstName = [model objectForKey:kAccountFirstNameKey];
    NSString *lastName = [model objectForKey:kAccountLastNameKey];
    NSString *email = [model objectForKey:kAccountUsernameKey];
    NSString *password = [model objectForKey:kAccountPasswordKey];
    NSString *confirmPassword = [model objectForKey:kAccountConfirmPasswordKey];
    
    // FirstName, LastName, password should not be empty
    if(![firstName isNotEmpty] || ![lastName isNotEmpty] || ![password isNotEmpty])
    {
        return NSLocalizedString(@"cloudsignup.invalidForm.message", @"Please fill all the requiered fields");
    }
    // Email is checked for a valid address
    else if(![email isValidEmail])
    {
        return NSLocalizedString(@"accountdetails.alert.save.emailerror", @"The email is invalid");
    }
    // password should match confirm password
    else if(![password isEqualToString:confirmPassword])
    {
        return NSLocalizedString(@"cloudsignup.passwordMatch.message", @"The password does not match with the confirm password");
    }
    return nil;
}

#pragma mark - ASIHTTPRequest delegate methods
-(void)requestFinished:(ASIHTTPRequest *)request {
    NewCloudAccountHTTPRequest *signupRequest = (NewCloudAccountHTTPRequest *)request;
    if([signupRequest signupSuccess])
    {
        AccountInfo *account = [signupRequest signupAccount];
        
        [[AccountManager sharedManager] saveAccountInfo:account];
        
        if(self.controller.delegate)
        {
            [self.controller.delegate accountControllerDidFinishSaving:self.controller];
        }
    }
    else
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"cloudsignup.alert.title", @"Alfresco Cloud Sign Up") message:NSLocalizedString(@"cloudsignup.unsuccessful.message", @"The cloud sign up was unsuccessful, please try again later") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
        [errorAlert show];
        [errorAlert release];
    }
}


-(void)requestFailed:(ASIHTTPRequest *)request {
    NSLog(@"Cloud signup request failed: %@", [request error]);
}
@end
