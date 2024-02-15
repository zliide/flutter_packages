// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import LocalAuthentication;
@import XCTest;
@import local_auth_darwin;

#import <OCMock/OCMock.h>

// Set a long timeout to avoid flake due to slow CI.
static const NSTimeInterval kTimeout = 30.0;

/**
 * A context factory that returns preset contexts.
 */
@interface StubAuthContextFactory : NSObject <FLADAuthContextFactory>
@property(copy, nonatomic) NSMutableArray *contexts;
- (instancetype)initWithContexts:(NSArray *)contexts;
@end

@implementation StubAuthContextFactory

- (instancetype)initWithContexts:(NSArray *)contexts {
  self = [super init];
  if (self) {
    _contexts = [contexts mutableCopy];
  }
  return self;
}

- (LAContext *)createAuthContext {
  NSAssert(self.contexts.count > 0, @"Insufficient test contexts provided");
  LAContext *context = [self.contexts firstObject];
  [self.contexts removeObjectAtIndex:0];
  return context;
}

@end

#pragma mark -

@interface FLALocalAuthPluginTests : XCTestCase
@end

@implementation FLALocalAuthPluginTests

- (void)setUp {
  self.continueAfterFailure = NO;
}

- (void)testSuccessfullAuthWithBiometrics {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
  FLADAuthStrings *strings = [self createAuthStrings];
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);

  // evaluatePolicy:localizedReason:reply: calls back on an internal queue, which is not
  // guaranteed to be on the main thread. Ensure that's handled correctly by calling back on
  // a background thread.
  void (^backgroundThreadReplyCaller)(NSInvocation *) = ^(NSInvocation *invocation) {
    void (^reply)(BOOL, NSError *);
    [invocation getArgument:&reply atIndex:4];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
      reply(YES, nil);
    });
  };
  OCMStub([mockAuthContext evaluatePolicy:policy localizedReason:strings.reason reply:[OCMArg any]])
      .andDo(backgroundThreadReplyCaller);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Result is called"];
  [plugin authenticateWithOptions:[FLADAuthOptions makeWithBiometricOnly:YES
                                                                  sticky:NO
                                                         useErrorDialogs:NO]
                          strings:strings
                       completion:^(FLADAuthResultDetails *_Nullable resultDetails,
                                    FlutterError *_Nullable error) {
                         XCTAssertTrue([NSThread isMainThread]);
                         XCTAssertEqual(resultDetails.result, FLADAuthResultSuccess);
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];
  [self waitForExpectationsWithTimeout:kTimeout handler:nil];
}

- (void)testSuccessfullAuthWithoutBiometrics {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthentication;
  FLADAuthStrings *strings = [self createAuthStrings];
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);

  // evaluatePolicy:localizedReason:reply: calls back on an internal queue, which is not
  // guaranteed to be on the main thread. Ensure that's handled correctly by calling back on
  // a background thread.
  void (^backgroundThreadReplyCaller)(NSInvocation *) = ^(NSInvocation *invocation) {
    void (^reply)(BOOL, NSError *);
    [invocation getArgument:&reply atIndex:4];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
      reply(YES, nil);
    });
  };
  OCMStub([mockAuthContext evaluatePolicy:policy localizedReason:strings.reason reply:[OCMArg any]])
      .andDo(backgroundThreadReplyCaller);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Result is called"];
  [plugin authenticateWithOptions:[FLADAuthOptions makeWithBiometricOnly:NO
                                                                  sticky:NO
                                                         useErrorDialogs:NO]
                          strings:strings
                       completion:^(FLADAuthResultDetails *_Nullable resultDetails,
                                    FlutterError *_Nullable error) {
                         XCTAssertTrue([NSThread isMainThread]);
                         XCTAssertEqual(resultDetails.result, FLADAuthResultSuccess);
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];
  [self waitForExpectationsWithTimeout:kTimeout handler:nil];
}

- (void)testFailedAuthWithBiometrics {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
  FLADAuthStrings *strings = [self createAuthStrings];
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);

  // evaluatePolicy:localizedReason:reply: calls back on an internal queue, which is not
  // guaranteed to be on the main thread. Ensure that's handled correctly by calling back on
  // a background thread.
  void (^backgroundThreadReplyCaller)(NSInvocation *) = ^(NSInvocation *invocation) {
    void (^reply)(BOOL, NSError *);
    [invocation getArgument:&reply atIndex:4];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
      reply(NO, [NSError errorWithDomain:@"error" code:LAErrorAuthenticationFailed userInfo:nil]);
    });
  };
  OCMStub([mockAuthContext evaluatePolicy:policy localizedReason:strings.reason reply:[OCMArg any]])
      .andDo(backgroundThreadReplyCaller);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Result is called"];
  [plugin authenticateWithOptions:[FLADAuthOptions makeWithBiometricOnly:YES
                                                                  sticky:NO
                                                         useErrorDialogs:NO]
                          strings:strings
                       completion:^(FLADAuthResultDetails *_Nullable resultDetails,
                                    FlutterError *_Nullable error) {
                         XCTAssertTrue([NSThread isMainThread]);
                         // TODO(stuartmorgan): Fix this; this was the pre-Pigeon-migration
                         // behavior, so is preserved as part of the migration, but a failed
                         // authentication should return failure, not an error that results in a
                         // PlatformException.
                         XCTAssertEqual(resultDetails.result, FLADAuthResultErrorNotAvailable);
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];
  [self waitForExpectationsWithTimeout:kTimeout handler:nil];
}

