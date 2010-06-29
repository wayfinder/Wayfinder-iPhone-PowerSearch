/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFFavoriteListController.h"
#import "WFFavoriteModel.h"
#import "WFTableListViewCell.h"
#import "WFDetailsViewController.h"
#import "WFCommandRouter.h"
#import "constants.h"

@interface WFFavoriteListController()
- (void) editButtonPressed;
@end

@implementation WFFavoriteListController

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        self.title = NSLocalizedString(@"Favorites", nil);
        tableEdited = NO;
        
        editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                   target:self
                                                                   action:@selector(editButtonPressed)];
        self.navigationItem.rightBarButtonItem = editButton;
        
        doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                   target:self
                                                                   action:@selector(editButtonPressed)];
        
        favorites = [WFFavoriteModel SharedFavoriteArray];
        favorites.delegate = self;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 58;
    self.tableView.clipsToBounds = YES;	
    self.tableView.backgroundColor = [UIColor WFBackgroundGray];
    self.tableView.scrollEnabled = YES;
    self.tableView.frame = CGRectMake(0,0, 320, MAIN_VIEW_HEIGHT);
}

- (void)didReceiveMemoryWarning {
    if (detailsCtrl && detailsCtrl != self.navigationController.topViewController) {
        [detailsCtrl release];
        detailsCtrl = nil;
    }
    
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Turn editing off
    if (self.tableView.editing)
        [self editButtonPressed];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return [favorites getResultsCount];
}

- (UITableViewCell *)tableView:(UITableView *)atableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath  
{
    static NSString *MyIdentifier = @"MyIdentifierList";
    WFTableListViewCell *cell = (WFTableListViewCell *)[atableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[[WFTableListViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
    }
    
    [cell setCell:[favorites resultAtIndex:indexPath.row]];
    cell.labelIndex.text = [NSString stringWithFormat:@"%d", indexPath.row+1];
    
    return cell;
}

- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [atableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!detailsCtrl) {
        detailsCtrl = [[WFDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    
    // Set this every time just in case the same result model was used in map view
    [detailsCtrl setDetailSource:favorites];
    
    [detailsCtrl showDetailsForItem:[favorites resultAtIndex:indexPath.row]];
    
    if (detailsCtrl != [self.navigationController topViewController])
        [self.navigationController pushViewController:detailsCtrl animated:YES];
}

- (void) tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // User has clicked delete
    [favorites removeFavoriteAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    // To update results on map.
    tableEdited = YES;
}

- (void) tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
       toIndexPath:(NSIndexPath *)toIndexPath
{
    [favorites moveFavoriteAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
    tableEdited = YES;
}

- (BOOL) tableView:(UITableView *)tableView
canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void) editButtonPressed
{
    if (self.tableView.editing) {
        [self setEditing:NO animated:YES];
        [self.navigationItem setRightBarButtonItem:editButton animated:YES];
        [self.tableView reloadData];
        if (tableEdited) {
            [[WFCommandRouter SharedCommandRouter] clearResultsOnMap];
            [[WFCommandRouter SharedCommandRouter] showVisibleItemsOnMap];
        }
    }
    else {
        [self setEditing:YES animated:YES];
        [self.navigationItem setRightBarButtonItem:doneButton animated:YES];
    }
}

// WFFavoriteModelDelegate methods
- (void) operationFailedWithError:(NSError *)anError
{
    NSLog(@"Detail download failed");
}

- (void) favoriteListUpdated:(WFFavoriteModel *)model
{
    if (!self.tableView.editing)
        [self.tableView reloadData];
}

- (void) detailsReadyForItem:(NSDictionary *)item
{
    // Show details view
}

@end
