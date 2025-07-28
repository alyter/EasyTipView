//
//  ZCOfflineHandler.h
//  Zoho Creator
//
//  Created by Riyaz Mohammed on 08/07/15.
//  Copyright (c) 2015 Zoho Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "ZohoCreator.h"
//#import "ZCDownloadFileHandler.h"
@class ZCComponent;
@class ZCComponentArray;
@class ZCRecordArray;
//@class ZCOfflineAppList;
//@class ZCApplication;
//@class ZCButton;
//@class ZCField;
//@class ZCForm;
//@class ZCView;
//@class ZCApplicationComponentsArray;

#define OfflineRecordsSubmittingNotification @"offlineRecordsSubmitting"
#define OfflineRecordsSubmittingEndNotification @"offlineRecordsEndSubmitting"
#define SECTION_MCreator @"/section"

#define FORM_STORAGE_FOLDERNAME @"/formStorage"

@interface ZCOfflineHandler : NSObject

+(NSString *)loadZCFormOfflineWithZCComponent:(ZCComponent *)component;

+(void)addUnSyncedRecords:(ZCRecordArray *)recordArray forComponent:(ZCComponent *)comp ;
+(void)saveUnSyncedRecords:(ZCRecordArray *)recordsArray forComponent:(ZCComponent *)comp;
+(void)addOfflineRecords:(ZCRecordArray *)recordsArray forComponent:(ZCComponent *)comp;
+(void)saveOfflineRecords:(ZCRecordArray *)recordsArray forComponent:(ZCComponent *)comp;


//-(NSUInteger )numberOfBulkSubmitEntriesInApp:(ZCApplication *)app;
//-(NSUInteger)numberOfBulkSubmitEntriesInComponent:(ZCComponent *)comp viewLinkName:(NSString *)viewLinkName;
//-(NSUInteger)numberOfUnsyncedBulkSubmitEntriesInComponent:(ZCComponent *)comp viewLinkName:(NSString *)viewLinkName;
//-(NSUInteger )numberOfUnsyncedBulkSubmitEntriesInApp:(ZCApplication *)app;
//+(void)addUnSyncedRecordsForBulkSubmit:(NSArray *)formWithRecordArray forComponent:(ZCComponent *)comp viewLinkName:(NSString *)viewLinkName;
//+(void)saveUnSyncedRecordsForBulkSubmit:(NSArray *)formWithRecordArray forComponent:(ZCComponent *)comp viewLinkName:(NSString *)viewLinkName;
//+(void)addBulkSubmitRecords:(NSArray *)formWithRecordArray forComponent:(ZCComponent *)comp viewLinkName:(NSString *)viewLinkName;
//+(BOOL)saveBulkSubmitRecords:(NSArray *)formWithRecordArray forComponent:(ZCComponent *)comp viewLinkName:(NSString *)viewLinkName;

//+(NSArray *)unsyncedBulkSubmitRecordsArrayForComponent:(ZCComponent *)comp viewLinkName:(NSString *)viewLinkName;
//+(NSArray *)BulkSubmitRecordsArrayForComponent:(ZCComponent *)comp viewLinkName:(NSString *)viewLinkName;


//+(void)initiateOfflineRecordsSubmitForComponentArray:(ZCComponentArray *)compArray numberOfFailedEntries:(completionBlockNumber)numberCompletion completion:(completionBlock)completion;
+(ZCRecordArray *)unsyncedRecordsArrayForComponent:(ZCComponent *)comp;
+(ZCRecordArray *)offlineRecordsArrayForComponent:(ZCComponent *)comp;

+(BOOL)archiveUnSyncedRecords:(ZCRecordArray *)recordsArray forFormComponent:(ZCComponent *)comp;
+(BOOL)archiveOfflineRecords:(ZCRecordArray *)recordsArray forFormComponent:(ZCComponent *)comp;


//+(ZCOfflineAppList *)unSyncedAppList;
//+(ZCOfflineAppList *)offlineAppListForOfflineEntries;

//+(BOOL)archiveUnsyncedAppList:(ZCOfflineAppList *)applist;
//+(BOOL)archiveOfflineAppListForOfflineEntries:(ZCOfflineAppList *)applist;

