/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import "WFDetailsViewController.h"
#import "WFDetailViewCell.h"
#import "WFPropellerView.h"
#import "WFResultsModel.h"
#import "WFFavoriteModel.h"
#import "WFCommandRouter.h"
//#import "WFSearchBarViewController.h"
#import "PowerSearchAppDelegate.h"
#import "WFImageLoader.h"
#import "WFHRSViewCell.h"

#define TEXT_MARGIN 10

@interface WFDetailsViewController()
- (void) formatItem:(NSMutableDictionary *)dict ofKey:(NSString *)key;
- (void) initialiseWithItem:(NSDictionary *)item;
@end

@implementation WFDetailsViewController

@synthesize itemInfo, descriptionText;

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        self.tableView.rowHeight = 44;
        self.tableView.sectionFooterHeight = 0;
        self.tableView.opaque = YES;
        self.title = NSLocalizedString(@"Details", @"Details");
        addFavoriteButtonNbr = -1;
        
        [[WFCommandRouter SharedCommandRouter] addAboutButtonTo:self.navigationItem];
        
        // Create details view by hand
        tableHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
        
        // Create and place icon/photo view
        displayImage = [[UIImageView alloc] initWithFrame:CGRectMake(224, 7, 87, 86)];
        [tableHeader addSubview:displayImage];
        
        // Create and place photo frame
        frameImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"details-photo-frame-empty.png"]];
        frameImage.center = displayImage.center;
        [tableHeader addSubview:frameImage];
        
        // Create and place text fields
        labelName = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 205, 40)];
        labelName.numberOfLines = 2;
        labelName.adjustsFontSizeToFitWidth = YES;
        labelName.minimumFontSize = 15.0;
        labelName.font = [UIFont boldSystemFontOfSize:17.0];
        labelName.opaque = NO;
        labelName.backgroundColor = [UIColor clearColor];
        [tableHeader addSubview:labelName];
        
        labelPlace = [[UILabel alloc] initWithFrame:CGRectMake(15, 76, 205, 16)];
        labelPlace.adjustsFontSizeToFitWidth = YES;
        labelPlace.minimumFontSize = 8.0;
        labelPlace.font = [UIFont systemFontOfSize:12.0];
        labelPlace.opaque = NO;
        labelPlace.backgroundColor = [UIColor clearColor];
        [tableHeader addSubview:labelPlace];
        
        labelAddress = [[UILabel alloc] initWithFrame:CGRectMake(15, 58, 205, 16)];
        labelAddress.adjustsFontSizeToFitWidth = YES;
        labelAddress.minimumFontSize = 8.0;
        labelAddress.font = [UIFont systemFontOfSize:12.0];
        labelAddress.opaque = NO;
        labelAddress.backgroundColor = [UIColor clearColor];
        [tableHeader addSubview:labelAddress];
        
        displayImage.contentMode = UIViewContentModeScaleAspectFill;
        displayImage.clipsToBounds = YES;
        
        itemDetails = [[NSMutableDictionary alloc] init];
        addressInfo = [[NSMutableDictionary alloc] init];
        visibleSections = [[NSMutableArray alloc] initWithCapacity:1];
        
        descriptionText = [[UILabel alloc] init];
        tableFooter = [[UIView alloc] init];
        descriptionText.font = [UIFont systemFontOfSize:14];
        descriptionText.backgroundColor = [UIColor clearColor];
        descriptionText.opaque = YES;
        descriptionText.numberOfLines = 0;
        [tableFooter addSubview:self.descriptionText];
        
        self.tableView.backgroundColor = [UIColor WFBackgroundGray];
        self.tableView.tableHeaderView = tableHeader;
        
        propellerView = [[WFPropellerView alloc] initWithFrame:CGRectMake(0, 0, 320, MAIN_VIEW_HEIGHT)];
        [propellerView setLabelText:NSLocalizedString(@"Loading", @"Loading")];
        
        [self.view addSubview:propellerView];
        
