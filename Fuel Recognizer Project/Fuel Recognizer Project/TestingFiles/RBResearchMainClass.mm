//
//  RBResearchMainClass.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 02.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import "RBResearchMainClass.h"
#import "RBFilesHelper.h"
#import "NSString+Score.h"
#import "RBProcessImageHelper.h"
#import <TesseractOCR/TesseractOCR.h>
#import "UIImage+Tesseract.h"
#import "NSArray+Mean.h"
#import "ImageFilter.h"
#import "ImageProcessingImplementation.h"
#import "NSArray+Combinatory.h"
#import "UIImage+OpenCV.h"
#import "ImageProcessingImplementation.h"
#include <stdexcept>
#import "RBFuelModel.h"
#import "ReceiptModel.h"
#import "RBFuelModel+Comparing.h"

@interface RBResearchMainClass ()
@property (nonatomic,strong) Tesseract *tesseract;
@property (nonatomic,strong) id <ImageProcessingProtocol> imageProcessor;
@property (nonatomic, strong) NSArray *filtersArray;
@property (nonatomic, strong) NSArray *extractDataMethods;


@end

typedef cv::Mat (^MatBlock)(cv::Mat res);


@implementation RBResearchMainClass

//mat = thresholdImage(mat);
//
//mat = findContoursAndCrop(mat);
//mat = calculateAndRotateAngle(mat, mat);
//mat = findBoxes(mat, mat);

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"pol"];
        self.imageProcessor = [ImageProcessingImplementation new];
        self.filtersArray = @[
                             ^(cv::Mat mat){
                                 mat = greyscale(mat);
                                 return mat;
                             },
                              ^(cv::Mat mat){
                                  mat = thresholdImage(mat);
                                  return mat;
                              },
                              ^(cv::Mat mat){
                                  mat = findContoursAndCrop(mat);
                                  return mat;
                              },
//
                              ^(cv::Mat mat){ // I swipe this after test
                                  mat = findContoursAndCrop(mat);
                                  mat = findBoxes(mat, mat);
                                  return mat;
                              },
                              ^(cv::Mat mat){
                                  mat = calculateAndRotateAngle(mat, mat);
                                  return mat;
                              }
                             ];
    }
    return self;
}

- (NSString *) ocrImage:(UIImage *)ocrImage {
    __block cv::Mat Img = [ocrImage CVMat];
    self.tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"pol"];

    [self.filtersArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        Img = ((MatBlock)obj)(Img); // invoke the correct block of code
    }];
    
    
    UIImage *image = [self.imageProcessor imageWithCVMat:Img];
    NSString *ocrText = [image ocrWithTesseract:self.tesseract];
    [self.tesseract clear];
    return ocrText;
}

- (void) makeOcrAndSegmentedTesting {

    NSString *folderName = @"ocr_segm";

    @autoreleasepool{
        
        NSDictionary *avarage = [self scoresForFilesInMainBundle:[NSBundle bundleForClass:[self class]] andResourcesBundleName:@"SampleReceipts" andForResources:@"receipts" andFilters:self.filtersArray];
        
        NSString *values = [NSString stringWithFormat:@"%@,%@,%@", [avarage objectForKey:@"time"], [avarage objectForKey:@"score"], [avarage objectForKey:@"categorization_score"]];
        
        
        
        
        NSDictionary *textAfterOcr = [avarage objectForKey:@"textAfterOcr"];
        
        NSError *error = nil;
        NSData *json1= [ NSJSONSerialization dataWithJSONObject :textAfterOcr options:NSJSONWritingPrettyPrinted error:&error];
        //
        //                    NSString* newStr = [[NSString alloc] initWithData:json1 encoding:NSUTF8StringEncoding];
        
        if(error == nil){
            [RBFilesHelper saveOcrText:json1 andFolderName:folderName];
        }
        [RBFilesHelper writeAtEndOfFile:values andFolderName:folderName];
        
    }
    

}

