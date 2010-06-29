// vim: set ft=objc:

static NSString *searchDescReplyString = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\" ?><!DOCTYPE isab-mc2><isab-mc2> \
   <search_desc_reply crc=\"50ad6465\" length=\"4\" transaction_id=\"id282475249\"> \
      <search_hit_type heading=\"0\" round=\"0\"> \
         <name>Places</name> \
         <image_name>search_heading_places</image_name> \
      </search_hit_type> \
      <search_hit_type heading=\"1\" round=\"0\"> \
         <name>Addresses</name> \
         <image_name>search_heading_addresses</image_name> \
      </search_hit_type> \
      <search_hit_type heading=\"2\" round=\"1\"> \
         <name>Eniro Personer</name> \
         <top_region_id>1</top_region_id> \
         <image_name>search_heading_eniro_wo_text</image_name> \
      </search_hit_type> \
      <search_hit_type heading=\"3\" round=\"1\"> \
         <name>Eniro Företag</name> \
         <top_region_id>1</top_region_id> \
         <image_name>search_heading_eniro_wo_text</image_name> \
      </search_hit_type> \
   </search_desc_reply> \
</isab-mc2>";


static NSString *searchReplyString = @"<?xml version=\"1.0\" encoding=\"utf-8\" ?> <!DOCTYPE isab-mc2> <isab-mc2> \
    <compact_search_reply transaction_id=\"id1144108930\"> \
        <search_hit_list numberitems=\"3\" ending_index=\"2\" starting_index=\"0\" total_numberitems=\"3\" heading=\"0\"> \
            <search_item image=\"tat_petrolstation\" search_item_type=\"pointofinterest\"> \
                <name>Espoo/Otaniemi, Miestentie 1</name> \
                <itemid>c:70002902:37:0:E</itemid> \
                <location_name>Tapiola, Espoo</location_name> \
                <lat>717965973</lat> \
                <lon>296173547</lon> \
                <search_area search_area_type=\"city\"> \
                    <name>Tapiola</name> \
                    <areaid>b:1F:37:0:B</areaid> \
                    <search_area search_area_type=\"municipal\"> \
                        <name>Espoo</name> \
                        <areaid>a:2:37:0:1</areaid> \
                    </search_area> \
                </search_area> \
            </search_item> \
            <search_item image=\"tat_petrolstation\" search_item_type=\"pointofinterest\"> \
                <name>Espoo/Otaniemi, Miestentie 1</name> \
                <itemid>c:70002A67:37:0:E</itemid> \
                <location_name>Tapiola, Espoo</location_name> \
                <lat>717965973</lat> \
                <lon>296173547</lon> \
                <search_area search_area_type=\"city\"> \
                    <name>Tapiola</name> \
                    <areaid>b:1F:37:0:B</areaid> \
                    <search_area search_area_type=\"municipal\"> \
                        <name>Espoo</name> \
                        <areaid>a:2:37:0:1</areaid> \
                    </search_area> \
                </search_area> \
            </search_item> \
            <search_item image=\"search_heading_places\" search_item_type=\"pointofinterest\"> \
                <name>Otaniemi, Luolamiehentie</name> \
                <itemid>c:70002A42:37:0:E</itemid> \
                <location_name>Tapiola, Espoo</location_name> \
                <lat>718030190</lat> \
                <lon>296258681</lon> \
                <search_area search_area_type=\"city\"> \
                    <name>Tapiola</name> \
                    <areaid>b:1F:37:0:B</areaid> \
                    <search_area search_area_type=\"municipal\"> \
                        <name>Espoo</name> \
                        <areaid>a:2:37:0:1</areaid> \
                    </search_area> \
                </search_area> \
            </search_item> \
        </search_hit_list> \
        <search_hit_list numberitems=\"0\" ending_index=\"0\" starting_index=\"-1\" total_numberitems=\"0\" heading=\"1\"/> \
    </compact_search_reply> \
</isab-mc2>";

