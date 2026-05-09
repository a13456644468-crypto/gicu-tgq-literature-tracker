import Photos
import SwiftUI
import UIKit

enum ExportError: Error, LocalizedError {
    case renderFailed
    case photoDenied

    var errorDescription: String? {
        switch self {
        case .renderFailed: "Checklist 图片生成失败"
        case .photoDenied: "没有相册写入权限"
        }
    }
}

@MainActor
enum ChecklistExporter {
    static func saveToPhotos(items: [ChecklistItem], date: Date, shift: Shift) async throws {
        let image = try render(items: items, date: date, shift: shift)
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw ExportError.photoDenied }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    static func render(items: [ChecklistItem], date: Date, shift: Shift) throws -> UIImage {
        let view = ChecklistTableExportView(items: items, date: date, shift: shift)
            .frame(width: 1400)
            .padding(32)
            .background(Color.white)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.uiImage else { throw ExportError.renderFailed }
        return image
    }
}

struct ChecklistTableExportView: View {
    let items: [ChecklistItem]
    let date: Date
    let shift: Shift

    private let columns = [
        GridItem(.fixed(90)),
        GridItem(.fixed(110)),
        GridItem(.flexible(minimum: 160)),
        GridItem(.flexible(minimum: 140)),
        GridItem(.flexible(minimum: 150)),
        GridItem(.flexible(minimum: 110)),
        GridItem(.flexible(minimum: 110)),
        GridItem(.flexible(minimum: 120)),
        GridItem(.flexible(minimum: 120)),
        GridItem(.flexible(minimum: 140))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("浙江大学医学院附属第二医院 GICU")
                        .font(.title2.weight(.semibold))
                    Text("ICU 每日 Checklist")
                        .font(.largeTitle.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(date.gicuDayText)
                    Text(shift.title)
                }
                .font(.title3.weight(.medium))
            }

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(headers, id: \.self) { header in
                    cell(header, isHeader: true)
                }
                ForEach(items) { item in
                    cell(item.bedNumber)
                    cell(item.patientName)
                    cell(item.diagnosis)
                    cell(item.pathogen)
                    cell(item.antibiotics)
                    cell(item.anticoagulation)
                    cell(item.nutrition)
                    cell(item.plannedIO)
                    cell(item.actualIO)
                    cell(item.notes)
                }
            }
            .overlay(Rectangle().stroke(.black.opacity(0.55), lineWidth: 1))
        }
        .foregroundStyle(.black)
    }

    private var headers: [String] {
        ["床号", "姓名", "诊断", "病原体", "抗生素", "抗凝", "营养", "计划出入量", "实际出入量", "备注"]
    }

    private func cell(_ text: String, isHeader: Bool = false) -> some View {
        Text(text.isEmpty ? " " : text)
            .font(isHeader ? .headline : .body)
            .frame(maxWidth: .infinity, minHeight: isHeader ? 48 : 70, alignment: .topLeading)
            .padding(8)
            .background(isHeader ? Color(red: 0.91, green: 0.97, blue: 0.96) : Color.white)
            .border(.black.opacity(0.35), width: 0.6)
    }
}
