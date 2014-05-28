//
//  RBFilesHelper.h
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 02.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RBFilesHelper : NSObject

+ (NSArray *) readImagesFilesFromMainBundle:(NSBundle*)mainBundle andResourcesBundleName:(NSString*)bundleName;
+ (NSDictionary *) dictionaryContainsImagesDataFromMainBundle:(NSBundle *)mainBundle andResourcesBundleName:(NSString*)bundleName;
+ (NSDictionary *) dictionaryContainsSegmentedReceiptsDataFromMainBundle:(NSBundle *)mainBundle andResourcesBundleName:(NSString*)bundleName andCategorizationJson:(NSString *)categorizationJson;

+ (NSString *) resourceFileNameWithoutExtensionForImage:(UIImage *)image;
+ (void) writeAtEndOfFile:(NSString *)values andFolderName:(NSString *)folderName;
+ (void) saveImage:(UIImage *)image withFileName:(NSString*)fileName andComment:(NSString*)comment;

+ (void) saveOcrText:(NSData *)savedData andFolderName:(NSString*)comment;
+ (NSString *) getWritedStr;
@end
