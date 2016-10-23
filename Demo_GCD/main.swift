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

let asyncQueue = DispatchQueue(label: "demo.async_queue", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
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
  let fileURL = URL(fileURLWithPath: ""/*file path string*/)
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

let type = GCDType.WatchProcess
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
}

// run forever
RunLoop.current.run(until: .distantFuture);
