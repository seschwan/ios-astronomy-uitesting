//
//  AstronomyUITests.swift
//  AstronomyUITests
//
//  Created by Seschwan on 8/15/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import XCTest

class AstronomyUITests: XCTestCase {
    
    
    var app: XCUIApplication {
        return XCUIApplication()
    }
    
    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting"]
        continueAfterFailure = false
        app.launch()
    }
    
    func testGoToPreviousSol() {
        app.buttons["PhotosCollectionViewController.PreviousSolButton"].tap()
        XCTAssert(app.navigationBars["Sol 14"].exists)
    }
    
    func testGoToNextSol() {
        app.buttons["PhotosCollectionViewController.NextSolButton"].tap()
        XCTAssert(app.navigationBars["Sol 16"].exists)
        
    }
    
    func testImageLoad() {
        XCUIApplication().collectionViews.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.tap()
        XCTAssert(app.images["PhotoDetailViewController.ImageView"].exists)
    }
    
    func testImageSave() {
        let app = XCUIApplication()
        app.collectionViews.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Save to Photo Library"]/*[[".buttons[\"Save to Photo Library\"]",".buttons[\"PhotoDetailViewController.SaveButton\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.tap()
        XCTAssert(app.alerts["Photo Saved!"].exists)
        app.alerts["Photo Saved!"].buttons["Okay"].tap()
      
    }
    
}