// Add this define if all data sections are shown. If not, most data will go to "don't show" section
#ifdef SHOW_ALL_DATA
        itemToSection = 
        [[NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt:AddressSection], @"vis_address",
          [NSNumber numberWithInt:AddressSection], @"vis_house_nbr",
          [NSNumber numberWithInt:AddressSection], @"vis_complete_zip",
          [NSNumber numberWithInt:AddressSection], @"vis_zip_code",
          [NSNumber numberWithInt:AddressSection], @"vis_full_address",
          [NSNumber numberWithInt:AddressSection], @"vis_zip_area",
          [NSNumber numberWithInt:AddressSection], @"post_address",
          [NSNumber numberWithInt:AddressSection], @"post_zip_area",
          [NSNumber numberWithInt:AddressSection], @"post_zip_code",
          [NSNumber numberWithInt:AddressSection], @"citypart",
          [NSNumber numberWithInt:AddressSection], @"state",
          [NSNumber numberWithInt:AddressSection], @"neighborhood",
          [NSNumber numberWithInt:AddressSection], @"supplier",
          [NSNumber numberWithInt:AddressSection], @"text",
          [NSNumber numberWithInt:AddressSection], @"image_url",
          [NSNumber numberWithInt:AddressSection], @"short_description",
          [NSNumber numberWithInt:AddressSection], @"brandname",
          [NSNumber numberWithInt:MapSection], @"booking_phone_number",
          [NSNumber numberWithInt:MapSection], @"booking_url",
          [NSNumber numberWithInt:ContactsSection], @"email",
          [NSNumber numberWithInt:ContactsSection], @"phone_number",
          [NSNumber numberWithInt:ContactsSection], @"mobile_phone",
          [NSNumber numberWithInt:ContactsSection], @"url",
          [NSNumber numberWithInt:ContactsSection], @"wap_url",
          [NSNumber numberWithInt:DescriptionSection], @"long_description",
          [NSNumber numberWithInt:HotelSection], @"check_in",
          [NSNumber numberWithInt:HotelSection], @"check_out",
          [NSNumber numberWithInt:HotelSection], @"nbr_of_rooms",
          [NSNumber numberWithInt:HotelSection], @"weekend_rate",
          [NSNumber numberWithInt:HotelSection], @"breakfast",
          [NSNumber numberWithInt:HotelSection], @"hotel_services",
          [NSNumber numberWithInt:HotelSection], @"conferences",
          [NSNumber numberWithInt:HotelSection], @"booking_advisable",
          [NSNumber numberWithInt:PriceSection], @"single_room_from",
          [NSNumber numberWithInt:PriceSection], @"double_room_from",
          [NSNumber numberWithInt:PriceSection], @"triple_room_from",
          [NSNumber numberWithInt:PriceSection], @"suite_from",
          [NSNumber numberWithInt:PriceSection], @"extra_bed_from",
          [NSNumber numberWithInt:PriceSection], @"nonhotel_cost",
          [NSNumber numberWithInt:PriceSection], @"average_cost",
          [NSNumber numberWithInt:PriceSection], @"admission_charge",
          [NSNumber numberWithInt:PriceSection], @"price_petrol_superplus",
          [NSNumber numberWithInt:PriceSection], @"price_petrol_super",
          [NSNumber numberWithInt:PriceSection], @"price_petrol_normal",
          [NSNumber numberWithInt:PriceSection], @"price_diesel",
          [NSNumber numberWithInt:PriceSection], @"price_biodiesel",
          [NSNumber numberWithInt:PriceSection], @"credit_card",
          [NSNumber numberWithInt:RestaurantSection], @"home_delivery",
          [NSNumber numberWithInt:RestaurantSection], @"takeaway_available",
          [NSNumber numberWithInt:RestaurantSection], @"allowed_to_bring_alcohol",
          [NSNumber numberWithInt:RestaurantSection], @"type_food",
          [NSNumber numberWithInt:SkiSection], @"ski_mountain_min_max_height",
          [NSNumber numberWithInt:SkiSection], @"snow_depth_valley_mountain",
          [NSNumber numberWithInt:SkiSection], @"snow_quality",
          [NSNumber numberWithInt:SkiSection], @"lifts_open_total",
          [NSNumber numberWithInt:SkiSection], @"ski_slopes_open_total",
          [NSNumber numberWithInt:SkiSection], @"cross_country_skiing_km",
          [NSNumber numberWithInt:SkiSection], @"glacier_area",
          [NSNumber numberWithInt:SkiSection], @"last_snowfall",
          [NSNumber numberWithInt:AccessSection], @"nearest_train",
          [NSNumber numberWithInt:AccessSection], @"disabled_access",
          [NSNumber numberWithInt:AccessSection], @"open_hours",
          [NSNumber numberWithInt:AccessSection], @"open_for_season",
          [NSNumber numberWithInt:InfoSection], @"special_feature",
          [NSNumber numberWithInt:InfoSection], @"decor",
          [NSNumber numberWithInt:InfoSection], @"owner",
          [NSNumber numberWithInt:InfoSection], @"free_of_charge",
          [NSNumber numberWithInt:InfoSection], @"tracking_data",
          [NSNumber numberWithInt:InfoSection], @"start_date",
          [NSNumber numberWithInt:InfoSection], @"end_date",
          [NSNumber numberWithInt:InfoSection], @"start_time",
          [NSNumber numberWithInt:InfoSection], @"end_time",
          [NSNumber numberWithInt:InfoSection], @"contact_info",
          [NSNumber numberWithInt:InfoSection], @"short_info",
          [NSNumber numberWithInt:InfoSection], @"fax_number",
          [NSNumber numberWithInt:InfoSection], @"accommodation_type",
          nil] retain];