- (BOOL) canTesting:(NSArray *)filters {
    __block BOOL canTesting = YES;
    __block NSString *folderName = @"";
    [filters enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSInteger indexInArray = [self.filtersArray indexOfObject:obj];
        
        if(indexInArray == 2 || indexInArray == 3 || indexInArray == 4) {
            if([folderName rangeOfString:@"1"].location == NSNotFound) {
                canTesting = NO;
                *stop = YES;
            }
        }
        
        if(indexInArray == 1) {
            if([folderName rangeOfString:@"0"].location == NSNotFound) {
                canTesting = NO;
                *stop = YES;
            }
        }
        
        folderName = [NSString stringWithFormat:@"%@%d", folderName, indexInArray];
    }];
    
    
    return canTesting;
}

- (void) makeSegmentedTesting {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]] ;
    NSString *resourcesBundleName = @"SampleReceipts";
    NSDictionary *dict = [RBFilesHelper dictionaryContainsImagesDataFromMainBundle:[NSBundle bundleForClass:[self class]] andResourcesBundleName:resourcesBundleName];
    NSDictionary *receipts = [dict objectForKey:@"receipts"];
    
    NSDictionary *categorizationDictionary = [RBFilesHelper dictionaryContainsSegmentedReceiptsDataFromMainBundle:bundle andResourcesBundleName:resourcesBundleName andCategorizationJson:@"AfterCategorization"];

    NSMutableArray *categorizationArray = [[NSMutableArray alloc] init];
    
    [receipts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *receiptTxt = obj;
        NSString *fileName = key;
        
        RBFuelModel *fuelModel = [categorizationDictionary objectForKey:fileName];
        
        ReceiptModel *receiptModel = [[ReceiptModel alloc] initWithOcrString:receiptTxt];
        CGFloat categorizationScore = [fuelModel scoreModels:receiptModel];
        
        [categorizationArray addObject:@(categorizationScore)];
    }];
    
    NSString *values = [NSString stringWithFormat:@"%@", [categorizationArray mean]];

    [RBFilesHelper writeAtEndOfFile:values andFolderName:@"categorization"];


}

- (void) makeOcrTesting {

    NSString *writedStr = [RBFilesHelper getWritedStr];

    NSArray *allCombinations = [self.filtersArray allCombinations];
    
    [allCombinations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *arr = obj;
        NSAssert([arr isKindOfClass:[NSArray class]], @"wrong class");
        
        
        [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSArray *arr2 = obj;
            NSAssert([arr2 isKindOfClass:[NSArray class]], @"wrong class");
            
            
            NSString *filtersNameStr = [self getFiltersName:arr2];
            if ([self canTesting:arr2] && [writedStr rangeOfString:filtersNameStr].location == NSNotFound) {
                @autoreleasepool{
                    
                    NSLog(@"Testing values %@", filtersNameStr);
                    NSDictionary *avarage = [self scoresForFilesInMainBundle:[NSBundle bundleForClass:[self class]] andResourcesBundleName:@"SampleReceipts" andForResources:@"receipts" andFilters:arr2];
                    
                    NSString *values = [NSString stringWithFormat:@"%@,%@,%@", [avarage objectForKey:@"time"], [avarage objectForKey:@"score"], [avarage objectForKey:@"categorization_score"]];
                    
                    
                    
                    NSString *folderName = [avarage objectForKey:@"folderName"];
                    
                    NSDictionary *textAfterOcr = [avarage objectForKey:@"textAfterOcr"];

                    NSError *error = nil;
                    NSData *json1= [ NSJSONSerialization dataWithJSONObject :textAfterOcr options:NSJSONWritingPrettyPrinted error:&error];
//
//                    NSString* newStr = [[NSString alloc] initWithData:json1 encoding:NSUTF8StringEncoding];

                    if(error == nil){
                        [RBFilesHelper saveOcrText:json1 andFolderName:folderName];
                    }
                    [RBFilesHelper writeAtEndOfFile:values andFolderName:folderName];
                    
                }

            }
            else {
                NSLog(@"exists %@", filtersNameStr);
            }
            

            
        }];
        

    }];
}

