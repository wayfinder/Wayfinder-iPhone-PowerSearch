/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFVectorMapViewController.h"
#import "WFCommandRouter.h"
#import "WFDetailsViewController.h"
#import "WFVectorMapView.h"
#import "WFPropellerView.h"
#import "constants.h"

@implementation WFVectorMapViewController


- (void)loadView {
    // Set PowerSearch title to navigation bar
    UIImageView *titleImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"power-search-title.png"]];
    self.navigationItem.titleView = titleImg;
    [titleImg release];
    self.title = NSLocalizedString(@"Map", @"Map button text");
    
    // Set locate button to the navigation bar
    if (!locateButton) {
        locateButton = [[UISegmentedControl alloc]
                        initWithItems:[NSArray arrayWithObject:[NSString stringWithString:@""]]];
        locateButton.tintColor = [UIColor grayColor];
        locateButton.momentary = YES;
        locateButton.segmentedControlStyle = UISegmentedControlStyleBar;
        locateButton.frame = CGRectMake(0, 0, 30, 30);
        [locateButton addTarget:self
                         action:@selector(locationButtonPressed:)
               forControlEvents:UIControlEventValueChanged];
        
        locatePropeller = [[UIActivityIndicatorView alloc]
                           initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [locatePropeller startAnimating];
        locatePropeller.center = CGPointMake(15, 15);
        [locateButton addSubview:locatePropeller];
    }
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:locateButton];
    
    mapView = [[WFVectorMapView alloc] initWithFrame:CGRectMake(0, 0, 320, MAIN_VIEW_HEIGHT)];
    mapView.mapCtrl = self;
    self.view = mapView;
    
    if (!propellerView && !locationReceived) {
        propellerView = [[WFPropellerView alloc] initWithFrame:CGRectMake(0, 0, 320, MAIN_VIEW_HEIGHT)];
        [propellerView setLabelText:NSLocalizedString(@"Locating you", nil)];
        
        [self.view addSubview:propellerView];
    }
    
    [[WFCommandRouter SharedCommandRouter] addAboutButtonTo:self.navigationItem];
    
    [[WFCommandRouter SharedCommandRouter] setPointer:locateButton forId:locateButtonPtr];
    [[WFCommandRouter SharedCommandRouter] setPointer:self.navigationItem.rightBarButtonItem forId:aboutButtonPtr];
    
    /* Command router can't set about and locate buttons inactive because they have not
       been created when it tries. Set them disabled here and activate again in command router */
    if (!locationReceived) {
        locateButton.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
}


- (void)didReceiveMemoryWarning {
    NSLog(@"WFVectorMapViewController: didReceiveMemoryWarning");
    if (detailsCtrl && detailsCtrl != self.navigationController.topViewController) {
        [detailsCtrl release];
        detailsCtrl = nil;
    }
    
    /* Don't call this from super. It will release map view and this causes Bad Things.
       WFVectorMapView (and MapLib) is not made so that it can be released and recreated
       at any time. Let's just hope that other memory releases are enough. */
    //[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}


- (void)dealloc {
    [propellerView release];
    [locateButton release];
    [super dealloc];
}

- (void) showDetailsForItem:(NSDictionary *)item
{
    if (!detailsCtrl) {
        detailsCtrl = [[WFDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    
    // Set this every time just in case the same result model was used in map view
    [detailsCtrl setDetailSource:mapView.resultModel];
    
    [detailsCtrl showDetailsForItem:item];
    
    if (detailsCtrl != [self.navigationController topViewController])
        [self.navigationController pushViewController:detailsCtrl animated:YES];
}

- (void) didReceiveInitialLocation
{
    // We can just remove the whole propeller view as it's only shown during startup
    [propellerView removeFromSuperview];
    [propellerView release];
    [locatePropeller removeFromSuperview];
    [locatePropeller release];
    locatePropeller = nil;
    propellerView = nil;
    locationReceived = YES;
    [locateButton setImage:[UIImage imageNamed:@"relocate-icon.png"] forSegmentAtIndex:0];
}

- (void) didStartFollowingLocation
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    locateButton.tintColor = [UIColor blackColor];
}

- (void) didStopFollowingLocation
{
    locateButton.tintColor = [UIColor grayColor];
}

- (void) didFinishUpdatingLocation
{
    locateButton.tintColor = [UIColor grayColor];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void) locationButtonPressed:(id)sender
{
    if (locateButton.enabled) {
        // Prevent screen power save
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        locateButton.tintColor = [UIColor blackColor];
        [mapView showCurrentLocationOnMap];
    }
}

@end
