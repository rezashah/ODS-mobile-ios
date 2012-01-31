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
//  DocumentViewController.m
//

#import "DocumentViewController.h"
#import "SavedDocument.h"
#import "DocumentCommentsTableViewController.h"
#import "CommentsHttpRequest.h"
#import "NodeRef.h"
#import "IFTemporaryModel.h"
#import "AppProperties.h"
#import "ToggleBarButtonItemDecorator.h"
#import "Utility.h"
#import "ThemeProperties.h"
#import "FileDownloadManager.h"
#import "RepositoryServices.h"
#import "NodeRef.h"
#import "TransparentToolbar.h"
#import "MBProgressHUD.h"
#import "BarButtonBadge.h"
#import "AccountManager.h"
#import "QOPartnerApplicationAnnotationKeys.h"

#define kWebViewTag 1234
#define kToolbarSpacerWidth 7.5f
#define kFrameLoadCodeError 102

#define kAlertViewOverwriteConfirmation 1
#define kAlertViewDeleteConfirmation 2

@interface DocumentViewController (private) 
- (void)loadCommentsViewController:(NSDictionary *)model;
- (void)replaceCommentButtonWithBadge:(NSString *)badgeTitle;
- (void)startHUD;
- (void)stopHUD;
- (void)cancelActiveHTTPConnections;
- (NSString *)applicationDocumentsDirectory;
- (NSString *)fixMimeTypeFor:(NSString *)originalMimeType;
@end

@implementation DocumentViewController
@synthesize cmisObjectId;
@synthesize fileData;
@synthesize fileName;
@synthesize filePath;
@synthesize contentMimeType;
@synthesize fileMetadata;
@synthesize isDownloaded;
@synthesize documentToolbar;
@synthesize favoriteButton;
@synthesize likeBarButton;
@synthesize webView;
@synthesize docInteractionController;
@synthesize actionButton;
@synthesize actionSheet = _actionSheet;
@synthesize commentButton;
@synthesize likeRequest;
@synthesize commentsRequest;
@synthesize showLikeButton;
@synthesize isVersionDocument;
@synthesize HUD;
@synthesize selectedAccountUUID;
@synthesize tenantID;
@synthesize repositoryID;

BOOL isFullScreen = NO;
UIView *previousTabBarView;

NSInteger const kGetCommentsCountTag = 6;
NSString* const PartnerApplicationFileMetadataKey = @"PartnerApplicationFileMetadataKey";
NSString* const PartnerApplicationDocumentPathKey = @"PartnerApplicationDocumentPath";

