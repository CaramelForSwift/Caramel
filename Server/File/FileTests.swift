//
//  FileTests.swift
//  Jelly
//
//  Created by Steve Streza on 31.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Quick
import Nimble
@testable import Jelly

class FileSpec: QuickSpec {
	override func spec() {
		describe("file") {
			let root = File.rootDirectory
			it("should have valid root") {
				expect(root.path) == File.pathSeparator
				expect(root.exists) == true
				expect(root.isDirectory) == true
				expect(root.isFile) == false
				expect(root.pathComponents) == [File.pathSeparator]
				expect(root.lastPathComponent) == File.pathSeparator
			}
			
			let etc = root.fileByAppendingPathComponent("etc")
			it("should have created /etc properly") {
				expect(etc.path) == "\(File.pathSeparator)etc"
				expect(etc.exists) == true
				expect(etc.isDirectory) == true
				expect(etc.isFile) == false
				expect(etc.pathComponents) == [File.pathSeparator, "etc"]
				expect(etc.lastPathComponent) == "etc"
				expect(etc.parentDirectory) == root
			}
			
			let passwd = etc.fileByAppendingPathComponent("passwd")
			it("should have created /etc/passwd properly") {
				expect(passwd.path) == "\(File.pathSeparator)etc\(File.pathSeparator)passwd"
				expect(passwd.exists) == true
				expect(passwd.isDirectory) == false
				expect(passwd.isFile) == true
				expect(passwd.pathComponents) == [File.pathSeparator, "etc", "passwd"]
				expect(passwd.lastPathComponent) == "passwd"
				expect(passwd.parentDirectory) == etc
			}
			
			let passwdData = passwd.data
			it("should be able to read /etc/passwd data") {
				expect(passwdData!.bytes.count) > 0
			}
			
			let home = File.homeDirectory
			it("should have created home directory") {
				expect(home.pathComponents.first) == File.pathSeparator
				expect(home.pathComponents.count) > 1
			}
		}
	}
}