- (void)testFailedWithUnknownErrorCode {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthentication;
  FLADAuthStrings *strings = [self createAuthStrings];
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);

  // evaluatePolicy:localizedReason:reply: calls back on an internal queue, which is not
  // guaranteed to be on the main thread. Ensure that's handled correctly by calling back on
  // a background thread.
  void (^backgroundThreadReplyCaller)(NSInvocation *) = ^(NSInvocation *invocation) {
    void (^reply)(BOOL, NSError *);
    [invocation getArgument:&reply atIndex:4];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
      reply(NO, [NSError errorWithDomain:@"error" code:99 userInfo:nil]);
    });
  };
  OCMStub([mockAuthContext evaluatePolicy:policy localizedReason:strings.reason reply:[OCMArg any]])
      .andDo(backgroundThreadReplyCaller);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Result is called"];
  [plugin authenticateWithOptions:[FLADAuthOptions makeWithBiometricOnly:NO
                                                                  sticky:NO
                                                         useErrorDialogs:NO]
                          strings:strings
                       completion:^(FLADAuthResultDetails *_Nullable resultDetails,
                                    FlutterError *_Nullable error) {
                         XCTAssertTrue([NSThread isMainThread]);
                         XCTAssertEqual(resultDetails.result, FLADAuthResultErrorNotAvailable);
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];
  [self waitForExpectationsWithTimeout:kTimeout handler:nil];
}

- (void)testSystemCancelledWithoutStickyAuth {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthentication;
  FLADAuthStrings *strings = [self createAuthStrings];
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);

  // evaluatePolicy:localizedReason:reply: calls back on an internal queue, which is not
  // guaranteed to be on the main thread. Ensure that's handled correctly by calling back on
  // a background thread.
  void (^backgroundThreadReplyCaller)(NSInvocation *) = ^(NSInvocation *invocation) {
    void (^reply)(BOOL, NSError *);
    [invocation getArgument:&reply atIndex:4];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
      reply(NO, [NSError errorWithDomain:@"error" code:LAErrorSystemCancel userInfo:nil]);
    });
  };
  OCMStub([mockAuthContext evaluatePolicy:policy localizedReason:strings.reason reply:[OCMArg any]])
      .andDo(backgroundThreadReplyCaller);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Result is called"];
  [plugin authenticateWithOptions:[FLADAuthOptions makeWithBiometricOnly:NO
                                                                  sticky:NO
                                                         useErrorDialogs:NO]
                          strings:strings
                       completion:^(FLADAuthResultDetails *_Nullable resultDetails,
                                    FlutterError *_Nullable error) {
                         XCTAssertTrue([NSThread isMainThread]);
                         XCTAssertEqual(resultDetails.result, FLADAuthResultFailure);
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];
  [self waitForExpectationsWithTimeout:kTimeout handler:nil];
}

- (void)testFailedAuthWithoutBiometrics {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthentication;
  FLADAuthStrings *strings = [self createAuthStrings];
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);

  // evaluatePolicy:localizedReason:reply: calls back on an internal queue, which is not
  // guaranteed to be on the main thread. Ensure that's handled correctly by calling back on
  // a background thread.
  void (^backgroundThreadReplyCaller)(NSInvocation *) = ^(NSInvocation *invocation) {
    void (^reply)(BOOL, NSError *);
    [invocation getArgument:&reply atIndex:4];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
      reply(NO, [NSError errorWithDomain:@"error" code:LAErrorAuthenticationFailed userInfo:nil]);
    });
  };
  OCMStub([mockAuthContext evaluatePolicy:policy localizedReason:strings.reason reply:[OCMArg any]])
      .andDo(backgroundThreadReplyCaller);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Result is called"];
  [plugin authenticateWithOptions:[FLADAuthOptions makeWithBiometricOnly:NO
                                                                  sticky:NO
                                                         useErrorDialogs:NO]
                          strings:strings
                       completion:^(FLADAuthResultDetails *_Nullable resultDetails,
                                    FlutterError *_Nullable error) {
                         XCTAssertTrue([NSThread isMainThread]);
                         // TODO(stuartmorgan): Fix this; this was the pre-Pigeon-migration
                         // behavior, so is preserved as part of the migration, but a failed
                         // authentication should return failure, not an error that results in a
                         // PlatformException.
                         XCTAssertEqual(resultDetails.result, FLADAuthResultErrorNotAvailable);
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];
  [self waitForExpectationsWithTimeout:kTimeout handler:nil];
}