- (void)dealloc {
    NSError *error = nil;
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
    //Preventing the removal of the temp file for the case another instance of this class
    //is using the same temp file
    //[[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (error)
        NSLog(@"Error removing temporary file at path %@.  Error: %@", path, error);
    
    [self cancelActiveHTTPConnections];
    [cmisObjectId release];
	[fileData release];
	[fileName release];
    [filePath release];
    [contentMimeType release];
    [fileMetadata release];
	[documentToolbar release];
	[favoriteButton release];
	[webView release];
    [likeBarButton release];
    [previousTabBarView release];
	[docInteractionController release];
    [actionButton release];
    [_actionSheet release];
    [commentButton release];
    [likeRequest release];
    [commentsRequest release];
    [previewRequest release];
    [HUD release];
    [selectedAccountUUID release];
    [tenantID release];
    [repositoryID release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [webView removeFromSuperview];
    self.webView = nil;
    
    [super viewDidUnload];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    blankRequestLoaded = YES;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    /**
     * 02dec2011: mhatfield
     * This UIWebView code seems to be a duplicate of code in viewDidLoad:
     * I have commented it out to prevent NSURL errors (code -999, kCFURLErrorCancelled)
     */
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
    
    if(filePath) {
        //If filepath is set, it is preferred from the filename in the temp path
        path = filePath;
        //self.fileName = [filePath lastPathComponent];
    }
    
    NSURL *url = [NSURL fileURLWithPath:path];
    //Only reload content if the request is the blank page
    if(contentMimeType && blankRequestLoaded){
        [SavedDocument completeProtectFileAtPath:path];
        NSData *requestData = [NSData dataWithContentsOfFile:path options:NSDataWritingFileProtectionComplete error:nil];
        
        [webView loadData:requestData MIMEType:contentMimeType textEncodingName:@"UTF-8" baseURL:url];
    } else if(blankRequestLoaded) {
        [webView loadRequest:previewRequest];
    }
    
    blankRequestLoaded = NO;
    [[self commentButton] setEnabled:YES];
    
    BOOL usingAlfresco = [[AccountManager sharedManager] isAlfrescoAccountForAccountUUID:selectedAccountUUID];
    BOOL showCommentButton = [[AppProperties propertyForKey:kPShowCommentButton] boolValue];
    BOOL useLocalComments = [[NSUserDefaults standardUserDefaults] boolForKey:@"useLocalComments"];
    
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:selectedAccountUUID];
    BOOL validAccount = account?YES:NO;
    
#ifdef TARGET_ALFRESCO
    if (isDownloaded) showCommentButton = NO;
#endif

    //Calling the comment request service for the comment count
    if ((showCommentButton && usingAlfresco) && !(isDownloaded && useLocalComments) && validAccount)
    {
        self.commentsRequest = [CommentsHttpRequest commentsHttpGetRequestWithNodeRef:[NodeRef nodeRefFromCmisObjectId:self.cmisObjectId] 
                                                                          accountUUID:selectedAccountUUID tenantID:self.tenantID];
        [commentsRequest setDelegate:self];
        [commentsRequest setDidFinishSelector:@selector(commentsHttpRequestDidFinish:)];
        [commentsRequest setDidFailSelector:@selector(commentsHttpRequestDidFail:)];
        [commentsRequest setTag:kGetCommentsCountTag];
        [commentsRequest startAsynchronous];
    } else if(useLocalComments) { //We retrieve the count from the saved comments 
        [self replaceCommentButtonWithBadge:[NSString stringWithFormat:@"%d", [fileMetadata.localComments count]]];
    }
}


/*
 Started with the idea in http://stackoverflow.com/questions/1110052/uiview-doesnt-resize-to-full-screen-when-hiding-the-nav-bar-tab-bar
 UIView doesn't resize to full screen when hiding the nav bar & tab bar
 
 made several changes, including changing tab bar for custom toolbar
 */
- (void) handleTap:(UIGestureRecognizer *)sender {
    NSLog(@"Tapping UIWebView");
    isFullScreen = !isFullScreen;
    
    [UIView beginAnimations:@"fullscreen" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:.3];
    
    //move tab bar up/down
    //We don't need the logic to hide the toolbar in the ipad since 
    //the toolbar is in the nav bar
    if(!IS_IPAD) {
        CGRect tabBarFrame = documentToolbar.frame;
        int tabBarHeight = tabBarFrame.size.height;
        int offset = isFullScreen ? tabBarHeight : -1 * tabBarHeight;
        int tabBarY = tabBarFrame.origin.y + offset;
        tabBarFrame.origin.y = tabBarY;
        documentToolbar.frame = tabBarFrame;
        
        
        CGRect webViewFrame = webView.frame;
        int webViewHeight = webViewFrame.size.height+ offset;
        webViewFrame.size.height = webViewHeight;
        webView.frame = webViewFrame;
        //fade it in/out
        self.navigationController.navigationBar.alpha = isFullScreen ? 0 : 1;
        documentToolbar.alpha = isFullScreen ? 0 : 1;
        
        //resize webview to be full screen / normal
        [webView removeFromSuperview];
        [self.view addSubview:webView];
    }
    
    [self.navigationController setNavigationBarHidden:isFullScreen animated:YES];
    [UIView commitAnimations];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    NSInteger spacersCount = 0;
    
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    BOOL usingAlfresco = [[AccountManager sharedManager] isAlfrescoAccountForAccountUUID:selectedAccountUUID];
    
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:selectedAccountUUID];
    BOOL validAccount = account?YES:NO;
    
    showLikeButton = (usingAlfresco ? [[AppProperties propertyForKey:kPShowLikeButton] boolValue] : NO);
    if (showLikeButton && !isDownloaded) {
        NSString *productVersion = [repoInfo productVersion];
        showLikeButton = ([productVersion hasPrefix:@"3.5"] || [productVersion hasPrefix:@"4."]);
    }
    
    NSMutableArray *updatedItemsArray = [NSMutableArray arrayWithArray:[documentToolbar items]];
    NSString *title = nil;
    if(fileMetadata) {
        title = fileMetadata.filename;
    } else {
        title = fileName;
    }
    
    isVideo = isVideoExtension([title pathExtension]) || isMimeTypeVideo(contentMimeType);
    if(!isVideo) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        
        [tapRecognizer setDelegate:self];
        [tapRecognizer setNumberOfTapsRequired : 1];
        [webView addGestureRecognizer:tapRecognizer];
        [tapRecognizer release];
    }
    
    //For the ipad toolbar we don't have the flexible space as the first element of the toolbar items
	NSInteger actionButtonIndex = IS_IPAD?0:1;
    self.actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self 
                  action:@selector(performAction:)] autorelease];
    [updatedItemsArray insertObject:[self iconSpacer] atIndex:actionButtonIndex];
    spacersCount++;
    [updatedItemsArray insertObject:actionButton atIndex:actionButtonIndex];
    
    BOOL showCommentButton = [[AppProperties propertyForKey:kPShowCommentButton] boolValue];
    
    if(!isDownloaded) {
        UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"download.png"] 
                                                                           style:UIBarButtonItemStylePlain 
                                                                          target:self action:@selector(downloadButtonPressed)];
        [updatedItemsArray addObject:[self iconSpacer]];
        spacersCount++;
        [updatedItemsArray addObject:downloadButton];
        [downloadButton release];
    } else {
        UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash 
                                                                                     target:self action:@selector(trashButtonPressed)];
        [updatedItemsArray addObject:[self iconSpacer]];
        spacersCount++;
        [updatedItemsArray addObject:trashButton];
        [trashButton release];
    }