static NSString *searchReplyString_1 = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\" ?><!DOCTYPE isab-mc2><isab-mc2> \
   <compact_search_reply transaction_id=\"id1458777923\"> \
      <ad_results_text>Sponsored results</ad_results_text> \
      <all_results_text>All results</all_results_text> \
      <search_hit_list ending_index=\"8\" heading=\"4\" numberitems=\"9\" starting_index=\"0\" total_numberitems=\"9\"> \
         <ad_results_text>Sponsored results</ad_results_text> \
         <all_results_text>All results</all_results_text> \
         <search_item image=\"search_heading_eniro_wo_text\" search_item_type=\"pointofinterest\"> \
            <name>Taksi/ L√§hitaksi</name> \
            <itemid>Xc:2AD2D9C2:11B62E3D:0:E:31868:7</itemid> \
            <location_name>Nuijamiestentie 7 C, HELSINKI</location_name> \
            <lat>718461378</lat> \
            <lon>297152061</lon> \
         </search_item> \
         <search_item image=\"search_heading_eniro_wo_text\" search_item_type=\"pointofinterest\"> \
            <name>Terveystalo Espoo Ty√∂terveys Otaniemi</name> \
            <itemid>Xc:2ACD1C4E:11A77A21:0:E:75511:7</itemid> \
            <location_name>S√§hk√∂miehentie 3, ESPOO</location_name> \
            <lat>718085198</lat> \
            <lon>296188449</lon> \
         </search_item> \
         <search_item image=\"search_heading_eniro_wo_text\" search_item_type=\"pointofinterest\"> \
            <name>Alepa Otaniemi</name> \
            <itemid>Xc:2ACC8230:11A8706E:0:E:164590:7</itemid> \
            <location_name>Otakaari 11, ESPOO</location_name> \
            <lat>718045744</lat> \
            <lon>296251502</lon> \
         </search_item> \
         <search_item image=\"search_heading_eniro_wo_text\" search_item_type=\"pointofinterest\"> \
            <name>Apteekki Otaniemi</name> \
            <itemid>Xc:7FFFFFFF:7FFFFFFF:0:E:32285:7</itemid> \
            <location_name>Otakaari 13, ESPOO</location_name> \
         </search_item> \
         <search_item image=\"search_heading_eniro_wo_text\" search_item_type=\"pointofinterest\"> \
            <name>K-extra Otaniemi</name> \
            <itemid>Xc:2ACC8230:11A8706E:0:E:140074:7</itemid> \
            <location_name>Otakaari 11, ESPOO</location_name> \
            <lat>718045744</lat> \
            <lon>296251502</lon> \
         </search_item> \
         <search_item image=\"search_heading_eniro_wo_text\" search_item_type=\"pointofinterest\"> \
            <name>Otaniemen Asuntos√§√§ti√∂</name> \
            <itemid>Xc:2ACC40FD:11A84180:0:E:147289:7</itemid> \
            <location_name>Otakaari 11, ESPOO</location_name> \
            <lat>718029053</lat> \
            <lon>296239488</lon> \
         </search_item> \
         <search_item image=\"search_heading_eniro_wo_text\" search_item_type=\"pointofinterest\"> \
            <name>Otaniemen kehitys Oy / Otaniemi Marketing</name> \
            <itemid>Xc:7FFFFFFF:7FFFFFFF:0:E:179779:7</itemid> \
            <location_name>Innopoli 2, Tekniikantie 14,  </location_name> \
         </search_item> \
         <search_item image=\"search_heading_eniro_wo_text\" search_item_type=\"pointofinterest\"> \
            <name>Taksiasema Otaniemi</name> \
            <itemid>Xc:7FFFFFFF:7FFFFFFF:0:E:31858:7</itemid> \
            <location_name>Dipoli, ESPOO</location_name> \
         </search_item> \
         <search_item image=\"search_heading_eniro_wo_text\" search_item_type=\"pointofinterest\"> \
            <name>Yliopistokirjakauppa Otaniemi</name> \
            <itemid>Xc:2ACC8230:11A8706E:0:E:144139:7</itemid> \
            <location_name>Otakaari 11, ESPOO</location_name> \
            <lat>718045744</lat> \
            <lon>296251502</lon> \
         </search_item> \
      </search_hit_list> \
   </compact_search_reply> \
</isab-mc2>";

