// ============================================================
// backfill-cost-prices.apex
// Backfills Cost_Price__c on existing PricebookEntries created by an
// earlier run of seed-retail-quotes.apex (which predated the cost field).
// Idempotent: skips PBEs that already have a Cost_Price__c value.
// ============================================================

Map<String, Decimal> costMap = new Map<String, Decimal>{
    'RTL-DEMO-001' => 1800.00,
    'RTL-DEMO-002' => 550.00,
    'RTL-DEMO-003' => 900.00,
    'RTL-DEMO-004' => 1100.00,
    'RTL-DEMO-005' => 500.00,
    'RTL-DEMO-006' => 200.00,
    'RTL-DEMO-007' => 160.00,
    'RTL-DEMO-008' => 350.00
};

List<PricebookEntry> pbes = [
    SELECT Id, Product2.ProductCode, Cost_Price__c
    FROM PricebookEntry
    WHERE Product2.ProductCode IN :costMap.keySet()
];

List<PricebookEntry> toUpdate = new List<PricebookEntry>();
for (PricebookEntry pbe : pbes) {
    if (pbe.Cost_Price__c == null) {
        pbe.Cost_Price__c = costMap.get(pbe.Product2.ProductCode);
        toUpdate.add(pbe);
    }
}

if (!toUpdate.isEmpty()) {
    update toUpdate;
    System.debug('>>> Backfilled Cost_Price__c on ' + toUpdate.size() + ' PricebookEntries.');
} else {
    System.debug('>>> All matching PricebookEntries already have Cost_Price__c set. Nothing to do.');
}
