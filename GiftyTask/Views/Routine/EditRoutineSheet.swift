import SwiftUI

// MARK: - Edit Routine Sheet
struct EditRoutineSheet: View {
    @Binding var isPresented: Bool
    let routine: Routine
    @EnvironmentObject var routineViewModel: RoutineViewModel
    
    @State private var title: String
    @State private var description: String
    @State private var points: Int
    @State private var showDeleteConfirm = false
    
    init(isPresented: Binding<Bool>, routine: Routine) {
        _isPresented = isPresented
        self.routine = routine
        _title = State(initialValue: routine.title)
        _description = State(initialValue: routine.description ?? "")
        _points = State(initialValue: routine.points)
    }
    
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
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("削除")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("ルーティンを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                    .foregroundColor(secondaryColor)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveRoutine()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canSave ? primaryColor : secondaryColor.opacity(0.5))
                    .disabled(!canSave)
                }
            }
            .alert("ルーティンを削除", isPresented: $showDeleteConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    deleteRoutine()
                }
            } message: {
                Text("このルーティンを削除しますか？この操作は取り消せません。")
            }
        }
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveRoutine() {
        var updated = routine
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.description = description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.points = points
        routineViewModel.updateRoutine(updated)
        HapticManager.shared.successNotification()
        isPresented = false
    }
    
    private func deleteRoutine() {
        routineViewModel.deleteRoutine(id: routine.id)
        HapticManager.shared.mediumImpact()
        isPresented = false
    }
}