- (void)testLocalizedFallbackTitle {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthentication;
  FLADAuthStrings *strings = [self createAuthStrings];
  strings.localizedFallbackTitle = @"a title";
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);

  // evaluatePolicy:localizedReason:reply: calls back on an internal queue, which is not
  // guaranteed to be on the main thread. Ensure that's handled correctly by calling back on
  // a background thread.
  void (^backgroundThreadReplyCaller)(NSInvocation *) = ^(NSInvocation *invocation) {
    void (^reply)(BOOL, NSError *);
    [invocation getArgument:&reply atIndex:4];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
      reply(YES, nil);
    });
  };
  OCMStub([mockAuthContext evaluatePolicy:policy localizedReason:strings.reason reply:[OCMArg any]])
      .andDo(backgroundThreadReplyCaller);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Result is called"];
  [plugin authenticateWithOptions:[FLADAuthOptions makeWithBiometricOnly:NO
                                                                  sticky:NO
                                                         useErrorDialogs:NO]
                          strings:strings
                       completion:^(FLADAuthResultDetails *_Nullable resultDetails,
                                    FlutterError *_Nullable error) {
                         OCMVerify([mockAuthContext
                             setLocalizedFallbackTitle:strings.localizedFallbackTitle]);
                         [expectation fulfill];
                       }];
  [self waitForExpectationsWithTimeout:kTimeout handler:nil];
}

- (void)testSkippedLocalizedFallbackTitle {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthentication;
  FLADAuthStrings *strings = [self createAuthStrings];
  strings.localizedFallbackTitle = nil;
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);

  // evaluatePolicy:localizedReason:reply: calls back on an internal queue, which is not
  // guaranteed to be on the main thread. Ensure that's handled correctly by calling back on
  // a background thread.
  void (^backgroundThreadReplyCaller)(NSInvocation *) = ^(NSInvocation *invocation) {
    void (^reply)(BOOL, NSError *);
    [invocation getArgument:&reply atIndex:4];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
      reply(YES, nil);
    });
  };
  OCMStub([mockAuthContext evaluatePolicy:policy localizedReason:strings.reason reply:[OCMArg any]])
      .andDo(backgroundThreadReplyCaller);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Result is called"];
  [plugin authenticateWithOptions:[FLADAuthOptions makeWithBiometricOnly:NO
                                                                  sticky:NO
                                                         useErrorDialogs:NO]
                          strings:strings
                       completion:^(FLADAuthResultDetails *_Nullable resultDetails,
                                    FlutterError *_Nullable error) {
                         OCMVerify([mockAuthContext setLocalizedFallbackTitle:nil]);
                         [expectation fulfill];
                       }];
  [self waitForExpectationsWithTimeout:kTimeout handler:nil];
}

- (void)testDeviceSupportsBiometrics_withEnrolledHardware {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);

  FlutterError *error;
  NSNumber *result = [plugin deviceCanSupportBiometricsWithError:&error];
  XCTAssertTrue([result boolValue]);
  XCTAssertNil(error);
}

- (void)testDeviceSupportsBiometrics_withNonEnrolledHardware {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
  void (^canEvaluatePolicyHandler)(NSInvocation *) = ^(NSInvocation *invocation) {
    // Write error
    NSError *__autoreleasing *authError;
    [invocation getArgument:&authError atIndex:3];
    *authError = [NSError errorWithDomain:@"error" code:LAErrorBiometryNotEnrolled userInfo:nil];
    // Write return value
    BOOL returnValue = NO;
    NSValue *nsReturnValue = [NSValue valueWithBytes:&returnValue objCType:@encode(BOOL)];
    [invocation setReturnValue:&nsReturnValue];
  };
  OCMStub([mockAuthContext canEvaluatePolicy:policy
                                       error:(NSError * __autoreleasing *)[OCMArg anyPointer]])
      .andDo(canEvaluatePolicyHandler);

  FlutterError *error;
  NSNumber *result = [plugin deviceCanSupportBiometricsWithError:&error];
  XCTAssertTrue([result boolValue]);
  XCTAssertNil(error);
}

