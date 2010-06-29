/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFSearchViewController.h"
#import "WFResultListController.h"
#import "WFResultsModel.h"
#import "WFCommandRouter.h"
#import "WFPropellerView.h"
#import "constants.h"

// File name of favorites
NSString *SEARCH_HISTORY_FILE_NAME = @"searchHistory.archive";

@interface WFSearchViewController()
- (void)showOldWordsFor:(NSString *)newWord;
- (void)wordSearchTimerFired:(NSTimer*)theTimer;
@end


@implementation WFSearchViewController


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    
    // Create a table view to show old search words.
    tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0, 320, 201) style:UITableViewStylePlain];
    tableView.clipsToBounds = YES;	
    tableView.backgroundColor = [UIColor WFBackgroundGray];
    tableView.scrollEnabled = YES;
    tableView.frame = CGRectMake(0,0, 320, 201);
    tableView.autoresizingMask = 0;
    
    tableView.bounces = NO;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.showsHorizontalScrollIndicator = NO;
    tableView.delegate = self;
    tableView.dataSource = self;
    
    self.title = NSLocalizedString(@"Search", @"Search field placeholder");
    
    // Create an empty grey view for searching
    bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, MAIN_VIEW_HEIGHT)];
    bgView.backgroundColor = [UIColor WFDarkBackgroundGray];
    
    self.view = bgView;
    [self.view addSubview:tableView];
    
    if (!titleBgView) {
        titleBgView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
        self.navigationItem.titleView = titleBgView;
        srchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
        srchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        srchBar.placeholder = NSLocalizedString(@"Search", @"Search field placeholder");
        srchBar.barStyle = UIBarStyleBlackOpaque;
        srchBar.delegate = self;
        [titleBgView addSubview:srchBar];
        [srchBar sizeToFit];
        srchBar.frame = CGRectMake(srchBar.frame.origin.x - 3, srchBar.frame.origin.y,
                                   srchBar.frame.size.width, srchBar.frame.size.height);
        
        listWords = [[NSMutableArray alloc] init];
        [self loadWords];
    }
    
    resultModel = [[WFCommandRouter SharedCommandRouter] getResultModelForType:textSearchType];
}

- (void)didReceiveMemoryWarning {
    if (resultList && self == self.navigationController.topViewController) {
        [resultList release];
        resultList = nil;
    }
    
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}


- (void)dealloc {
    [propellerView release];
    [srchBar release];
    [titleBgView release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    /* It could be that user is coming back to search view from result view
     before results were reseive. Call cancel for the operation just in case */
    [resultModel cancelDownload];
    [resultModel clearResults];
    [[WFCommandRouter SharedCommandRouter] clearResultsOnMap];
    
    [listWords removeAllObjects];
    [tableView reloadData];
    tableView.bounces = NO;
    tableView.hidden = YES;
    
    // As the only thing to do here is search, place focus to search field and show keyboard
    [srchBar becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    /* Seems that search bar size is changed when user is in results/details and
     returns to the search view. Fix frames here. */
    titleBgView.frame = CGRectMake(0.0, 0.0, 320.0, 44.0);
}

- (void)wordSearchTimerFired:(NSTimer*)theTimer
{
    [self showOldWordsFor:[theTimer userInfo]];
    [wordSearchTimer invalidate];
    [wordSearchTimer release];
    wordSearchTimer = nil;
}

- (void)showOldWordsFor:(NSString *)newWord
{
    NSString *firstLetter = [[newWord substringWithRange:NSMakeRange(0, 1)] lowercaseString];
    NSArray *words = [oldSearchWords objectForKey:firstLetter];
    [listWords removeAllObjects];
    
    if (words) {
        for (NSString *item in words) {
            if (NSOrderedSame == [item compare:newWord options:NSCaseInsensitiveSearch range:NSMakeRange(0, [newWord length])]) {
                [listWords addObject:item];
            }
        }
    }
    
    if ([listWords count] > 0) {
        tableView.hidden = NO;
        tableView.bounces = YES;
        tableView.showsVerticalScrollIndicator = YES;
    }
    else {
        tableView.hidden = YES;
        tableView.bounces = NO;
        tableView.showsVerticalScrollIndicator = NO;
    }
    [tableView reloadData];
}

- (void) loadWords
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                         NSUserDomainMask, YES); 
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:SEARCH_HISTORY_FILE_NAME];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        oldSearchWords = [[NSKeyedUnarchiver unarchiveObjectWithFile:filePath] retain];
    }
    
    // If loading failed or file does not exist:
    if (!oldSearchWords)
        oldSearchWords = [[NSMutableDictionary alloc] init];
}

