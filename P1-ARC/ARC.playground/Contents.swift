import UIKit

var str = "Hello, playground"


//  ************************************************************
//  MARK: - P1 - ARC
//

/*:
 # "WEAK, STRONG, UNOWNED, OH MY!" - A GUIDE TO REFERENCES IN SWIFT
 ---
 
 ## ARC
 _**ARC**_ is a compile time feature that is Apple's version of _Automated memory management_.
 + It stands for _**Automatic Reference Counting**_.
 + This means that it only frees up memory for objects when there are zero strong references to them.
 
 ## Strong
 Let's start off with what a _**strong reference**_ is.
 + It's essentially a normal reference (pointer and all), but it's special in it's own right in that it protects the referred object from getting deallocated by ARC by _increasing it's retain count by 1_.
 + In essence, as long as anything has a strong reference to an object, it will not be deallocated.
 + This is important to remember for later when I explain _retain cycles_ and _stuff_.
 
 _Strong references_ are used almost everywhere in Swift.
 + In fact, the declaration of a property is strong by default!
 + Generally, we are safe to use strong references when the hierarchy relationships of objects are linear.
 + When a hierarchy of strong references flow from parent to child, then it's always ok to use strong references.
 
 Here is an example of strong references at play.
 */
class Kraken {
  let tentacle = Tentacle() //strong reference to child.
}


class Tentacle {
  let sucker = Sucker() //strong reference to child
}


class Sucker {}
/*:
 Here we have a linear hierarchy at play.
 + `Kraken` has a _strong reference_ to a `Tentacle` instance
 + which has a _strong reference_ to a `Sucker` instance.
 + The flow goes from Parent (Kraken) all the way down to child (Sucker).
 
 Similarly, in animation blocks, the reference hierarchy is similar as well:
 ```
 UIView.animate(withDuration: 0.3) {
 self.view.alpha = 0.0
 }
 ```
 */
/*:
 Since `animate(withDuration:) is a static method on `UIView`, the closure here is the parent and self is the child.
 
 What about when a child wants to reference a parent?
 + Here is where we want to use _weak and unowned references_.
 */
/*:
 ## WEAK AND UNOWNED REFERENCES
 ### WEAK
 A _weak reference_ is just a pointer to an object that doesn't protect the object from being deallocated by ARC.
 + While strong references increase the retain count of an object by 1, weak references do not.
 + In addition, weak references zero out the pointer to your object when it successfully deallocates.    + This ensures that when you access a _weak reference_, it will either be a valid object, or nil.
 
 In Swift, all _weak references_ are _non-constant Optionals_ (think var vs. let)
 + because the reference can and will be mutated to nil when there is no longer anything holding a strong reference to it.
 
 For example, this won't compile:
 */
class Kraken2 {
  //let is a constant! All weak variables MUST be mutable.
  //    weak let tentacle = Tentacle()
}
/*:
 Because `tentacle` is a `let` constant. Let constants by definition cannot be mutated at runtime.
 + Since weak variables can be nil if nobody holds a strong reference to them, the Swift compiler requires you to have weak variables as vars.
 Important places to use _weak variables_ are in cases where you have potential _retain cycles_.
 + A _retain cycle_ is what happens when two objects both have _strong references to each other_.
 + If 2 objects have _strong references to each other_, ARC will not generate the appropriate release message code on each instance since they are keeping each other alive.
 */
/*:
 A perfect example of this is with the (fairly new) NSNotification APIs. Take a look at the codes:
 ```
 class Kraken3 {
 var notificationObserver: ((Notification) -> Void)?
 init() {
 notificationObserver =
 NotificationCenter.default.addObserver(forName: "humanEnteredKrakensLair",
 object: nil,
 queue: .main) { notification in
 self.eatHuman()
 }
 }
 
 deinit {
 NotificationCenter.default.removeObserver(notificationObserver)
 }
 }
 ```
 */
/*:
 At this point we have a _**retain cycle**_. You see, Closures in swift behave exactly like blocks in Objective-C.
 + If any variable is declared outside of the closure's scope,
 + referencing that variable inside the closure's scope creates another _strong reference_ to that object.
 + The only exceptions to this are variables that use _value semantics_ such as Ints, Strings, Arrays, and Dictionaries in Swift.
 
 Here, `NotificationCenter` retains a closure that captures self strongly when you call `eatHuman()`.
 + Best practice says that you clear out _notification observers_ in the `deinit` function.
 + The problem here is that we don’t clear out the block until `deinit`,
 + but `deinit` won’t ever be called by ARC because the _closure_ has a _strong_ reference to the Kraken3 instance!
 
 Other gotchas where this could happen is in places like NSTimers and NSThread.
 
 The fix is to use a weak reference to self in the closure's capture list.
 + This breaks the _strong reference cycle_.
 */
