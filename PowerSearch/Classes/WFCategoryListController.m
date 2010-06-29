/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFCategoryListController.h"
#import "WFResultListController.h"
#import "WFPropellerView.h"
#import "WFCommandRouter.h"
#import "WFResultsModel.h"
#import "WFCategoryModel.h"


@implementation WFCategoryListController


- (void)loadView {
    [super loadView];
    [self setContentType:Category];
    resultModel = [[WFCommandRouter SharedCommandRouter] getResultModelForType:categorySearchType];
    categoryModel = [WFCategoryModel SharedCategoryArray];
    categoryModel.delegate = self;
    
    [[WFCommandRouter SharedCommandRouter] addAboutButtonTo:self.navigationItem];
    
    if (Finish != [categoryModel getTransactionStatus]) {
        self.tableView.userInteractionEnabled = NO;
        self.tableView.showsVerticalScrollIndicator = NO;
        self.tableView.showsHorizontalScrollIndicator = NO;
        propellerView = [[WFPropellerView alloc] initWithFrame:CGRectMake(0, 0, 320, MAIN_VIEW_HEIGHT)];
        [propellerView setLabelText:NSLocalizedString(@"Loading", @"Loading")];
    
        [self.view addSubview:propellerView];
    }
}


- (void)dealloc {
    [propellerView release];
    [resultList release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    if (resultList && self == self.navigationController.topViewController) {
        [resultList release];
        resultList = nil;
    }
    
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}

- (void)viewWillAppear:(BOOL)animated
{
    /* It could be that user is coming back to category list from result view
       before results were reseive. Call cancel for the operation just in case */
    [resultModel cancelDownload];
    [resultModel clearResults];
    [[WFCommandRouter SharedCommandRouter] clearResultsOnMap];
}

- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
    [atableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedCellIndex = indexPath;
    if (!resultList) {
        resultList = [[WFResultListController alloc] initWithStyle:UITableViewStylePlain];
        [resultList setResultModel:resultModel];
        [resultList setNavigationBarType:defaultNavBar];
    }
    
    //NSDictionary *selectedCategory = [categoryModel getCategoryAtIndex:indexPath.row];
    
    //[resultList showResultsForCategory:[selectedCategory objectForKey:@"name"]];
    [resultList showResultsForCategory:[categoryModel getCategoryAtIndex:indexPath.row]];
    
    if (resultList != [self.navigationController topViewController])
        [self.navigationController pushViewController:resultList animated:YES];
}

// WFCategoryModelDelegate methods
- (void) categoryTransactionStatus:(TransactionStatus)status
{
    if (Finish == status && propellerView) {
        // Used only during startup so remove view
        [self.tableView reloadData];
        [propellerView removeFromSuperview];
        [propellerView release];
        self.tableView.userInteractionEnabled = YES;
        self.tableView.showsVerticalScrollIndicator = YES;
        [self.tableView flashScrollIndicators];
    }
}


@end
