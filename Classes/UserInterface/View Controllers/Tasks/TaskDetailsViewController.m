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
// TaskDetailsViewController 
//
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "TaskDetailsViewController.h"
#import "AsyncLoadingUIImageView.h"
#import "AvatarHTTPRequest.h"
#import "TaskItem.h"
#import "DateIconView.h"
#import "TaskDocumentViewCell.h"
#import "NodeThumbnailHTTPRequest.h"
#import "DocumentItem.h"
#import "ASIDownloadCache.h"

#define HEADER_HEIGHT 40.0
#define HEADER_TITLE_MARGIN 10.0
#define DOCUMENT_CELL_HEIGHT 120.0

@interface TaskDetailsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) UIView *taskDetailsHeaderView;
@property (nonatomic, retain) UILabel *taskDetailsHeaderTitle;
@property (nonatomic, retain) UILabel *taskNameLabel;
@property (nonatomic, retain) AsyncLoadingUIImageView *assigneeImageView;
@property (nonatomic, retain) DateIconView *dueDateIconView;
@property (nonatomic, retain) UIView *documentHeaderView;
@property (nonatomic, retain) UILabel *documentHeaderTitle;
@property (nonatomic, retain) UITableView *documentTable;

@end

@implementation TaskDetailsViewController

@synthesize taskNameLabel = _taskNameLabel;
@synthesize assigneeImageView = _assigneeImageView;
@synthesize documentTable = _documentTable;
@synthesize taskItem = _taskItem;
@synthesize dueDateIconView = _dateIconView;
@synthesize taskDetailsHeaderView = _taskDetailsHeaderView;
@synthesize taskDetailsHeaderTitle = _taskDetailsHeaderTitle;
@synthesize documentHeaderView = _documentHeaderView;
@synthesize documentHeaderTitle = _documentHeaderTitle;

#pragma mark - View lifecycle

- (void)dealloc
{
    [_taskNameLabel release];
    [_assigneeImageView release];
    [_documentTable release];
    [_taskItem release];
    [_dateIconView release];
    [_taskDetailsHeaderView release];
    [_taskDetailsHeaderTitle release];
    [_documentHeaderView release];
    [_documentHeaderTitle release];
    [super dealloc];
}

- (void)loadView
{
    [super loadView];
//    self.navigationItem.leftBarButtonItem = nil; // kinda hacky (by default the detailNavigationController adds it), but is sure works. And in the end, isn't that what matters?
}

// I'd rather do this in viewDidLoad, but viewDidAppear is the only place where the view frame is correct.
// See very good explanation http://stackoverflow.com/questions/6757018/why-am-i-having-to-manually-set-my-views-frame-in-viewdidload
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.view.backgroundColor = [UIColor whiteColor];

    // Task detail header
    UIView *taskDetailsHeaderView = [[UIView alloc] init];
    taskDetailsHeaderView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    self.taskDetailsHeaderView = taskDetailsHeaderView;
    [self.view addSubview:self.taskDetailsHeaderView];
    [taskDetailsHeaderView release];

    UILabel *taskDetailsHeaderTitle = [[UILabel alloc] init];
    taskDetailsHeaderTitle.backgroundColor = [UIColor clearColor];
    taskDetailsHeaderTitle.textColor = [UIColor whiteColor];
    taskDetailsHeaderTitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    taskDetailsHeaderTitle.text = @"Task details";
    self.taskDetailsHeaderTitle = taskDetailsHeaderTitle;
    [self.view addSubview:self.taskDetailsHeaderTitle];
    [taskDetailsHeaderTitle release];

    // Task name
    UILabel *taskNameLabel = [[UILabel alloc] init];
    taskNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    taskNameLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.taskNameLabel = taskNameLabel;
    [self.view addSubview:self.taskNameLabel];
    [taskNameLabel release];

    // Task assignee
    AsyncLoadingUIImageView *assigneeImageView = [[AsyncLoadingUIImageView alloc] init];
    [assigneeImageView setContentMode:UIViewContentModeScaleToFill];
    [assigneeImageView.layer setMasksToBounds:YES];
    [assigneeImageView.layer setCornerRadius:10];
    assigneeImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    assigneeImageView.layer.borderWidth = 1.0;
    self.assigneeImageView = assigneeImageView;
    [self.view addSubview:self.assigneeImageView];
    [assigneeImageView release];

    // Due date
    DateIconView *dateIconView = [[DateIconView alloc] init];
    self.dueDateIconView = dateIconView;
    [self.view addSubview:self.dueDateIconView];
    [dateIconView release];

    // Document detail header
    UIView *documentHeaderView = [[UIView alloc] init];
    documentHeaderView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    self.documentHeaderView = documentHeaderView;
    [self.view addSubview:self.documentHeaderView];
    [documentHeaderView release];

    UILabel *documentHeaderTitle = [[UILabel alloc] init];
    documentHeaderTitle.backgroundColor = [UIColor clearColor];
    documentHeaderTitle.textColor = [UIColor whiteColor];
    documentHeaderTitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    documentHeaderTitle.text = @"Documents";
    self.documentHeaderTitle = documentHeaderTitle;
    [self.view addSubview:self.documentHeaderTitle];
    [documentHeaderTitle release];

    // Document table
    UITableView *documentTableView = [[UITableView alloc] init];
    documentTableView.delegate = self;
    documentTableView.dataSource = self;
    self.documentTable = documentTableView;
    [self.view addSubview:self.documentTable];
    [documentTableView release];

    // Calculate frames of all components
    [self calculateSubViewFrames];

    // Show and load task task details
    [self showTask];
}