#ifdef TARGET_ALFRESCO
    if (isDownloaded) {
        showCommentButton = NO;
        showLikeButton = NO;
    }
#endif
    
    if (showCommentButton && usingAlfresco && !isVersionDocument)
    {
        UIImage *commentIconImage = [UIImage imageNamed:@"comments.png"];
        self.commentButton = [[[UIBarButtonItem alloc] initWithImage:commentIconImage 
                                                                          style:UIBarButtonItemStylePlain 
                                                                         target:self action:@selector(commentsButtonPressed:)] autorelease];
        [updatedItemsArray addObject:[self iconSpacer]];
        spacersCount++;
        [updatedItemsArray addObject:commentButton];
    }
    

    //Calling the like request service
    if (showLikeButton && [self cmisObjectId] && !isVersionDocument && !isDownloaded && validAccount) 
    {
        self.likeRequest = [LikeHTTPRequest getHTTPRequestForNodeRef:[NodeRef nodeRefFromCmisObjectId:self.cmisObjectId] 
                                                         accountUUID:self.fileMetadata.accountUUID
                                                            tenantID:self.fileMetadata.tenantID];
        [likeRequest setLikeDelegate:self];
        [likeRequest setTag:kLike_GET_Request];
        [likeRequest startAsynchronous];
        
        UIImage *likeChecked = [UIImage imageNamed:@"like-checked.png"];
        UIImage *likeUnchecked = [UIImage imageNamed:@"like-unchecked.png"];
        
        [self setLikeBarButton:[[[ToggleBarButtonItemDecorator alloc ] initWithOffImage:likeUnchecked onImage:likeChecked 
                                                                                 style:UIBarButtonItemStylePlain 
                                                                                target:self action:@selector(toggleLikeDocument:)]autorelease]];
        [updatedItemsArray addObject:[self iconSpacer]];
        spacersCount++;
        [updatedItemsArray addObject:[likeBarButton barButton]];
    }
    [[self documentToolbar] setItems:updatedItemsArray];
    //Finished documentToolbar customization
    
