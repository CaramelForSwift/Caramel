//
//  FileMetadata.swift
//  Caramel
//
//  Created by Steve Streza on 31.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public struct FileMetadata {

	// These values were derived from /usr/include/sys/types/_s_ifmt.h on OS X.
	// They were converted from octals to decimals.
	private enum FileStatModeType: Int {
		case S_IFMT   = 61440 /* [XSI] type of file mask */
		case S_IFIFO  = 4096  /* [XSI] named pipe (fifo) */
		case S_IFCHR  = 8192  /* [XSI] character special */
		case S_IFDIR  = 16384 /* [XSI] directory */
		case S_IFBLK  = 24576 /* [XSI] block special */
		case S_IFREG  = 32768 /* [XSI] regular */
		case S_IFLNK  = 40960 /* [XSI] symbolic link */
		case S_IFSOCK = 49152 /* [XSI] socket */
	}
	
	let fileStat: stat
	
	internal init(fileStat: stat) {
		self.fileStat = fileStat
	}
	
	private func matchesFlag(value: Int, _ flag: FileStatModeType) -> Bool {
		return (value & flag.rawValue == flag.rawValue)
	}
	
	public var isFile: Bool {
		get {
			return self.matchesFlag(Int(self.fileStat.st_mode), .S_IFREG)
		}
	}
	
	public var isDirectory: Bool {
		get {
			return self.matchesFlag(Int(self.fileStat.st_mode), .S_IFDIR)
		}
	}
}