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
    var onEdit: (() -> Void)? = nil
    
    init(task: Binding<Task>, onComplete: @escaping (Task, UIImage?) -> Void, onEdit: (() -> Void)? = nil) {
        _task = task
        self.onComplete = onComplete
        self.onEdit = onEdit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            descriptionView
            metadataView
            progressView
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
            Text(task.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            if onEdit != nil {
                Button { onEdit?() } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Circle()
                .fill(priorityColor(task.priority))
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
            fromLabel
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
    
    // MARK: - From Label（送り主表示）
    @ViewBuilder
    private var fromLabel: some View {
        let name = task.senderName ?? task.fromDisplayName ?? "匿名ユーザー"
        if task.senderId != nil || task.fromDisplayName != nil || task.senderName != nil {
            HStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if task.senderTotalCompletedCount > 0 {
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("\(task.senderTotalCompletedCount)達成")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    // MARK: - 進捗（目標日数制のときのみ）
    @ViewBuilder
    private var progressView: some View {
        if task.isTargetDaysTask {
            Text("進捗: \(task.currentCount)/\(task.targetDays)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Complete Button
    private var completeButton: some View {
        Button(action: {
            if task.status == .pendingApproval { return }
            if task.verificationMode == .selfDeclaration && task.status != .completed {
                completeTask(with: nil)
            }
        }) {
            HStack {
                Spacer()
                Text(completeButtonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(buttonBackground)
            .cornerRadius(12)
        }
        .disabled(task.status == .completed || task.status == .pendingApproval)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if task.verificationMode == .photoEvidence && task.status != .completed && task.status != .pendingApproval {
                        triggerCamera()
                    }
                }
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
    
    private var completeButtonTitle: String {
        switch task.status {
        case .completed: return "完了済み"
        case .pendingApproval: return "承認待ち"
        default: return "完了"
        }
    }
    
    // MARK: - Button Background
    @ViewBuilder
    private var buttonBackground: some View {
        if task.status == .completed {
            Color.green
        } else if task.status == .pendingApproval {
            Color.orange
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