#else
        itemToSection = 
        [[NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt:AddressSection], @"vis_address",
          [NSNumber numberWithInt:AddressSection], @"vis_house_nbr",
          [NSNumber numberWithInt:AddressSection], @"vis_complete_zip",
          [NSNumber numberWithInt:AddressSection], @"vis_zip_code",
          [NSNumber numberWithInt:AddressSection], @"vis_full_address",
          [NSNumber numberWithInt:AddressSection], @"vis_zip_area",
          [NSNumber numberWithInt:AddressSection], @"post_address",
          [NSNumber numberWithInt:AddressSection], @"post_zip_area",
          [NSNumber numberWithInt:AddressSection], @"post_zip_code",
          [NSNumber numberWithInt:AddressSection], @"citypart",
          [NSNumber numberWithInt:AddressSection], @"state",
          [NSNumber numberWithInt:AddressSection], @"neighborhood",
          [NSNumber numberWithInt:AddressSection], @"supplier",
          [NSNumber numberWithInt:AddressSection], @"text",
          [NSNumber numberWithInt:AddressSection], @"image_url",
          [NSNumber numberWithInt:AddressSection], @"short_description",
          [NSNumber numberWithInt:AddressSection], @"brandname",
          [NSNumber numberWithInt:MapSection], @"booking_phone_number",
          [NSNumber numberWithInt:MapSection], @"booking_url",
          [NSNumber numberWithInt:ContactsSection], @"email",
          [NSNumber numberWithInt:ContactsSection], @"phone_number",
          [NSNumber numberWithInt:ContactsSection], @"mobile_phone",
          [NSNumber numberWithInt:ContactsSection], @"url",
          [NSNumber numberWithInt:ContactsSection], @"wap_url",
          [NSNumber numberWithInt:DescriptionSection], @"long_description",
          [NSNumber numberWithInt:DontShowSection], @"check_in",
          [NSNumber numberWithInt:DontShowSection], @"check_out",
          [NSNumber numberWithInt:DontShowSection], @"nbr_of_rooms",
          [NSNumber numberWithInt:DontShowSection], @"weekend_rate",
          [NSNumber numberWithInt:DontShowSection], @"breakfast",
          [NSNumber numberWithInt:DontShowSection], @"hotel_services",
          [NSNumber numberWithInt:DontShowSection], @"conferences",
          [NSNumber numberWithInt:DontShowSection], @"booking_advisable",
          [NSNumber numberWithInt:DontShowSection], @"single_room_from",
          [NSNumber numberWithInt:DontShowSection], @"double_room_from",
          [NSNumber numberWithInt:DontShowSection], @"triple_room_from",
          [NSNumber numberWithInt:DontShowSection], @"suite_from",
          [NSNumber numberWithInt:DontShowSection], @"extra_bed_from",
          [NSNumber numberWithInt:DontShowSection], @"nonhotel_cost",
          [NSNumber numberWithInt:DontShowSection], @"average_cost",
          [NSNumber numberWithInt:DontShowSection], @"admission_charge",
          [NSNumber numberWithInt:DontShowSection], @"price_petrol_superplus",
          [NSNumber numberWithInt:DontShowSection], @"price_petrol_super",
          [NSNumber numberWithInt:DontShowSection], @"price_petrol_normal",
          [NSNumber numberWithInt:DontShowSection], @"price_diesel",
          [NSNumber numberWithInt:DontShowSection], @"price_biodiesel",
          [NSNumber numberWithInt:DontShowSection], @"credit_card",
          [NSNumber numberWithInt:DontShowSection], @"home_delivery",
          [NSNumber numberWithInt:DontShowSection], @"takeaway_available",
          [NSNumber numberWithInt:DontShowSection], @"allowed_to_bring_alcohol",
          [NSNumber numberWithInt:DontShowSection], @"type_food",
          [NSNumber numberWithInt:DontShowSection], @"ski_mountain_min_max_height",
          [NSNumber numberWithInt:DontShowSection], @"snow_depth_valley_mountain",
          [NSNumber numberWithInt:DontShowSection], @"snow_quality",
          [NSNumber numberWithInt:DontShowSection], @"lifts_open_total",
          [NSNumber numberWithInt:DontShowSection], @"ski_slopes_open_total",
          [NSNumber numberWithInt:DontShowSection], @"cross_country_skiing_km",
          [NSNumber numberWithInt:DontShowSection], @"glacier_area",
          [NSNumber numberWithInt:DontShowSection], @"last_snowfall",
          [NSNumber numberWithInt:DontShowSection], @"nearest_train",
          [NSNumber numberWithInt:DontShowSection], @"disabled_access",
          [NSNumber numberWithInt:DontShowSection], @"open_hours",
          [NSNumber numberWithInt:DontShowSection], @"open_for_season",
          [NSNumber numberWithInt:DontShowSection], @"special_feature",
          [NSNumber numberWithInt:DontShowSection], @"decor",
          [NSNumber numberWithInt:DontShowSection], @"owner",
          [NSNumber numberWithInt:DontShowSection], @"free_of_charge",
          [NSNumber numberWithInt:DontShowSection], @"tracking_data",
          [NSNumber numberWithInt:DontShowSection], @"start_date",
          [NSNumber numberWithInt:DontShowSection], @"end_date",
          [NSNumber numberWithInt:DontShowSection], @"start_time",
          [NSNumber numberWithInt:DontShowSection], @"end_time",
          [NSNumber numberWithInt:DontShowSection], @"accommodation_type",
          [NSNumber numberWithInt:DontShowSection], @"contact_info",
          [NSNumber numberWithInt:DontShowSection], @"short_info",
          [NSNumber numberWithInt:DontShowSection], @"fax_number",
          nil] retain];