- (void)testDeviceSupportsBiometrics_withNoBiometricHardware {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
  void (^canEvaluatePolicyHandler)(NSInvocation *) = ^(NSInvocation *invocation) {
    // Write error
    NSError *__autoreleasing *authError;
    [invocation getArgument:&authError atIndex:3];
    *authError = [NSError errorWithDomain:@"error" code:0 userInfo:nil];
    // Write return value
    BOOL returnValue = NO;
    NSValue *nsReturnValue = [NSValue valueWithBytes:&returnValue objCType:@encode(BOOL)];
    [invocation setReturnValue:&nsReturnValue];
  };
  OCMStub([mockAuthContext canEvaluatePolicy:policy
                                       error:(NSError * __autoreleasing *)[OCMArg anyPointer]])
      .andDo(canEvaluatePolicyHandler);

  FlutterError *error;
  NSNumber *result = [plugin deviceCanSupportBiometricsWithError:&error];
  XCTAssertFalse([result boolValue]);
  XCTAssertNil(error);
}

- (void)testGetEnrolledBiometricsWithFaceID {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);
  OCMStub([mockAuthContext biometryType]).andReturn(LABiometryTypeFaceID);

  FlutterError *error;
  NSArray<FLADAuthBiometricWrapper *> *result = [plugin getEnrolledBiometricsWithError:&error];
  XCTAssertEqual([result count], 1);
  XCTAssertEqual(result[0].value, FLADAuthBiometricFace);
  XCTAssertNil(error);
}

- (void)testGetEnrolledBiometricsWithTouchID {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
  OCMStub([mockAuthContext canEvaluatePolicy:policy error:[OCMArg setTo:nil]]).andReturn(YES);
  OCMStub([mockAuthContext biometryType]).andReturn(LABiometryTypeTouchID);

  FlutterError *error;
  NSArray<FLADAuthBiometricWrapper *> *result = [plugin getEnrolledBiometricsWithError:&error];
  XCTAssertEqual([result count], 1);
  XCTAssertEqual(result[0].value, FLADAuthBiometricFingerprint);
  XCTAssertNil(error);
}

- (void)testGetEnrolledBiometricsWithoutEnrolledHardware {
  id mockAuthContext = OCMClassMock([LAContext class]);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  const LAPolicy policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
  void (^canEvaluatePolicyHandler)(NSInvocation *) = ^(NSInvocation *invocation) {
    // Write error
    NSError *__autoreleasing *authError;
    [invocation getArgument:&authError atIndex:3];
    *authError = [NSError errorWithDomain:@"error" code:LAErrorBiometryNotEnrolled userInfo:nil];
    // Write return value
    BOOL returnValue = NO;
    NSValue *nsReturnValue = [NSValue valueWithBytes:&returnValue objCType:@encode(BOOL)];
    [invocation setReturnValue:&nsReturnValue];
  };
  OCMStub([mockAuthContext canEvaluatePolicy:policy
                                       error:(NSError * __autoreleasing *)[OCMArg anyPointer]])
      .andDo(canEvaluatePolicyHandler);

  FlutterError *error;
  NSArray<FLADAuthBiometricWrapper *> *result = [plugin getEnrolledBiometricsWithError:&error];
  XCTAssertEqual([result count], 0);
  XCTAssertNil(error);
}

- (void)testIsDeviceSupportedHandlesSupported {
  id mockAuthContext = OCMClassMock([LAContext class]);
  OCMStub([mockAuthContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication
                                       error:[OCMArg setTo:nil]])
      .andReturn(YES);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  FlutterError *error;
  NSNumber *result = [plugin isDeviceSupportedWithError:&error];
  XCTAssertTrue([result boolValue]);
  XCTAssertNil(error);
}

- (void)testIsDeviceSupportedHandlesUnsupported {
  id mockAuthContext = OCMClassMock([LAContext class]);
  OCMStub([mockAuthContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication
                                       error:[OCMArg setTo:nil]])
      .andReturn(NO);
  FLALocalAuthPlugin *plugin = [[FLALocalAuthPlugin alloc]
      initWithContextFactory:[[StubAuthContextFactory alloc]
                                 initWithContexts:@[ mockAuthContext ]]];

  FlutterError *error;
  NSNumber *result = [plugin isDeviceSupportedWithError:&error];
  XCTAssertFalse([result boolValue]);
  XCTAssertNil(error);
}

// Creates an FLADAuthStrings with placeholder values.
- (FLADAuthStrings *)createAuthStrings {
  return [FLADAuthStrings makeWithReason:@"a reason"
                                 lockOut:@"locked out"
                      goToSettingsButton:@"Go To Settings"
                 goToSettingsDescription:@"Settings"
                            cancelButton:@"Cancel"
                  localizedFallbackTitle:nil];
}
@end