- (NSString *) getFiltersName:(NSArray *)filters {
    __block NSString *folderName = @"";
    [filters enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSInteger indexInArray = [self.filtersArray indexOfObject:obj];
        
            folderName = [NSString stringWithFormat:@"%@%d", folderName, indexInArray];
    }];
    return folderName;

}

- (NSDictionary *) scoresForFilesInMainBundle:(NSBundle *)bundle andResourcesBundleName:(NSString*)resourcesBundleName andForResources:(NSString*)resourcesName andFilters:(NSArray *)filters {
    
    NSString *onlyImage = nil;//;@"5";//@"1";
    
    NSArray *images = [RBFilesHelper readImagesFilesFromMainBundle:bundle andResourcesBundleName:resourcesBundleName];
    NSDictionary *dict = [RBFilesHelper dictionaryContainsImagesDataFromMainBundle:bundle andResourcesBundleName:resourcesBundleName];
    
    NSDictionary *receipts = [dict objectForKey:resourcesName];
    
    NSMutableArray *scoreArray = [[NSMutableArray alloc] initWithCapacity:images.count];
    NSMutableArray *timeArray = [[NSMutableArray alloc] initWithCapacity:images.count];

    NSMutableArray *categorizationArray = [[NSMutableArray alloc] initWithCapacity:images.count];

    
    __block Tesseract *tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"pol"];
    
    
    NSDictionary *categorizationDictionary = [RBFilesHelper dictionaryContainsSegmentedReceiptsDataFromMainBundle:bundle andResourcesBundleName:resourcesBundleName andCategorizationJson:@"AfterCategorization"];
    
 

    __block NSString *filtersName = [self getFiltersName:filters];
    
    NSMutableDictionary *textsAfterOcr = [[NSMutableDictionary alloc] init];
    
    [images enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"pol"];

        __block UIImage *image = (UIImage *)obj;

        NSString *fileName = [RBFilesHelper resourceFileNameWithoutExtensionForImage:image];

        
        if(onlyImage == nil || [fileName isEqualToString:onlyImage]) {
            NSDate *methodStart = [NSDate date];
            
            
            
            __block cv::Mat Img = [image CVMat];
            
            [filters enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                Img = ((MatBlock)obj)(Img); // invoke the correct block of code
            }];
            
            
            image = [self.imageProcessor imageWithCVMat:Img];
            
            
            [RBFilesHelper saveImage:image withFileName:fileName andComment:filtersName];
            [tesseract setImage:image];
            NSString *ocrText = [image ocrWithTesseract:tesseract];
            
            
            RBFuelModel *fuelModel = [categorizationDictionary objectForKey:fileName];
            
            
            
            ReceiptModel *receiptModel = [[ReceiptModel alloc] initWithOcrString:ocrText];
            CGFloat categorizationScore = [fuelModel scoreModels:receiptModel];
            
            
            
            
            [categorizationArray addObject:@(categorizationScore)];
            NSString *jsonText = [receipts objectForKey:fileName];
            
            CGFloat scores = [jsonText scoreAgainst:ocrText fuzziness:@(0.8)];
            [scoreArray addObject:@(scores)];
            NSLog(@"FileName %@ score %f categorizationScore %f", fileName, scores, categorizationScore);
            NSLog(@"recognized text %@", ocrText);
            
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            NSLog(@"execution time %f", executionTime);
            [timeArray addObject:@(executionTime)];
            [textsAfterOcr setObject:ocrText forKey:fileName];
            
            [tesseract clear];

        }
        
        
    }];
    
    

    

    return @{@"score": [scoreArray mean], @"time": [timeArray mean], @"folderName" : filtersName, @"textAfterOcr":textsAfterOcr ,@"categorization_score" : [categorizationArray mean]};
}




@end
