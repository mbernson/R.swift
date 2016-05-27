//
//  Nib.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 09-12-15.
//  Copyright © 2015 Mathijs Kadijk. All rights reserved.
//

import Foundation

private let ElementNameToTypeMapping = [
  // TODO: Should contain all standard view elements, like button -> UIButton, view -> UIView etc
  "view": Type._UIView,
  "tableViewCell": Type._UITableViewCell,
  "collectionViewCell": Type._UICollectionViewCell,
  "collectionReusableView": Type._UICollectionReusableView
]

struct Nib: WhiteListedExtensionsResourceType, ReusableContainer {
  static let supportedExtensions: Set<String> = ["xib", "xml"]

  let name: String
  let rootViews: [Type]
  let reusables: [Reusable]

  init(url: NSURL) throws {
    try Nib.throwIfUnsupportedExtension(url.pathExtension)

    name = url.filename!

    let parserDelegate = NibParserDelegate()

    let parser = NSXMLParser(contentsOfURL: url)!
    parser.delegate = parserDelegate
    parser.parse()

    rootViews = parserDelegate.rootViews
    reusables = parserDelegate.reusables
  }
}

private class NibParserDelegate: NSObject, NSXMLParserDelegate {
  let ignoredRootViewElements = [
    "placeholder",
    "customObject",
  ]
  var rootViews: [Type] = []
  var reusables: [Reusable] = []

  // State
  var isObjectsTagOpened = false;
  var levelSinceObjectsTagOpened = 0;

  private func isElementIgnored(elementName: String) -> Bool {
    return ignoredRootViewElements.contains(elementName) || elementName.containsString("Recognizer")
  }

  @objc func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
    switch elementName {
    case "objects":
      isObjectsTagOpened = true;

    default:
      if isObjectsTagOpened {
        levelSinceObjectsTagOpened += 1;

        if let rootView = viewWithAttributes(attributeDict, elementName: elementName)
          where levelSinceObjectsTagOpened == 1 && !isElementIgnored(elementName) {
            rootViews.append(rootView)
        }
      }

      if let reusable = reusableFromAttributes(attributeDict, elementName: elementName) {
        reusables.append(reusable)
      }
    }
  }

  @objc func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    switch elementName {
    case "objects":
      isObjectsTagOpened = false;

    default:
      if isObjectsTagOpened {
        levelSinceObjectsTagOpened -= 1;
      }
    }
  }

  func viewWithAttributes(attributeDict: [String : String], elementName: String) -> Type? {
    let customModuleProvider = attributeDict["customModuleProvider"]
    let customModule = (customModuleProvider == "target") ? nil : attributeDict["customModule"]
    let customClass = attributeDict["customClass"]
    let customType = customClass.map { Type(module: Module(name: customModule), name: $0, optional: false) }

    return customType ?? ElementNameToTypeMapping[elementName] ?? Type._UIView
  }

  func reusableFromAttributes(attributeDict: [String : String], elementName: String) -> Reusable? {
    guard let reuseIdentifier = attributeDict["reuseIdentifier"] where !reuseIdentifier.isEmpty else {
      return nil
    }

    let customModuleProvider = attributeDict["customModuleProvider"]
    let customModule = (customModuleProvider == "target") ? nil : attributeDict["customModule"]
    let customClass = attributeDict["customClass"]
    let customType = customClass.map { Type(module: Module(name: customModule), name: $0, optional: false) }

    let type = customType ?? ElementNameToTypeMapping[elementName] ?? Type._UIView

    return Reusable(identifier: reuseIdentifier, type: type)
  }
}
