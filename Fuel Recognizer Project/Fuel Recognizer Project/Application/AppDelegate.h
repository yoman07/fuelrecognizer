//
//  G8AppDelegate.h
//  Template Framework Project
//
//  Created by Daniele on 14/10/13.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

/**
 *  This is handler for window
 */
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator ;
-(NSArray*)getAllReceipts;
@end
