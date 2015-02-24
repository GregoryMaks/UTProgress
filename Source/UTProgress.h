////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*

UTProgress.h

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

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Interface

// Serves as copy of Apple NSProgress but with some enhancements and also some minor issues
@interface UTProgress : NSObject

@property (nonatomic, assign) NSUInteger totalUnitCount;
@property (nonatomic, assign) NSUInteger completedUnitCount;

@property (nonatomic, weak) NSString *bubblingMessage; ///< message that bubbles up to root progress bar
@property (nonatomic, weak) NSString *developerBubblingMessage; ///< message intended for dev usage (bubbles up)

/// KVO observable property
@property (nonatomic, assign, readonly) float fractionCompleted;

+ (instancetype)rootProgressWithTotalUnitCount:(NSUInteger)aTotalUnitCount;
+ (instancetype)progressWithParent:(UTProgress *)aParent totalUnitCount:(NSUInteger)aTotalUnitCount;

/// @param aParent can be nil or parent progress set as current prior to calling this method
- (id)initWithParent:(UTProgress *)aParent totalUnitCount:(NSUInteger)aTotalUnitCount;

/// Becomes progress to which child progresses can be added
- (void)becomeCurrentWithPendingUnitCount:(NSUInteger)aPendingUnitCount;
- (void)resignCurrent;

/// Can be called to mark progress as 100% completed
- (void)completeProgress;

@end
