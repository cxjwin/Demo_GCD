//
//  main.swift
//  Demo_GCD
//
//  Created by cxjwin on 2016/10/15.
//  Copyright © 2016年 cxjwin. All rights reserved.
//

import Foundation
import Cocoa

enum GCDType: String {
  case Async = "Async"
  case AsyncAfter = "AsyncAfter"
  case SyncQueue = "SyncQueue"
  case AsyncQueue = "AsyncQueue"
  case ReadWriteLock = "ReadWriteLock"
  case Group = "Group"
  case Timer = "Timer"
  case MonitoredDirectory = "MonitoredDirectory"
  case WatchProcess = "WatchProcess"
  case IOReadWrite = "IOReadWrite"
}

func demoAsync() {
  DispatchQueue.main.async {
    print("hello world")
  }
}

func demoAsyncAfter() {
  DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    print("hello world after 1s.")
  }
}

let syncQueue = DispatchQueue(label: "demo.sync_queue")
func demoSyncQueue() {
  syncQueue.async {
    print("hello world")
  }
}

let asyncQueue = DispatchQueue(label: "demo.async_queue", qos: .default, attributes: .concurrent)
func demoAsyncQueue() {
  asyncQueue.async {
    print("hello world")
  }
}

var number: Int = 0
func singleWrite(num: Int) {
  asyncQueue.async(flags: .barrier) {
    number = num
  }
}

func mutiRead() -> Int {
  var tempNum = 0
  asyncQueue.sync {
    tempNum = number
  }
  return tempNum
}

func demoReadWriteLock() {
  DispatchQueue.global().async {
    DispatchQueue.concurrentPerform(iterations: 100) { idx in
      singleWrite(num: idx)
      if (idx % 4 == 0) {
        print("read num : \(mutiRead())")
      }
    }
  }
}

func demoGroup() {
  let group = DispatchGroup()
  asyncQueue.async(group: group) {
    print("\(Thread.current),async - group")
    sleep(1)
  }

  group.enter()
  asyncQueue.async {
    print("\(Thread.current),enter - leave")
    sleep(1)
    group.leave()
  }

  group.wait()
  print("one more time.")

  asyncQueue.async(group: group) {
    print("\(Thread.current),async - group")
    sleep(1)
  }

  group.enter()
  asyncQueue.async {
    print("\(Thread.current),enter - leave")
    sleep(1)
    group.leave()
  }

  group.notify(queue: DispatchQueue.global()) {
    print("over ...")
  }

  print("end of func")
}

let timer = DispatchSource.makeTimerSource()
func demoTimer() {
  print("begin")
  timer.scheduleOneshot(deadline: .now() + 2)
  timer.setEventHandler {
    print("handle evet")
  }

  timer.setCancelHandler {
    print("cancel")
  }

  timer.resume()
}

func demoMonitoredDirectory() {
  // 这里是我桌面的文件夹,大家测试的时候可以指定自己的文件夹
  let fileURL = URL(fileURLWithPath: "/Users/cxjwin/Desktop/Docs"/*file path string*/)
  let monitoredDirectoryFileDescriptor = open(fileURL.path, O_EVTONLY)
  let directoryMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredDirectoryFileDescriptor, eventMask: .write)

  directoryMonitorSource.setEventHandler {
    print("change file")
  }

  directoryMonitorSource.setCancelHandler {
    close(monitoredDirectoryFileDescriptor)
  }

  directoryMonitorSource.resume();
}

var processSource: DispatchSourceProcess! = nil
func demoWatchProcess() {
  let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.mail")
  let processIdentifier = apps.first?.processIdentifier
  if let pid = processIdentifier {
    processSource = DispatchSource.makeProcessSource(identifier: pid, eventMask: .all)
    print("\(processSource)")
    processSource.setEventHandler {
      print("email exit")
    }
    processSource.resume()
  }
}

func demoIORead() {
  // 这里是我桌面的文件,大家测试的时候可以指定自己的文件
  let fileURL = URL(fileURLWithPath: "/Users/cxjwin/Desktop/duty.md"/*file path string*/)
  let fileDescriptor = open(fileURL.path, O_RDWR)
  DispatchIO.read(fromFileDescriptor: fileDescriptor, maxLength: -1, runningHandlerOn: asyncQueue) {
    (data, num) -> Void in
    print("thread : \(Thread.current), data length : \(data.count), return value : \(num)")

    demoIOWrite(data: data)
  }
}

func demoIOWrite(data: DispatchData) {
  // 这里是我桌面的文件(文件必须先存在,这里创建一个空文件),大家测试的时候可以指定自己的文件
  let fileURL = URL(fileURLWithPath: "/Users/cxjwin/Desktop/hello.md"/*file path string*/)
  let fileDescriptor = open(fileURL.path, O_RDWR)
  DispatchIO.write(toFileDescriptor: fileDescriptor, data: data, runningHandlerOn: asyncQueue) {
    (data, num) -> Void in
    print("thread : \(Thread.current), data length : \(data), return value : \(num)")
  }
}

let type = GCDType.IOReadWrite
switch type {
case .Async:
  demoAsync()
case .AsyncAfter:
  demoAsyncAfter()
case .SyncQueue:
  demoSyncQueue()
case .AsyncQueue:
  demoAsyncQueue()
case .ReadWriteLock:
  demoReadWriteLock()
case .Group:
  demoGroup()
case .Timer:
  demoTimer()
case .MonitoredDirectory:
  demoMonitoredDirectory()
case .WatchProcess:
  demoWatchProcess()
case .IOReadWrite:
  demoIORead()
}

// run forever
RunLoop.current.run(until: .distantFuture);