//+(BOOL)archiveUnsyncedComponentList:(ZCComponentArray *)compArray ForApp:(ZCApplication *)app;
//+(BOOL)archiveOfflineComponentListForOfflineEnries:(ZCComponentArray *)compArray ForApp:(ZCApplication *)app;
//+(ZCComponentArray *)unSyncedComponetListForOfflineFormsForApp:(ZCApplication *)app;
//+(ZCComponentArray *)unSyncedComponetListForApp:(ZCApplication *)app;
//+(ZCComponentArray *)offlineComponentListForApp:(ZCApplication *)app;
//+(ZCComponentArray *)offlineComponetListHavingRecordsForApp:(ZCApplication *)app;

+(NSInteger)unsyncedRecordsCountForComponent:(ZCComponent *)comp;
+(NSInteger)offlineRecordsCountForComponent:(ZCComponent *)comp;

//+(NSInteger)unsyncecRecordsCountForApp:(ZCApplication *)app;
//+(NSInteger)offlineRecordsCount;
//+(NSInteger)offlineRecordsCountForApp:(ZCApplication *)app;
//+(void)storeComponentInOfflineList:(ZCComponent *)componentlocal httpHttpHeader:(NSHTTPURLResponse *)responseToSave;
//+(void)removeComponentInOfflineList:(ZCComponent *)componentlocal;

//+(void)storeComponentInOfflineList;
+(void)deleteOfflineComponents;
//form
//+(BOOL)checkIfOfflineCapable:(ZCForm *)form;
//+(void)submitOfflineWithZCButton:(ZCButton *)button completion:(completionAfterPostWithZCResponseList)completion;


//+(BOOL)saveNewFormInCoreData:(ZCForm *)form;
//+(BOOL)saveModifiedFormInCoreData:(ZCForm *)form;

//+(NSNumber *)lastModifiedTimeOfForm:(ZCComponent *)comp;

//+(BOOL)saveForOffline:(ZCForm *)form;
//+(BOOL )savePageHTMLStringForffline:(NSString *)html component:(ZCComponent *)comp;
//+(BOOL )deletePageFromOffline:(ZCComponent *)comp;
//+(BOOL )deleteFormFromOffline:(ZCForm *)form;
//+(void)syncFormWithFormComponent:(ZCComponent *)comp bulkSubmitForm:(ZCForm *)bulkSubmitForm numberOfFailedEntries:(completionBlockNumber)numberCompletion completion:(completionCompleteBlock)completion;
//+(ZCForm *)loadZCFormOfflineWithZCComponent:(ZCComponent *)component;
//+(NSString *)loadHTMLformOfflineWithZCComponent:(ZCComponent *)component;
//+(ZCForm *)loadZCFormOfflineWithZCView:(ZCView *)zcView;
//+(void)loadLookFieldsDataDiffFor:(ZCForm *)form completion:(completionCompleteBlock)completion;
//+(void)loadFieldsForOffline:(ZCForm *)form completion:(completionCompleteBlock)completion;
//+(ZCApplicationComponentsArray *)offlineAppArrayOfFormComponents;
//+(ZCApplicationComponentsArray *)offlineAppArrayOfPageComponents;
//+(ZCAppList *)applistOfOfflineForms;
//+(ZCAppList *)applistOfOfflinePages;
//View
//+(ZCApplicationComponentsArray *)offlineAppArrayOfViewComponents;

//SectionArray
//+(BOOL)saveZCSection:(ZCSection *)section;
//+(ZCSection *)loadZCSection:(ZCApplication *)app;
//+(BOOL)removeZCSection:(ZCApplication *)app;



//All apps
//
//+(NSInteger)offlineRecordsCountInAllApps;
//+(NSInteger)unsyncedRecordsCountInAppApps;

// Save In Drafts
//+(void) saveInDraftsForForm:(ZCForm *) form completion:(completionAfterSavingFormInDraft) completion;
//+(BOOL) checkIfFormIsInDrafts:(ZCForm *) zcForm;
//+(ZCRecord *) readFromDraftsForForm:(ZCForm *) form;
//+(void) removeFromDraftsForForm:(ZCForm *) zcForm;
//+(void) saveCurrentFormResponse:(ZCForm *) form completion:(completionAfterSavingFormInDraft) completion;


//offline support plan
//+(BOOL)isOfflineSupported:(ZCComponent *)component;
//+(BOOL)alreadyIsOffline:(ZCComponent *)comp;
//+(BOOL)addOfflineEnabledApp:(ZCApplication *)app;
//+(BOOL)removeOfflineEnabledApp:(ZCApplication *)app;



@end




@interface NSString (MD5)

- (NSString *)MD5;

@end

