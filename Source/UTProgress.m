////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*

UTProgress.m

The MIT License (MIT)

Copyright (c) 2014 Gregory Maksyuk (GregoryMaks)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Imports

#import "UTProgress.h"
#import "UTProgressGroup.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Constants

static void * kUTProgressKVOContext = &kUTProgressKVOContext;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Private interface

@interface UTProgress ()
{
    NSUInteger _totalUnitCount;
    NSUInteger _completedUnitCount;
}

@property (nonatomic, strong) UTProgress *parent;
@property (nonatomic, strong) NSMutableArray *groups;

@property (nonatomic, assign) BOOL isCurrent;
@property (nonatomic, strong) UTProgressGroup *currentGroup;

@property (nonatomic, assign) float fractionCompleted;

- (void)recalculateFractionCompleted;

- (void)addChild:(UTProgress *)aChildProgress;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Implementation

@implementation UTProgress

- (NSUInteger)totalUnitCount
{
    @synchronized(self)
    {
        return _totalUnitCount;
    }
}
- (void)setTotalUnitCount:(NSUInteger)totalUnitCount
{
    @synchronized(self)
    {
        if (totalUnitCount != _totalUnitCount)
        {
            _totalUnitCount = totalUnitCount;
            [self recalculateFractionCompleted];
        }
    }
}

- (NSUInteger)completedUnitCount
{
    @synchronized(self)
    {
        return _completedUnitCount;
    }
}
- (void)setCompletedUnitCount:(NSUInteger)completedUnitCount
{
    @synchronized(self)
    {
        if (completedUnitCount != _completedUnitCount)
        {
            _completedUnitCount = completedUnitCount;
            [self recalculateFractionCompleted];
        }
    }
}

+ (instancetype)rootProgressWithTotalUnitCount:(NSUInteger)aTotalUnitCount
{
    return [[[self class] alloc] initWithParent:nil totalUnitCount:aTotalUnitCount];
}

+ (instancetype)progressWithParent:(UTProgress *)aParent totalUnitCount:(NSUInteger)aTotalUnitCount
{
    return [[[self class] alloc] initWithParent:aParent totalUnitCount:aTotalUnitCount];
}

- (id)initWithParent:(UTProgress *)aParent totalUnitCount:(NSUInteger)aTotalUnitCount
{
    if (self = [super init])
    {
        self.groups = [NSMutableArray array];
        self.isCurrent = NO;
        
        if (aParent != nil)
        {
            if (!aParent.isCurrent)
            {
                [NSException raise:@"Logic" format:@"Parent progress should be made current before adding children.\
Use [parent becomeCurrentWithPendingUnitCount]."];
            }
            
            self.parent = aParent;
            [self.parent addChild:self];
        }
        
        self.totalUnitCount = aTotalUnitCount;
    }
    return self;
}

- (void)dealloc
{
    for (UTProgressGroup *group in self.groups)
    {
        for (UTProgress *child in group.children)
        {
            @try
            {
                [child removeObserver:self forKeyPath:@"fractionCompleted" context:kUTProgressKVOContext];
                [child removeObserver:self forKeyPath:@"bubblingMessage" context:kUTProgressKVOContext];
                [child removeObserver:self forKeyPath:@"developerBubblingMessage" context:kUTProgressKVOContext];
            }
            @catch (NSException *exception) {}
        }
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Progress %p - <fractionCompleted: %.2f | completedUnits: %lu | totalUnits: %lu>",
            self,
            self.fractionCompleted,
            (unsigned long)self.completedUnitCount,
            (unsigned long)self.totalUnitCount];
}

- (void)becomeCurrentWithPendingUnitCount:(NSUInteger)aPendingUnitCount
{
    self.isCurrent = YES;
    
    // Create new group to add children to
    self.currentGroup = [[UTProgressGroup alloc] init];
    self.currentGroup.pendingUnitCount = aPendingUnitCount;
    [self.groups addObject:self.currentGroup];
}

- (void)resignCurrent
{
    self.isCurrent = NO;
    
    self.currentGroup = nil;
}

- (void)completeProgress
{
    [self.groups removeAllObjects];
    self.completedUnitCount = self.totalUnitCount;
    [self recalculateFractionCompleted];
}

#pragma mark -
#pragma mark Private methods

- (void)addChild:(UTProgress *)aChildProgress
{
    if (!self.isCurrent || self.currentGroup == nil)
    {
        NSAssert(NO, @"");
        return;
    }
    
    [self.currentGroup.children addObject:aChildProgress];
    
    [aChildProgress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:kUTProgressKVOContext];
    [aChildProgress addObserver:self forKeyPath:@"bubblingMessage" options:NSKeyValueObservingOptionNew context:kUTProgressKVOContext];
    [aChildProgress addObserver:self forKeyPath:@"developerBubblingMessage" options:NSKeyValueObservingOptionNew context:kUTProgressKVOContext];
}

- (void)recalculateFractionCompleted
{
    float fractionPerUnit = 1.0f / self.totalUnitCount;
    
    float groupFractionsSum = 0;  // holds summary of all fractions from all groups (will be (group_pending_units / total_units) * valid_group_count if 100% completed)
    
    NSUInteger totalGroupUnits = 0;
    if (self.groups.count > 0)
    {
        for (UTProgressGroup *group in self.groups)
        {
            if (group.children.count != 0)  // check only valid groups
            {
                totalGroupUnits += group.pendingUnitCount;
            }
        }
        
        for (UTProgressGroup *group in self.groups)
        {
            if (group.children.count != 0)  // check only valid groups
            {
                float childFractionSum = 0;   // holds summary of all children fractions (will be 1.0 * child_count if 100% completed)
                for (UTProgress *child in group.children)
                {
                    childFractionSum += [child fractionCompleted];
                }
                
                float fractionPerGroup = fractionPerUnit * (float)group.pendingUnitCount;
                groupFractionsSum += fractionPerGroup * (childFractionSum / (float)group.children.count);
            }
        }
    }
    
    self.fractionCompleted = (fractionPerUnit * self.completedUnitCount) +
        ((self.groups.count == 0) ? 0 : groupFractionsSum);
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BOOL handled = NO;
    if (context == kUTProgressKVOContext)
    {
        if ([keyPath isEqual:@"fractionCompleted"])
        {
            handled = YES;
            [self recalculateFractionCompleted];
        }
        else if ([keyPath isEqual:@"bubblingMessage"])
        {
            handled = YES;
            self.bubblingMessage = [object bubblingMessage];
        }
        else if ([keyPath isEqual:@"developerBubblingMessage"])
        {
            handled = YES;
            self.developerBubblingMessage = [object developerBubblingMessage];
        }
    }
    
    if (!handled)
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
