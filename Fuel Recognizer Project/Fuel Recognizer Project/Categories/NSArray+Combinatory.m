//
//  NSArray+Combinatory.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 09.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import "NSArray+Combinatory.h"

@implementation NSArray (Combinatory)


- (NSArray *) permutations:(NSArray *)array {
    NSMutableArray *permutations = nil;
    
    int i = 0;
    for (i = 0; i < array.count ; i++){
        
        if (!permutations){
            permutations = [NSMutableArray array];
            for (NSString *character in array){
                [permutations addObject:[NSArray arrayWithObject:character]];
            }
            
        } else {
            
            //make copy of permutations array and clean og array
            NSMutableArray *aCopy = [permutations copy] ;
            [permutations removeAllObjects];
            
            for (NSString *character in array){
                
                //loop through the copy
                for (NSArray *oldArray in aCopy){
                    
                    //check if old string contains looping char..
                    if ([oldArray containsObject:character] == NO){
                        
                        //update array
                        NSMutableArray *newArray = [NSMutableArray arrayWithArray:oldArray];
                        [newArray addObject:character];
                        
                        //add to permutations
                        [permutations addObject:newArray];
                        
                    }
                    
                }
            }
        }
        
        
        
    }
    return permutations;
}

- (NSArray *) allCombinations {
    NSMutableArray *allCombinations = [[NSMutableArray alloc] init];
    NSArray *powerset = [self powerSet:self];
    [powerset enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *arr = obj;
        if (arr.count > 0) {
            [allCombinations addObject:[self permutations:arr]];
        }
    }];
    return allCombinations;
}

- (NSArray *) permutationsSelf {
    return [self permutations:self];
}

- (NSArray *)powerSelf {
    return [self powerSet:self];
}

// answer the powerset of array: an array of all possible subarrays of the passed array
- (NSArray *)powerSet:(NSArray *)array {
    
    NSInteger length = array.count;
    if (length == 0) return [NSArray arrayWithObject:[NSArray array]];
    
    // get an object from the array and the array without that object
    id lastObject = [array lastObject];
    NSArray *arrayLessOne = [array subarrayWithRange:NSMakeRange(0,length-1)];
    
    // compute the powerset of the array without that object
    // recursion makes me happy
    NSArray *powerSetLessOne = [self powerSet:arrayLessOne];
    
    // powerset is the union of the powerSetLessOne and powerSetLessOne where
    // each element is unioned with the removed element
    NSMutableArray *powerset = [NSMutableArray arrayWithArray:powerSetLessOne];
    
    // add the removed object to every element of the recursive power set
    for (NSArray *lessOneElement in powerSetLessOne) {
        [powerset addObject:[lessOneElement arrayByAddingObject:lastObject]];
    }
    return [NSArray arrayWithArray:powerset];
}


@end
