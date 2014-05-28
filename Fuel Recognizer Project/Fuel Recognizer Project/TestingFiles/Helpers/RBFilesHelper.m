//
//  RBFilesHelper.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 02.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import "RBFilesHelper.h"
#import "RBFuelModel.h"

@implementation RBFilesHelper

+ (NSArray *) readImagesFilesFromMainBundle:(NSBundle*)mainBundle andResourcesBundleName:(NSString*)bundleName {
    NSArray *filesList = [self pathsForFilesFromMainBundle:mainBundle andResourcesBundleName:bundleName];
    NSMutableArray *imagesList = [[NSMutableArray alloc] initWithCapacity:filesList.count];
    [filesList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        UIImage *image = [UIImage imageWithContentsOfFile:obj];
        if(image != nil) {
            [imagesList addObject:image];
        }
    }];
    
    
    return imagesList;
}

+ (NSString *) resourcePathFromMainBundle:(NSBundle*)mainBundle andResourcesBundleName:(NSString*)bundleName {
    return [NSString stringWithFormat:@"%@/%@.bundle",[mainBundle resourcePath],bundleName];
}

+ (NSArray *) pathsForFilesFromMainBundle:(NSBundle*)mainBundle andResourcesBundleName:(NSString*)bundleName {
    NSString *resourcePath = [self resourcePathFromMainBundle:mainBundle andResourcesBundleName:bundleName];
    
    
    NSError *readFilesError;
    NSArray *filesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:&readFilesError];
    NSMutableArray *filesListFullPath = [[NSMutableArray alloc] initWithCapacity:filesList.count];
    [filesList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *imagePath = [NSString stringWithFormat:@"%@/%@", resourcePath, obj];
        [filesListFullPath addObject:imagePath];
    }];
    return filesListFullPath;
}

+ (NSDictionary *) dictionaryContainsSegmentedReceiptsDataFromMainBundle:(NSBundle *)mainBundle andResourcesBundleName:(NSString*)bundleName andCategorizationJson:(NSString *)categorizationJson {
    
    NSString *resourcePath = [self resourcePathFromMainBundle:mainBundle andResourcesBundleName:bundleName];
    NSString *jsonFile = [NSString stringWithFormat:@"%@/%@.json",resourcePath,categorizationJson];
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:NULL];
    
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    NSDictionary *myDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    
    NSMutableDictionary *fuelDictionary = [[NSMutableDictionary alloc] initWithCapacity:myDictionary.count];
    
    myDictionary = [myDictionary objectForKey:@"receipts"];
    [myDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSDictionary *receiptDictionary = obj;
        NSAssert([receiptDictionary isKindOfClass:[NSDictionary class]], @"Wrong class");
        RBFuelModel *fuelModel = [[RBFuelModel alloc] initWithDictionary:receiptDictionary ];
        NSAssert([fuelModel isKindOfClass:[RBFuelModel class]], @"Wrong class");
        [fuelDictionary setObject:fuelModel forKey:key];
    }];
    
    if(!myDictionary) {
        NSLog(@"%@",error);
    }
    else {
        //Do Something
        NSLog(@"%@", myDictionary);
    }
    
    return fuelDictionary;
}
+ (NSDictionary *) dictionaryContainsImagesDataFromMainBundle:(NSBundle *)mainBundle andResourcesBundleName:(NSString*)bundleName {
    NSString *resourcePath = [self resourcePathFromMainBundle:mainBundle andResourcesBundleName:bundleName];
    NSString *jsonFile = [NSString stringWithFormat:@"%@/%@.json",resourcePath,bundleName];
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:NULL];
    
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    NSDictionary *myDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    if(!myDictionary) {
        NSLog(@"%@",error);
    }
    else {
        //Do Something
        NSLog(@"%@", myDictionary);
    }

    return myDictionary;
}

+ (NSString *) resourceFileNameWithoutExtensionForImage:(UIImage *)image {
    NSString *imagePath = image.accessibilityIdentifier;
    NSString *fileName = [[[[imagePath componentsSeparatedByString:@"/"] lastObject] componentsSeparatedByString:@"."] firstObject];
    return fileName;
}

+ (void)writeAtEndOfFile:(NSString *)values andFolderName:(NSString *)folderName;
{
//    NSString *noWhiteSpaces = [folderName stringByReplacingOccurrencesOfString:@" " withString:@""];
//    
//    NSString *path = [[self applicationDocumentsDirectory].path
//                      stringByAppendingPathComponent:noWhiteSpaces];
//    
//    NSError * error = nil;
//    [[NSFileManager defaultManager] createDirectoryAtPath:path
//                              withIntermediateDirectories:YES
//                                               attributes:nil
//                                                    error:&error];
//    if (error != nil) {
//        NSLog(@"error creating directory: %@", error);
//        //..
//    }
//    
//    
//   path = [path stringByAppendingPathComponent:@"results.txt"];
//    
    NSString *path = [[self applicationDocumentsDirectory].path
                      stringByAppendingPathComponent:@"results.txt"];

    NSString *writedStr = [self getWritedStr];
    
    
    
    NSString *content = [NSString stringWithFormat:@"%@%@ ,%@\n",writedStr, folderName,values];

    
    [content writeToFile:path atomically:YES
                   encoding:NSUTF8StringEncoding error:nil];
    
   

}

+ (void) saveOcrText:(NSData *)savedData andFolderName:(NSString*)comment{
    NSString *noWhiteSpaces = [comment stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *path = [[self applicationDocumentsDirectory].path
                      stringByAppendingPathComponent:noWhiteSpaces];
    
    NSError * error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error != nil) {
        NSLog(@"error creating directory: %@", error);
        //..
    }
    
    
    path = [path stringByAppendingPathComponent:@"ocrResults.txt"];
    

    [savedData writeToFile:path atomically:YES];

}

+ (NSString *) getWritedStr {
    NSString *path = [[self applicationDocumentsDirectory].path
                      stringByAppendingPathComponent:@"results.txt"];
    NSString *writedStr = @"";
    if([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        [fileHandle seekToEndOfFile];
        writedStr = [[NSString alloc]initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    }
    
    return writedStr;
}

/**
 Returns the URL to the application's Documents directory.
 */
+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}



+ (void) saveImage:(UIImage *)image withFileName:(NSString*)fileName andComment:(NSString*)comment{
    
    NSString *noWhiteSpaces = [comment stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *path = [[self applicationDocumentsDirectory].path
                      stringByAppendingPathComponent:noWhiteSpaces];
    
    NSError * error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error != nil) {
        NSLog(@"error creating directory: %@", error);
        //..
    }
    
    
    path = [path stringByAppendingPathComponent:fileName];
    
    // Convert UIImage object into NSData (a wrapper for a stream of bytes) formatted according to PNG spec
    NSData *imageData = UIImagePNGRepresentation(image);
//    
//    NSString *path = [[self applicationDocumentsDirectory].path
//                      stringByAppendingPathComponent:fileName];
//    
    [imageData writeToFile:path atomically:YES];
}

@end
