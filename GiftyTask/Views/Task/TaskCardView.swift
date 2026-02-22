import SwiftUI
import PhotosUI

// MARK: - Task Card View (Glassmorphism + Long Press Camera)
struct TaskCardView: View {
    @Binding var task: Task  // @StateObjectから@Bindingに変更
    @State private var isPressed = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: UIImage?
    @State private var isProcessing = false  // TaskCardViewModelから移動
    
    let onComplete: (Task, UIImage?) -> Void
    
    init(task: Binding<Task>, onComplete: @escaping (Task, UIImage?) -> Void) {
        _task = task
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            descriptionView
            metadataView
            completeButton
        }
        .padding(20)
        .glassmorphism(cornerRadius: 20)
        .overlay(loadingOverlay)
        .sheet(isPresented: $showCamera) {
            CameraView(selectedImage: $selectedPhoto, isPresented: $showCamera)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            if let photo = newValue {
                completeTask(with: photo)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text(task.title)  // viewModel.taskからtaskに変更
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Circle()
                .fill(priorityColor(task.priority))  // viewModel.taskからtaskに変更
                .frame(width: 12, height: 12)
        }
    }
    
    // MARK: - Description View
    @ViewBuilder
    private var descriptionView: some View {
        if let description = task.description, !description.isEmpty {  // viewModel.taskからtaskに変更
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
    
    // MARK: - Metadata View
    private var metadataView: some View {
        HStack(spacing: 16) {
            dueDateLabel
            verificationModeLabel
            Spacer()
            xpRewardLabel
        }
    }
    
    // MARK: - Due Date Label
    @ViewBuilder
    private var dueDateLabel: some View {
        if let dueDate = task.dueDate {  // viewModel.taskからtaskに変更
            Label {
                Text(dueDate, style: .date)
                    .font(.system(size: 12))
            } icon: {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
            }
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Verification Mode Label
    private var verificationModeLabel: some View {
        Label {
            Text(task.verificationMode == .photoEvidence ? "写真" : "申告")  // viewModel.taskからtaskに変更
                .font(.system(size: 12))
        } icon: {
            Image(systemName: task.verificationMode == .photoEvidence ? "camera.fill" : "hand.raised.fill")  // viewModel.taskからtaskに変更
                .font(.system(size: 12))
        }
        .foregroundColor(.secondary)
    }
    
    // MARK: - XP Reward Label
    private var xpRewardLabel: some View {
        Label {
            Text("\(task.xpReward) XP")  // viewModel.taskからtaskに変更
                .font(.system(size: 12, weight: .semibold))
        } icon: {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
        }
        .foregroundColor(.orange)
    }
    
    // MARK: - Complete Button
    private var completeButton: some View {
        Button(action: {
            // 自己申告モードの場合のみ、タップで完了
            if task.verificationMode == .selfDeclaration && task.status != .completed {  // viewModel.taskからtaskに変更
                completeTask(with: nil)
            }
        }) {
            HStack {
                Spacer()
                Text(task.status == .completed ? "完了済み" : "完了")  // viewModel.taskからtaskに変更
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(buttonBackground)
            .cornerRadius(12)
        }
        .disabled(task.status == .completed)  // viewModel.taskからtaskに変更
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    // 長押し時の処理（写真証拠モード）
                    if task.verificationMode == .photoEvidence && task.status != .completed {  // viewModel.taskからtaskに変更
                        triggerCamera()
                    }
                }
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
    
    // MARK: - Button Background
    @ViewBuilder
    private var buttonBackground: some View {
        if task.status == .completed {  // viewModel.taskからtaskに変更
            Color.green
        } else {
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    // MARK: - Loading Overlay
    @ViewBuilder
    private var loadingOverlay: some View {
        if isProcessing {  // viewModel.isProcessingからisProcessingに変更
            Color.black.opacity(0.3)
                .cornerRadius(20)
            ProgressView()
                .tint(.white)
        }
    }
    
    // MARK: - Helper Methods
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .green
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    private func triggerCamera() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        showCamera = true
    }
    
    private func completeTask(with photo: UIImage?) {
        // TaskViewModelでの処理はTaskListViewのonCompleteで行われる
        // ここでは直接onCompleteを呼び出す
        onComplete(task, photo)
    }
}

// TaskCardViewModelは削除

// MARK: - Camera View (簡易版)
struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        
        // カメラが利用可能かチェック
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            // シミュレーターなど、カメラが利用できない場合は写真ライブラリを使用
            picker.sourceType = .photoLibrary
            print("⚠️ カメラが利用できないため、写真ライブラリを開きます")
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            TaskCardView(
                task: .constant(PreviewContainer.mockTasks[0]),
                onComplete: { task, photo in
                    print("Task completed: \(task.title)")
                }
            )
            .padding(.horizontal)
            
            TaskCardView(
                task: .constant(PreviewContainer.mockTasks[1]),
                onComplete: { task, photo in
                    print("Task completed: \(task.title)")
                }
            )
            .padding(.horizontal)
            
            TaskCardView(
                task: .constant(PreviewContainer.mockTasks[2]),
                onComplete: { task, photo in
                    print("Task completed: \(task.title)")
                }
            )
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