/*:
 Changing `self` to `weak` won't increase self's `_retain count_ by 1,
 + therefore allowing to ARC to deallocate it properly at the correct time.
 
 To use weak and unowned variables in a closure, you use the [] in syntax inside of the closure's body. Example:
 */
/*:
 ```
 class Exercise {
 
 func doSomething() {
 print("I do something")
 }
 
 let closure = { [weak self] in
 self?.doSomething() //Remember, all weak variables are Optionals!
 }
 }
 ```
 */
/*:
 Why is the weak self inside of square brackets?
 + That looks weird!
 + In Swift, we see square brackets and we think Arrays .
 + Well guess what? You can specify multiple _capture values_ in a closure!
 */
/*:
 ```
 //Look at that sweet, sweet Array of capture values.
 let closure = { [weak self, unowned krakenInstance] in
 self?.doSomething() //weak variables are Optionals!
 krakenInstance.eatMoreHumans() //unowned variables are not.
 }
 ```
 */
/*:
 That looks more like an Array right?
 So, now you know why capture values are in square brackets.
 So, now, using what we've learned so far, we can fix the _retain cycle_ in the notification code we posted above by adding [weak self] to the closure's capture list:
 */
/*:
 ```
 NotificationCenter.default.addObserver(
 forName: "humanEnteredKrakensLair",
 object: nil,
 queue: .main) { [weak self] notification in //The retain cycle is fixed by using capture lists!
 self?.eatHuman() //self is now an optional!
 }
 ```
 */
/*:
 One other place we need to use _weak and unowned variables_ is when using _protocols_ to employ delegation amongst classes  in Swift,
 + since classes use reference semantics.
 In Swift, structs and enums can conform to protocols as well, but they use value semantics.
 If a parent class uses delegation with a child class like so:
 */
class Kraken4: LossOfLimbDelegate {
  let tentacle = Tentacle4()
  init() {
    tentacle.delegate = self
  }
  
  func limbHasBeenLost() {
    startCrying()
  }
  
  func startCrying() {
    print("Starting crying")
  }
}

protocol LossOfLimbDelegate {
  func limbHasBeenLost()
}

class Tentacle4 {
  var delegate: LossOfLimbDelegate?
  
  func cutOffTentacle() {
    delegate?.limbHasBeenLost()
  }
}
/*:
 Then we need to use a weak variable.
 + Here's why:
 + `Tentacle4` in this case holds a strong reference to `Kraken` in the form of it's delegate property.
 
 AT THE SAME TIME
 
 Kraken holds a _strong reference_ to `Tentacle` in it's `tentacle` property.
 
 To use a weak variable in this scenario, we add a weak specifier to the beginning of the delegate declaration:
 ```
 weak var delegate: LossOfLimbDelegate5?
 ```
 */
/*:
 What's that you say? Doing this won't compile?!
 + The problem is because non class type protocols cannot be marked as weak.
 
 At this point, we have to use a class protocol to mark the delegate property as weak by having our protocol inherit :class.
 
 
 > When do we not use :class ? According to Apple: “Use a class-only protocol when the behavior defined by that protocol’s requirements assumes or requires that a conforming type has reference semantics rather than value semantics.”
 */
/*:
 ```
 protocol LossOfLimbDelegate5: class { //The protocol now inherits class
 func limbHasBeenLost()
 }
 ```
 */
class Kraken5: LossOfLimbDelegate5 {
  let tentacle5 = Tentacle5()
  init() {
    tentacle5.delegate = self
  }
  
  func limbHasBeenLost5() {
    startCrying5()
  }
  
  func startCrying5() {
    print("Starting crying")
  }
}

protocol LossOfLimbDelegate5: class { //The protocol now inherits class
  func limbHasBeenLost5()
}

class Tentacle5 {
  weak var delegate: LossOfLimbDelegate5?
  
  func cutOffTentacle5() {
    delegate?.limbHasBeenLost5()
  }
}
/*:
 Essentially, if you have a reference hierarchy exactly like the one I showed above, you use :class.
 + In struct and enum situations, there is no need for :class because structs and enums use value semantics
 + while classes use reference semantics.
 */
