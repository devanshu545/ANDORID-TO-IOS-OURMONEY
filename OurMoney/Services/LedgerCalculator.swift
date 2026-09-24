enum TransactionType {
    case income
    case transfer
    case expense // Assuming a general expense type for shared transactions
}

struct Split {
    let userId: String
    let amountPaise: Int64
}

struct Transaction {
    let isDeleted: Bool
    let personal: Bool
    let type: TransactionType
    let paidBy: String
    let amountPaise: Int64
    let splits: [Split]
}

struct Settlement {
    let paidBy: String
    let receivedBy: String
    let amountPaise: Int64
}

struct LedgerBalance {
    let amountOwedToMePaise: Int64
    let amountIOwePaise: Int64
    let netBalancePaise: Int64 // Positive means I am ahead, negative means I am behind
    let totalSharedPaidByMePaise: Int64
    let totalSharedPaidByPartnerPaise: Int64
    let myResponsibilityPaise: Int64
    let partnerResponsibilityPaise: Int64
    let totalSettlementsPaidByMePaise: Int64
    let totalSettlementsPaidByPartnerPaise: Int64
}

class LedgerCalculator {
    func calculateNetBalance(
        currentUserId: String,
        transactions: [Transaction],
        settlements: [Settlement]
    ) -> LedgerBalance {
        var myTotalPaid: Int64 = 0
        var partnerTotalPaid: Int64 = 0

        var myTotalResponsibility: Int64 = 0
        var partnerTotalResponsibility: Int64 = 0

        // Process ONLY Shared Transactions
        for tx in transactions {
            // Ignore Personal, Income, deleted, and Transfer transactions
            if tx.isDeleted || tx.personal || tx.type == .income || tx.type == .transfer {
                continue
            }

            // 1. Who actually paid?
            if tx.paidBy == currentUserId {
                myTotalPaid += tx.amountPaise
            } else {
                partnerTotalPaid += tx.amountPaise
            }

            // 2. Who is responsible for what portion? (Kept for UI display if needed)
            for split in tx.splits {
                if split.userId == currentUserId {
                    myTotalResponsibility += split.amountPaise
                } else {
                    partnerTotalResponsibility += split.amountPaise
                }
            }
        }

        // 50/50 SPLIT MATHEMATICAL MODEL
        // Net balance is calculated as half the difference between what I paid and what the partner paid.
        var myNetBalance = (myTotalPaid - partnerTotalPaid) / 2

        var settlementsByMe: Int64 = 0
        var settlementsByPartner: Int64 = 0

        // Process Settlements
        for settlement in settlements {
            if settlement.paidBy == currentUserId {
                // I made a settlement payment to the partner. This puts me more "ahead".
                myNetBalance += settlement.amountPaise
                settlementsByMe += settlement.amountPaise
            } else if settlement.receivedBy == currentUserId {
                // I received a settlement payment from the partner. This reduces my "ahead" balance.
                myNetBalance -= settlement.amountPaise
                settlementsByPartner += settlement.amountPaise
            }
        }

        let owedToMe = myNetBalance > 0 ? myNetBalance : 0
        let iOwe = myNetBalance < 0 ? -myNetBalance : 0

        return LedgerBalance(
            amountOwedToMePaise: owedToMe,
            amountIOwePaise: iOwe,
            netBalancePaise: myNetBalance,
            totalSharedPaidByMePaise: myTotalPaid,
            totalSharedPaidByPartnerPaise: partnerTotalPaid,
            myResponsibilityPaise: myTotalResponsibility,
            partnerResponsibilityPaise: partnerTotalResponsibility,
            totalSettlementsPaidByMePaise: settlementsByMe,
            totalSettlementsPaidByPartnerPaise: settlementsByPartner
        )
    }
}