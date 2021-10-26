/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

final class ErrorFactoryTests: XCTestCase {

  // MARK: - Test Assumptions

  private enum Assumptions {
    static let errorReporter = """
      An error factory should be created with the provided error reporter
      """

    static let facebookDomain = """
      An error should be created with the Facebook error domain when another \
      domain is not provided
      """
    static let providedDomain = """
      An error should be created with the provided domain
      """

    static let providedCode = """
      An error should be created with the provided code
      """
    static let invalidArgumentCode = """
      An error should be created with an invalid argument code
      """

    static let nilMessage = """
      An error should be created without a message if one is not provided
      """
    static let providedMessage = """
      An error should be created with the provided message
      """
    static let invalidArgumentMessage = """
      An error should be created with a default invalid argument message
      """
    static let invalidArgumentName = """
      Invalid argument errors should be created with a name
      """
    static let invalidArgumentWithoutValue = """
      Invalid argument errors should be created with a nil value
      """
    static let invalidArgumentWithValue = """
      Invalid argument errors should be created with a value
      """

    static let nilUnderlyingError = """
      An error should be created without an underlying error if one \
      is not provided
      """
    static let providedUnderlyingError = """
      An error should be created with the provided underlying error
      """

    static let noAdditionalUserInfo = """
      An error should be created without additional user info values if \
      they are not provided
      """
    static let additionalUserInfo = """
      An error should be created with additional user info values if \
      they are provided
      """

    static let reporting = """
      An error should be sent to the factory's error reporter
      """
  }

  // MARK: - Test Fixture

  lazy var factory = SDKErrorFactory(reporter: reporter)
  let reporter = TestErrorReporter()
  var error: Error! // swiftlint:disable:this implicitly_unwrapped_optional
  var nsError: NSError { error as NSError }

  // MARK: - Tests

  // MARK: Dependencies

  func testDependencies() {
    XCTAssertTrue(factory.reporter === reporter, Assumptions.errorReporter)
  }

  // MARK: General Errors

  func testGeneralErrorWithOnlyCode() throws {
    error = factory.error(
      code: Values.code,
      userInfo: nil,
      message: nil,
      underlyingError: nil
    )

    XCTAssertEqual(nsError.domain, ErrorDomain, Assumptions.facebookDomain)
    XCTAssertEqual(nsError.code, Values.code, Assumptions.providedCode)
    XCTAssertFalse(
      nsError.userInfo.keys.contains(Values.userInfoKey),
      Assumptions.noAdditionalUserInfo
    )
    XCTAssertNil(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      Assumptions.nilMessage
    )
    XCTAssertNil(
      nsError.userInfo[NSUnderlyingErrorKey],
      Assumptions.nilUnderlyingError
    )
    try checkReporting(domain: ErrorDomain, code: Values.code, message: nil)
  }

  func testGeneralErrorWithAllParameters() throws {
    error = factory.error(
      domain: Values.domain,
      code: Values.code,
      userInfo: Values.userInfo,
      message: Values.message,
      underlyingError: Values.underlyingError
    )

    XCTAssertEqual(nsError.domain, Values.domain, Assumptions.providedDomain)
    XCTAssertEqual(nsError.code, Values.code, Assumptions.providedCode)
    XCTAssertEqual(
      nsError.userInfo[Values.userInfoKey] as? String,
      Values.userInfoValue,
      Assumptions.additionalUserInfo
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      Values.message,
      Assumptions.providedMessage
    )
    XCTAssertEqual(
      nsError.userInfo[NSUnderlyingErrorKey] as? UnderlyingError,
      Values.underlyingError,
      Assumptions.providedUnderlyingError
    )
    try checkReporting(
      domain: Values.domain,
      code: Values.code,
      message: Values.message
    )
  }

  // MARK: - Invalid Argument Errors

