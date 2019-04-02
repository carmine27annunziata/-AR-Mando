import SceneKit


struct MainScene {
    var scene: SCNScene?
    
    init() {
        scene = self.initializeScene()
    }
    
    func initializeScene() -> SCNScene? {
        let scene = SCNScene()
        
        setDefaults(scene: scene)
        
        return scene
    }
    
    func setDefaults(scene: SCNScene) {
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = SCNLight.LightType.ambient
        ambientLightNode.light?.color = UIColor(white: 0.6, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        let directionalNode = SCNNode()
        directionalNode.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(-130), GLKMathDegreesToRadians(0), GLKMathDegreesToRadians(35))
        directionalNode.light = directionalLight
        scene.rootNode.addChildNode(directionalNode)
    }
    
    func easeOutElastic(_ t: Float) -> Float {
        let p: Float = 0.3
        let result = pow(2.0, -10.0 * t) * sin((t - p / 4.0) * (2.0 * Float.pi) / p) + 1.0
        return result
    }
    
    func addSphere(parent: SCNNode, position: SCNVector3) {
        
        guard let scene = self.scene else { return }
        
        let sphere = Sphere()
        
        let prevScale = sphere.scale
        sphere.scale = SCNVector3(0.01, 0.01, 0.01)
        let scaleAction = SCNAction.scale(to: CGFloat(prevScale.x), duration: 1.5)
        scaleAction.timingMode = .linear
        
        scaleAction.timingFunction = { (p: Float) in
            return self.easeOutElastic(p)
        }
        
        sphere.name = "Sphere"
        sphere.position = scene.rootNode.convertPosition(position, to: parent)
        let orientation = sphere.orientation
        var glQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        let multiplier = GLKQuaternionMakeWithAngleAndAxis(1, -1.5, 0, 0)
        glQuaternion = GLKQuaternionMultiply(glQuaternion, multiplier)
        sphere.orientation = SCNQuaternion(x: glQuaternion.x, y: glQuaternion.y, z: glQuaternion.z, w: glQuaternion.w)
        parent.addChildNode(sphere)
        sphere.runAction(scaleAction, forKey: "scaleAction")
    }
}
