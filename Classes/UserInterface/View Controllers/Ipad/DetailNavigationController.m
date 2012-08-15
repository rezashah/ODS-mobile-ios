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
//  DetailsPlaceholderViewController.m
//

#import "DetailNavigationController.h"
#import "Theme.h"
#import "ThemeProperties.h"
#import "PlaceholderViewController.h"
#import "IpadSupport.h"

@interface DetailNavigationController ()
@property (readwrite, nonatomic) UIViewController *detailViewController;
@property (retain, nonatomic) UIViewController *fullScreenModalController;
- (void)configureView;
@end

@implementation DetailNavigationController

@synthesize detailViewController = _detailViewController;
@synthesize fullScreenModalController = _fullScreenModalController;
@synthesize popoverButtonTitle;
@synthesize popoverController;
@synthesize masterPopoverBarButton;
@synthesize collapseBarButton;
@synthesize mgSplitViewController;

static BOOL isExpanded = YES;

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_detailViewController release];
    [_fullScreenModalController release];
    [popoverButtonTitle release];
    [popoverController release];
    [masterPopoverBarButton release];
    [collapseBarButton release];
    [mgSplitViewController release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Detail", @"Detail");
        self.popoverButtonTitle = NSLocalizedString(@"popover.button.title", @"Alfresco");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBrowseDocuments:) 
                                                     name:kBrowseDocumentsNotification object:nil];
    }
    return self;
}	

#pragma mark - Managing the detail item


- (void)resetViewControllerStackWithNewTopViewController:(UIViewController *)newTopViewController dismissPopover:(BOOL)dismissPopover
{
    if (self.detailViewController != newTopViewController) 
    {
        [self setViewControllers:nil animated:NO];
        [self setDetailViewController:newTopViewController];
        
        // Update the view.
        [self configureView];
    }
    
    if (dismissPopover)
    {
        [self dismissPopover];
    }
}

- (void)addViewControllerToStack:(UIViewController *)newTopViewController
{
    [self setViewControllers:nil animated:NO];
    [self setFullScreenModalController:newTopViewController];
    
    [self configureView];
    
    [self dismissPopover];
}

- (void)dismissPopover
{
    if (self.popoverController && self.popoverController.popoverVisible)
    {
        [self.popoverController dismissPopoverAnimated:YES];
    }
}

// This method should not be used!  Instead use resetViewControllerStackWithNewTopViewController:dismissPopover
- (void)setDetailViewController:(UIViewController *)newDetailViewController dismissPopover:(BOOL)dismiss
{
    [self resetViewControllerStackWithNewTopViewController:newDetailViewController dismissPopover:dismiss];
}

- (void)configureView
{
    // Update the user interface for the detail item.
    
    if (self.detailViewController) {
        NSLog(@"Detail View Controller title: %@",self.detailViewController.title);
        
        if (self.fullScreenModalController)
        {
            [self setViewControllers:[NSArray arrayWithObjects:self.detailViewController, self.fullScreenModalController, nil]];
        }
        else 
        {
            [self setViewControllers:[NSArray arrayWithObject:self.detailViewController]];
        }
        
        
        if(masterPopoverBarButton != nil && !self.mgSplitViewController.isLandscape) {
            [self.detailViewController.navigationItem setLeftBarButtonItem:masterPopoverBarButton animated:NO];
        } else {
            [self.detailViewController.navigationItem setLeftBarButtonItem:collapseBarButton animated:NO];
        }        
    }
}

#pragma mark - Split view

