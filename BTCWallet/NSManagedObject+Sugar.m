//
//  Created by Admin on 9/8/16.
//

#import "NSManagedObject+Sugar.h"
#import <objc/runtime.h>

static const char *_contextKey = "contextKey";
static const char *_storeURLKey = "storeURLKey";

static NSManagedObjectContextConcurrencyType _concurrencyType = NSMainQueueConcurrencyType;
static NSUInteger _fetchBatchSize = 100;

@implementation NSManagedObject (Sugar)

#pragma mark - create objects

+ (instancetype)managedObject
{
    __block NSEntityDescription *entity = nil;
    __block NSManagedObject *obj = nil;
    
    [self.context performBlockAndWait:^{
        entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:self.context];
        obj = [[self alloc] initWithEntity:entity insertIntoManagedObjectContext:self.context];
    }];
    
    return obj;
}

+ (NSArray *)managedObjectArrayWithLength:(NSUInteger)length
{
    __block NSEntityDescription *entity = nil;
    NSMutableArray *a = [NSMutableArray arrayWithCapacity:length];
    
    [self.context performBlockAndWait:^{
        entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:self.context];
        
        for (NSUInteger i = 0; i < length; i++) {
            [a addObject:[[self alloc] initWithEntity:entity insertIntoManagedObjectContext:self.context]];
        }
    }];
    
    return a;
}

#pragma mark - fetch existing objects

+ (NSArray *)allObjects
{
    return [self fetchObjects:self.fetchRequest];
}

+ (NSArray *)objectsMatching:(NSString *)predicateFormat, ...
{
    NSArray *a;
    va_list args;

    va_start(args, predicateFormat);
    a = [self objectsMatching:predicateFormat arguments:args];
    va_end(args);
    return a;
}

+ (NSArray *)objectsMatching:(NSString *)predicateFormat arguments:(va_list)args
{
    NSFetchRequest *request = self.fetchRequest;
    
    request.predicate = [NSPredicate predicateWithFormat:predicateFormat arguments:args];
    return [self fetchObjects:request];
}

+ (NSArray *)objectsSortedBy:(NSString *)key ascending:(BOOL)ascending
{
    return [self objectsSortedBy:key ascending:ascending offset:0 limit:0];
}

+ (NSArray *)objectsSortedBy:(NSString *)key ascending:(BOOL)ascending offset:(NSUInteger)offset limit:(NSUInteger)limit
{
    NSFetchRequest *request = self.fetchRequest;
    
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:key ascending:ascending]];
    request.fetchOffset = offset;
    request.fetchLimit = limit;
    return [self fetchObjects:request];
}

+ (NSArray *)fetchObjects:(NSFetchRequest *)request
{
    __block NSArray *a = nil;
    __block NSError *error = nil;

    [self.context performBlockAndWait:^{
        @try {
            a = [self.context executeFetchRequest:request error:&error];
            if (error) NSLog(@"%s: %@", __func__, error);
        }
        @catch (NSException *exception) {
#if DEBUG
            @throw;
#endif
            // if this is a not a debug build, delete the persisent data store before crashing
            [[NSFileManager defaultManager]
             removeItemAtURL:objc_getAssociatedObject([NSManagedObject class], &_storeURLKey) error:nil];
            @throw;
        }
    }];
     
    return a;
}

#pragma mark - count exising objects

+ (NSUInteger)countAllObjects
{
    return [self countObjects:self.fetchRequest];
}

+ (NSUInteger)countObjectsMatching:(NSString *)predicateFormat, ...
{
    NSUInteger count;
    va_list args;
    
    va_start(args, predicateFormat);
    count = [self countObjectsMatching:predicateFormat arguments:args];
    va_end(args);
    return count;
}

+ (NSUInteger)countObjectsMatching:(NSString *)predicateFormat arguments:(va_list)args
{
    NSFetchRequest *request = self.fetchRequest;
    
    request.predicate = [NSPredicate predicateWithFormat:predicateFormat arguments:args];
    return [self countObjects:request];
}

+ (NSUInteger)countObjects:(NSFetchRequest *)request
{
    __block NSUInteger count = 0;
    __block NSError *error = nil;

    [self.context performBlockAndWait:^{
        @try {
            count = [self.context countForFetchRequest:request error:&error];
            if (error) NSLog(@"%s: %@", __func__, error);
        }
        @catch (NSException *exception) {
#if DEBUG
            @throw;
#endif
            // if this is a not a debug build, delete the persisent data store before crashing
            [[NSFileManager defaultManager]
             removeItemAtURL:objc_getAssociatedObject([NSManagedObject class], &_storeURLKey) error:nil];
            @throw;
        }
    }];
    
    return count;
}

#pragma mark - delete objects

+ (NSUInteger)deleteObjects:(NSArray *)objects
{
    [self.context performBlockAndWait:^{
        for (NSManagedObject *obj in objects) {
            [self.context deleteObject:obj];
        }
    }];
    
    return objects.count;
}

