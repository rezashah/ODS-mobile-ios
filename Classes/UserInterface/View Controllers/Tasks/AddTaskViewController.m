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
//  AddTaskViewController.m
//

#import "AddTaskViewController.h"
#import "Theme.h"
#import "DocumentPickerViewController.h"
#import "DocumentPickerSelection.h"
#import "DatePickerViewController.h"
#import "PeoplePickerViewController.h"
#import "TaskManager.h"
#import "TaskAttachmentsViewController.h"
#import "TaskAssigneesViewController.h"
#import "ASIHTTPRequest.h"
#import "Utility.h"
#import "DocumentItem.h"
#import "Kal.h"
#import "AccountManager.h"
#import "NSNotificationCenter+CustomNotification.h"

@interface AddTaskViewController () <ASIHTTPRequestDelegate, DocumentPickerViewControllerDelegate, DatePickerDelegate, PeoplePickerDelegate, MBProgressHUDDelegate>

@property (nonatomic, retain) NSDate *dueDate;
@property (nonatomic, retain) NSMutableArray *assignees;
@property (nonatomic, retain) NSMutableArray *attachments;
@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic) AlfrescoWorkflowType workflowType;

@property (nonatomic, retain) DocumentPickerViewController *documentPickerViewController;

// View
@property (nonatomic, retain) MBProgressHUD *progressHud;
@property (nonatomic, retain) UITextField *titleField;
@property (nonatomic, retain) UISegmentedControl *priorityControl;
@property (nonatomic, retain) UISwitch *emailSwitch;
@property (nonatomic, retain) UIStepper *approvalPercentageStepper;

@property (nonatomic, retain) UIPopoverController *datePopoverController;
@property (nonatomic, retain) KalViewController *kal;

@property (nonatomic, retain) NSArray *taskTypeFieldGroups;
@property (nonatomic, assign) NSInteger stepperSection;
@property (nonatomic, assign) NSInteger stepperRow;

- (void)checkEnableDoneButton;

@end

@implementation AddTaskViewController

BOOL shouldSetFirstResponderOnAppear;

@synthesize addTaskDelegate = _addTaskDelegate;
@synthesize defaultText = _defaultText;
@synthesize documentPickerViewController = _documentPickerViewController;
@synthesize dueDate = _dueDate;
@synthesize assignees = _assignees;
@synthesize attachments = _attachments;

@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;
@synthesize workflowType = _workflowType;
@synthesize progressHud = _progressHud;
@synthesize priorityControl = _priorityControl;
@synthesize emailSwitch = _emailSwitch;
@synthesize approvalPercentageStepper = _approvalPercentageStepper;
@synthesize titleField = _titleField;

@synthesize datePopoverController = _datePopoverController;
@synthesize kal = _kal;

