/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <UIKit/UIKit.h>
#import "WFXMLService.h"
#import "constants.h"

@class WFResultsModel;
@class WFAppStateStore;

@protocol WFResultModelDelegate
- (void) operationFailedWithError:(NSError *)anError;
@optional
- (void) resultsCleared; // Called when result list is emptied
- (void) detailsReadyForItem:(NSDictionary *)item;
// newSearch parameter is YES if this is first search and NO if we just fetched
// more results to old search.
- (void) didReceiveResultsForModel:(WFResultsModel *)model newSearch:(BOOL)newSearch;
@end

@interface WFResultsModel : NSObject <WFXMLServiceDelegate>
{
@private
    WFAppStateStore *store;
    WFXMLService *service;
    NSObject<WFResultModelDelegate> *delegate;
    NSObject<WFResultModelDelegate> *detailDelegate;
    NSMutableArray *searchResultsArray;
    TransactionStatus transactionStatus;
    NSString *transactionId;
    BOOL sorted;
    BOOL newSearch;
    BOOL wasCategorySearch;
    NSString *searchString;
    int resultsShown;
}

@property (nonatomic,retain) NSMutableArray *searchResultsArray;
@property (nonatomic,assign) NSObject<WFResultModelDelegate> *delegate;
@property (nonatomic,assign) NSObject<WFResultModelDelegate> *detailDelegate;
@property (nonatomic,retain) NSString *searchString;
@property (nonatomic) BOOL wasCategorySearch;

- (id)init;
- (int)getResultsCount;
- (NSArray *)getResults;
- (NSArray *)getResultsInRange:(NSRange)range;
- (NSDictionary *)resultAtIndex:(NSInteger)index;
- (void)clearResults;
- (void)addResult:(NSDictionary *)newResult;

// Method for fetching more results with the same search word
- (void)showMoreResults;
// Method for asking if there are more results available
- (BOOL)hasMoreResults;

/* Do the actual search from xmlService */
- (void)searchWithString:(NSString *)queryString;
- (void)searchWithCategory:(NSString *)categoryId;
- (void)getDetailsFor:(NSDictionary *) obj;

// This method cancels ongoing search (detail download is allowed to
// end and the results are ignored)
- (void)cancelDownload;

@end