/*:
 ### UNOWNED
 _Weak and unowned references_ behave similarly but are NOT the same.
 + Unowned references, like weak references, do not increase the retain count of the object being referred.
 + However, in Swift, an _unowned reference_ has the added benefit of not being an Optional.
 + This makes them easier to manage rather than resorting to using optional binding.
 + This is not unlike _Implicitly Unwrapped Optionals_ .
 + In addition, _unowned references_ are non-zeroing.
 + This means that when the object is deallocated, it does not zero out the pointer.
 + This means that use of _unowned references_ can, in some cases, lead to dangling pointers.
 + For you nerds out there that remember the Objective-C days like I do, unowned references map to unsafe_unretained references.
 
 This is where it gets a little confusing. Weak and unowned references both do not increase retain counts.
 + They can both be used to break retain cycles. So when do we use them?!
 
 > According to Apple's docs: “Use a weak reference whenever it is valid for that reference to become nil at some point during its lifetime. Conversely, use an unowned reference when you know that the reference will never be nil once it has been set during initialization.”
 
 Well there you have it: Just like an implicitly unwrapped optional, If you can guarantee that the reference will not be nil at its point of use, use unowned. If not, then you should be using weak.
 
 Here's a good example of a class that creates a retain cycle using a closure where the captured self will not be nil:
 */
class RetainCycle {
  var closure: (() -> Void)!
  var string = "Hello"
  
  init() {
    closure = {
      self.string = "Hello, World!"
    }
  }
}

//Initialize the class and activate the retain cycle.
let retainCycleInstance = RetainCycle()

// At this point we can guarantee the captured self inside the closure will not be nil.
// - Any further code after this (especially code that alters self's reference) needs to be judged on whether or not unowned still works here.
retainCycleInstance.closure()
/*:
 In this case, the retain cycle comes from the closure capturing self strongly while self has a strong reference to the closure via the closure property. To break this we simply add [unowned self] to the closure assignment:
 */
/*:
 ```
 closure = { [unowned self] in
 self.string = "Hello, World!"
 }
 ```
 */

class RetainCycle6 {
  var closure6: (() -> Void)!
  var string = "Hello"
  
  init() {
    closure6 = { [unowned self] in
      self.string = "Hello, World!"
    }
  }
}


let retainCycleInstance6 = RetainCycle6()

retainCycleInstance6.closure6()
/*:
 In this case, we can assume self will never be nil since we call closure immediately after the initialization of the RetainCycle class.
 
 > Apple also says this about unowned references: “Define a capture in a closure as an unowned reference when the closure and the instance it captures will always refer to each other, and will always be deallocated at the same time.”
 
 If you know your reference is going to be zeroed out properly and your 2 references are MUTUALLY DEPENDENT on each other (one can't live without the other), then you should prefer unowned over weak, since you aren't going to want to have to deal with the overhead of your program trying to unnecessarily zero your reference pointers.
 
 A really good place to use _unowned references_ is when using self in closure properties that are lazily defined like so:
 */
class Kraken7 {
  let petName = "Krakey-poo"
  lazy var businessCardName: () -> String = { [unowned self] in
    return "Mr. Kraken AKA " + self.petName
  }
}
/*:
 We need unowned self here to prevent a retain cycle.
 + Kraken holds on to the businessCardName closure for it's lifetime and the businessCardName closure holds on to the Kraken for it's lifetime.
 + They are mutually dependent, so they will always be deallocated at the same time.
 + Therefore, it satisfies the rules for using unowned!
 
 HOWEVER, this is not to be confused with lazy variables that AREN'T closures such as this:
 */
class Kraken8 {
  let petName = "Krakey-poo"
  lazy var businessCardName: String = {
    return "Mr. Kraken AKA " + self.petName
  }()
}
/*:
 Unowned self is not needed since nothing actually retains the closure that's called by the lazy variable. The variable simply assigns itself the result of the closure and deallocates the closure (and decrements the captured self's reference count) immediately after it's first use. Here's a screenshot that proves this! (Screenshot taken shamelessly from Алексей in the comments section!)
 */
class Kraken9 {
  let petName = "Krakey-poo"
  
  lazy var businessCardName: String = {
    print(#function)
    return "Mr. Kraken AKA " + self.petName
  }()
  
  deinit {
    print(#function)
  }
}

print("\n\nCreate Kraken9")
var kraken9: Kraken9? = Kraken9()

print("\nCreate Kraken9")
kraken9 = Kraken9()
kraken9?.businessCardName
kraken9 = nil
print("Exit")
/*:
 ## CONCLUSION
 Retain cycles suck.
  + But with careful coding and consideration of your reference hierarchy, memory leaks and abandoned memory can be avoided through careful use of weak and unowned.
 */