@synthesize taskTypeFieldGroups = _taskTypeFieldGroups;
@synthesize stepperSection = _stepperSection;
@synthesize stepperRow = _stepperRow;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.datePopoverController)
    {
        [self.datePopoverController dismissPopoverAnimated:NO];
    }
    
    [_defaultText release];
    [_documentPickerViewController release];
    [_dueDate release];
    [_assignees release];
    [_attachments release];
    [_accountUuid release];
    [_tenantID release];
    [_progressHud release];
    [_priorityControl release];
    [_emailSwitch release];
    [_approvalPercentageStepper release];
    [_titleField release];
    [_datePopoverController release];
    [_kal release];
    [_taskTypeFieldGroups release];
    
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style account:(NSString *)uuid tenantID:(NSString *)tenantID 
           workflowType:(AlfrescoWorkflowType)workflowType attachment:(RepositoryItem *)attachment
{
    self = [self initWithStyle:style account:uuid tenantID:tenantID workflowType:workflowType];
    if (self)
    {
        self.attachments = [NSMutableArray arrayWithObject:attachment];
        shouldSetFirstResponderOnAppear = NO;
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style account:(NSString *)uuid tenantID:(NSString *)tenantID workflowType:(AlfrescoWorkflowType)workflowType
{
    self = [super initWithStyle:style];
    if (self) 
    {
        self.accountUuid = uuid;
        self.tenantID = tenantID;
        self.workflowType = workflowType;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [Theme setThemeForUITableViewController:self];
    self.navigationItem.title = NSLocalizedString(@"task.create.title", nil);
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancelButtonTapped:)] autorelease]];
    
    UIBarButtonItem *createButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(createTaskButtonTapped:)] autorelease];
    [createButton setEnabled:NO];
    [createButton setTitle:NSLocalizedString(@"task.create.button", nil)];
    styleButtonAsDefaultAction(createButton);
    [self.navigationItem setRightBarButtonItem:createButton];
    
    self.taskTypeFieldGroups = [self createTaskTypeFieldsArray];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSessionClearedNotification:) name:kNotificationSessionCleared object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // When navigation controller is popped to this controller, reload the data to reflect any changes
    [self.tableView reloadData];
    
    [self checkEnableDoneButton];
    
    if (self.titleField.text.length == 0)
    {
        shouldSetFirstResponderOnAppear = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (shouldSetFirstResponderOnAppear)
    {
        shouldSetFirstResponderOnAppear = NO;
        [self.titleField becomeFirstResponder];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)createTaskButtonTapped:(id)sender
{
    if (self.titleField.text.length < 1)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"task.create.notitle.message", nil) , NSLocalizedString(@"task.create.notitle.title", nil));
        return;
    }
    
    if (self.assignees.count == 0)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"task.create.noassignees.message", nil) , NSLocalizedString(@"task.create.noassignees.title", nil));
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"task.create.creating", nil);
    self.progressHud = hud;
    [self.view resignFirstResponder];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long) NULL), ^(void)
    {
        TaskItem *task = [[[TaskItem alloc] init] autorelease];
        task.title = self.titleField.text;
        task.workflowType = self.workflowType;
        task.dueDate = self.dueDate;
        task.priorityInt = self.priorityControl.selectedSegmentIndex + 1;
        task.emailNotification = self.emailSwitch.isOn;
        
        if (self.attachments)
        {
            NSMutableArray *documentItems = [NSMutableArray arrayWithCapacity:self.attachments.count];
            for (RepositoryItem *repositoryItem in self.attachments)
            {
                DocumentItem *documentItem = [[DocumentItem alloc] initWithRepositoryItem:repositoryItem];
                [documentItems addObject:documentItem];
                [documentItem release];
            }
            task.documentItems = documentItems;
        }

        NSArray *assigneeArray = [NSArray arrayWithArray:self.assignees];
        
        if (self.workflowType == AlfrescoWorkflowTypeReview)
        {
            double approvalValue = self.approvalPercentageStepper.value;
            task.approvalPercentage = (approvalValue / self.assignees.count) * 100;
        }
        
        [[TaskManager sharedManager] startTaskCreateRequestForTask:task assignees:assigneeArray 
                                                       accountUUID:self.accountUuid tenantID:self.tenantID delegate:self];
    });
}

- (void)cancelButtonTapped:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (NSArray *)createTaskTypeFieldsArray
{
    NSMutableArray *fieldGroups = [NSMutableArray array];
    
    // Title and Due Date always group 1
    [fieldGroups addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:AddTaskRowTypeTitle], [NSNumber numberWithInt:AddTaskRowTypeDueDate], nil]];
    
    // Group 2 only had the approvers field for "Review & Approve" type
    if (self.workflowType == AlfrescoWorkflowTypeReview)
    {
        [fieldGroups addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:AddTaskRowTypeAssignees], [NSNumber numberWithInt:AddTaskRowTypeApprovers], [NSNumber numberWithInt:AddTaskRowTypeAttachments], nil]];
        self.stepperSection = 1;
        self.stepperRow = 1;
    }
    else
    {
        [fieldGroups addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:AddTaskRowTypeAssignees], [NSNumber numberWithInt:AddTaskRowTypeAttachments], nil]];
    }
    
    // Group 3 is common to both types
    [fieldGroups addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:AddTaskRowTypePriority], [NSNumber numberWithInt:AddTaskRowTypeEmailNotification], nil]];
    
    return [NSArray arrayWithArray:fieldGroups];
}

