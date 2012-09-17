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
//  FavoriteTableViewCell.m
//

#import "FavoriteTableViewCell.h"

@implementation FavoriteTableViewCell


@synthesize filename;
@synthesize details;
@synthesize serverName;
@synthesize image;
@synthesize progressBar;
@synthesize status;
@synthesize favoriteButton;

- (void)dealloc
{
	[filename release];
	[details release];
    [serverName release];
	[image release];
    [progressBar release];
    [status release];
    [favoriteButton release];
    
    [super dealloc];
}


NSString * const FavoriteTableCellIdentifier = @"FavoriteCellIdentifier";
/*
 - (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
 {
 self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
 if (self) {
 // Initialization code
 }
 return self;
 }
 
 - (void)setSelected:(BOOL)selected animated:(BOOL)animated
 {
 [super setSelected:selected animated:animated];
 
 // Configure the view for the selected state
 }
 */

@end
