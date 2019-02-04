//
//  SettingsViewController.swift
//  BlinkRecorder
//
//  Created by Nick Wilkerson on 1/16/19.
//  Copyright © 2019 Wiselab. All rights reserved.
//

import UIKit

let kGenerateRandomData = "GenerateRandomData"
let kCaptureId = "CaptureId"
let kIsoKey = "ISO"
let kExposureKey = "Exposure"
let kWhiteBalanceLock = "WhiteBalanceLock"

class SettingsViewController: UIViewController {
    
    
    
    let dataTextField = UITextField()
    let dataTextFieldLabel = UILabel()
    
    let generateRandomLabel = UILabel()
    let generateRandomSwitch = UISwitch()
    
    let captureCountLabel = UILabel()
    
    let isoTextFieldLabel = UILabel()
    let isoTextField = UITextField()
    
    let exposureTextFieldLabel = UILabel()
    let exposureTextField = UITextField()
    
    let whiteBalanceLockLabel = UILabel()
    let whiteBalanceLockSwitch = UISwitch()
    
    
    
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.white
        
        let margin = CGFloat(10)
        let labelHeight = CGFloat(20)
        let textFieldHeight = CGFloat(30)
        let separation = CGFloat(10)
        
        view.addSubview(dataTextFieldLabel)
        dataTextFieldLabel.translatesAutoresizingMaskIntoConstraints = false
        dataTextFieldLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        dataTextFieldLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin).isActive = true
        dataTextFieldLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin).isActive = true
        dataTextFieldLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        view.addSubview(dataTextField)
        dataTextField.translatesAutoresizingMaskIntoConstraints = false
        dataTextField.topAnchor.constraint(equalTo: dataTextFieldLabel.bottomAnchor, constant: separation).isActive = true
        dataTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin).isActive = true
        dataTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin).isActive = true
        dataTextField.heightAnchor.constraint(equalToConstant: textFieldHeight).isActive = true
        
        view.addSubview(generateRandomSwitch)
        generateRandomSwitch.translatesAutoresizingMaskIntoConstraints = false
        generateRandomSwitch.topAnchor.constraint(equalTo: dataTextField.bottomAnchor, constant: separation).isActive = true
        generateRandomSwitch.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -margin).isActive = true
        
        view.addSubview(generateRandomLabel)
        generateRandomLabel.translatesAutoresizingMaskIntoConstraints = false
        generateRandomLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin).isActive = true
        generateRandomLabel.rightAnchor.constraint(equalTo: generateRandomSwitch.leftAnchor).isActive = true
        generateRandomLabel.bottomAnchor.constraint(equalTo: generateRandomSwitch.bottomAnchor).isActive = true
        generateRandomLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        view.addSubview(captureCountLabel)
        captureCountLabel.translatesAutoresizingMaskIntoConstraints = false
        captureCountLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin).isActive = true
        captureCountLabel.topAnchor.constraint(equalTo: generateRandomLabel.bottomAnchor, constant: separation).isActive = true
        captureCountLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        captureCountLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        view.addSubview(isoTextFieldLabel)
        isoTextFieldLabel.translatesAutoresizingMaskIntoConstraints = false
        isoTextFieldLabel.topAnchor.constraint(equalTo: captureCountLabel.bottomAnchor, constant: separation).isActive = true
        isoTextFieldLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin).isActive = true
        isoTextFieldLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin).isActive = true
        isoTextFieldLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        view.addSubview(isoTextField)
        isoTextField.translatesAutoresizingMaskIntoConstraints = false
        isoTextField.topAnchor.constraint(equalTo: isoTextFieldLabel.bottomAnchor, constant: separation).isActive = true
        isoTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin).isActive = true
        isoTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin).isActive = true
        isoTextField.heightAnchor.constraint(equalToConstant: textFieldHeight).isActive = true
        
        view.addSubview(exposureTextFieldLabel)
        exposureTextFieldLabel.translatesAutoresizingMaskIntoConstraints = false
        exposureTextFieldLabel.topAnchor.constraint(equalTo: isoTextField.bottomAnchor, constant: separation).isActive = true
        exposureTextFieldLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin).isActive = true
        exposureTextFieldLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin).isActive = true
        exposureTextFieldLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        view.addSubview(exposureTextField)
        exposureTextField.translatesAutoresizingMaskIntoConstraints = false
        exposureTextField.topAnchor.constraint(equalTo: exposureTextFieldLabel.bottomAnchor, constant: separation).isActive = true
        exposureTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin).isActive = true
        exposureTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin).isActive = true
        exposureTextField.heightAnchor.constraint(equalToConstant: textFieldHeight).isActive = true
        
        view.addSubview(whiteBalanceLockSwitch)
        whiteBalanceLockSwitch.translatesAutoresizingMaskIntoConstraints = false
        whiteBalanceLockSwitch.topAnchor.constraint(equalTo: exposureTextField.bottomAnchor, constant: separation).isActive = true
        whiteBalanceLockSwitch.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -margin).isActive = true
        
        view.addSubview(whiteBalanceLockLabel)
        whiteBalanceLockLabel.translatesAutoresizingMaskIntoConstraints = false
        whiteBalanceLockLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin).isActive = true
        whiteBalanceLockLabel.rightAnchor.constraint(equalTo: whiteBalanceLockSwitch.leftAnchor).isActive = true
        whiteBalanceLockLabel.bottomAnchor.constraint(equalTo: whiteBalanceLockSwitch.bottomAnchor).isActive = true
        whiteBalanceLockLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataTextFieldLabel.text = "Data"
        
        dataTextField.layer.borderWidth = 1.0
        dataTextField.layer.borderColor = UIColor.black.cgColor
        dataTextField.delegate = self
        
        generateRandomLabel.text = "Generate Random Data"
        generateRandomSwitch.addTarget(self, action: #selector(generateRandomSwitchChanged), for: .valueChanged)
        
        isoTextFieldLabel.text = "ISO"
        isoTextField.layer.borderWidth = 1.0
        isoTextField.layer.borderColor = UIColor.black.cgColor
        isoTextField.delegate = self
        exposureTextFieldLabel.text = "Exposure Duration (ms)"
        exposureTextField.layer.borderWidth = 1.0
        exposureTextField.layer.borderColor = UIColor.black.cgColor
        exposureTextField.delegate = self
        
        whiteBalanceLockLabel.text = "White Balance Lock"
        whiteBalanceLockSwitch.addTarget(self, action: #selector(whiteBalanceLockSwitchChanged), for: .valueChanged)
        
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        let dataValue = UserDefaults.standard.integer(forKey: kLightData)
        dataTextField.text = String(format: "%x", dataValue).uppercased()
        
        let generateRandomData = UserDefaults.standard.bool(forKey: kGenerateRandomData)
        generateRandomSwitch.setOn(generateRandomData, animated: false)
        if generateRandomData {
            dataTextField.isEnabled = false
            dataTextField.textColor = UIColor.gray
        } else {
            dataTextField.isEnabled = true
            dataTextField.textColor = UIColor.black
        }
        captureCountLabel.text = String(format: "Capture Id: %d", UserDefaults.standard.integer(forKey: kCaptureId))
        let iso = UserDefaults.standard.float(forKey: kIsoKey)
        isoTextField.text = String(format: "%.2f", iso)
        let exposure = UserDefaults.standard.integer(forKey: kExposureKey)
        exposureTextField.text = String(format:"%d", exposure)
        
        let whiteBalanceLock = UserDefaults.standard.bool(forKey: kWhiteBalanceLock)
        whiteBalanceLockSwitch.setOn(whiteBalanceLock, animated: false)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        saveTextFieldValues()
    }
    
    
    @objc func generateRandomSwitchChanged() {
        UserDefaults.standard.set(generateRandomSwitch.isOn, forKey: kGenerateRandomData)
        if generateRandomSwitch.isOn {
            dataTextField.isEnabled = false
            dataTextField.textColor = UIColor.gray
        } else {
            dataTextField.isEnabled = true
            dataTextField.textColor = UIColor.black
        }
    }
    
    @objc func whiteBalanceLockSwitchChanged() {
        UserDefaults.standard.set(whiteBalanceLockSwitch.isOn, forKey: kWhiteBalanceLock)
    }
    
    func saveTextFieldValues() {
        if let text = dataTextField.text {
            let value = Int(text, radix: 16)
            UserDefaults.standard.set(value, forKey: kLightData)
        }
        
        if let text = isoTextField.text {
            let value = Int(text)
            UserDefaults.standard.set(value, forKey: kIsoKey)
        }
        
        if let text = exposureTextField.text {
            let value = Float(text)
            UserDefaults.standard.set(value, forKey: kExposureKey)
        }
    }
    
    
    
    
}


extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField == dataTextField {
            if let text = textField.text {
                let value = Int(text, radix: 16)
                UserDefaults.standard.set(value, forKey: kLightData)
            }
        } else if textField == isoTextField {
            if let text = textField.text {
                let value = Int(text)
                UserDefaults.standard.set(value, forKey: kIsoKey)
            }
        } else if textField == exposureTextField {
            if let text = textField.text {
                let value = Float(text)
                UserDefaults.standard.set(value, forKey: kExposureKey)
            }
        }
        return true
    }
    
}