//////////////
    
    [webView setAlpha:0.0];
    [webView setScalesPageToFit:YES];
    webView.mediaPlaybackRequiresUserAction = YES;
    webView.allowsInlineMediaPlayback = YES;

	// write the file contents to the file system
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
    
    if(self.fileData) {
        [self.fileData writeToFile:path atomically:NO];
    } else if(filePath) {
        //If filepath is set, it is preferred from the filename in the temp path
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *tempPath = [SavedDocument pathToTempFile:[filePath lastPathComponent]];
        //We only use it if the file is in the temp path
        if([fileManager fileExistsAtPath:tempPath]) {
            path = filePath;
        } else {
            //Can happen when ASIHTTPRequest returns a cached file
            NSError *error = nil;
            //Ignore the error
            [fileManager removeItemAtPath:path error:nil];
            [fileManager copyItemAtPath:filePath toPath:path error:&error];
            
            if(error) {
                NSLog(@"Error copying file to temp path %@", [error description]);
            }
        }
    }
	
	// get a URL that points to the file on the filesystemw
	NSURL *url = [NSURL fileURLWithPath:path];
    
    if(!contentMimeType)
    {
        self.contentMimeType = mimeTypeForFilename([url lastPathComponent]);
    }
    
    self.contentMimeType = [self fixMimeTypeFor:contentMimeType];
    previewRequest = [[NSURLRequest requestWithURL:url] retain];
    
    /**
     * Note: UIWebView is populated in viewDidAppear
     */
    // load the document into the view
    if (self.fileData && contentMimeType)
    {
        [webView loadData:fileData MIMEType:contentMimeType textEncodingName:@"UTF-8" baseURL:url];
    }
    else if (contentMimeType)
    {
        [SavedDocument completeProtectFileAtPath:path];
        NSData *requestData = [NSData dataWithContentsOfFile:path];
        [webView loadData:requestData MIMEType:contentMimeType textEncodingName:@"UTF-8" baseURL:url];
    }
    else
    {
        [webView loadRequest:previewRequest];
    }
    
    [webView setDelegate:self];
	
	//We move the tool to the nav bar in the ipad
    if(IS_IPAD) {
        CGFloat width = 35;
        NSInteger normalItems = [documentToolbar.items count] - spacersCount;
        
        TransparentToolbar *ipadToolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, 0, normalItems*width+spacersCount*kToolbarSpacerWidth+10, 44.01)];
        [ipadToolbar setTintColor:[ThemeProperties toolbarColor]];
        [ipadToolbar setItems:[documentToolbar items]];
        [documentToolbar removeFromSuperview];
        self.documentToolbar = ipadToolbar;
        
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:ipadToolbar] autorelease];
        [ipadToolbar release];
        //Adding the height of the toolbar
        webView.frame = self.view.frame;
    }

	// we want to release this object since it may take a lot of memory space
    self.fileData = nil;
	
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self setTitle:title];
}

- (NSString *)fixMimeTypeFor:(NSString *)originalMimeType 
{
    NSDictionary *mimeTypesFix = [NSDictionary dictionaryWithObject:@"audio/mp4" forKey:@"audio/m4a"];
    
    NSString *fixedMimeType = [mimeTypesFix objectForKey:originalMimeType];
    return fixedMimeType?fixedMimeType:originalMimeType;
}

- (UIBarButtonItem *)iconSpacer
{       
    UIBarButtonItem *iconSpacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace 
                                                                                 target:nil action:nil] autorelease];
    [iconSpacer setWidth:kToolbarSpacerWidth];
    return iconSpacer;
}
    

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)replaceCommentButtonWithBadge:(NSString *)badgeTitle 
{
    // Only do this replacement if the comment button exists
    if ([self commentButton]) {
        if (![[AppProperties propertyForKey:kPShowCommentButtonBadge] boolValue] ) {
            // Dont show if the setting is not enabled
            return;
        }
        
        UIImage *commentIconImage = [UIImage imageNamed:@"comments.png"];
        NSMutableArray *updatedItemsArray = [NSMutableArray arrayWithArray:[documentToolbar items]];
        NSInteger commentIndex = [updatedItemsArray indexOfObject:self.commentButton];
        [updatedItemsArray removeObject:self.commentButton];
        self.commentButton = [BarButtonBadge barButtonWithImage:commentIconImage badgeString:badgeTitle atRight:NO toTarget:self action:@selector(commentsButtonPressed:)];
        [updatedItemsArray insertObject:self.commentButton atIndex:commentIndex];
        [documentToolbar setItems:updatedItemsArray animated:NO];
        [documentToolbar reloadInputViews];
    }
}

