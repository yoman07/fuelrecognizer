//
//  RBResearchMainClass.h
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 02.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RBResearchMainClass : NSObject

- (void) makeOcrTesting;
- (void) makeSegmentedTesting;
- (void) makeOcrAndSegmentedTesting;
- (NSString *) ocrImage:(UIImage *)ocrImage ;
@end