#endif
    }
    return self;
}


- (void)dealloc
{
    [itemDetails release];
    [visibleSections release];
    [addressInfo release];
    [itemInfo release];
    [itemToSection release];
    [descriptionText release];
    [tableFooter release];
    [addrParser release];
    [propellerView release];
    [labelName release];
    [labelPlace release];
    [labelAddress release];
    [displayImage release];
    [frameImage release];
    [tableHeader release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) formatItem:(NSMutableDictionary *)dict ofKey:(NSString *)key
{
    if ([key isEqual:@"phone_number"] ||
        [key isEqual:@"mobile_phone"] ||
        [key isEqual:@"booking_phone_number"]) {
        NSString *value = [dict objectForKey:@"value"];
        [dict setObject:[NSString stringWithFormat:@"tel:%@", value] forKey:@"href"];
        [dict setObject:@"details-icon-phone.png" forKey:@"image"];
    }
    else if ([key isEqual:@"email"]) {
        NSString *value = [dict objectForKey:@"value"];
        [dict setObject:[NSString stringWithFormat:@"mailto:%@", value] forKey:@"href"];
        [dict setObject:@"details-icon-email.png" forKey:@"image"];
    }
    else if ([key isEqual:@"url"] ||
             [key isEqual:@"booking_url"]) {
        NSString *value = [dict objectForKey:@"value"];
        NSString *urlRef;
        if ([value hasPrefix:@"http://"])
            urlRef = value;
        else
            urlRef = [NSString stringWithFormat:@"http://%@", value];
        [dict setObject:urlRef forKey:@"href"];
        [dict setObject:@"details-icon-web.png" forKey:@"image"];
    }  
    else if ([key isEqual:@"vis_zip_area"] ||
        [key isEqual:@"state"] ||
        [key isEqual:@"vis_full_address"] ||
        [key isEqual:@"vis_house_nbr"] ||
        [key isEqual:@"vis_address"] ||
        [key isEqual:@"short_description"] ||
        [key isEqual:@"vis_zip_code"]){
        [addressInfo setObject:[dict objectForKey:@"value"] forKey:key];
    }
    else if ([key isEqual:@"image_url"]) {
        // Download custom image
        [[WFImageLoader SharedImageLoader]
         loadImageFromAddress:[dict objectForKey:@"value"]
         to:displayImage
         maxSize:CGSizeMake(84,84)];
        hasCustomImage = YES;
    }
}

- (void)setDetailSource:(id)model
{
    detailSource = model;
    [detailSource setDetailDelegate:self];
}

- (void) showDetailsForItem:(NSDictionary *)item
{
    NSIndexPath *beginning = [NSIndexPath indexPathForRow:0 inSection:0];
    if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:beginning
         atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
    
    // Clear footer so it's not visible with propeller view. Is possible if previously
    // shown detail view was "short".
    descriptionText.text = @"";
    
    // Show propeller
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    propellerView.hidden = NO;
    self.tableView.userInteractionEnabled = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    [detailSource getDetailsFor:item];
}

- (void)initialiseWithItem:(NSDictionary *)item
{
    // Set to nil so table is resized with the correct footer size
    self.tableView.tableFooterView = nil;
    hasCustomImage = NO;
    
    [itemDetails removeAllObjects];
    [visibleSections removeAllObjects];
    [addressInfo removeAllObjects];
    
    if (nil != [item objectForKey:@"itemName"] && [[item objectForKey:@"itemName"] length] > 0)
        labelName.text = [item objectForKey:@"itemName"];
    else
        labelName.text = [item objectForKey:@"name"];
    descriptionText.text = @"";

    // customize navBar
    //[[WFSearchBarViewController sharedSearchBar] setDetailsBackButtonViewVisible:YES];
    
    NSDictionary *infoItems = [item objectForKey:@"info"]; 
    
    // Add "Show on map" button after the contacts section
    if (nil != [item objectForKey:@"lat"] && nil != [item objectForKey:@"lon"]) {
        if (nil == [itemDetails objectForKey:[NSNumber numberWithInt:MapSection]])
            [itemDetails setObject:[NSMutableArray arrayWithCapacity:1] forKey:[NSNumber numberWithInt:MapSection]];
        
        [[itemDetails objectForKey:[NSNumber numberWithInt:MapSection]] addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Show on map", @""), @"value",
          @"show_on_map", @"key", @"detail_icon_maps.png", @"image", nil]];
        // Also add 'Show Route' buttons
        [[itemDetails objectForKey:[NSNumber numberWithInt:MapSection]] addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Show route by car", @""), @"value",
          @"show_route_car", @"key", @"detail_icon_car_route.png", @"image", nil]];
        [[itemDetails objectForKey:[NSNumber numberWithInt:MapSection]] addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Show route by foot", @""), @"value",
          @"show_route_pedestrian", @"key", @"detail_icon_pedestrian_route.png", @"image", nil]];
        if (NSNotFound == [visibleSections indexOfObject:[NSNumber numberWithInt:MapSection]])
            [visibleSections addObject:[NSNumber numberWithInt:MapSection]];
    }
        
    // Define which section the data belongs to
    for (NSString *key in infoItems) {
        NSNumber *section = [itemToSection objectForKey:key];
        
        // Place really long text to description section
        if ([section intValue] != DontShowSection &&
            [section intValue] != AddressSection &&
            [section intValue] != ContactsSection &&
            [section intValue] != MapSection &&
            [[[infoItems objectForKey:key] objectForKey:@"value"] length] > 45 /*???*/)
            section = [NSNumber numberWithInt:DescriptionSection];
        
        if (nil == section)
            section = [NSNumber numberWithInt:InfoSection];
        
        // Create this section to list if not there yet
        if (nil == [itemDetails objectForKey:section]) {
            [itemDetails setObject:[NSMutableArray arrayWithCapacity:1] forKey:section];
            if ([section intValue] != DontShowSection &&
                [section intValue] != AddressSection &&
                [section intValue] != DescriptionSection)
                [visibleSections addObject:section];
        }
        
        // We also need the key so create a new dictionary
        NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[infoItems objectForKey:key]];
        [tempDict setObject:key forKey:@"key"];
        [self formatItem:tempDict ofKey:key];
        
        [[itemDetails objectForKey:section] addObject:tempDict];
    }
    
    // Add "Add to contacts" button to contacts section
    if (nil == [itemDetails objectForKey:[NSNumber numberWithInt:ContactsSection]])
        [itemDetails setObject:[NSMutableArray arrayWithCapacity:1] forKey:[NSNumber numberWithInt:ContactsSection]];
    
    [[itemDetails objectForKey:[NSNumber numberWithInt:ContactsSection]] addObject:[NSDictionary
                                                                                     dictionaryWithObjectsAndKeys:
                                                                                     NSLocalizedString(@"Add to Contacts", @""), @"value",
                                                                                     @"details-icon-contact.png", @"image",
                                                                                     @"add_to_contacts", @"key", nil]];
    [[itemDetails objectForKey:[NSNumber numberWithInt:ContactsSection]] addObject:[NSDictionary
                                                                                    dictionaryWithObjectsAndKeys:
                                                                                    NSLocalizedString(@"Add to favorites", nil), @"value",
                                                                                    @"details-icon-favorites.png", @"image",
                                                                                    @"add_to_favorites", @"key", nil]];
    
    // Add contact section if it's not in list yet
    if (NSNotFound == [visibleSections indexOfObject:[NSNumber numberWithInt:ContactsSection]])
        [visibleSections addObject:[NSNumber numberWithInt:ContactsSection]];
    
    [visibleSections sortUsingSelector:@selector(compare:)];
    
    if (!addrParser)
        addrParser = [[WFAddrParser alloc] init];
    labelAddress.text = [addrParser parseStreetAddressForDict:item];

    labelPlace.text = [addrParser parseMunicipality:item];
    
    // And construct footer text
    NSMutableString *tmp = [NSMutableString string];
    NSArray *footerArray = [itemDetails objectForKey:[NSNumber numberWithInt:DescriptionSection]];
    for (NSDictionary *element in footerArray) {
        NSString *value = [[element objectForKey:@"value"] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSString *name = [element objectForKey:@"name"];
        
        if ([[element objectForKey:@"key"] isEqual:@"long_description"])
            name = @"";
        
        [tmp appendFormat:@"%@\n\n", value];        
    }
    if( nil != [[infoItems objectForKey:@"supplier"] objectForKey:@"value"])
        [tmp appendFormat:@"%@: %@\n\n",[[infoItems objectForKey:@"supplier"] objectForKey:@"name"], 
                                        [[infoItems objectForKey:@"supplier"] objectForKey:@"value"]]; 
    if ([tmp length] > 0) {
        descriptionText.frame = CGRectMake(TEXT_MARGIN, TEXT_MARGIN, self.tableView.bounds.size.width - TEXT_MARGIN * 2, 10);
        descriptionText.text = tmp;
        [descriptionText sizeToFit];
        tableFooter.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, descriptionText.frame.size.height + TEXT_MARGIN);        
        self.tableView.tableFooterView = tableFooter;
    }
    
    // Load category icon if item does not have a custom image
    if (!hasCustomImage) {
        // Set correct frame and reorder images
        frameImage.image = [UIImage imageNamed:@"details-photo-frame-empty.png"];
        [tableHeader bringSubviewToFront:displayImage];
        if (nil != [item objectForKey:@"image"] && [[item objectForKey:@"image"] length] > 0) {
            [[WFImageLoader SharedImageLoader] loadImageNamed:[item objectForKey:@"image"] to:displayImage];
        }
        else
            displayImage.image = [UIImage imageNamed:@"placeholder-icon.png"];
    }
    else {
        frameImage.image = [UIImage imageNamed:@"details-photo-frame.png"];
        [tableHeader bringSubviewToFront:frameImage];
    }
    
    self.itemInfo = item;
    [self.tableView reloadData];
    
}

