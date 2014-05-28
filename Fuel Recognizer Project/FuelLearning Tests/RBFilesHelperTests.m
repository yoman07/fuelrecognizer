//
//  RBFilesHelperTests.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 02.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RBFilesHelper.h"

@interface RBFilesHelperTests : XCTestCase

@end

@implementation RBFilesHelperTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testReadFiles
{
    NSArray *files = [RBFilesHelper readImagesFilesFromMainBundle:[NSBundle bundleForClass:[self class]] andResourcesBundleName:@"ReceiptsTests"];
    XCTAssertEqual(files.count, 4, @"Files should contain 4 files");
}

- (void) testFilesAreImages {
    NSArray *files = [RBFilesHelper readImagesFilesFromMainBundle:[NSBundle bundleForClass:[self class]] andResourcesBundleName:@"ReceiptsTests"];

    [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        XCTAssertTrue([obj isKindOfClass:[UIImage class]], @"All files should be images");
    }];
}

- (void) testDataDictionary {
    NSDictionary *filesDictionary = [RBFilesHelper dictionaryContainsImagesDataFromMainBundle:[NSBundle bundleForClass:[self class]] andResourcesBundleName:@"ReceiptsTests"];
    
    NSDictionary *receiptsDictionary = [filesDictionary objectForKey:@"receipts"];

    
    NSString *stringFor1file = [receiptsDictionary objectForKey:@"1"];
    NSString *stringFor2file = [receiptsDictionary objectForKey:@"2"];
    NSString *stringFor3file = [receiptsDictionary objectForKey:@"3"];
    NSString *stringFor4file = [receiptsDictionary objectForKey:@"4"];
    
    XCTAssertNotNil(stringFor1file, @"problem with read string");
    XCTAssertNotNil(stringFor2file, @"problem with read string");
    XCTAssertNotNil(stringFor3file, @"problem with read string");
    XCTAssertNotNil(stringFor4file, @"problem with read string");
}

- (void) testCompareDataFile {
    
    
    NSString *jsonForFile1 =
@"Beskidus Sp. z o.o\n\
Zembrzyce 663\n\
34-210 Zembrzyce\n\
Stacja Paliw BP (802)\n\
NIP 552-158-63-76\n\
2013-11-17 nr wydr. 180214\n\
PARAGON FISKALNY\n\
BEZOLOW 95 18,631 x 5,37 zł 100,04 A\n\
1p\n\
Sprzed. opod. PTU A 100,04\n\
Kwota A 23,00% 18,71\n\
Podatek PTU 18,71\n\
SUMA PLN 100,04\n\
3ELoS-o2JTY-YTNDD-3TX4G-M6CoB\n\
BAE 09234983\n\
Karta Bankowa 100,04\n\
Nr transakcji 4175";
    NSDictionary *filesDictionary = [RBFilesHelper dictionaryContainsImagesDataFromMainBundle:[NSBundle bundleForClass:[self class]] andResourcesBundleName:@"ReceiptsTests"];
    
    NSDictionary *receiptsDictionary = [filesDictionary objectForKey:@"receipts"];
    
    
    NSString *stringFor1file = [receiptsDictionary objectForKey:@"2"];
    
    XCTAssertEqualObjects(stringFor1file, jsonForFile1, @"Problem with parse data");
    
}

- (void) testGetResourceFileName {
    NSArray *files = [RBFilesHelper readImagesFilesFromMainBundle:[NSBundle bundleForClass:[self class]] andResourcesBundleName:@"ReceiptsTests"];
    UIImage *image = files[0];
    
    NSString *imageName = [RBFilesHelper resourceFileNameWithoutExtensionForImage:image];
    
    XCTAssertEqualObjects(imageName, @"1", @"Filename should be the same");
}


@end
