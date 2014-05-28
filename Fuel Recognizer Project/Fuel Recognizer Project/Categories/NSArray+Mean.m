//
//  NSArray+Mean.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 03.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import "NSArray+Mean.h"

@implementation NSArray (Mean)

- (NSNumber *)mean
{
    double runningTotal = 0.0;
    
    for(NSNumber *number in self)
    {
        runningTotal += [number doubleValue];
    }
    
    return @(runningTotal/self.count);
}

@end