- (void) saveWords
{
    if (oldSearchWords && [oldSearchWords count] > 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                             NSUserDomainMask, YES); 
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:SEARCH_HISTORY_FILE_NAME];
        
        [NSKeyedArchiver archiveRootObject:oldSearchWords toFile:filePath];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (wordSearchTimer) {
        [wordSearchTimer invalidate];
        [wordSearchTimer release];
        wordSearchTimer = nil;
    }
    [searchBar resignFirstResponder];
    tableView.frame = CGRectMake(0,0, 320, MAIN_VIEW_HEIGHT);
    if([searchBar.text length] > 0)
    {
        if (!resultList) {
            resultList = [[WFResultListController alloc] initWithStyle:UITableViewStylePlain];
            [resultList setResultModel:resultModel];
            [resultList setNavigationBarType:defaultNavBar];
        }
        
        // Add this search string to array
        NSString *firstLetter = [[searchBar.text substringWithRange:NSMakeRange(0, 1)] lowercaseString];
        NSMutableArray *words = [oldSearchWords objectForKey:firstLetter];
        BOOL addWord = YES;
        if (words) {
            // Don't add the same word multiple times
            for (NSString *item in words) {
                if (NSOrderedSame == [item caseInsensitiveCompare:searchBar.text]) {
                    addWord = NO;
                    break;
                }
            }
        }
        else {
            words = [[NSMutableArray alloc] init];
        }
        
        if (addWord) {
            [words addObject:searchBar.text];
            [words sortUsingSelector:@selector(compare:)];
            [oldSearchWords setObject:words forKey:firstLetter];
        }
        
        [resultList showResultsForString:searchBar.text];
        
        if (resultList != [self.navigationController topViewController])
            [self.navigationController pushViewController:resultList animated:YES];
    }
    else {
        // Do nothing?
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    tableView.frame = CGRectMake(0, 0, 320, 201);
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (wordSearchTimer && [wordSearchTimer isValid]) {
        [wordSearchTimer invalidate];
        [wordSearchTimer release];
        wordSearchTimer = nil;
    }
    
    if([searchText length] > 0)
        wordSearchTimer = [[NSTimer scheduledTimerWithTimeInterval:1
                                                            target:self
                                                          selector:@selector(wordSearchTimerFired:)
                                                          userInfo:searchText
                                                           repeats:NO] retain];
    else {
        [listWords removeAllObjects];
        [tableView reloadData];
        tableView.hidden = YES;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([srchBar isFirstResponder]) {
        [srchBar resignFirstResponder];
        tableView.frame = CGRectMake(0,0, 320, MAIN_VIEW_HEIGHT);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    if ([listWords count] > 0)
        return [listWords count] + 1;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)atableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath  
{
    static NSString *MyIdentifier = @"searchWordCell";
    UITableViewCell *cell = [atableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
    }
    
    if (indexPath.row >= [listWords count]) {
        // Make a "Clear history" button
        cell.text = NSLocalizedString(@"Clear history", nil);
    }
    else {
        cell.text = [listWords objectAtIndex:indexPath.row];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= [listWords count]) {
        // Delete history button pressed
        [oldSearchWords removeAllObjects];
        [listWords removeAllObjects];
        tableView.hidden = YES;
    }
    else {
        srchBar.text = [listWords objectAtIndex:indexPath.row];
        [self searchBarSearchButtonClicked:srchBar];
    }
}

@end
