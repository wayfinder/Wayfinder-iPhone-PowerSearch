/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Add some colors that are used in PowerSearch to UIColor
@interface UIColor ( WFColors )
+ WFBackgroundGray;
+ WFDarkBackgroundGray;
+ WFBackgroundBlack;
@end

typedef enum
{	
        Results,
        Category,
        Details
}withContent;

typedef enum
{	
    FreetextSearchMode,
    CategorySearchMode,
    DefaultMode     
}searchBarMode;

typedef enum
{
    InProgress,
    Finish,
    Abort
}TransactionStatus;

typedef enum
{
    Detail = -1,
    Map = 0,
    List = 1
} View;

typedef enum
{
    StartUpBackground,
    SearchBackground,
    ProcessingBackground        
}Background;


typedef enum
{
    DetailView,
    ContentView       
}SubViews;

typedef enum
{
    DontShowSection,
    AddressSection,
    MapSection,
    ContactsSection,
    AccessSection,
    PriceSection,
    HotelSection,
    RestaurantSection,
    SkiSection,
    InfoSection,
    DescriptionSection
}DetailsSectionId;

typedef enum
{	
    carRoute,
    pedestrianRoute
}routingType;

typedef enum
{
    tabBarPtr,
    mapTabNaviCtrlPtr,
    searchTabNaviCtrlPtr,
    categoryTabNaviCtrlPtr,
    favoriteTabNavCtrlPtr,
    mapViewCtrl,
    searchViewCtrl,
    categoryViewCtrl,
    mapViewPtr,
    mainNavPtr,
    upperShadowPtr,
    lowerShadowPtr,
    locateButtonPtr,
    aboutButtonPtr
}pointerId;

typedef enum
{	
    defaultNavBar,
    searchNavBar
}navBarType;

typedef enum
{	
    categorySearchType,
    textSearchType
}searchType;

// Define if compiling the premium version
//#define PREMIUM_VERSION 1

// Define if you want the fake location to show some changing accuracies
//#define FAKE_LOCATION_DEMO 1

// use this to fetch map & results from development server.
#define USEHEADSERVER 1

// Constant strings used for example in XML documents
#define STR_NAME @"name"
#define STR_IMAGE_NAME @"image_name"
#define STR_IMAGE_SAVE @"save_image"
#define STR_TOP_REGION_ID @"top_region_id"
#define STR_TOP_REGION_NAME @"name_node"
#define STR_BOUNDING_BOX @"boundingbox"
#define STR_NORTH_LAT @"north_lat"
#define STR_WEST_LON @"west_lon"
#define STR_SOUTH_LAT @"south_lat"
#define STR_EAST_LON @"east_lon"
#define STR_HEADING @"heading"
#define STR_MAX_WIDTH @"max_width"
#define STR_MAX_HEIGHT @"max_height"

#define STR_CLIENTTYPE @"wf-iphone-demo"
#define STR_BUILD_VERSION @"414";

#ifdef USEHEADSERVER
#define STR_BASEURL @"http://oss-xml.services.wayfinder.com:80"
#define STR_HOSTNAME @"oss-xml.sevices.wayfinder.com"
#define STR_XMLUSER @"iphonedemo"
#define STR_XMLPASSWD @"iphone-demo"
#define STR_XMLUIN @"694520733"
#else
#define STR_BASEURL @"http://oss-xml.services.wayfinder.com:80"
#define STR_HOSTNAME @"oss-xml.services.wayfinder.com"
#define STR_XMLUSER @"iphonedemo"
#define STR_XMLPASSWD @"iphone-demo"
#define STR_XMLUIN @"694520733"
#endif

#define MC2_SCALE 11930464.7111
#define WGS84_SEMIMAJOR 6378137.0

#define MAIN_VIEW_HEIGHT 367
