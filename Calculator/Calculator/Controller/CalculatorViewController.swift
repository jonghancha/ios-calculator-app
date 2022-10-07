//
//  Calculator - ViewController.swift
//  Created by yagom.
//  Copyright © yagom. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    private var stackCalculation = ""
    private var finalCalculation = ""
    private var result = 0.0
    private var formula: Formula?
    private var isCalculateResult: Bool = false
    
    @IBOutlet weak var calculatorScrollView: UIScrollView!
    @IBOutlet weak var calculatorStackView: UIStackView!
    @IBOutlet weak var operandLabel: UILabel!
    @IBOutlet weak var operatorLabel: UILabel!
    
    @IBAction func acButton(_ sender: UIButton) {
        resetLabelText()
        resetCalculation()
        resetCalculatorStackView()
    }
    
    @IBAction func ceButton(_ sender: UIButton) {
        stackCalculation = ""
        operandLabel.text = ""
    }
    
    @IBAction func changeSignButton(_ sender: UIButton) {
        guard let operandLabelText = operandLabel.text else { return }
        
        if operandLabelText.contains(Operator.subtract.rawValue) {
            stackCalculation = operandLabelText.trimmingCharacters(in: ["-"])
            operandLabel.text = stackCalculation
            changeSignFinalCalculation(from: "+", to: "-")
        } else {
            stackCalculation = "-" + operandLabelText
            operandLabel.text = stackCalculation
            changeSignFinalCalculation(from: "-", to: "+")
        }
    }
    
    @IBAction func inputOperatorButton(_ sender: UIButton) {
        if operandLabel.text != "" {
            updateCalculatorStackView()
        }
        
        isCalculateResult = false
        switch sender.tag {
        case 91:
            pushOperator(finalCalculationInput: "/", operatorInput: "÷")
        case 92:
            pushOperator(finalCalculationInput: "*", operatorInput: "x")
        case 93:
            pushOperator(finalCalculationInput: "-", operatorInput: "-")
        case 94:
            pushOperator(finalCalculationInput: "+", operatorInput: "+")
        default:
            break
        }
    }
    
    @IBAction func resultButton(_ sender: UIButton) {
        if isCalculateResult == false {
            updateFinalCalculation(userInput: stackCalculation.trimmingCharacters(in: ["-"]))
        }
        updateCalculatorStackView()
        
        resetLabelText()
        stackCalculation = ""
        
        try? showResult()
        operandLabel.text = String(result)
        resetCalculation()
        resetCalculatorStackView()
    }
    
    @IBAction func inputNumberButton(_ sender: UIButton) {
        switch sender.tag {
        case -1:
            pushOperand(".")
        case 0, 1, 2, 3, 4, 5, 6 ,7, 8, 9:
            pushOperand("\(sender.tag)")
        case 10:
            pushOperand("00")
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetLabelText()
        resetCalculation()
        resetCalculatorStackView()
    }
    
    private func resetLabelText() {
        operandLabel.text = ""
        operatorLabel.text = ""
    }
    
    private func resetCalculation() {
        stackCalculation = ""
        finalCalculation = "0" + "+"
        isCalculateResult = false
    }
    
    private func resetCalculatorStackView() {
        calculatorStackView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
    }
    private func pushOperand(_ userInput: String) {
        stackCalculation = stackCalculation + userInput
        operandLabel.text = stackCalculation
    }
    
    private func pushOperator(finalCalculationInput: String, operatorInput: String) {
        updateFinalCalculation(userInput: stackCalculation.trimmingCharacters(in: ["-"]))
        changeOperator(replacement: finalCalculationInput)
        
        stackCalculation = ""
        operatorLabel.text = operatorInput
        operandLabel.text = ""
    }
    
    private func changeSignFinalCalculation(from target: String, to replacement: String) {
        if finalCalculation.count == 0 {
            return
        }
        
        var finalCalculationList = Array(finalCalculation).map { String($0) }
        
        for count in (0...finalCalculationList.count-1).reversed() {
            if finalCalculationList[count] == target {
                finalCalculationList[count] = replacement
                finalCalculation = finalCalculationList.joined()
                return
            } else if finalCalculationList[count] == replacement {
                finalCalculationList[count] = target
                finalCalculation = finalCalculationList.joined()
                return
            } else if finalCalculationList[count] == "*" || finalCalculationList[count] == "/" {
                updateFinalCalculation(userInput: stackCalculation.trimmingCharacters(in: ["-"]))
                
                try? showResult()
                resetCalculation()
                
                finalCalculation = "0" + "-" + "\(result)"
                finalCalculation = finalCalculation.replacingOccurrences(of: "--", with: "+")
                isCalculateResult = true
                return
            }
        }
    }
    
    private func changeOperator(replacement: String) {
        if finalCalculation.count == 0 {
            return
        }
        
        var finalCalculationList = Array(finalCalculation).map { String($0) }
        var lastFinalCalculation = finalCalculationList[finalCalculationList.count-1]
        
        if operandLabel.text == "" {
            lastFinalCalculation = replacement
            finalCalculationList[finalCalculationList.count-1] = lastFinalCalculation
            finalCalculation = finalCalculationList.joined()
            return
        } else {
            updateFinalCalculation(userInput: replacement)
            return
        }
    }
    
    private func updateCalculatorStackView() {
        let calculatorLabel = UILabel()
        let whiteSpace = " "
        
        calculatorLabel.text = (operatorLabel.text ?? "") + whiteSpace + (operandLabel.text ?? "")
        calculatorLabel.textColor = .white
        calculatorLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        
        calculatorStackView.addArrangedSubview(calculatorLabel)
        scrollToCalculatorScrollViewBottom()
    }
    
    private func scrollToCalculatorScrollViewBottom() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.001) {
            self.calculatorScrollView.setContentOffset(CGPoint(x: 0, y: self.calculatorScrollView.contentSize.height-self.calculatorScrollView.bounds.height), animated: true)
        }
    }
    
    private func updateFinalCalculation(userInput: String) {
        finalCalculation = finalCalculation + userInput
    }
    
    private func showResult() throws {
        print(finalCalculation)
        let calculation = ExpressionParser.parse(from: finalCalculation)
        formula = Formula(operands: calculation.operands, operators: calculation.operators)
        
        do {
            guard let calculatorResult = try formula?.result() else { return }
            result = calculatorResult
            isCalculateResult = true
        } catch CalculateError.invalidNumber {
            showErrorMessage(CalculateError.invalidNumber)
        } catch CalculateError.emptyOperands {
            showErrorMessage(CalculateError.emptyOperands)
        } catch CalculateError.emptyOperators {
            showErrorMessage(CalculateError.emptyOperators)
        }
    }
    
    private func showErrorMessage(_ errorType: CalculateError) {
        operandLabel.text = errorType.rawValue
        operatorLabel.text = "Error"
        
        resetCalculation()
        resetCalculatorStackView()
    }
}