#pragma mark ASIHttpRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
    self.progressHud.labelText = NSLocalizedString(@"task.create.created", nil);
    self.progressHud.delegate = self;
    [self.progressHud hide:YES afterDelay:0.5];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    stopProgressHUD(self.progressHud);
    displayErrorMessageWithTitle(request.error.localizedDescription, NSLocalizedString(@"task.create.error", nil));
}

#pragma mark MBprogressHud delegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    if (self.addTaskDelegate)
    {
        AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.accountUuid];
        BOOL userInAssigneeList = NO;
        for (Person *person in self.assignees) {
            if ([account.username isEqualToString:person.userName])
            {
                userInAssigneeList = YES;
                break;
            }
        }
        
        if (userInAssigneeList)
        {
            [self.addTaskDelegate taskAddedForLoggedInUser];
        }
    }
    
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.taskTypeFieldGroups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.taskTypeFieldGroups objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch ([[[self.taskTypeFieldGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] integerValue])
    {
        case AddTaskRowTypeTitle:
        {
            cell.textLabel.text = NSLocalizedString(@"task.create.taskTitle", nil);
            if (!self.titleField)
            {
                UITextField *titleField = [[UITextField alloc] init];
                
                if (self.defaultText)
                {
                    titleField.text = self.defaultText;
                }
                
                titleField.placeholder = NSLocalizedString(@"task.create.taskTitle.placeholder", nil);
                titleField.autocorrectionType = UITextAutocorrectionTypeNo;
                titleField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
                titleField.adjustsFontSizeToFitWidth = YES;
                titleField.tag = 101;

                self.titleField = titleField;
                [self.titleField addTarget:self action:@selector(titleFieldChanged) forControlEvents:UIControlEventEditingChanged];
                [titleField release];
                
                shouldSetFirstResponderOnAppear = YES;
            }
            
            if (IS_IPAD)
            {
                self.titleField.frame = CGRectMake(150, 12, 300, 30);
            }
            else if (self.tableView.frame.size.width > 400)
            {
                self.titleField.frame = CGRectMake(150, 12, 280, 30);
            }
            else
            {
                self.titleField.frame = CGRectMake(100, 12, 205, 30);
            }
            
            [cell addSubview:self.titleField];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }

        case AddTaskRowTypeDueDate:
        {
            cell.textLabel.text = NSLocalizedString(@"task.create.duedate", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (self.dueDate)
            {
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                df.dateStyle = NSDateFormatterMediumStyle;
                cell.detailTextLabel.text = [df stringFromDate:self.dueDate];
                [df release];
            }
            else
            {
                cell.detailTextLabel.text = NSLocalizedString(@"task.create.duedate.placeholder", nil);
            }
            break;
        }

        case AddTaskRowTypeAssignees:
        {
            if (self.workflowType == AlfrescoWorkflowTypeTodo)
            {
                cell.textLabel.text = NSLocalizedString(@"task.create.assignee", nil);
            }
            else 
            {
                cell.textLabel.text = NSLocalizedString(@"task.create.assignees", nil);
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (self.assignees != nil && self.assignees.count > 0)
            {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d %@", self.assignees.count,
                                             (self.assignees.count > 1) ? [NSLocalizedString(@"task.create.assignees", nil) lowercaseString]
                                                                      : [NSLocalizedString(@"task.create.assignee", nil) lowercaseString]];
            }
            else
            {
                cell.detailTextLabel.text = NSLocalizedString(@"task.create.assignee.placeholder", nil);
            }
            break;
        }

        case AddTaskRowTypeAttachments:
        {
            cell.textLabel.text = NSLocalizedString(@"task.create.attachments", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (self.attachments != nil && self.attachments.count > 0)
            {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d %@", self.attachments.count,
                          (self.attachments.count > 1) ? [NSLocalizedString(@"task.create.attachments", nil) lowercaseString]
                                                       : [NSLocalizedString(@"task.create.attachment", nil) lowercaseString]];
            }
            else
            {
                cell.detailTextLabel.text = NSLocalizedString(@"task.create.attachments.placeholder", nil);
            }
            break;
        }

        case AddTaskRowTypePriority:
        {
            cell.textLabel.text = NSLocalizedString(@"task.create.priority", nil);
            NSArray *itemArray = [NSArray arrayWithObjects:NSLocalizedString(@"task.create.priority.high", nil),
                                                           NSLocalizedString(@"task.create.priority.medium", nil),
                                                           NSLocalizedString(@"task.create.priority.low", nil), nil];
            if (!self.priorityControl)
            {
                UISegmentedControl *priorityControl = [[UISegmentedControl alloc] initWithItems:itemArray];
                priorityControl.segmentedControlStyle = UISegmentedControlStylePlain;
                priorityControl.selectedSegmentIndex = 1;
                
                NSDictionary *attributes = [NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:15.0f] forKey:UITextAttributeFont];
                [priorityControl setTitleTextAttributes:attributes forState:UIControlStateNormal];

                self.priorityControl = priorityControl;
                [priorityControl release];
            }
            
            if (IS_IPAD)
            {
                self.priorityControl.frame = CGRectMake(248, 7, 250, 30);
            }
            else if (self.tableView.frame.size.width > 400)
            {
                self.priorityControl.frame = CGRectMake(215, 7, 250, 30);
            }
            else
            {
                self.priorityControl.frame = CGRectMake(100, 6, 205, 30);
                [self.priorityControl setWidth:85.0 forSegmentAtIndex:1];
            }
            
            [cell addSubview:self.priorityControl];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }

        case AddTaskRowTypeEmailNotification:
        {
            cell.textLabel.text = NSLocalizedString(@"task.create.emailnotification", nil);
            
            if (!self.emailSwitch)
            {
                UISwitch *emailSwitch = [[UISwitch alloc] init];
                self.emailSwitch = emailSwitch;
                [emailSwitch release];
            }
            
            if (IS_IPAD)
            {
                self.emailSwitch.frame = CGRectMake(420, 7, 40, 30);
            }
            else if (self.tableView.frame.size.width > 400)
            {
                self.emailSwitch.frame = CGRectMake(386, 6, 40, 30);
            }
            else
            {
                self.emailSwitch.frame = CGRectMake(227, 6, 40, 30);
            }
            
            [self.emailSwitch setOn:YES];
            [cell addSubview:self.emailSwitch];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }

        case AddTaskRowTypeApprovers:
        {
            int numberApprovers = 1;
            if (self.assignees.count > 0)
            {
                numberApprovers = self.approvalPercentageStepper.value;
            }
            
            if (numberApprovers == 0)
            {
                numberApprovers = 1;
            }
            else if (numberApprovers > self.assignees.count)
            {
                numberApprovers = self.assignees.count;
            }
            
            if (self.assignees.count == 0)
            {
                cell.textLabel.text = NSLocalizedString(@"task.create.approvers", nil);
            }
            else if (self.assignees.count == 1)
            {
                cell.textLabel.text = [NSString stringWithFormat:@"%i of %i %@", numberApprovers, self.assignees.count, 
                                       NSLocalizedString(@"task.create.approver", nil)];
            }
            else
            {
                cell.textLabel.text = [NSString stringWithFormat:@"%i of %i %@", numberApprovers, self.assignees.count, 
                                       NSLocalizedString(@"task.create.approvers", nil)];
            }
            
            if (!self.approvalPercentageStepper)
            {
                UIStepper *approvalStepper = [[UIStepper alloc] init];
                approvalStepper.enabled = NO;
                self.approvalPercentageStepper = approvalStepper;
                [self.approvalPercentageStepper addTarget:self action:@selector(stepperPressed) forControlEvents:UIControlEventValueChanged];
                [approvalStepper release];
            }
            
            if (IS_IPAD)
            {
                self.approvalPercentageStepper.frame = CGRectMake(400, 7, 40, 30);
            }
            else if (self.tableView.frame.size.width > 400)
            {
                self.approvalPercentageStepper.frame = CGRectMake(368, 6, 40, 30);
            }
            else
            {
                self.approvalPercentageStepper.frame = CGRectMake(207, 6, 40, 30);
            }
            
            if (self.assignees.count > 0)
            {
                self.approvalPercentageStepper.enabled = YES;
                self.approvalPercentageStepper.minimumValue = 1;
                self.approvalPercentageStepper.maximumValue = self.assignees.count;
            }
            else 
            {
                self.approvalPercentageStepper.minimumValue = 0;
                self.approvalPercentageStepper.maximumValue = 0;
                self.approvalPercentageStepper.enabled = NO;
            }
            
            [cell addSubview:self.approvalPercentageStepper];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }

        default:
            break;
    }

    return cell;
}