// WFResultModelDelegate methods
- (void) operationFailedWithError:(NSError *)anError
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void) detailsReadyForItem:(NSDictionary *)item
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self initialiseWithItem:item];
    propellerView.hidden = YES;
    self.tableView.userInteractionEnabled = YES;
    self.tableView.showsVerticalScrollIndicator = YES;
    [self.tableView flashScrollIndicators];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [visibleSections count] ? [visibleSections count] : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([visibleSections count] > section) {
        NSNumber *sect = [visibleSections objectAtIndex:section];
        return [[itemDetails objectForKey:sect] count];
    }
    return 0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView 
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}


- (UIView *)tableView:(UITableView *)tableView
    viewForHeaderInSection:(NSInteger)section
{
    if ([visibleSections count] < section + 1)
        return nil;
    NSNumber *sect = [visibleSections objectAtIndex:section];
    UILabel *headerLabel = [[UILabel alloc] init];
    
    switch ([sect intValue]) {
        case AccessSection:
            headerLabel.text = NSLocalizedString(@"Access information", @"");
            break;
        case PriceSection:
            headerLabel.text = NSLocalizedString(@"Price information", @"");
            break;
        case HotelSection:
            headerLabel.text = NSLocalizedString(@"Hotel information", @"");
            break;
        case RestaurantSection:
            headerLabel.text = NSLocalizedString(@"Restaurant information", @"");
            break;
        case SkiSection:
            headerLabel.text = NSLocalizedString(@"Ski Resort information", @"");
            break;
        case InfoSection:
            headerLabel.text = NSLocalizedString(@"Details", @"");
            break;
        default:
            [headerLabel release];
            return nil;
    }

    headerLabel.textAlignment = UITextAlignmentCenter;
    headerLabel.font = [UIFont boldSystemFontOfSize:16];
    headerLabel.backgroundColor = [UIColor clearColor];

    return [headerLabel autorelease];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([visibleSections count] < section + 1)
        return 0;
    NSNumber *sect = [visibleSections objectAtIndex:section];
    
    switch ([sect intValue]) {
        case AccessSection:
        case PriceSection:
        case HotelSection:
        case RestaurantSection:
        case SkiSection:
        case InfoSection:
            // These have title text
            return 35;
            break;
        default:
            return 5;
            break;
    }
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)atableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath  
{
    WFDetailViewCell *defaultCell;
    WFHRSViewCell *HRSCell;
    
    
    static NSString *cellId = @"detailsViewCell";
    static NSString *HRSCellId = @"HRSCellId";
    NSString *bgImageName;
    NSString *activeBgImageName;
    NSNumber *sect = [visibleSections objectAtIndex:indexPath.section];
    NSDictionary *info = [[itemDetails objectForKey:sect] objectAtIndex:indexPath.row];
    
    if([sect intValue] == MapSection && ([[info objectForKey:@"key"] isEqual:@"booking_url"]) || 
                                         ([[info objectForKey:@"key"] isEqual:@"booking_phone_number"]) )
    {
        HRSCell = (WFHRSViewCell *) [atableView dequeueReusableCellWithIdentifier:HRSCellId];
        if (HRSCell == nil) 
        {
            HRSCell = [[[WFHRSViewCell alloc]
                     initWithFrame:CGRectZero reuseIdentifier:HRSCellId] autorelease];
        }
        defaultCell = (WFDetailViewCell *)HRSCell;
    }
    else
    {
        defaultCell = (WFDetailViewCell *)[atableView dequeueReusableCellWithIdentifier:cellId];
        if (defaultCell == nil) 
        {
            defaultCell = [[[WFDetailViewCell alloc]
                     initWithFrame:CGRectZero reuseIdentifier:cellId] autorelease];
        }
    }
   
    
    // Check which image should be used
    if (1 == [[itemDetails objectForKey:sect] count]) {
        // Just one item in list. Used single image.
        bgImageName = [NSString stringWithString:@"list-group-item-background-single.png"];
        activeBgImageName = [NSString stringWithString:@"list-group-item-background-processing-single.png"];
    }
    else {
        // More that one item in list. Determine where is this one.
        if (0 == indexPath.row) {
            // First image in list
            bgImageName = [NSString stringWithString:@"list-group-item-background-top.png"];
            activeBgImageName = [NSString stringWithString:@"list-group-item-background-processing-top.png"];
        }
        else if ([[itemDetails objectForKey:sect] count] == indexPath.row + 1) {
            // Last image in list
            bgImageName = [NSString stringWithString:@"list-group-item-background-bottom.png"];
            activeBgImageName = [NSString stringWithString:@"list-group-item-background-processing-bottom.png"];
        }
        else {
            // Middle item
            bgImageName = [NSString stringWithString:@"list-group-item-background-middle.png"];
            activeBgImageName = [NSString stringWithString:@"list-group-item-background-processing-middle.png"];
        }
    }
    
    UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:bgImageName]];
    defaultCell.backgroundView = bgView;
    [bgView release];
    
    // Only contact and map sections have interactive cells
    if ([sect intValue] == ContactsSection || [sect intValue] == MapSection) {
        UIImageView *aBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:activeBgImageName]];
        defaultCell.selectedBackgroundView = aBgView;
        defaultCell.selectionStyle = UITableViewCellSelectionStyleGray;
        [aBgView release];
    }
    else {
        defaultCell.selectedBackgroundView = nil;
        defaultCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }      
   
    [defaultCell setCell:info forSection:[sect intValue]];    
    return defaultCell;
}


- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    BOOL animated = NO;
    NSNumber *sect = [visibleSections objectAtIndex:indexPath.section];
    NSDictionary *info = [[itemDetails objectForKey:sect]
                          objectAtIndex:indexPath.row];
    
    
    if ([sect intValue] == MapSection && ([info objectForKey:@"key"] == @"show_on_map" )) {
        
        [[WFCommandRouter SharedCommandRouter] showItemOnMap:itemInfo];
        animated = YES;
        
    }
    else if ([sect intValue] == MapSection && ([info objectForKey:@"key"] == @"show_route_car" )) {
        [[WFCommandRouter SharedCommandRouter] showRouteTo:itemInfo routeType:carRoute];
        animated = YES;
    }
    else if ([sect intValue] == MapSection && ([info objectForKey:@"key"] == @"show_route_pedestrian" )) {
        [[WFCommandRouter SharedCommandRouter] showRouteTo:itemInfo routeType:pedestrianRoute];
        animated = YES;
    }
    else if ([info objectForKey:@"href"]) {
        // Remove spaces from string
        [[UIApplication sharedApplication]
         openURL:[NSURL URLWithString:
                  [[info objectForKey:@"href"] stringByReplacingOccurrencesOfString:@" " withString:@""]]];
        animated = YES;
    }
    if ([sect intValue] == ContactsSection && [[info objectForKey:@"key"] isEqual:@"add_to_contacts"]) {
        [[WFCommandRouter SharedCommandRouter] openAddressBookWithData:itemInfo forNavController:self.navigationController];
        animated = YES;
    }
    if ([sect intValue] == ContactsSection && [[info objectForKey:@"key"] isEqual:@"add_to_favorites"]) {
        UIActionSheet *favoriteSheet = [[UIActionSheet alloc] init];
        favoriteSheet.delegate = self;
        addFavoriteButtonNbr = [favoriteSheet addButtonWithTitle:NSLocalizedString(@"Add to favorites", nil)];
        favoriteSheet.cancelButtonIndex = [favoriteSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        
        favoriteSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        
        [favoriteSheet showInView:self.view.window];
        animated = YES;
    }
    
    [atableView deselectRowAtIndexPath:indexPath animated:animated];
}

// UIActionSheetDelegate methods
- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (addFavoriteButtonNbr == buttonIndex) {
        [[WFFavoriteModel SharedFavoriteArray] addFavorite:itemInfo];
    }
    
    [actionSheet release];
}

@end
