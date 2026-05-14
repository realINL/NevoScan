//
//  InstructionView.swift
//  NevoScan
//
//  Created by Илья Лебедев on 16.01.2026.
//

import SwiftUI
import PhotosUI

struct Instruction {
    let point: Int
    let title: String
    let description: String
    let image: UIImage
}

struct InstructionCardView: View {
    let instruction: Instruction
    let coef = 0.91
    
    var body: some View {
        HStack() {
            Image(uiImage: instruction.image)
                .resizable()
                .frame(width: .FHeight(120), height: .FHeight(120))
                .cornerRadius(20)
            
            Spacer(minLength: 14 * coef)
            
            VStack(alignment: .leading) {
                (Text(verbatim: "\(instruction.point). ")
                    + Text(LocalizedStringKey(stringLiteral: instruction.title)))
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(LocalizedStringKey(stringLiteral: instruction.description))
                    .font(.caption)
            }
            .frame(maxWidth: 240 * coef)
        }
        .padding(.leading, 32 * coef)
        .padding(.trailing, 24 * coef)
        .padding(.vertical, 5 * coef)
    }
}

//#Preview {
//    InstructionView()
//}

extension Instruction {
    static let Instruction_MOCK_UP = [
        Instruction(point: 1, title: "instruction.focus.title", description: "instruction.focus.body", image: .i1),
        Instruction(point: 2, title: "instruction.light.title", description: "instruction.light.body", image: .i2),
        Instruction(point: 3, title: "instruction.clear.title", description: "instruction.clear.body", image: .i3)
    ]
}