- (void) titleFieldChanged
{
    [self checkEnableDoneButton];
}

- (void) stepperPressed
{
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.stepperRow inSection:self.stepperSection]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([[[self.taskTypeFieldGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] integerValue])
    {
        case AddTaskRowTypeDueDate:
        {
            [self.view endEditing:YES];
            [self showDatePicker:[self.tableView cellForRowAtIndexPath:indexPath]];
            break;
        }
            
        case AddTaskRowTypeAssignees:
        {
            if (self.workflowType == AlfrescoWorkflowTypeTodo || self.assignees == nil || self.assignees.count == 0)
            {
                PeoplePickerViewController *peoplePicker = [[PeoplePickerViewController alloc] initWithAccount:self.accountUuid tenantID:self.tenantID];
                peoplePicker.delegate = self;
                peoplePicker.selection = self.assignees;
                if (self.workflowType == AlfrescoWorkflowTypeTodo)
                {
                    peoplePicker.isMultipleSelection = NO;
                }
                else
                {
                    peoplePicker.isMultipleSelection = YES;
                }
                [self.navigationController pushViewController:peoplePicker animated:YES];
                [peoplePicker release];
            }
            else
            {
                TaskAssigneesViewController *taskAssigneesViewController = [[TaskAssigneesViewController alloc] initWithAccount:self.accountUuid tenantID:self.tenantID];
                taskAssigneesViewController.assignees = self.assignees;
                if (self.workflowType == AlfrescoWorkflowTypeTodo)
                {
                    taskAssigneesViewController.isMultipleSelection = NO;
                }
                else
                {
                    taskAssigneesViewController.isMultipleSelection = YES;
                }
                [self.navigationController pushViewController:taskAssigneesViewController animated:YES];
                [taskAssigneesViewController release];
            }
            break;
        }
        
        case AddTaskRowTypeAttachments:
        {
            // Instantiate document picker if it doesn't exist yet.
            if (!self.documentPickerViewController)
            {
                DocumentPickerViewController *documentPicker = [DocumentPickerViewController documentPickerForAccount:self.accountUuid tenantId:self.tenantID];
                documentPicker.selection.selectiontextPrefix = NSLocalizedString(@"document.picker.selection.button.attach", nil);
                documentPicker.delegate = self;
                
                self.documentPickerViewController = documentPicker;
            }
            else
            {
                // We need to make sure that the picker also shows already selected items as being selected.
                // But in the meantime, some could have been deleted and the selection is out of sync.
                // So here we clear it first, and add all the current attachments.
                [self.documentPickerViewController.selection clearAll];
                [self.documentPickerViewController.selection addDocuments:self.attachments];
            }
            
            // Show document picker directly if no attachment are already chosen
            if (self.attachments == nil || self.attachments.count == 0)
            {
                [self.documentPickerViewController reopenAtLastLocationWithNavigationController:self.navigationController];
            }
            else // Show the attachment overview controller otherwise
            {
                TaskAttachmentsViewController *taskAttachmentsViewController = [[TaskAttachmentsViewController alloc] init];
                taskAttachmentsViewController.attachments = self.attachments;
                taskAttachmentsViewController.documentPickerViewController = self.documentPickerViewController;
                [self.navigationController pushViewController:taskAttachmentsViewController animated:YES];
                [taskAttachmentsViewController release];
            }
            break;
        }
            
        default:
            break;
    }
}


