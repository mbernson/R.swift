//
//  NibTests.swift
//  R.swift
//
//  Created by Mathijs Bernson on 27/05/16.
//  Copyright © 2016 Mathijs Kadijk. All rights reserved.
//

import XCTest
@testable import rswift

class NibTests: XCTestCase {

  let bundle = NSBundle(forClass: NibTests.self)

  // Related issue:
  // https://github.com/mac-cain13/R.swift/issues/223
  func testIssue223_AdditionalRootObjectsAreIgnoredInXibs() {
    let url = bundle.URLForResource("Issue223CollectionViewCellWithRootObjects.xib", withExtension: "xml")!
    let nib = try! Nib(url: url)

    XCTAssertEqual(nib.reusables.count, 1)
    XCTAssertEqual(nib.rootViews.count, 1)
  }
}
