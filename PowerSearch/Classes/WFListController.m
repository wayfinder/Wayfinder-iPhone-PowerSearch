/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "constants.h"
#import "WFListController.h"
#import "WFTableListViewCell.h"
#import "WFTableCategoryViewCell.h"
#import "WFResultsModel.h"
#import "WFCategoryModel.h"


#define RESULTS_ROW_HEIGHT 58
#define CATEGORY_ROW_HEIGHT 45

@implementation WFListController

@synthesize /*resultModel,*/ selectedCellIndex;
@synthesize category;

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.rowHeight = RESULTS_ROW_HEIGHT;
        self.tableView.clipsToBounds = YES;	
        self.tableView.backgroundColor = [UIColor WFBackgroundGray];
        self.tableView.scrollEnabled = YES;
        self.tableView.frame = CGRectMake(0,0, 320, MAIN_VIEW_HEIGHT);
        
        selectedCellIndex = nil;
        self.category = [WFCategoryModel SharedCategoryArray];
    }
    return self;
}

- (int) getResultsCount
{
    return [resultModel getResultsCount];
}

- (withContent) getContentType 
{
    return contentType;
}

- (void)setCellSize
{
    if (contentType == Results)
        self.tableView.rowHeight = RESULTS_ROW_HEIGHT;
    else if (contentType == Category)
        self.tableView.rowHeight = CATEGORY_ROW_HEIGHT;
}

// We have to do this in order to have correct cell heights
// trough different transitions.
- (void)viewDidLoad
{
    [self setCellSize];
}

- (void) setContentType:(withContent) type
{
    switch (type) {
        case Results:
            break;
        case Category:
            self.title = NSLocalizedString(@"Categories", @"Category field placeholder");
            break;
        default:
            NSLog(@"Invelid type set in WFListController: setContentType");
            return;
            break;
    }
    contentType = type;
    [self setCellSize];
}

- (void) resetContents:(BOOL)reset
{
    if (selectedCellIndex != nil)
    {
        [self.tableView deselectRowAtIndexPath:selectedCellIndex animated:YES];
        self.selectedCellIndex = nil;
    }
    [self.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}



- (void)dealloc 
{
    [selectedCellIndex release];
	[super dealloc];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (contentType == Results)
        return RESULTS_ROW_HEIGHT;
    else if (contentType == Category)
        return CATEGORY_ROW_HEIGHT;
    else
        return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView 
{
	return 1;
}



- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section 
{
    if (contentType == Results) {
        if ([resultModel hasMoreResults])
            return (NSInteger)[resultModel getResultsCount] + 1;

        return (NSInteger)[resultModel getResultsCount];
    }
    else
        return [category getCategoriesCount];
}


- (UITableViewCell *)tableView:(UITableView *)atableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath  
{		
    if (contentType == Results) {
        static NSString *MyIdentifier = @"MyIdentifierList";   
        WFTableListViewCell *cell = (WFTableListViewCell *)[atableView dequeueReusableCellWithIdentifier:MyIdentifier];

        if (cell == nil)
        {
            cell = [[[WFTableListViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
        }
        
        if (indexPath.row >= [resultModel getResultsCount]) {
            // Create "Show more results button here
            [cell showMoreCell];
        }
        else {
            [cell setCell:[resultModel resultAtIndex:indexPath.row]];
            NSString *strIndex = [NSString stringWithFormat:@"%d", indexPath.row+1];
            cell.labelIndex.text = strIndex;
        }
    
        return cell;
    }
    else {
        static NSString *MyIdentifier = @"MyIdentifierCategory"; 
        WFTableCategoryViewCell *cell = (WFTableCategoryViewCell *)[atableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) 
        {
            cell = [[[WFTableCategoryViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
        }
    
        [cell setCell:[self.category getCategoryAtIndex:indexPath.row]];
        return cell;
    }
    // Stop Spinning - Finished populating the list
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO]; 
}


/*- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
    [atableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedCellIndex = indexPath;
    //searchController = [WFSearchBarViewController sharedSearchBar].searchController;
    //[searchController rowSelected:indexPath.row];

}*/

@end