#pragma mark -
#pragma mark Action Selectors

- (IBAction)sendMail {
    if([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        
        NSString *mimeType = nil;
        if(self.contentMimeType)
        {
            mimeType = self.contentMimeType;
        } 
        else
        {
            mimeType = mimeTypeForFilenameWithDefault(fileName, @"application/octet-stream");
        }
        
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
        
        if(filePath) {
            //If filepath is set, it is preferred from the filename in the temp path
            path = filePath;
            //self.fileName = [filePath lastPathComponent];
        }
        [mailer addAttachmentData:[NSData dataWithContentsOfFile:path] 
                         mimeType:mimeType fileName:fileName];	
        [mailer setSubject:fileName];
        [mailer setMessageBody:NSLocalizedString(@"sendMailBodyText", 
                                                 @"Sent from my document repository using Fresh Docs, the native iPhone client for Alfresco.") 
                        isHTML:NO];
        
        [self presentModalViewController:mailer animated:YES];
        mailer.mailComposeDelegate = self;
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"noEmailSetupDialogTitle", @"Mail Setup")
                                                        message:NSLocalizedString(@"noEmailSetupDialogMessage", @"Mail is currently not setup on your device and is required to send emails")
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)addToFavorites {
	if ([SavedDocument isSaved:fileName]) {
		[SavedDocument unsave:fileName];
		[self.favoriteButton setImage:[UIImage imageNamed:@"favorite-unchecked.png"]];
	}
	else {
		[SavedDocument save:fileName];
		[self.favoriteButton setImage:[UIImage imageNamed:@"favorite-checked.png"]];
	}
}

- (IBAction)toggleLikeDocument: (id) sender
{
    
	NSLog(@"Document liked: %@", likeBarButton.toggleState? @"YES" : @"NO");
    NodeRef *nodeRef = [NodeRef nodeRefFromCmisObjectId:self.cmisObjectId];
    
    if([likeBarButton toggleState] == YES) {
        self.likeRequest = [LikeHTTPRequest postHTTPRequestForNodeRef:nodeRef 
                                                          accountUUID:self.fileMetadata.accountUUID
                                                             tenantID:self.fileMetadata.tenantID];
    } else {
        self.likeRequest = [LikeHTTPRequest deleteHTTPRequest:nodeRef 
                                                  accountUUID:self.fileMetadata.accountUUID
                                                     tenantID:self.fileMetadata.tenantID];
    }
    
    [self.likeRequest setLikeDelegate:self];
    [self.likeRequest startAsynchronous];
    [likeBarButton.barButton setEnabled:NO];
}

- (void)performAction:(id)sender {

    if(self.actionSheet.isVisible) {
        return;
    }
    
    self.actionSheet = [[[UIActionSheet alloc]
                         initWithTitle:@""
                         delegate:self 
                         cancelButtonTitle:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")
                         destructiveButtonTitle:nil 
                         otherButtonTitles: NSLocalizedString(@"documentview.action.openin", @"Open in..."),NSLocalizedString(@"documentview.action.print", @"Print"), nil] autorelease];
    if(IS_IPAD) {
        [self.actionSheet setActionSheetStyle:UIActionSheetStyleDefault];
        [self.actionSheet showFromBarButtonItem:sender  animated:YES];
    } else {
        [self.actionSheet showInView:[[self tabBarController] view]];
    }
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *buttonLabel = [actionSheet buttonTitleAtIndex:buttonIndex];
    
	if ([buttonLabel isEqualToString:NSLocalizedString(@"documentview.action.openin", @"Open in...")]) {
        [self actionButtonPressed:self.actionButton];
    } else if([buttonLabel isEqualToString:NSLocalizedString(@"documentview.action.print", @"Print")]) {
        UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
        
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = self.navigationController.title;
        
        printController.printInfo = printInfo;
        printController.printFormatter = [self.webView viewPrintFormatter];
        printController.showsPageRange = YES;
        
        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
        ^(UIPrintInteractionController *printController, BOOL completed, NSError *error)
        {
            if (!completed && error)
            {
                NSLog(@"Printing could not complete because of error: %@", error);
            }
        };
        
        if(IS_IPAD) {
            [printController presentFromBarButtonItem:self.actionButton animated:YES completionHandler:completionHandler];
        } else {
            [printController presentAnimated:YES completionHandler:completionHandler];
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
}

- (IBAction)actionButtonPressed:(UIBarButtonItem *)sender {
    if (docInteractionController == nil) {
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
        NSURL *url = [NSURL fileURLWithPath:path];
        [self setDocInteractionController:[UIDocumentInteractionController interactionControllerWithURL:url]];
        [[self docInteractionController] setDelegate:self];
        
        /**
         * Quickoffice integration
         */
        NSString *appIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"AppIdentifier"];
        NSString *partnerApplicationSecretUUID = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"QuickofficePartnerKey"];
        
        // Original document path
        NSString* documentPath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent: [url lastPathComponent]];
        
        // PartnerAppInfo dictionary
        NSMutableDictionary* partnerAppInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               documentPath, PartnerApplicationDocumentPathKey,
                                               nil];
        
        if (!isDownloaded)
        {
            // File metadata (download info only)
            [partnerAppInfo setValue:fileMetadata.downloadInfo forKey:PartnerApplicationFileMetadataKey];
        }
        
        // Annotation dictionary
        NSDictionary* annotation = [NSDictionary dictionaryWithObjectsAndKeys:
                                    partnerApplicationSecretUUID, PartnerApplicationSecretUUIDKey,
                                    partnerAppInfo, PartnerApplicationInfoKey, 
                                    appIdentifier, PartnerApplicationIdentifierKey,
                                    PartnerApplicationDocumentExtension, PartnerApplicationDocumentExtensionKey,
                                    PartnerApplicationDocumentUTI, PartnerApplicationDocumentUTIKey,
                                    nil];
        
        self.docInteractionController.annotation = annotation;
    }
    else {
        [docInteractionController dismissMenuAnimated:YES];
    }
		
    if ( ![[self docInteractionController] presentOpenInMenuFromBarButtonItem:sender animated:YES] ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"noAppsAvailableDialogTitle", @"No Applications Available")
                                                        message:NSLocalizedString(@"noAppsAvailableDialogMessage", @"There are no applications that are capable of opening this file on this device")
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}


