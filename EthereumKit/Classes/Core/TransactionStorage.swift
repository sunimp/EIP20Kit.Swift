import RxSwift
import GRDB

class TransactionStorage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createTransactions") { db in
            try db.create(table: Transaction.databaseTableName) { t in
                t.column(Transaction.Columns.hash.name, .text).notNull()
                t.column(Transaction.Columns.nonce.name, .integer).notNull()
                t.column(Transaction.Columns.input.name, .text).notNull()
                t.column(Transaction.Columns.from.name, .text).notNull()
                t.column(Transaction.Columns.to.name, .text).notNull()
                t.column(Transaction.Columns.value.name, .text).notNull()
                t.column(Transaction.Columns.gasLimit.name, .integer).notNull()
                t.column(Transaction.Columns.gasPrice.name, .integer).notNull()
                t.column(Transaction.Columns.timestamp.name, .double).notNull()

                t.primaryKey([Transaction.Columns.hash.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createInternalTransactions") { db in
            try db.create(table: InternalTransaction.databaseTableName) { t in
                t.column(InternalTransaction.Columns.hash.name, .text)
                        .notNull()
                        .indexed()
                        .references(Transaction.databaseTableName, column: Transaction.Columns.hash.name, onDelete: .cascade)
                t.column(InternalTransaction.Columns.blockNumber.name, .integer).notNull()
                t.column(InternalTransaction.Columns.from.name, .text).notNull()
                t.column(InternalTransaction.Columns.to.name, .text).notNull()
                t.column(InternalTransaction.Columns.value.name, .text).notNull()
                t.column(InternalTransaction.Columns.traceId.name, .integer).notNull()

                t.primaryKey([InternalTransaction.Columns.hash.name, InternalTransaction.Columns.traceId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("recreateTransactions") { db in
            try db.drop(table: Transaction.databaseTableName)

            try db.create(table: Transaction.databaseTableName) { t in
                t.column(Transaction.Columns.hash.name, .text).notNull()
                t.column(Transaction.Columns.nonce.name, .integer).notNull()
                t.column(Transaction.Columns.input.name, .text).notNull()
                t.column(Transaction.Columns.from.name, .text).notNull()
                t.column(Transaction.Columns.to.name, .text).notNull()
                t.column(Transaction.Columns.value.name, .text).notNull()
                t.column(Transaction.Columns.gasLimit.name, .integer).notNull()
                t.column(Transaction.Columns.gasPrice.name, .integer).notNull()
                t.column(Transaction.Columns.timestamp.name, .double).notNull()

                t.primaryKey([Transaction.Columns.hash.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("recreateInternalTransactions") { db in
            try db.drop(table: InternalTransaction.databaseTableName)
            try db.create(table: InternalTransaction.databaseTableName) { t in
                t.column(InternalTransaction.Columns.hash.name, .text).notNull().indexed()
                t.column(InternalTransaction.Columns.blockNumber.name, .integer).notNull()
                t.column(InternalTransaction.Columns.from.name, .text).notNull()
                t.column(InternalTransaction.Columns.to.name, .text).notNull()
                t.column(InternalTransaction.Columns.value.name, .text).notNull()
                t.column(InternalTransaction.Columns.traceId.name, .integer).notNull()

                t.primaryKey([InternalTransaction.Columns.hash.name, InternalTransaction.Columns.traceId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createTransactionReceipts") { db in
            try db.create(table: TransactionReceipt.databaseTableName) { t in
                t.column(TransactionReceipt.Columns.transactionHash.name, .text).notNull()
                t.column(TransactionReceipt.Columns.transactionIndex.name, .integer).notNull()
                t.column(TransactionReceipt.Columns.blockHash.name, .text).notNull()
                t.column(TransactionReceipt.Columns.blockNumber.name, .integer).notNull()
                t.column(TransactionReceipt.Columns.from.name, .text).notNull()
                t.column(TransactionReceipt.Columns.to.name, .text)
                t.column(TransactionReceipt.Columns.cumulativeGasUsed.name, .integer).notNull()
                t.column(TransactionReceipt.Columns.gasUsed.name, .integer).notNull()
                t.column(TransactionReceipt.Columns.contractAddress.name, .text)
                t.column(TransactionReceipt.Columns.logsBloom.name, .text).notNull()
                t.column(TransactionReceipt.Columns.root.name, .text)
                t.column(TransactionReceipt.Columns.status.name, .integer)

                t.primaryKey([TransactionReceipt.Columns.transactionHash.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createTransactionLogs") { db in
            try db.create(table: TransactionLog.databaseTableName) { t in
                t.column(TransactionLog.Columns.address.name, .text).notNull()
                t.column(TransactionLog.Columns.blockHash.name, .text).notNull()
                t.column(TransactionLog.Columns.blockNumber.name, .integer).notNull()
                t.column(TransactionLog.Columns.data.name, .text).notNull()
                t.column(TransactionLog.Columns.logIndex.name, .integer).notNull()
                t.column(TransactionLog.Columns.removed.name, .boolean).notNull()
                t.column(TransactionLog.Columns.topics.name, .text).notNull()
                t.column(TransactionLog.Columns.transactionHash.name, .text).notNull()
                t.column(TransactionLog.Columns.transactionIndex.name, .integer).notNull()

                t.primaryKey(
                        [TransactionLog.Columns.transactionHash.name, TransactionLog.Columns.logIndex.name],
                        onConflict: .replace
                )
                t.foreignKey(
                        [TransactionLog.Columns.transactionHash.name],
                        references: TransactionReceipt.databaseTableName,
                        columns: [TransactionReceipt.Columns.transactionHash.name],
                        onDelete: .cascade
                )
            }
        }

        migrator.registerMigration("createNotSyncedTransactions") { db in
            try db.create(table: NotSyncedTransaction.databaseTableName) { t in
                t.column(NotSyncedTransaction.Columns.hash.name, .text).notNull()
                t.column(NotSyncedTransaction.Columns.nonce.name, .integer)
                t.column(NotSyncedTransaction.Columns.from.name, .text)
                t.column(NotSyncedTransaction.Columns.to.name, .text)
                t.column(NotSyncedTransaction.Columns.value.name, .text)
                t.column(NotSyncedTransaction.Columns.gasPrice.name, .integer)
                t.column(NotSyncedTransaction.Columns.gasLimit.name, .integer)
                t.column(NotSyncedTransaction.Columns.input.name, .text)
                t.column(NotSyncedTransaction.Columns.blockHash.name, .text)
                t.column(NotSyncedTransaction.Columns.blockNumber.name, .integer)
                t.column(NotSyncedTransaction.Columns.transactionIndex.name, .integer)
                t.column(NotSyncedTransaction.Columns.timestamp.name, .double)

                t.primaryKey([NotSyncedTransaction.Columns.hash.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createTransactionSyncerStates") { db in
            try db.create(table: TransactionSyncerState.databaseTableName) { t in
                t.column(TransactionSyncerState.Columns.id.name, .text).notNull().primaryKey()
                t.column(TransactionSyncerState.Columns.lastBlockNumber.name, .integer).notNull()
            }
        }

        return migrator
    }

    func fullTransactions(from transactions: [Transaction]) -> [FullTransaction] {
        let hashes = transactions.map { $0.hash }

        let receipts = try! dbPool.read { db -> [ReceiptWithLogs] in
            let request = TransactionReceipt
                    .including(all: TransactionReceipt.logs)
                    .filter(hashes.contains(TransactionReceipt.Columns.transactionHash))

            return try ReceiptWithLogs.fetchAll(db, request)
        }

        let internals = try! dbPool.read { db in
            try InternalTransaction
                    .filter(hashes.contains(InternalTransaction.Columns.hash))
                    .fetchAll(db)
        }

        let groupedReceipts = Dictionary(grouping: receipts, by: { $0.receipt.transactionHash })
        let groupedInternals = Dictionary(grouping: internals, by: { $0.hash })

        return transactions.map { transaction -> FullTransaction in
            FullTransaction(
                    transaction: transaction,
                    receiptWithLogs: groupedReceipts[transaction.hash]?.first,
                    internalTransactions: groupedInternals[transaction.hash] ?? []
            )
        }
    }

}

extension TransactionStorage: ITransactionStorage {

    func getNotSyncedTransactions(limit: Int) -> [NotSyncedTransaction] {
        try! dbPool.read { db in
            try NotSyncedTransaction.limit(limit).fetchAll(db)
        }
    }

    func add(notSyncedTransactions: [NotSyncedTransaction]) {
        print("\(notSyncedTransactions.count) notSyncedTransactions inserting")
        try! dbPool.write { db in
            for transaction in notSyncedTransactions {
                try transaction.insert(db)
            }
        }
    }

    func update(notSyncedTransaction: NotSyncedTransaction) {
        try! dbPool.write { db in
            try notSyncedTransaction.update(db)
        }
    }

    func remove(notSyncedTransaction: NotSyncedTransaction) {
        try! dbPool.write { db in
            try notSyncedTransaction.delete(db)
        }
    }

    func save(transaction: Transaction) {
        try! dbPool.write { db in
            try transaction.save(db)
        }
    }

    func save(transactions: [Transaction]) {
        _ = try? dbPool.write { db in
            for transaction in transactions {
                try transaction.insert(db)
            }
        }
    }

    func getFirstPendingTransaction() -> Transaction? {
        try? dbPool.read { db in
            try Transaction
                    .joining(optional: Transaction.receipt)
                    .filter(sql: "transaction_receipts.transactionHash IS NULL")
                    .order(Transaction.Columns.nonce.asc)
                    .fetchOne(db)
        }
    }

    func save(transactionReceipt: TransactionReceipt) {
        try! dbPool.write { db in
            try transactionReceipt.insert(db)
        }
    }

    func getTransactionReceipt(hash: Data) -> TransactionReceipt? {
        try! dbPool.read { db in
            try TransactionReceipt.filter(TransactionReceipt.Columns.transactionHash == hash).fetchOne(db)
        }
    }

    func save(logs: [TransactionLog]) {
        try! dbPool.write { db in
            for log in logs {
                try log.insert(db)
            }
        }
    }

    func save(internalTransactions: [InternalTransaction]) {
        _ = try? dbPool.write { db in
            for internalTransaction in internalTransactions {
                try internalTransaction.insert(db)
            }
        }
    }

    func getHashesFromTransactions() -> [Data] {
        try! dbPool.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT \(Transaction.Columns.hash.name) FROM \(Transaction.databaseTableName)")
            return rows.compactMap {
                $0[Transaction.Columns.hash.name] as? Data
            }
        }
    }

    func etherTransactionsSingle(address: Address, fromHash: Data?, limit: Int?) -> Single<[FullTransaction]> {
        Single.create { [weak self] observer in
            guard let storage = self else {
                observer(.success([]))
                return Disposables.create()
            }

            let transactions: [Transaction] = try! storage.dbPool.read { db in
                var whereClause = """
                                  WHERE
                                  (
                                    (\(Transaction.databaseTableName).'\(Transaction.Columns.from)' = \("x'" + address.raw.hex + "'") AND \(Transaction.databaseTableName).\(Transaction.Columns.value) > 0) OR
                                    \(Transaction.databaseTableName).'\(Transaction.Columns.to)' = \("x'" + address.raw.hex + "'") OR 
                                    \(InternalTransaction.databaseTableName).'\(InternalTransaction.Columns.to)' = \("x'" + address.raw.hex + "'")
                                  )
                                  """

                if let fromHash = fromHash,
                   let fromTransaction = try Transaction.filter(Transaction.Columns.hash == fromHash).fetchOne(db) {
                    let transactionIndex = (try fromTransaction.receipt.fetchOne(db))?.transactionIndex ?? 0

                    whereClause += """
                                   AND (
                                    \(Transaction.Columns.timestamp.name) < \(fromTransaction.timestamp) || 
                                        (
                                            \(Transaction.databaseTableName).\(Transaction.Columns.timestamp.name) == \(fromTransaction.timestamp) AND 
                                            \(TransactionReceipt.databaseTableName).\(TransactionReceipt.Columns.transactionIndex.name) < \(transactionIndex)
                                        )
                                   )
                                   """
                }

                var limitClause = ""
                if let limit = limit {
                    limitClause += "LIMIT \(limit)"
                }

                let orderClause = """
                                  ORDER BY \(Transaction.databaseTableName).\(Transaction.Columns.timestamp.name) DESC, 
                                  \(TransactionReceipt.databaseTableName).\(TransactionReceipt.Columns.transactionIndex.name) DESC
                                  """

                let sql = """
                          SELECT transactions.*
                          FROM transactions
                          LEFT JOIN transaction_receipts ON transactions.hash = transaction_receipts.transactionHash
                          LEFT JOIN internal_transactions ON transactions.hash = internal_transactions.hash
                          \(whereClause)
                          GROUP BY transactions.hash
                          \(orderClause)
                          \(limitClause)
                          """

                let rows = try Row.fetchAll(db.makeSelectStatement(sql: sql))
                return rows.map { row -> Transaction in
                    Transaction(row: row)
                }
            }

            observer(.success(storage.fullTransactions(from: transactions)))

            return Disposables.create()
        }
    }

    func transaction(hash: Data) -> FullTransaction? {
        fullTransactions(byHashes: [hash]).first
    }

    func fullTransactions(byHashes hashes: [Data]) -> [FullTransaction] {
        let transactions = try! dbPool.read { db in
            try Transaction.filter(hashes.contains(Transaction.Columns.hash)).fetchAll(db)
        }

        return fullTransactions(from: transactions)
    }

    func fullTransactions(fromHash: Data?) -> [FullTransaction] {
        let transactions: [Transaction] = try! dbPool.read { db in
            var whereClause = ""

            if let fromHash = fromHash,
               let fromTransaction = try Transaction.filter(Transaction.Columns.hash == fromHash).fetchOne(db) {
                let transactionIndex = (try fromTransaction.receipt.fetchOne(db))?.transactionIndex ?? 0

                whereClause += """
                               WHERE (
                                \(Transaction.Columns.timestamp.name) < \(fromTransaction.timestamp) || 
                                    (
                                        \(Transaction.databaseTableName).\(Transaction.Columns.timestamp.name) == \(fromTransaction.timestamp) AND 
                                        \(TransactionReceipt.databaseTableName).\(TransactionReceipt.Columns.transactionIndex.name) < \(transactionIndex)
                                    )
                               )
                               """
            }

            let orderClause = """
                              ORDER BY \(Transaction.databaseTableName).\(Transaction.Columns.timestamp.name) DESC, 
                              \(TransactionReceipt.databaseTableName).\(TransactionReceipt.Columns.transactionIndex.name) DESC
                              """

            let sql = """
                      SELECT transactions.*
                      FROM transactions
                      LEFT JOIN transaction_receipts ON transactions.hash = transaction_receipts.transactionHash
                      \(whereClause)
                      \(orderClause)
                      """

            let rows = try Row.fetchAll(db.makeSelectStatement(sql: sql))
            return rows.map { row -> Transaction in
                Transaction(row: row)
            }
        }

        return fullTransactions(from: transactions)
    }

}

extension TransactionStorage: ITransactionSyncerStateStorage {

    func transactionSyncerState(id: String) -> TransactionSyncerState? {
        try! dbPool.read { db in
            try TransactionSyncerState.filter(TransactionSyncerState.Columns.id == id).fetchOne(db)
        }
    }

    func save(transactionSyncerState: TransactionSyncerState) {
        try! dbPool.write { db in
            try transactionSyncerState.save(db)
        }
    }

}