static NSString *catListReplyString = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\" ?><!DOCTYPE isab-mc2><isab-mc2> \
   <category_list_reply count=\"4\" crc=\"662a90c5\" transaction_id=\"id282475249\"> \
      <cat cat_id=\"152\"> \
         <name>ATM</name> \
         <image_name>tat_atm</image_name> \
      </cat> \
      <cat cat_id=\"18\"> \
         <name>Airport</name> \
         <image_name>tat_airport</image_name> \
      </cat> \
      <cat cat_id=\"151\"> \
         <name>Bank</name> \
         <image_name>tat_bank</image_name> \
      </cat> \
      <cat cat_id=\"76\"> \
         <name>Car dealer</name> \
         <image_name></image_name> \
      </cat> \
   </category_list_reply> \
</isab-mc2>";

static NSString *catReplyString = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\" ?><!DOCTYPE isab-mc2><isab-mc2> \
   <compact_search_reply transaction_id=\"id1622650073\"> \
      <ad_results_text>Sponsored results</ad_results_text> \
      <all_results_text>All results</all_results_text> \
      <search_hit_list ending_index=\"2\" heading=\"0\" numberitems=\"3\" starting_index=\"0\" total_numberitems=\"3\"> \
         <ad_results_text>Sponsored results</ad_results_text> \
         <all_results_text>All results</all_results_text> \
         <search_item image=\"tat_airport\" search_item_type=\"pointofinterest\"> \
            <name>Helsinki-Malmin lentoasema, Malmin Lentoasema</name> \
            <itemid>c:700031DE:37:0:E</itemid> \
            <lat>718830142</lat> \
            <lon>298764031</lon> \
         </search_item> \
         <search_item image=\"tat_airport\" search_item_type=\"pointofinterest\"> \
            <name>Helsinki-Vantaan lentoasema, Lentoasemantie</name> \
            <itemid>c:70002C26:37:0:E</itemid> \
            <lat>719696390</lat> \
            <lon>297889234</lon> \
         </search_item> \
         <search_item image=\"tat_airport\" search_item_type=\"pointofinterest\"> \
            <name>Lappeenrannan lentoasema, Lentokentäntie 21</name> \
            <itemid>c:70001ECF:38:0:E</itemid> \
            <lat>728284334</lat> \
            <lon>335919386</lon> \
         </search_item> \
      </search_hit_list> \
      <search_hit_list ending_index=\"0\" heading=\"1\" numberitems=\"0\" starting_index=\"-1\" total_numberitems=\"0\"/> \
   </compact_search_reply> \
</isab-mc2>";

static NSString *catSearchReplyString = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\" ?><!DOCTYPE isab-mc2><isab-mc2> \
   <compact_search_reply transaction_id=\"id1622650073\"> \
      <ad_results_text>Sponsored results</ad_results_text> \
      <all_results_text>All results</all_results_text> \
      <search_hit_list ending_index=\"0\" heading=\"0\" numberitems=\"1\" starting_index=\"0\" total_numberitems=\"1\"> \
         <ad_results_text>Sponsored results</ad_results_text> \
         <all_results_text>All results</all_results_text> \
         <search_item image=\"search_heading_eniro_wo_text\" search_item_type=\"pointofinterest\"> \
            <name>Ye Olde Airport</name> \
            <itemid>c:6666:66:0:E</itemid> \
            <lat>718830142</lat> \
            <lon>298764031</lon> \
         </search_item> \
      </search_hit_list> \
      <search_hit_list ending_index=\"0\" heading=\"1\" numberitems=\"0\" starting_index=\"-1\" total_numberitems=\"0\"/> \
   </compact_search_reply> \
</isab-mc2>";

