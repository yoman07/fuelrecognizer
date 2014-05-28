//
//  RBNSarrayMeanTests.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 03.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSArray+Mean.h"

@interface RBNSarrayMeanTests : XCTestCase

@end

@implementation RBNSarrayMeanTests

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

- (void)testMean
{
    NSArray *numbers = @[@1,@2,@2,@3,@1,@2,@3];
    NSNumber *mean = [numbers mean];
    XCTAssertEqual([mean doubleValue], [@2 doubleValue], @"Wrong mean");
}

@end