- (void)downloadButtonPressed
{
    if ([[FileDownloadManager sharedInstance] downloadExistsForKey:fileName]) {
        UIAlertView *overwritePrompt = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.overwrite.download.prompt.title", @"")
                                                                  message:NSLocalizedString(@"documentview.overwrite.download.prompt.message", @"Yes/No Question")
                                                                 delegate:self 
                                                        cancelButtonTitle:NSLocalizedString(@"No", @"No Button Text") 
                                                         otherButtonTitles:NSLocalizedString(@"Yes", @"Yes BUtton Text"), nil] autorelease];
        
        [overwritePrompt setTag:kAlertViewOverwriteConfirmation];
        [overwritePrompt show];
    }
    else {
        [self saveFileLocally];
    }
}

- (void)saveFileLocally 
{
    NSString *filename = [[FileDownloadManager sharedInstance] setDownload:fileMetadata.downloadInfo forKey:fileName withFilePath:fileName];
    //Since the file was moved from the temp path to the save file we want to update the file path to the one in the saved documents
    self.filePath = [SavedDocument pathToSavedFile:filename];
    
    UIAlertView *saveConfirmationAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.download.confirmation.title", @"")
                                                                    message:NSLocalizedString(@"documentview.download.confirmation.message", @"The document has been saved to your device")
                                                                   delegate:nil 
                                                          cancelButtonTitle: NSLocalizedString(@"okayButtonText", @"OK") 
                                                          otherButtonTitles:nil, nil];
    [saveConfirmationAlert show];
    [saveConfirmationAlert release];
}