- (void)showDatePicker:(UITableViewCell *)cell
{
    if (self.dueDate)
    {
        self.kal = [[[KalViewController alloc] initWithSelectedDate:self.dueDate] autorelease];
    }
    else 
    {
        self.kal = [[[KalViewController alloc] init] autorelease];
    }
    self.kal.title = NSLocalizedString(@"date.picker.title", nil);
    self.kal.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"date.picker.today", nil) 
                                                                              style:UIBarButtonItemStyleBordered 
                                                                             target:self 
                                                                             action:@selector(showAndSelectToday)] autorelease];
    
    self.kal.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self action:@selector(pickerDone:)] autorelease];
    
    if (IS_IPAD)
    {
    
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.kal];
        //resize the popover view shown
        //in the current view to the view's size
        self.kal.contentSizeForViewInPopover = CGSizeMake(320, 310);
        
        //create a popover controller
        self.datePopoverController = [[[UIPopoverController alloc] initWithContentViewController:navController] autorelease];
        [navController release];
        CGRect popoverRect = [self.view convertRect:[cell frame] fromView:self.tableView];
        
        popoverRect.size.width = MIN(popoverRect.size.width, 100) ; 
        popoverRect.origin.x  = popoverRect.origin.x; 
        
        [self.datePopoverController presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else 
    {
        [self.navigationController pushViewController:self.kal animated:YES];
    }
}