static NSString *mapReplyString =
@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\" ?>"
"<!DOCTYPE isab-mc2>"
"<isab-mc2><map_reply><href>"
"<![CDATA[Map.png?lla=717873657&llo=297556052&ula=717835782&ulo=297503083&w=320&h=460&s=22496&r=&mt=std&is=%FF%FC%02&map=1&topomap=1&poi=1&route=1&scale=0&traffic=0]]>"
"</href></map_reply></isab-mc2>";

static NSString *poiDetailReplyString =
@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\" ?> \
<!DOCTYPE isab-mc2><isab-mc2> \
   <poi_info_reply transaction_id=\"id74243042\"> \
      <info_item numberfields=\"5\"> \
         <typeName></typeName> \
         <itemName>Vaskifysio Oy</itemName> \
         <lat>733526274</lat> \
         <lon>283439173</lon> \
         <info_field info_type=\"vis_address\"> \
            <fieldName>Address</fieldName> \
            <fieldValue>Hatanp√§√§n puistokuja 22 C 60</fieldValue> \
         </info_field> \
         <info_field info_type=\"vis_zip_code\"> \
            <fieldName>Zip Code</fieldName> \
            <fieldValue>33900</fieldValue> \
         </info_field> \
         <info_field info_type=\"vis_zip_area\"> \
            <fieldName>City</fieldName> \
            <fieldValue>TAMPERE</fieldValue> \
         </info_field> \
         <info_field info_type=\"supplier\"> \
            <fieldName>Supplier</fieldName> \
            <fieldValue>Eniro</fieldValue> \
         </info_field> \
         <info_field info_type=\"phone_number\"> \
            <fieldName>Phone Number</fieldName> \
            <fieldValue>+358331340360</fieldValue> \
         </info_field> \
      </info_item> \
   </poi_info_reply> \
</isab-mc2>";

static NSString *searchPositionDescReplyString =
@"<?xml version=\"1.0\" encoding=\"utf-8\" ?> \
<!DOCTYPE isab-mc2><isab-mc2> \
    <search_position_desc_reply transaction_id=\"id1855127939\" length=\"1\"> \
        <top_region top_region_type=\"country\"> \
            <top_region_id>4</top_region_id> \
            <boundingbox east_lon=\"31.58671193\" position_sytem=\"WGS84Deg\" south_lat=\"59.67527395\" north_lat=\"70.09222409\" west_lon=\"19.16868442\"/> \
            <name_node language=\"finnish\">Suomi</name_node> \
        </top_region> \
        <search_hit_type round=\"1\" heading=\"4\"> \
            <name>Eniro Keltaiset Sivut</name> \
            <image_name>search_heading_eniro_wo_text</image_name> \
        </search_hit_type> \
    </search_position_desc_reply> \
</isab-mc2>";

static NSString *poiDetailErrorReplyString =
@"<?xml version=\"1.0\" encoding=\"utf-8\" ?> \
<!DOCTYPE isab-mc2><isab-mc2> \
    <poi_info_reply transaction_id=\"id1535179371\"> \
        <status_code>-1</status_code> \
        <status_message>Connection failed to database.</status_message> \
    </poi_info_reply> \
</isab-mc2>";

