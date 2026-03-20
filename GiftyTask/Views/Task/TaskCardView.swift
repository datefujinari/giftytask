import SwiftUI
import PhotosUI

// MARK: - Task Card View (Glassmorphism + Long Press Camera)
struct TaskCardView: View {
    @Binding var task: Task  // @StateObjectから@Bindingに変更
    @State private var isPressed = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showPhotoSourceDialog = false
    @State private var selectedPhoto: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessing = false
    
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
        .sheet(isPresented: $showPhotoPicker) {
            PhotoLibraryPickerView(
                selectedPhotoItem: $selectedPhotoItem,
                isPresented: $showPhotoPicker
            )
        }
        .onChange(of: selectedPhoto) { _, newValue in
            if let photo = newValue {
                completeTask(with: photo)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            handleSelectedPhotoItem(newValue)
        }
        .confirmationDialog("完了報告に画像を添付", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
            Button("カメラで撮影") { showCamera = true }
            Button("フォトライブラリから選択") { showPhotoPicker = true }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("画像を選択してください")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                if let giftName = task.rewardDisplayName, !giftName.isEmpty {
                    Label(giftName, systemImage: "gift.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
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
            priorityLabel
            Spacer()
            creatorLabel
        }
    }
    
    // MARK: - Due Date Label
    @ViewBuilder
    private var dueDateLabel: some View {
        Label {
            Text(task.dueDate.map { Self.displayDateFormatter.string(from: $0) } ?? "期限なし")
                .font(.system(size: 12))
        } icon: {
            Image(systemName: "calendar")
                .font(.system(size: 12))
        }
        .foregroundColor(.secondary)
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
    
    private var priorityLabel: some View {
        Label {
            Text(task.priority.displayName)
                .font(.system(size: 12))
        } icon: {
            Circle()
                .fill(priorityColor(task.priority))
                .frame(width: 8, height: 8)
        }
        .foregroundColor(.secondary)
    }
    
    // MARK: - Creator Label
    @ViewBuilder
    private var creatorLabel: some View {
        let name = task.createdByUserName ?? task.senderName ?? task.fromDisplayName ?? (task.senderId == nil ? "自分" : "匿名ユーザー")
        if !name.isEmpty {
            HStack(spacing: 4) {
                Text("作成者")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
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
            } else if task.verificationMode == .photoEvidence && task.status != .completed {
                showPhotoSourceDialog = true
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
        .onChange(of: showPhotoSourceDialog) { _, newValue in
            if !newValue { selectedPhotoItem = nil }
        }
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
    
    private func handleSelectedPhotoItem(_ newValue: PhotosPickerItem?) {
        guard let item = newValue else { return }
        showPhotoPicker = false
        _Concurrency.Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run { selectedPhoto = image }
            }
        }
    }
    
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

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy:MM:dd"
        return formatter
    }()
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

// MARK: - Photo Library Picker Sheet
struct PhotoLibraryPickerView: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images
            ) {
                Label("写真を選択", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("フォトライブラリ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { isPresented = false }
                }
            }
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