- (void)splitViewController:(MGSplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)newPopoverController
{
    self.masterPopoverBarButton = barButtonItem;
    self.popoverController = newPopoverController;
    //If the splitController is in lanscape mode, it means we are collapsing the splitview
    //we don't want to set the popover button but keep the expand button visible
    if(!splitController.isLandscape) {
        UIViewController *current = [self.viewControllers objectAtIndex:0];
        self.collapseBarButton = nil;
        
        barButtonItem.title = self.popoverButtonTitle;
        [current.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
        
        UINavigationController *controller = (UINavigationController *) newPopoverController.contentViewController;
        controller.navigationBarHidden = YES;
    }
    
    self.mgSplitViewController = splitController;
}

- (void)splitViewController:(MGSplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    UIViewController *current = [self.viewControllers objectAtIndex:0];
    self.masterPopoverBarButton = nil;


    NSString *leftBarButtonName = (isExpanded ? @"collapse.png" : @"expand.png");
    self.collapseBarButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:leftBarButtonName] 
                                                               style:UIBarButtonItemStylePlain
                                                              target:self action:@selector(performAction:)] autorelease];
    [current.navigationItem setLeftBarButtonItem:self.collapseBarButton animated:YES];
    self.popoverController = nil;
    
    self.mgSplitViewController = splitController;
}

- (void)splitViewController:(MGSplitViewController *)svc willChangeOrientation:(UIInterfaceOrientation)toOrientation {
    if((toOrientation == UIInterfaceOrientationPortrait || toOrientation == UIInterfaceOrientationPortraitUpsideDown) && !isExpanded) {
        isExpanded = YES;
        UIViewController *current = [self.viewControllers objectAtIndex:self.viewControllers.count - 1];
        [[[current navigationItem] leftBarButtonItem] setImage:[UIImage imageNamed:@"expand.png"]];
        [mgSplitViewController setShowsMasterInLandscape:YES];
    }
}

- (void)performAction:(id)sender {
    
    UIViewController *current = [self.viewControllers objectAtIndex:0];
    if (isExpanded) {
        [[[current navigationItem] leftBarButtonItem] setImage:[UIImage imageNamed:@"expand.png"]];
    }
    else {
        [[[current navigationItem] leftBarButtonItem] setImage:[UIImage imageNamed:@"collapse.png"]];
    }
    isExpanded = !isExpanded;
    
    //[mgSplitViewController setSplitPosition:0 animated:YES];
    //[mgSplitViewController setShowsMasterInLandscape:isExpanded];
    [mgSplitViewController toggleMasterView:nil];
}

- (void)showFullScreen {
    UIViewController *current = [self.viewControllers objectAtIndex:0];
    if (isExpanded) {
        [[[current navigationItem] leftBarButtonItem] setImage:[UIImage imageNamed:@"expand.png"]];
        isExpanded = NO;
        [mgSplitViewController toggleMasterView:nil];
    }
}

- (void)showFullScreenOnTop {
    UIViewController *current = [self.viewControllers objectAtIndex:1];
    self.collapseBarButton = [[[UIBarButtonItem alloc] initWithTitle:@"Back" 
                                                               style:UIBarButtonItemStylePlain
                                                              target:self action:@selector(performCloseAction:)] autorelease];
    [current.navigationItem setLeftBarButtonItem:collapseBarButton animated:YES];
    
    if (isExpanded == YES)
    {
        [mgSplitViewController toggleMasterView:nil];
    }
}

- (void)performCloseAction:(id)sender {
    [self setViewControllers:[NSArray arrayWithObject:self.detailViewController] animated:NO];
    self.fullScreenModalController = nil;
    [self configureView];
    
    UIViewController *current = [self.viewControllers objectAtIndex:0];
    if(mgSplitViewController.isLandscape) 
    {
        NSString *leftBarButtonName = (isExpanded ? @"collapse.png" : @"expand.png");
        self.collapseBarButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:leftBarButtonName] 
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self action:@selector(performAction:)] autorelease];
        [current.navigationItem setLeftBarButtonItem:self.collapseBarButton animated:YES];
        
        if (isExpanded == YES)
        {
            [mgSplitViewController toggleMasterView:nil];
        }
    }
    else 
    {
        self.collapseBarButton = nil;
        
        UINavigationController *controller = (UINavigationController *) self.popoverController.contentViewController;
        controller.navigationBarHidden = YES;
    }
}

#pragma mark - NotificationCenter methods

-(void)handleBrowseDocuments:(NSNotification *)notification { 
    [IpadSupport clearDetailController];
    //We should show the popover in the case the user wants to browse the documents
    if(popoverController) {
        [popoverController presentPopoverFromBarButtonItem:masterPopoverBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

@end