- (void)trashButtonPressed
{
    UIAlertView *deleteConfirmationAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.delete.confirmation.title", @"")
                                                                       message:NSLocalizedString(@"documentview.delete.confirmation.message", @"Do you want to remove this document from your device?") 
                                                                      delegate:self 
                                                             cancelButtonTitle:NSLocalizedString(@"No", @"No Button Text") 
                                                             otherButtonTitles:NSLocalizedString(@"Yes", @"Yes BUtton Text"), nil] autorelease];

    [deleteConfirmationAlert setTag:kAlertViewDeleteConfirmation];
    [deleteConfirmationAlert show];
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertViewOverwriteConfirmation:
        {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [self saveFileLocally];
            }
            break;
        }
        case kAlertViewDeleteConfirmation:
        {
            if (buttonIndex != alertView.cancelButtonIndex) {
                NSLog(@"User confirmed removal of file %@", fileName);
                [[FileDownloadManager sharedInstance] removeDownloadInfoForFilename:fileName];
            }
            break;
        }
        default:
            NSLog(@"Unknown AlertView!");
            break;
    }
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertViewDeleteConfirmation && buttonIndex != alertView.cancelButtonIndex)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark -
#pragma View Comments Button and related methods

- (IBAction)commentsButtonPressed:(id)sender
{
    self.commentButton.enabled = NO;
    BOOL useLocalComments = [[NSUserDefaults standardUserDefaults] boolForKey:@"useLocalComments"];
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:selectedAccountUUID];
    BOOL validAccount = account?YES:NO;
    
    // Use local comments only if it is downloaded and the useLocalComments user setting is turned on
    // Otherwise use alfresco repository code
    if (self.cmisObjectId && ([self.cmisObjectId length] > 0) && !(isDownloaded && useLocalComments) && validAccount) {
        NSLog(@"Comment Button Pressed, retrieving Comments from current request");
        if([commentsRequest isFinished]) {
            [self loadCommentsViewController:commentsRequest.commentsDictionary];
        } else {
            commentsRequest.tag = 0;
            [self startHUD];
        }
    } else if(fileMetadata && isDownloaded && validAccount) {
        DocumentCommentsTableViewController *viewController = [[DocumentCommentsTableViewController alloc] initWithDownloadMetadata:fileMetadata];
        NSMutableDictionary *commentDicts = [NSMutableDictionary dictionaryWithObject:fileMetadata.localComments forKey:@"items"];
        [viewController setModel:[[[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionaryWithDictionary:commentDicts]] autorelease]];
        [viewController setSelectedAccountUUID:selectedAccountUUID];
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    }
    else {
        // We Should never get here, but just in case, throw an alert
        NSLog(@"NodeRef Not Available");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"NodeRef Not Available" 
                                                            message:@"Comments are not available for this document" 
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK") 
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        [alertView release];
    }
}

- (void)loadCommentsViewController:(NSDictionary *)model {
    DocumentCommentsTableViewController *viewController = [[DocumentCommentsTableViewController alloc] initWithCMISObjectId:self.cmisObjectId];
    [viewController setModel:[[[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionaryWithDictionary:model]] autorelease]]; 
    [viewController setSelectedAccountUUID:selectedAccountUUID];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (void)commentsHttpRequestDidFinish:(id)sender
{
    NSLog(@"commentsHttpRequestDidFinish");
    CommentsHttpRequest * request = (CommentsHttpRequest *)sender;

    if(request.tag == kGetCommentsCountTag) {
        NSArray *commentsArray = [request.commentsDictionary objectForKey:@"items"];
        [self replaceCommentButtonWithBadge:[NSString stringWithFormat:@"%d", [commentsArray count]]];
         //[badge setCount:[commentsArray count]];
    } else {
        [self loadCommentsViewController:commentsRequest.commentsDictionary];
    }
    [self stopHUD];
}

-(void)commentsHttpRequestDidFail:(id)sender
{
    NSLog(@"commentsHttpRequestDidFail!");
    [self stopHUD];
}



#pragma mark -
#pragma Like/Unlike button methods and related methods

- (IBAction)likeButtonPressed:(id)sender 
{	
    NSLog(@"Like Button Pressed");
}


#pragma mark -
#pragma mark UIDocumentInteractionControllerDelegate Methods

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    self.docInteractionController = nil;
    return self;
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:kDocumentFadeInTime];
    [self.webView setAlpha:1.0];
    [UIView commitAnimations];
}

