/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFResultListController.h"
#import "WFTableListViewCell.h"
#import "WFDetailsViewController.h"
#import "WFCommandRouter.h"
#import "WFPropellerView.h"
#import "WFNoResultsView.h"
#import "constants.h"


@implementation WFResultListController

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    [self setContentType:Results];
    
    propellerView = [[WFPropellerView alloc] initWithFrame:CGRectMake(0, 0, 320, MAIN_VIEW_HEIGHT)];
    [propellerView setLabelText:NSLocalizedString(@"Searching", @"Searching")];
    propellerView.hidden = YES;
    
    noResultsView = [[WFNoResultsView alloc] initWithFrame:CGRectMake(0, 0, 320, MAIN_VIEW_HEIGHT)];
    noResultsView.hidden = YES;
    
    [self.view addSubview:propellerView];
    [self.view addSubview:noResultsView];
    
    [[WFCommandRouter SharedCommandRouter] addAboutButtonTo:self.navigationItem];
}

- (void)didReceiveMemoryWarning {
    if (detailsCtrl && detailsCtrl != self.navigationController.topViewController) {
        [detailsCtrl release];
        detailsCtrl = nil;
    }

    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}


- (void)dealloc {
    [propellerView release];
    [noResultsView release];
    [detailsCtrl release];
    [super dealloc];
}

- (void)setResultModel:(WFResultsModel *)model
{
    resultModel = model;
    [resultModel setDelegate:self];
}

- (void)setNavigationBarType:(navBarType)barType
{
    if (textSearchType == barType) {
        // Create text search bar to the nav bar
        // TODO
    }
    else {
        // Just use default navigation bar
    }
}

- (void)showResultsForCategory:(NSDictionary *)categoryDict
{
    NSIndexPath *beginning = [NSIndexPath indexPathForRow:0 inSection:0];
    if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:beginning
         atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    // With categories we should say 'Loading'
    [propellerView setLabelText:NSLocalizedString(@"Loading", @"Loading")];
    propellerView.hidden = NO;
    noResultsView.hidden = YES;
    self.tableView.userInteractionEnabled = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.title = [categoryDict objectForKey:@"name"];
    [resultModel clearResults];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [resultModel searchWithCategory:[categoryDict objectForKey:@"cat_id"]];
}

- (void)showResultsForString:(NSString *)queryString
{
    NSIndexPath *beginning = [NSIndexPath indexPathForRow:0 inSection:0];
    if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:beginning
         atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    [propellerView setLabelText:NSLocalizedString(@"Searching", @"Searching")];
    propellerView.hidden = NO;
    noResultsView.hidden = YES;
    self.tableView.userInteractionEnabled = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.title = queryString;
    [resultModel clearResults];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [resultModel searchWithString:queryString];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // User could have cancelled search so hide propeller
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [atableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row >= [resultModel getResultsCount]) {
        // Set the propeller rolling in the cell
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        NSIndexPath *path = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        [[(WFTableListViewCell *)[self.tableView cellForRowAtIndexPath:path] activityView] startAnimating];
        // Need to fetch more results
        [resultModel showMoreResults];
        //[[WFCommandRouter SharedCommandRouter] showMoreResultsOnMap];
        //[mapView showMoreResults];
    }
    else {
        //[self searchDetailsFor:[resultModel resultAtIndex:selected] animateTransition:YES];
        if (!detailsCtrl) {
            detailsCtrl = [[WFDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        }
        
        // Set this every time just in case the same result model was used in map view
        [detailsCtrl setDetailSource:resultModel];
        
        [detailsCtrl showDetailsForItem:[resultModel resultAtIndex:indexPath.row]];
        
        if (detailsCtrl != [self.navigationController topViewController])
            [self.navigationController pushViewController:detailsCtrl animated:YES];
    }
}

// WFResultModelDelegate methods

- (void) operationFailedWithError:(NSError *)anError
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void) didReceiveResultsForModel:(WFResultsModel *)model newSearch:(BOOL)newSearch
{
    // Update badge if it's visible
#ifdef SHOW_RESULT_AMOUNT_IN_BADGE
    if (nil != self.navigationController.tabBarItem.badgeValue)
        self.navigationController.tabBarItem.badgeValue =
        [NSString stringWithFormat:@"%d", [resultModel getResultsCount]];
#endif
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if ([model getResultsCount] > 0) {
        // Hide propeller
        propellerView.hidden = YES;
        self.tableView.userInteractionEnabled = YES;
        self.tableView.showsVerticalScrollIndicator = YES;
        [self.tableView flashScrollIndicators];
        
        [self.tableView reloadData];
        // Only zoom to closest results on map if this was new search
        if (newSearch) {
            // Clear old results from map and zoom to 5 nearest
            [[WFCommandRouter SharedCommandRouter] clearResultsOnMap];
            [[WFCommandRouter SharedCommandRouter] zoomMapToNearestResults];
        }
        else {
            [[WFCommandRouter SharedCommandRouter] showMoreResultsOnMap];
            [[WFCommandRouter SharedCommandRouter] showVisibleItemsOnMap];
        }
    }
    else {
        // Show no results found note
        noResultsView.hidden = NO;
    }
}

- (void) resultsCleared
{
#ifdef SHOW_RESULT_AMOUNT_IN_BADGE
    // Update badge if it's visible
    if (nil != self.navigationController.tabBarItem.badgeValue)
        self.navigationController.tabBarItem.badgeValue =
        [NSString stringWithFormat:@"%d", [resultModel getResultsCount]];
#endif
}

/*- (void)viewDidAppear:(BOOL)animated
{
    // Maybe save memory and release detail view?
}*/

@end
