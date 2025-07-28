//
//  ZCOfflineMigrations.h
//  Migrations
//
//  Created by Vigneshkumar G on 14/01/19.
//  Copyright © 2019 viki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZCComponent.h"

@class ZCRecord;
@class ZCRecordArray;

typedef enum : NSUInteger {
    OfflineEntries,
    FailedEntries
} OfflineMode;


NS_ASSUME_NONNULL_BEGIN

@interface ZCOfflineMigrations : NSObject

+(NSArray<NSDictionary<NSString*,id>*>*)offineRecordDictArrayForReport:(ZCComponent*)component;
+(NSArray<NSDictionary<NSString*,id>*>*)unsyncedRecordDictArrayForReport:(ZCComponent*)component;

+ (ZCRecordArray*)offlineRecordsForReport:(ZCComponent*)component;
+ (ZCRecordArray*)unsyncedRecordsForReport:(ZCComponent*)component;


@end

NS_ASSUME_NONNULL_END
