import Foundation

/// A thread-local storage class that allows storing values specific to the current thread
internal class ThreadLocal<T> {
    private let key = "com.qa-point.xceasy.threadlocal.\(UUID().uuidString.lowercased())"

    /// The value stored in the thread-local storage.
    var value: T? {
        get {
            return Thread.current.threadDictionary[key] as? T
        }
        set {
            Thread.current.threadDictionary[key] = newValue
        }
    }
}