  func testInvalidArgumentErrorWithoutValue() throws {
    let argument = Argument.invalid(name: Values.argumentName, value: nil)
    error = factory.invalidArgumentError(
      name: argument.name,
      value: argument.value,
      message: nil,
      underlyingError: nil
    )

    XCTAssertEqual(nsError.domain, ErrorDomain, Assumptions.facebookDomain)
    XCTAssertEqual(
      nsError.code,
      CoreError.errorInvalidArgument.rawValue,
      Assumptions.invalidArgumentCode
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentNameKey] as? String,
      Values.argumentName,
      Assumptions.invalidArgumentName
    )
    XCTAssertNil(
      nsError.userInfo[ErrorArgumentValueKey],
      Assumptions.invalidArgumentWithoutValue
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      argument.expectedMessage,
      Assumptions.invalidArgumentMessage
    )
    XCTAssertNil(
      nsError.userInfo[NSUnderlyingErrorKey],
      Assumptions.nilUnderlyingError
    )
    try checkReporting(
      domain: ErrorDomain,
      code: CoreError.errorInvalidArgument.rawValue,
      message: argument.expectedMessage
    )
  }

  func testInvalidArgumentErrorWithValue() throws {
    let argument = Argument.invalid(
      name: Values.argumentName,
      value: Values.argumentValue
    )
    error = factory.invalidArgumentError(
      name: argument.name,
      value: argument.value,
      message: nil,
      underlyingError: nil
    )

    XCTAssertEqual(nsError.domain, ErrorDomain, Assumptions.facebookDomain)
    XCTAssertEqual(
      nsError.code,
      CoreError.errorInvalidArgument.rawValue,
      Assumptions.invalidArgumentCode
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentNameKey] as? String,
      Values.argumentName,
      Assumptions.invalidArgumentName
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentValueKey] as? String,
      Values.argumentValue,
      Assumptions.invalidArgumentWithValue
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      argument.expectedMessage,
      Assumptions.invalidArgumentMessage
    )
    XCTAssertNil(
      nsError.userInfo[NSUnderlyingErrorKey],
      Assumptions.nilUnderlyingError
    )
    try checkReporting(
      domain: ErrorDomain,
      code: CoreError.errorInvalidArgument.rawValue,
      message: argument.expectedMessage
    )
  }

  func testInvalidArgumentErrorWithAllParameters() throws {
    let argument = Argument.invalid(
      name: Values.argumentName,
      value: Values.argumentValue
    )
    error = factory.invalidArgumentError(
      domain: Values.domain,
      name: Values.argumentName,
      value: Values.argumentValue,
      message: Values.message,
      underlyingError: Values.underlyingError
    )

    XCTAssertEqual(nsError.domain, Values.domain, Assumptions.providedDomain)
    XCTAssertEqual(
      nsError.code,
      CoreError.errorInvalidArgument.rawValue,
      Assumptions.invalidArgumentCode
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentNameKey] as? String,
      argument.name,
      Assumptions.invalidArgumentName
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentValueKey] as? String,
      argument.value,
      Assumptions.invalidArgumentWithValue
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      Values.message,
      Assumptions.providedMessage
    )
    XCTAssertEqual(
      nsError.userInfo[NSUnderlyingErrorKey] as? UnderlyingError,
      Values.underlyingError,
      Assumptions.providedUnderlyingError
    )
    try checkReporting(
      domain: Values.domain,
      code: CoreError.errorInvalidArgument.rawValue,
      message: Values.message
    )
  }

  // MARK: - Provided and Expected Values

  private enum Values {
    static let domain = "domain"
    static let code = 14
    static let underlyingError = UnderlyingError()
    static let message = "message"
    static let argumentName = "name"
    static let argumentValue = "value"

    static let userInfoKey = "userInfoKey"
    static let userInfoValue = "userInfoValue"
    static let userInfo: [String: Any] = [
      userInfoKey: userInfoValue
    ]
  }

  struct UnderlyingError: Error, Equatable {}

  enum Argument {
    case invalid(name: String, value: String?)

    var name: String {
      switch self {
      case .invalid(name: let name, _):
        return name
      }
    }

    var value: String? {
      switch self {
      case .invalid(_, value: let value):
        return value
      }
    }

    var expectedMessage: String {
      switch self {
      case .invalid:
        return "Invalid value for \(name): \(value ?? "(null)")"
      }
    }
  }

  // MARK: - Common Validation

  private func checkReporting(
    domain: String,
    code: Int,
    message: String?,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    XCTAssertEqual(
      reporter.capturedErrorDomain,
      domain,
      Assumptions.reporting,
      file: file,
      line: line
    )
    XCTAssertEqual(
      reporter.capturedErrorCode,
      code,
      Assumptions.reporting,
      file: file,
      line: line
    )
    XCTAssertEqual(
      reporter.capturedMessage,
      message,
      Assumptions.reporting,
      file: file,
      line: line
    )
  }
}
