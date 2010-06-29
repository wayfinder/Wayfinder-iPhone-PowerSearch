/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PowerSearchAppDelegate.h"
#import "WFVectorMapViewController.h"
#import "WFSearchViewController.h"
#import "WFCategoryListController.h"
#import "WFNetworkDetector.h"
#import "WFFavoriteListController.h"
#import "WFCommandRouter.h"

@implementation PowerSearchAppDelegate

@synthesize window;


- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    application.statusBarStyle = UIStatusBarStyleBlackOpaque;
    
    // Check network
    netDetector = [[WFNetworkDetector alloc] init];
    if (!netDetector)
        NSLog(@"Error: Failed to instantiate WFNetworkDetector");
    else {
        [netDetector checkNetworkAvailable];
	}
    
    /* Most of the application UI is build here. */
    WFCommandRouter *cmdRouter = [WFCommandRouter SharedCommandRouter];
    
    // Create tab bar controller
    tabBarController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    tabBarController.delegate = cmdRouter;
    [cmdRouter setPointer:tabBarController forId:tabBarPtr];
    
    // create Main navigation controller: switches between about view and addressbook
    UINavigationController *mainNavController = [[UINavigationController alloc]
                                                 initWithRootViewController:tabBarController];
    mainNavController.navigationBarHidden = YES;
    
    [mainNavController setDelegate:cmdRouter];
    
    [cmdRouter setPointer:mainNavController forId:mainNavPtr];

    // Create Map tab controllers
    WFVectorMapViewController *mapCtrl = [[[WFVectorMapViewController alloc]
                                           initWithNibName:nil bundle:nil] autorelease];
    [cmdRouter setPointer:mapCtrl forId:mapViewCtrl];
    
    UINavigationController *mapTabNaviCtrl =
    [[UINavigationController alloc] initWithRootViewController:mapCtrl];
    
    mapTabNaviCtrl.title = NSLocalizedString(@"Map", @"Map button text");
    mapTabNaviCtrl.tabBarItem.image = [UIImage imageNamed:@"map-icon.png"];
    mapTabNaviCtrl.navigationBar.barStyle = UIBarStyleBlackOpaque;

    [cmdRouter setPointer:mapTabNaviCtrl forId:mapTabNaviCtrlPtr];
    
    
    // Create search tab controllers
    WFSearchViewController *searchCtrl = [[[WFSearchViewController alloc]
                                          initWithNibName:nil bundle:nil] autorelease];
    [cmdRouter setPointer:searchCtrl forId:searchViewCtrl];
    
    // Set the tab bar item to system search format
    searchCtrl.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:0];
    
    UINavigationController *searchTabNaviCtrl =
    [[UINavigationController alloc] initWithRootViewController:searchCtrl];
    
    searchTabNaviCtrl.title = NSLocalizedString(@"Search", @"Search field placeholder");
    searchTabNaviCtrl.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    [cmdRouter setPointer:searchTabNaviCtrl forId:searchTabNaviCtrlPtr];
    
    
    // Create category tab controllers
    WFCategoryListController *categoryCtrl = [[WFCategoryListController alloc] initWithStyle:UITableViewStylePlain];
    [cmdRouter setPointer:categoryCtrl forId:categoryViewCtrl];
    
    UINavigationController *categoryTabNaviCtrl =
    [[UINavigationController alloc] initWithRootViewController:categoryCtrl];
    
    categoryTabNaviCtrl.title = NSLocalizedString(@"Categories", @"Category field placeholder");
    categoryTabNaviCtrl.tabBarItem.image = [UIImage imageNamed:@"category_icon.png"];
    categoryTabNaviCtrl.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    [cmdRouter setPointer:categoryTabNaviCtrl forId:categoryTabNaviCtrlPtr];
    
    // Create favorites tab
    WFFavoriteListController *favoriteCtrl = [[WFFavoriteListController alloc] initWithStyle:UITableViewStylePlain];
    
    favoriteCtrl.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFavorites tag:0];
    
    UINavigationController *favoriteTabNaviCtrl =
    [[UINavigationController alloc] initWithRootViewController:favoriteCtrl];
    
    favoriteTabNaviCtrl.title = NSLocalizedString(@"Favorites", nil);
    favoriteTabNaviCtrl.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    [cmdRouter setPointer:favoriteTabNaviCtrl forId:favoriteTabNavCtrlPtr];
    
    
    tabBarController.viewControllers =
    [NSArray arrayWithObjects:mapTabNaviCtrl, searchTabNaviCtrl, categoryTabNaviCtrl, favoriteTabNaviCtrl, nil];
    
    
    // Set back active in didReceiveInitialLocation
    [cmdRouter setControlsActive:NO];
    
    // Lastly add some shadows over everything.
    UIImageView *upperShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"panel-shaddow-bottom.png"]];
    UIImageView *lowerShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"panel-shaddow-top.png"]];
    upperShadow.center = CGPointMake(160, (int)(64 + upperShadow.bounds.size.height / 2));
    lowerShadow.center = CGPointMake(160, (int)(432 - lowerShadow.bounds.size.height / 2));
    
    [cmdRouter setPointer:upperShadow forId:upperShadowPtr];
    [cmdRouter setPointer:lowerShadow forId:lowerShadowPtr];
    
    [window setBackgroundColor:[UIColor WFBackgroundBlack]];
    [window addSubview:mainNavController.view];
    [window addSubview:upperShadow];
    [window addSubview:lowerShadow];
    [window bringSubviewToFront:upperShadow];
    [window bringSubviewToFront:lowerShadow];
    [upperShadow release];
    [lowerShadow release];

    [window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[WFCommandRouter SharedCommandRouter] applicationWillTerminate];
}

- (void)dealloc {
    [tabBarController release];
    [netDetector release];
    [window release];
    [super dealloc];
}


@end
