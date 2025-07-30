//
//  ViewController.swift
//  Dice
//
//  Created by Abhishek Pandey
//

import UIKit
import SceneKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    var diceArray = [SCNNode]()
    var audioPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true

        prepareDiceSound()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            if let hitResult = results.first {
                addDiceToPlane(at: hitResult)
            }
        }
    }

    func addDiceToPlane(at location: ARHitTestResult) {
        let scene = SCNScene(named: "art.scnassets/dice.scn")!
        if let node = scene.rootNode.childNode(withName: "Dice_Red", recursively: true) {
            node.position = SCNVector3(
                location.worldTransform.columns.3.x,
                location.worldTransform.columns.3.y,
                location.worldTransform.columns.3.z)
            diceArray.append(node)
            sceneView.scene.rootNode.addChildNode(node)

            // Roll and give feedback when placed
            roll(dice: node)
            triggerHaptic()
            playDiceSound()
        }
    }

    func rollAll() {
        if !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
            triggerHaptic()
            playDiceSound()
        }
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }

    func roll(dice: SCNNode) {
        var generator = SystemRandomNumberGenerator()
        let randomX = Float(Int.random(in: 1...4, using: &generator)) * (Float.pi / 2)
        let randomZ = Float(Int.random(in: 1...4, using: &generator)) * (Float.pi / 2)

        dice.runAction(SCNAction.rotateBy(
            x: CGFloat(randomX * 5),
            y: 0,
            z: CGFloat(randomZ * 5),
            duration: 0.5
        ))
    }

    func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func playDiceSound() {
        audioPlayer?.play()
    }

    func prepareDiceSound() {
        if let path = Bundle.main.path(forResource: "dice-roll", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error loading sound: \(error.localizedDescription)")
            }
        } else {
            print("Dice sound file not found.")
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        let planeNode = SCNNode()
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        node.addChildNode(planeNode)
    }
}
