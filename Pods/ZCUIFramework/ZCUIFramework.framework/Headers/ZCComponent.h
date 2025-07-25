//
//  ZCComponent.h
//  ZohoCreatorFramework
//
//  Created by Solai Murugan on 26/01/14.
//  Copyright (c) 2014 Solai Murugan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import "AutoCoding.h"


//INTERFACE_FOR_ARRAY(ZCComponent, component, Component)
//@interface ZCComponentArray (ExtendedActions)
//
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
//- (void)addComponent:(ZCComponent *)component;
//#pragma clang diagnostic pop
//
//@end
@class ZCApplication;
@class ZCMOComponent;
@class EmbedComponentProperties;
@interface ZCComponent : NSObject


@property (nonatomic, strong) NSString *iconValue;
@property (nonatomic, strong) NSString *appLinkName;
@property (nonatomic, strong) NSString *appOwner;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *componentLinkName;
@property (nonatomic, strong) NSString *componentName;
@property (nonatomic, assign) NSInteger sequenceNumber;
//@property (nonatomic, assign) ComponentType type;
@property (nonatomic, assign) NSInteger iconType;
@property (nonatomic, strong) NSString *calendarDefaultDate;
@property (nonatomic, assign) BOOL isPushNotificationEnabled;
@property (nonatomic, assign) BOOL isStatelessForm;
@property (nonatomic, strong) NSString *queryString;
@property (nonatomic,assign) NSInteger iAppType;
@property (nonatomic,strong) NSMutableDictionary *headerDictionary;
//@property (nonatomic,strong) ZCOpenUrlTask *navigationURLTask;

//Map

@property (nonatomic, assign) BOOL isCustomLocation;
@property (nonatomic, assign) NSInteger mapRadius;
@property (nonatomic, assign) NSInteger mapUnits;
@property (nonatomic, assign) CGFloat latitude;
@property (nonatomic, assign) CGFloat longitude;

//Recent Component Property

@property (nonatomic,strong) NSDate *recentDate;
//@property (nonatomic,assign) ZCThemeColor componentAppThemeColor;
//@property (nonatomic,assign) ZCThemeColor componentThemeColor;

//MCreator
@property (nonatomic, strong) NSString *componentId;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *iconLocation;
@property (nonatomic, strong) NSString *iconSize;
@property (nonatomic, strong) NSString *pageId;
@property (nonatomic, assign) BOOL isHidden;

@property (nonatomic,assign) long long lastModified;
@property (nonatomic,assign) bool offlineEnabled;

//@property (nonatomic,assign) CalendarType calendarType;

@property (nonatomic,assign) NSInteger componentIndex; //Index of component in section for open URL


//Open Url edit record
//@property (nonatomic, strong) ZCRecord * recordToEdit;
@property (nonatomic, assign) BOOL isOpenURLComponent;

//download
@property (nonatomic, strong) NSDate  *downloadTimeKey;

@property (nonatomic, assign) NSRange downloadRange;


// Private Link
@property (nonatomic, strong) NSString *privateKey;
@property (nonatomic, assign) BOOL isEmbedInPage;

//Page
//@property (nonatomic, strong) NSString *formSuccessMeaage;
//@property (nonatomic, strong) NSString *formRedirectionURL;
//@property (nonatomic, assign) BOOL shouldShowFormHeader;



-(id)initWithLinkname:(NSString*)linkName appLinkname:(NSString*)appLinkname andAppOwner:(NSString*)appOwner;

@end