- (void)showAndSelectToday
{
    [self.kal showAndSelectDate:[NSDate date]];
}

- (void)pickerDone:(id)sender
{
    if (self.kal != nil)
    {
        self.dueDate = self.kal.selectedDate;
        self.kal = nil;
        [self.tableView reloadData];
        
        if (!IS_IPAD)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    
    if (self.datePopoverController)
    {
        [self.datePopoverController dismissPopoverAnimated:YES];
        self.datePopoverController = nil;
    }  
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.datePopoverController)
    {
        [self.datePopoverController dismissPopoverAnimated:YES];
        self.datePopoverController = nil;
    }
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}

#pragma mark - DatePicker delegate

- (void)datePicked:(NSDate *)date
{
    self.dueDate = date;
}

#pragma mark - PeoplePicker delegate

- (void)personsPicked:(NSArray *)persons
{
    self.assignees = [NSMutableArray arrayWithArray:persons];
}

#pragma mark - Document picker delegate

- (void)pickingFinished:(DocumentPickerSelection *)selection
{
    if (selection.selectedDocuments.count > 0)
    {
        if (!self.attachments)
        {
            self.attachments = [NSMutableArray arrayWithCapacity:selection.selectedDocuments.count];
        }

        // Selection object will always contain ALL the selected documents, not just the one who were newly picked
        [self.attachments removeAllObjects];
        [self.attachments addObjectsFromArray:selection.selectedDocuments];
    }
}

#pragma mark - Done buttun enable check

- (void)checkEnableDoneButton
{
    if (self.assignees.count > 0 && self.titleField.text.length >= 1)
    {
        [[self.navigationItem rightBarButtonItem] setEnabled:YES];
    }
    else
    {
        [[self.navigationItem rightBarButtonItem] setEnabled:NO];
    }
}

#pragma mark - Session Cleared Notification handler

- (void)handleSessionClearedNotification:(NSNotification *)notification
{
    NSString *accountUUID = notification.userInfo[@"accountUUID"];
    if (accountUUID == self.accountUuid)
    {
        [self dismissViewControllerAnimated:YES completion:^(void) {
            displayWarningMessageWithTitle(NSLocalizedString(@"docpreview.accountInactive.title", @"Account Inactive"), NSLocalizedString(@"task.create.error", @"Task creation failed"));
        }];
    }
}

@end