static NSString *routeReplyString =
@"<?xml version=\"1.0\" encoding=\"utf-8\" ?> \
<!DOCTYPE isab-mc2><isab-mc2> \
    <route_reply ptui=\"5\" transaction_id=\"id941991384\" route_id=\"D0CA_49670ABA\"> \
        <route_reply_header> \
            <total_distance>Kokonaismatka 2.2km</total_distance> \
            <total_distance_nbr>2223</total_distance_nbr> \
            <total_time>Aika 0:05:00</total_time> \
            <total_time_nbr>300</total_time_nbr> \
            <total_standstilltime>Pysähdyksiin kulunut aika 0:00:10</total_standstilltime> \
            <total_standstilltime_nbr>10</total_standstilltime_nbr> \
            <average_speed>Keskinopeus 26 km/t</average_speed> \
            <average_speed_nbr>7.410000</average_speed_nbr> \
            <routing_vehicle>henkilöauto</routing_vehicle> \
            <routing_vehicle_type>passengercar</routing_vehicle_type> \
            <boundingbox east_lon=\"296222165\" position_sytem=\"MC2\" south_lat=\"717908818\" north_lat=\"718061246\" west_lon=\"295877946\"/> \
        </route_reply_header> \
        <route_origin> \
            <search_item search_item_type=\"street\"> \
                <name>Tekniikantie</name> \
                <itemid>s:2800078A:37:0:8</itemid> \
            </search_item> \
        </route_origin> \
        <route_destination> \
            <search_item search_item_type=\"street\"> \
                <name>Tapiontori</name> \
                <itemid>s:30001B7B:37:0:8</itemid> \
            </search_item> \
        </route_destination> \
        <route_reply_items> \
            <route_reply_item> \
                <description>Lähde liikkeelle parittomat katunumerot vasemmalla, parilliset oikealla (K) paikasta nimeltä Tekniikantie (Teknikvägen)</description> \
            </route_reply_item> \
            <route_reply_item> \
                <description>1.9km --> Tapionaukio</description> \
            </route_reply_item> \
            <route_reply_item> \
                <description>270m pysäköi Tapiontori (Tapiotorget)</description> \
            </route_reply_item> \
            <route_reply_item> \
                <description>--> Tapiontori (Tapiotorget)</description> \
            </route_reply_item> \
            <route_reply_item> \
                <description>85m pysähdy Tapiontori (Tapiotorget)</description> \
            </route_reply_item> \
        </route_reply_items> \
    </route_reply> \
</isab-mc2>";


/* A 5x5 PNG */
static char imageData[] = {
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x0a, 0x00, 0x00, 0x00, 0x0a,
    0x04, 0x03, 0x00, 0x00, 0x00, 0x7f, 0x1c, 0xd2, 0x8e, 0x00, 0x00, 0x00,
    0x30, 0x50, 0x4c, 0x54, 0x45, 0xff, 0xb1, 0x4f, 0xfb, 0xb3, 0x57, 0xfe,
    0xb2, 0x52, 0xfc, 0xb2, 0x55, 0xff, 0xb4, 0x57, 0xfc, 0xb4, 0x59, 0xf1,
    0xb9, 0x72, 0xf0, 0xbb, 0x74, 0xfb, 0xbf, 0x71, 0xf2, 0xc0, 0x7a, 0xfa,
    0xc5, 0x7f, 0xa2, 0xc6, 0x9c, 0xbc, 0xdb, 0xef, 0xc9, 0xdb, 0xc1, 0xe0,
    0xd6, 0xc6, 0xef, 0xef, 0xe6, 0x3a, 0x03, 0x85, 0xbf, 0x00, 0x00, 0x00,
    0x09, 0x70, 0x48, 0x59, 0x73, 0x00, 0x00, 0x0b, 0x12, 0x00, 0x00, 0x0b,
    0x12, 0x01, 0xd2, 0xdd, 0x7e, 0xfc, 0x00, 0x00, 0x00, 0x25, 0x49, 0x44,
    0x41, 0x54, 0x08, 0xd7, 0x63, 0x78, 0x2e, 0x7d, 0xe7, 0xcc, 0x19, 0x86,
    0x97, 0x2a, 0x6f, 0x80, 0x64, 0xb0, 0x08, 0x88, 0x64, 0xd0, 0xf8, 0x03,
    0x24, 0x97, 0xd9, 0x83, 0xd8, 0x67, 0x40, 0x00, 0x17, 0x09, 0x00, 0xff,
    0x3a, 0x24, 0x04, 0x7d, 0x1b, 0xd4, 0xa7, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
};
