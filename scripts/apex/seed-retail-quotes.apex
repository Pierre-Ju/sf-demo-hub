// ============================================================
// seed-retail-quotes.apex
// Seeds Products, Pricebook, and Opportunity line items so the
// Quote demo flow has data to work with on an existing demo-retail org.
//
// Prerequisites: seed-retail.apex has been run (Accounts + Opportunities exist).
// Idempotent: keys off marker Product code 'RTL-DEMO-001'.
// ============================================================

List<Product2> marker = [SELECT Id FROM Product2 WHERE ProductCode = 'RTL-DEMO-001' LIMIT 1];
if (!marker.isEmpty()) {
    System.debug('>>> Retail quote-demo data already present. Skipping seed.');
    return;
}

System.debug('>>> Seeding Retail quote-demo data (products, pricebook, line items)...');

// === 1. Activate the Standard Pricebook ===
// In scratch orgs the standard pricebook exists but is inactive by default.
Pricebook2 stdPb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
if (!stdPb.IsActive) {
    stdPb.IsActive = true;
    update stdPb;
    System.debug('>>> Activated Standard Pricebook.');
}

// === 2. Create retail products ===
List<Product2> products = new List<Product2>{
    new Product2(Name='智能扫地机器人 Pro',  ProductCode='RTL-DEMO-001', IsActive=true,
                 Description='2025年款，全屋激光导航 + 自动集尘'),
    new Product2(Name='进口红酒礼盒装',      ProductCode='RTL-DEMO-002', IsActive=true,
                 Description='波尔多产区六支装节庆礼盒'),
    new Product2(Name='真丝家居四件套',       ProductCode='RTL-DEMO-003', IsActive=true,
                 Description='100% 桑蚕丝，1.8m 标准床品'),
    new Product2(Name='蓝牙降噪耳机',         ProductCode='RTL-DEMO-004', IsActive=true,
                 Description='主动降噪 + 35小时续航'),
    new Product2(Name='高端瓷器茶具套装',     ProductCode='RTL-DEMO-005', IsActive=true,
                 Description='景德镇手绘十二件套'),
    new Product2(Name='法式马卡龙礼盒',       ProductCode='RTL-DEMO-006', IsActive=true,
                 Description='12 枚装，6 种口味'),
    new Product2(Name='智能体脂秤',           ProductCode='RTL-DEMO-007', IsActive=true,
                 Description='13 项身体数据 + App 同步'),
    new Product2(Name='羊绒围巾',             ProductCode='RTL-DEMO-008', IsActive=true,
                 Description='内蒙古 100% 山羊绒')
};
insert products;

// === 3. Create PricebookEntry on Standard Pricebook ===
Map<String, Decimal> priceMap = new Map<String, Decimal>{
    'RTL-DEMO-001' => 2499.00,
    'RTL-DEMO-002' => 899.00,
    'RTL-DEMO-003' => 1599.00,
    'RTL-DEMO-004' => 1299.00,
    'RTL-DEMO-005' => 699.00,
    'RTL-DEMO-006' => 299.00,
    'RTL-DEMO-007' => 199.00,
    'RTL-DEMO-008' => 499.00
};
// 成本价：与售价拉开毛利率，部分商品毛利接近/超过 15% 阈值以演示审批触发
Map<String, Decimal> costMap = new Map<String, Decimal>{
    'RTL-DEMO-001' => 1800.00,  // 毛利 28%
    'RTL-DEMO-002' => 550.00,   // 毛利 39%
    'RTL-DEMO-003' => 900.00,   // 毛利 44%
    'RTL-DEMO-004' => 1100.00,  // 毛利 15%（临界）
    'RTL-DEMO-005' => 500.00,   // 毛利 28%
    'RTL-DEMO-006' => 200.00,   // 毛利 33%
    'RTL-DEMO-007' => 160.00,   // 毛利 20%
    'RTL-DEMO-008' => 350.00    // 毛利 30%
};
List<PricebookEntry> pbeList = new List<PricebookEntry>();
for (Product2 p : products) {
    pbeList.add(new PricebookEntry(
        Pricebook2Id     = stdPb.Id,
        Product2Id       = p.Id,
        UnitPrice        = priceMap.get(p.ProductCode),
        Cost_Price__c    = costMap.get(p.ProductCode),
        IsActive         = true,
        UseStandardPrice = false
    ));
}
insert pbeList;
Map<String, Id> codeToPbeId = new Map<String, Id>();
for (Integer i = 0; i < products.size(); i++) {
    codeToPbeId.put(products[i].ProductCode, pbeList[i].Id);
}

// === 4. Attach Standard Pricebook to all existing demo Opportunities ===
// Quote needs an Opportunity with a Pricebook2Id set in order to inherit line items.
List<Opportunity> opps = [SELECT Id, Name, Amount, StageName, Pricebook2Id
                          FROM Opportunity WHERE Pricebook2Id = NULL];
for (Opportunity o : opps) { o.Pricebook2Id = stdPb.Id; }
if (!opps.isEmpty()) update opps;
System.debug('>>> Attached Standard Pricebook to ' + opps.size() + ' Opportunities.');

// === 5. Add OpportunityLineItems to mid/late-stage Opps ===
// Pick Opps in Proposal/Price Quote and Closed Won stages — these are the ones
// most likely to need a quote in a real demo.
List<Opportunity> proposalOpps = [
    SELECT Id, Name, Amount
    FROM Opportunity
    WHERE StageName IN ('Proposal/Price Quote', 'Closed Won')
    ORDER BY Amount DESC
    LIMIT 6
];

// Mix of products per opp: 3-4 lines each, picked to roughly match Opp Amount.
// Keep quantities and unit prices simple — exact total doesn't need to match Amount.
List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
String[] codes = new String[]{'RTL-DEMO-001','RTL-DEMO-002','RTL-DEMO-003',
                              'RTL-DEMO-004','RTL-DEMO-005','RTL-DEMO-006',
                              'RTL-DEMO-007','RTL-DEMO-008'};
Integer[][] mixes = new Integer[][]{
    new Integer[]{0, 3, 5},          // 扫地机+四件套+马卡龙
    new Integer[]{1, 4, 7},          // 红酒+茶具+围巾
    new Integer[]{0, 2, 3, 6},       // 扫地机+四件套+耳机+体脂秤
    new Integer[]{2, 4, 5, 7},       // 四件套+茶具+马卡龙+围巾
    new Integer[]{0, 1, 3},          // 扫地机+红酒+耳机
    new Integer[]{2, 3, 4, 6}        // 四件套+耳机+茶具+体脂秤
};
Integer[] qtyBase = new Integer[]{50, 100, 30, 80, 200, 500, 150, 120};

for (Integer i = 0; i < proposalOpps.size(); i++) {
    Integer[] mix = mixes[Math.mod(i, mixes.size())];
    for (Integer idx : mix) {
        olis.add(new OpportunityLineItem(
            OpportunityId    = proposalOpps[i].Id,
            PricebookEntryId = codeToPbeId.get(codes[idx]),
            Quantity         = qtyBase[idx],
            UnitPrice        = priceMap.get(codes[idx])
        ));
    }
}
insert olis;

// === Summary ===
System.debug('>>> Seeded ' + products.size() + ' 商品, '
             + pbeList.size() + ' 价目条目, '
             + olis.size() + ' 商机产品行 (覆盖 ' + proposalOpps.size() + ' 条商机).');
System.debug('>>> 可在以下商机上创建 Quote（含产品行）：');
for (Opportunity o : proposalOpps) {
    System.debug('    - ' + o.Name + ' (¥' + o.Amount + ')');
}
