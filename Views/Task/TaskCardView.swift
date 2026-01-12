import SwiftUI
import PhotosUI

// MARK: - Task Card View (Glassmorphism + Long Press Camera)
struct TaskCardView: View {
    @StateObject private var viewModel: TaskCardViewModel
    @State private var isPressed = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: UIImage?
    
    init(task: Task, onComplete: @escaping (Task, UIImage?) -> Void) {
        _viewModel = StateObject(wrappedValue: TaskCardViewModel(task: task))
        self.onComplete = onComplete
    }
    
    let onComplete: (Task, UIImage?) -> Void
    
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
        .onChange(of: selectedPhoto) { newPhoto in
            if let photo = newPhoto {
                completeTask(with: photo)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text(viewModel.task.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Circle()
                .fill(priorityColor(viewModel.task.priority))
                .frame(width: 12, height: 12)
        }
    }
    
    // MARK: - Description View
    @ViewBuilder
    private var descriptionView: some View {
        if let description = viewModel.task.description, !description.isEmpty {
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
        if let dueDate = viewModel.task.dueDate {
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
            Text(viewModel.task.verificationMode == .photoEvidence ? "写真" : "申告")
                .font(.system(size: 12))
        } icon: {
            Image(systemName: viewModel.task.verificationMode == .photoEvidence ? "camera.fill" : "hand.raised.fill")
                .font(.system(size: 12))
        }
        .foregroundColor(.secondary)
    }
    
    // MARK: - XP Reward Label
    private var xpRewardLabel: some View {
        Label {
            Text("\(viewModel.task.xpReward) XP")
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
            if viewModel.task.verificationMode == .selfDeclaration {
                completeTask(with: nil)
            }
        }) {
            HStack {
                Spacer()
                Text(viewModel.task.status == .completed ? "完了済み" : "完了")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(buttonBackground)
            .cornerRadius(12)
        }
        .disabled(viewModel.task.status == .completed)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if viewModel.task.verificationMode == .photoEvidence {
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
        if viewModel.task.status == .completed {
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
        if viewModel.isProcessing {
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
        viewModel.completeTask { completedTask in
            onComplete(completedTask, photo)
        }
    }
}

// MARK: - Task Card ViewModel
class TaskCardViewModel: ObservableObject {
    @Published var task: Task
    @Published var isProcessing = false
    
    init(task: Task) {
        self.task = task
    }
    
    func completeTask(completion: @escaping (Task) -> Void) {
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var updatedTask = self.task
            updatedTask.complete()
            self.task = updatedTask
            self.isProcessing = false
            completion(updatedTask)
        }
    }
}

// MARK: - Camera View (簡易版)
struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
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
                task: PreviewContainer.mockTasks[0],
                onComplete: { task, photo in
                    print("Task completed: \(task.title)")
                }
            )
            .padding(.horizontal)
            
            TaskCardView(
                task: PreviewContainer.mockTasks[1],
                onComplete: { task, photo in
                    print("Task completed: \(task.title)")
                }
            )
            .padding(.horizontal)
            
            TaskCardView(
                task: PreviewContainer.mockTasks[2],
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
