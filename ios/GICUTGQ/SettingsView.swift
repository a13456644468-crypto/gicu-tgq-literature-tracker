import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var apiBaseURL = APIClient.shared.baseURL.absoluteString

    var body: some View {
        NavigationStack {
            Form {
                Section("后端服务") {
                    TextField("API Base URL", text: $apiBaseURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    Button("保存服务地址") {
                        do {
                            try APIClient.shared.saveBaseURL(apiBaseURL)
                            appState.message = "服务地址已保存"
                        } catch {
                            appState.message = error.localizedDescription
                        }
                    }
                }

                Section("模块") {
                    Label("SCI 文献自动追踪", systemImage: "doc.text.magnifyingglass")
                    Label("ICU Checklist JPG 导出", systemImage: "photo")
                    Label("快捷指令与 Siri 入口", systemImage: "sparkles")
                }
            }
            .navigationTitle("设置")
        }
    }
}
