//
//  IFLinkCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//
//  Based on work created by Matt Gallagher on 27/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//	For more information: http://cocoawithlove.com/2008/12/heterogeneous-cells-in.html
//

#import "IFLinkCellController.h"

#import "IFGenericTableViewController.h"

@implementation IFLinkCellController

@synthesize backgroundColor;
@synthesize updateTarget, updateAction;


//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	[model release];
	[backgroundColor release];
	
	[super dealloc];
}

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel usingControllerClass:(Class)newControllerClass inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		controllerClass = newControllerClass;
		model = [newModel retain];
		
		backgroundColor = nil;
	}
	return self;
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewController *tableViewController = (UITableViewController *)tableView.dataSource;
	IFGenericTableViewController *linkTableViewController = (IFGenericTableViewController *)[[[controllerClass alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	[linkTableViewController setModel:model];
	linkTableViewController.navigationItem.title = label;

	if (updateTarget && [updateTarget respondsToSelector:updateAction])
	{
		[updateTarget performSelector:updateAction withObject:self];
	}
	
	[tableViewController.navigationController pushViewController:linkTableViewController animated:YES];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"LinkDataCell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	
	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
	
	cell.textLabel.text = label;
	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	
    return cell;
}

@end