#pragma mark - core data stack

// call this before any NSManagedObject+Sugar methods to use a concurrency type other than NSMainQueueConcurrencyType
+ (void)setConcurrencyType:(NSManagedObjectContextConcurrencyType)type
{
    _concurrencyType = type;
}

// set the fetchBatchSize to use when fetching objects, default is 100
+ (void)setFetchBatchSize:(NSUInteger)fetchBatchSize
{
    _fetchBatchSize = fetchBatchSize;
}

// returns the managed object context for the application, or if the context doesn't already exist, creates it and binds
// it to the persistent store coordinator for the application
+ (NSManagedObjectContext *)context
{
    static dispatch_once_t onceToken = 0;
    
    dispatch_once(&onceToken, ^{
        NSURL *docURL =
            [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
        NSURL *modelURL = [NSBundle.mainBundle URLsForResourcesWithExtension:@"momd" subdirectory:nil].lastObject;
        NSString *projName = modelURL.lastPathComponent.stringByDeletingPathExtension;
        NSURL *storeURL = [[docURL URLByAppendingPathComponent:projName] URLByAppendingPathExtension:@"sqlite"];
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        NSPersistentStoreCoordinator *coordinator =
            [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        NSError *error = nil;
        
        if ([coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL
             options:@{NSMigratePersistentStoresAutomaticallyOption:@(YES),
                       NSInferMappingModelAutomaticallyOption:@(YES)} error:&error] == nil) {
            NSLog(@"%s: %@", __func__, error);
#if DEBUG
            abort();
#endif
            // if this is a not a debug build, attempt to delete and create a new persisent data store before crashing
            if (! [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]) {
                NSLog(@"%s: %@", __func__, error);
            }
            
            if ([coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL
                 options:@{NSMigratePersistentStoresAutomaticallyOption:@(YES),
                           NSInferMappingModelAutomaticallyOption:@(YES)} error:&error] == nil) {
                NSLog(@"%s: %@", __func__, error);
                abort(); // Forsooth, I am slain!
            }
        }

        if (coordinator) {
            NSManagedObjectContext *moc = nil;

            moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            moc.persistentStoreCoordinator = coordinator;

            objc_setAssociatedObject([NSManagedObject class], &_storeURLKey, storeURL,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [NSManagedObject setContext:moc];

            // this will save changes to the persistent store before the application terminates
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil
             queue:nil usingBlock:^(NSNotification *note) {
                [self saveContext];
            }];
        }
    });

    NSManagedObjectContext *context = objc_getAssociatedObject(self, &_contextKey);

    if (! context && self != [NSManagedObject class]) {
        context = [NSManagedObject context];
        [self setContext:context];
    }

    return (context == (id)[NSNull null]) ? nil : context;
}

// sets a different context for NSManagedObject+Sugar methods to use for this type of entity
+ (void)setContext:(NSManagedObjectContext *)context
{
    objc_setAssociatedObject(self, &_contextKey, (context ? context : [NSNull null]),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// persists changes (this is called automatically for the main context when the app terminates)
+ (void)saveContext
{
    if (! self.context.hasChanges) return;
    
    [self.context performBlockAndWait:^{
        if (self.context.hasChanges) {
            @autoreleasepool {
                NSError *error = nil;
                NSUInteger taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];

                // this seems to fix unreleased temporary object IDs
                [self.context obtainPermanentIDsForObjects:self.context.registeredObjects.allObjects error:nil];

                if (! [self.context save:&error]) { // persist changes
                    NSLog(@"%s: %@", __func__, error);
#if DEBUG
                    abort();
#endif
                }
                
                [[UIApplication sharedApplication] endBackgroundTask:taskId];
            }
        }
    }];
}

#pragma mark - entity methods

// override this if entity name differs from class name
+ (NSString *)entityName
{
    return NSStringFromClass([self class]);
}

+ (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:self.entityName];

    request.fetchBatchSize = _fetchBatchSize;
    request.returnsObjectsAsFaults = NO;
    return request;
}

+ (NSFetchedResultsController *)fetchedResultsController:(NSFetchRequest *)request
{
    return [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.context
            sectionNameKeyPath:nil cacheName:nil];
}

// id value = entity[@"key"]; thread safe valueForKey:
- (id)objectForKeyedSubscript:(id<NSCopying>)key
{
    __block id obj = nil;

    [self.managedObjectContext performBlockAndWait:^{
        obj = [self valueForKey:(NSString *)key];
    }];

    return obj;
}

// entity[@"key"] = value; thread safe setValue:forKey:
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    [self.managedObjectContext performBlockAndWait:^{
        [self setValue:obj forKey:(NSString *)key];
    }];
}

- (void)deleteObject
{
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext deleteObject:self];
    }];
}

@end