#pragma mark SubView creation

- (void)calculateSubViewFrames
{
    CGRect taskDetailsHeaderFrame = CGRectMake(0, 0, self.view.frame.size.width, HEADER_HEIGHT);
    self.taskDetailsHeaderView.frame = taskDetailsHeaderFrame;

    CGRect taskDetailsHeaderTitleFrame = CGRectMake(HEADER_TITLE_MARGIN, taskDetailsHeaderFrame.origin.y,
            taskDetailsHeaderFrame.size.width - HEADER_TITLE_MARGIN,  taskDetailsHeaderFrame.size.height);
    self.taskDetailsHeaderTitle.frame = taskDetailsHeaderTitleFrame;

    CGRect taskNameFrame = CGRectMake(20, taskDetailsHeaderFrame.origin.y + taskDetailsHeaderFrame.size.height + 10,
            self.view.frame.size.width / 2, 100);
    self.taskNameLabel.frame = taskNameFrame;

    CGFloat assigneeImageSize = 60;
    CGRect assigneeFrame = CGRectMake(taskNameFrame.origin.x + taskNameFrame.size.width + 20,
            taskNameFrame.origin.y + taskNameFrame.size.height/2 - assigneeImageSize/2, assigneeImageSize, assigneeImageSize);
    self.assigneeImageView.frame = assigneeFrame;

    CGRect dueDateFrame = CGRectMake(assigneeFrame.origin.x + assigneeFrame.size.width + 30,
            assigneeFrame.origin.y,  assigneeImageSize, assigneeImageSize);
    self.dueDateIconView.frame = dueDateFrame;

    // Document detail header
    CGRect documentHeaderFrame = CGRectMake(0, taskNameFrame.origin.y + taskNameFrame.size.height + 10,
            self.view.frame.size.width, taskDetailsHeaderFrame.size.height);
    self.documentHeaderView.frame = documentHeaderFrame;

    CGRect documentHeaderTitleFrame = CGRectMake(HEADER_TITLE_MARGIN, documentHeaderFrame.origin.y,
            documentHeaderFrame.size.width - HEADER_TITLE_MARGIN, documentHeaderFrame.size.height);
    self.documentHeaderTitle.frame = documentHeaderTitleFrame;

    // Document table
    CGRect documentTableFrame = CGRectMake(0, documentHeaderFrame.origin.y + documentHeaderFrame.size.height,
            self.view.frame.size.width, self.view.frame.size.height - documentHeaderFrame.origin.y - documentHeaderFrame.size.height);
    self.documentTable.frame = documentTableFrame;
}

#pragma mark Instance methods

- (void)showTask
{
    // Task name
    self.taskNameLabel.text = self.taskItem.description;

    // Set url for async loading of assignee avatar picture
    AvatarHTTPRequest *avatarHTTPRequest = [AvatarHTTPRequest
            httpRequestAvatarForUserName:self.taskItem.ownerUserName
                             accountUUID:self.taskItem.accountUUID
                                tenantID:self.taskItem.tenantId];
    avatarHTTPRequest.secondsToCache = 86400; // a day
    avatarHTTPRequest.downloadCache = [ASIDownloadCache sharedCache];
    [avatarHTTPRequest setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [self.assigneeImageView setImageWithRequest:avatarHTTPRequest];

    // Due date
    if (self.taskItem.dueDate)
    {
        self.dueDateIconView.date = self.taskItem.dueDate;
    } else
    {
        self.dueDateIconView.hidden = YES;
    }
}

#pragma mark UITableView delegate methods (document table)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.taskItem.documentItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TaskDocumentViewCell * cell = (TaskDocumentViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[TaskDocumentViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    DocumentItem *documentItem = [self.taskItem.documentItems objectAtIndex:indexPath.row];
    cell.nameLabel.text = documentItem.name;

    cell.thumbnailImageView.image = nil; // Need to set it to nil. Otherwise if cell was cached, the old image is seen for a brief moment
    NodeThumbnailHTTPRequest *request = [NodeThumbnailHTTPRequest httpRequestNodeThumbnail:documentItem.nodeRef
                                 accountUUID:self.taskItem.accountUUID tenantID:self.taskItem.tenantId];
    request.secondsToCache = 3600;
    request.downloadCache = [ASIDownloadCache sharedCache];
    [request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [cell.thumbnailImageView setImageWithRequest:request];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return DOCUMENT_CELL_HEIGHT;
}

#pragma mark Device rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self calculateSubViewFrames];
}

// When the collapse/expand functionality is used, the split view controller requests to re-layout the subviews.
// Hence, we can recalculate the subview frames by overriding this method.
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self calculateSubViewFrames];
}


@end
