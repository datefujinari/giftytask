import SwiftUI

// MARK: - Add Routine Sheet
struct AddRoutineSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var routineViewModel: RoutineViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var points = 10
    
    private let primaryColor = Color(hex: "#4F46E5")
    private let secondaryColor = Color(hex: "#6B7280")
    
    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("ルーティン名（必須）", text: $title)
                        .textContentType(.none)
                }
                
                Section("説明") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }
                
                Section("ポイント") {
                    Stepper(value: $points, in: 1...100) {
                        Text("\(points) pt")
                            .font(.body.weight(.medium))
                    }
                }
            }
            .navigationTitle("ルーティンを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                    .foregroundColor(secondaryColor)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addRoutine()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canAdd ? primaryColor : secondaryColor.opacity(0.5))
                    .disabled(!canAdd)
                }
            }
        }
    }
    
    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addRoutine() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let routine = Routine(
            title: trimmedTitle,
            description: trimmedDesc.isEmpty ? nil : trimmedDesc,
            points: points
        )
        routineViewModel.addRoutine(routine)
        HapticManager.shared.successNotification()
        isPresented = false
    }
}
