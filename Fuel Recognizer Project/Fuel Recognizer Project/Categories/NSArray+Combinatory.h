//
//  NSArray+Combinatory.h
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 09.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Combinatory)

- (NSArray *)powerSelf;
- (NSArray *) permutationsSelf;
- (NSArray *) allCombinations;

@end
