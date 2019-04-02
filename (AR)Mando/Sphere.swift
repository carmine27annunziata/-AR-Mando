
import SceneKit

class Sphere: SceneObject {
    
    init() {
        super.init(from: "armadillo.scn")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
}
    var animating: Bool = false
    
    func animate() {
        
        if animating { return }
        animating = true
        
        let rotateOne = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 5.0)
        let repeatForever = SCNAction.repeatForever(rotateOne)
        
        runAction(repeatForever)
    }
    
    func stopAnimating() {
        removeAllActions()
        animating = false
    }
}