/**
 * We want to know when the document cannot be rendered
 * UIWebView throws two errors when a document cannot be previewed
 * code:100 message: "Operation could not be completed. (NSURLErrorDomain error 100.)"
 * code:102 message: "Frame load interrupted"
 *
 * Note we also get an error when loading a video, as rendering is handed off to a QuickTime plug-in
 * code:204 message: "Plug-in handled load"
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Failed to load preview: %@", [error description]);
    if([error code] == kFrameLoadCodeError) { 
        [self performSelectorOnMainThread:@selector(previewLoadFailed) withObject:nil waitUntilDone:NO];
    }
    [self.webView setAlpha:1.0];
}

- (void)previewLoadFailed {
    UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.preview.failure.title", @"")
                                                           message:NSLocalizedString(@"documentview.preview.failure.message", @"Failed to preview the document" )
                                                          delegate:nil 
                                                 cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK")
                                                 otherButtonTitles:nil, nil];
    [failureAlert show];
    [failureAlert release];
    [self.webView setAlpha:1.0];
}

#pragma mark -
#pragma mark TapDetectingWindowDelegate

- (void)userDidTapWebView:(id)tapPoint {
    //show navigation
}

#pragma mark -
#pragma mark LikeHTTPRequest Delegate
- (void)likeRequest:(LikeHTTPRequest *)request likeRatingServiceDefined:(NSString *)isDefined 
{
    NSLog(@"likeRequest:likeRatingServiceDefined:");
    
}
- (void)likeRequest:(LikeHTTPRequest *)request documentIsLiked:(NSString *)isLiked 
{
    NSLog(@"likeRequest:documentIsLiked: %@", isLiked);
    BOOL boolLiked = [isLiked boolValue];
    
    if([likeBarButton toggleState] != boolLiked) 
    {
        [likeBarButton toggleImage];
    }
    [likeBarButton.barButton setEnabled:YES];
}

- (void)likeRequest:(LikeHTTPRequest *)request likeDocumentSuccess:(NSString *)isLiked 
{
    NSLog(@"likeRequest:likeDocumentSuccess:");
    [likeBarButton.barButton setEnabled:YES];
}

- (void)likeRequest:(LikeHTTPRequest *)request unlikeDocumentSuccess:(NSString *)isUnliked
{
    NSLog(@"likeRequest:unlikeDocumentSuccess:");
    [likeBarButton.barButton setEnabled:YES];
}

- (void)likeRequest:(LikeHTTPRequest *)request failedWithError:(NSError *)theError 
{
    NSLog(@"likeRequest:failedWithError:%@", [theError description]);
    if(request.tag == kLike_GET_Request)
        return;
    
    NSString* errorMessage = nil;
    if(likeBarButton.toggleState) {
        errorMessage = NSLocalizedString(@"documentview.like.failure.message", @"Failed to like the document" );
    } else {
        errorMessage = NSLocalizedString(@"documentview.unlike.failure.message", @"Failed to unlike the document" );
    }
    UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.like.failure.title", @"")
                                                           message:errorMessage
                                                          delegate:nil 
                                                 cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK")
                                                 otherButtonTitles:nil, nil];
    [failureAlert show];
    [failureAlert release];
    
    //Toggle the button back to the previous state.
    [likeBarButton toggleImage];
    [likeBarButton.barButton setEnabled:YES];
    
    
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)startHUD
{
	if (HUD) {
		return;
	}
    
    [self setHUD:[MBProgressHUD showHUDAddedTo:self.webView animated:YES]];
    [self.HUD setRemoveFromSuperViewOnHide:YES];
    [self.HUD setTaskInProgress:YES];
    [self.HUD setMode:MBProgressHUDModeIndeterminate];
}

- (void)stopHUD
{
	if (HUD) {
		[HUD setTaskInProgress:NO];
		[HUD hide:YES];
		[HUD removeFromSuperview];
		[self setHUD:nil];
	}
}

#pragma mark - NotificationCenter methods

- (void)cancelActiveHTTPConnections 
{
    [likeRequest clearDelegatesAndCancel];
    [commentsRequest clearDelegatesAndCancel];
}

- (void) applicationWillResignActive:(NSNotification *) notification 
{
    NSLog(@"applicationWillResignActive in DocumnetViewController");
    [self cancelActiveHTTPConnections];
}

#pragma mark -
#pragma mark File system support

- (NSString*) applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
