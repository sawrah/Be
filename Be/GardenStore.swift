import Foundation
import Combine
import CloudKit

class GardenStore: ObservableObject {
    @Published var iCloudAvailable = true
    @Published var iCloudMessage: String?

    private let privateDB = CKContainer.default().privateCloudDatabase
    private let recordType = "GardenTile"

    init() {
        checkAccountStatus()
    }

    func checkAccountStatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if status != .available {
                    self?.iCloudAvailable = false
                    self?.iCloudMessage = "Sign in to iCloud in Settings to save your garden."
                } else {
                    self?.iCloudAvailable = true
                    self?.iCloudMessage = nil
                }
            }
        }
    }

    // MARK: - Fetch tiles for a given user + month

    func fetchTiles(userID: String, month: Int, year: Int) async throws -> [CKRecord] {
        let predicate = NSPredicate(
            format: "userID == %@ AND month == %d AND year == %d",
            userID, month, year
        )
        let query = CKQuery(recordType: recordType, predicate: predicate)

        let (results, _) = try await privateDB.records(matching: query)
        return results.compactMap { try? $0.1.get() }
    }

    // MARK: - Save a planted tile

    func saveTile(
        userID: String,
        tileId: Int,
        month: Int,
        year: Int,
        flowerType: String = "purple",
        colorVariant: String = "default"
    ) async throws {
        let record = CKRecord(recordType: recordType)
        record["userID"] = userID as CKRecordValue
        record["month"] = month as CKRecordValue
        record["year"] = year as CKRecordValue
        record["tileId"] = tileId as CKRecordValue
        record["flowerType"] = flowerType as CKRecordValue
        record["colorVariant"] = colorVariant as CKRecordValue
        record["isPlanted"] = 1 as CKRecordValue
        record["plantedAt"] = Date() as CKRecordValue

        try await privateDB.save(record)
    }

    // MARK: - Delete a tile

    func deleteTile(recordID: CKRecord.ID) async throws {
        try await privateDB.deleteRecord(withID: recordID)
    }

    // MARK: - Sync local persistence to CloudKit

    func syncToCloud(userID: String, month: Int, year: Int) {
        guard iCloudAvailable else { return }

        let plantedIds = GardenPersistence.plantedTileIds(month: month, year: year)
        for tileId in plantedIds {
            Task {
                try? await saveTile(
                    userID: userID,
                    tileId: tileId,
                    month: month,
                    year: year
                )
            }
        }
    }
}
