import SwiftUI

struct ChecklistView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                controls
                    .padding()
                    .background(Color(.systemBackground))

                if appState.checklistItems.isEmpty {
                    EmptyStateView(title: "暂无 Checklist", systemImage: "checklist")
                } else {
                    List {
                        ForEach($appState.checklistItems) { $item in
                            ChecklistRowEditor(item: $item)
                        }
                        .onDelete { offsets in
                            appState.checklistItems.remove(atOffsets: offsets)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("ICU 每日 Checklist")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        appState.addEmptyChecklistRow()
                    } label: {
                        Image(systemName: "plus")
                    }
                    Button {
                        Task { await appState.saveChecklist() }
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Button {
                        exportJPG()
                    } label: {
                        Image(systemName: "photo")
                    }
                    .disabled(appState.checklistItems.isEmpty || isExporting)
                }
            }
            .task {
                if appState.checklistItems.isEmpty {
                    appState.addEmptyChecklistRow()
                }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            DatePicker("日期", selection: $appState.selectedDate, displayedComponents: .date)
            Picker("班次", selection: $appState.selectedShift) {
                ForEach(Shift.allCases) { shift in
                    Text(shift.title).tag(shift)
                }
            }
            .pickerStyle(.segmented)
            Button {
                Task { await appState.loadChecklist() }
            } label: {
                Label("加载当天记录", systemImage: "arrow.down.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .onChange(of: appState.selectedDate) { _, _ in
            for index in appState.checklistItems.indices {
                appState.checklistItems[index].checklistDate = appState.selectedDate
            }
        }
        .onChange(of: appState.selectedShift) { _, newValue in
            for index in appState.checklistItems.indices {
                appState.checklistItems[index].shift = newValue
            }
        }
    }

    private func exportJPG() {
        isExporting = true
        Task {
            do {
                try await ChecklistExporter.saveToPhotos(
                    items: appState.checklistItems,
                    date: appState.selectedDate,
                    shift: appState.selectedShift
                )
                appState.message = "JPG 已保存到相册"
            } catch {
                appState.message = error.localizedDescription
            }
            isExporting = false
        }
    }
}

struct ChecklistRowEditor: View {
    @Binding var item: ChecklistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("床号", text: $item.bedNumber)
                    .textInputAutocapitalization(.characters)
                TextField("姓名", text: $item.patientName)
            }
            TextField("诊断", text: $item.diagnosis, axis: .vertical)
            TextField("病原体", text: $item.pathogen, axis: .vertical)
            TextField("抗生素", text: $item.antibiotics, axis: .vertical)
            TextField("抗凝", text: $item.anticoagulation, axis: .vertical)
            TextField("营养", text: $item.nutrition, axis: .vertical)
            HStack {
                TextField("计划出入量", text: $item.plannedIO)
                TextField("实际出入量", text: $item.actualIO)
            }
            TextField("备注", text: $item.notes, axis: .vertical)
        }
        .textFieldStyle(.roundedBorder)
    }
}
