// ============================================================
// seed-retail.apex
// Seeds a China-market retail demo dataset onto a scratch org.
// All names / addresses / titles are Chinese, fitting Chinese market conventions.
// Idempotent: keys off marker account "锦绣商业控股集团".
// ============================================================

List<Account> marker = [SELECT Id FROM Account WHERE Name = '锦绣商业控股集团' LIMIT 1];
if (!marker.isEmpty()) {
    System.debug('>>> Retail demo data already present. Skipping seed.');
    return;
}

System.debug('>>> Seeding Retail demo data (China market)...');

// === 12 零售企业账户 ===
List<Account> accounts = new List<Account>{
    new Account(Name='锦绣商业控股集团',  Industry='Retail',      Type='Customer - Direct',
                AnnualRevenue=2800000000.0, NumberOfEmployees=15000, BillingCountry='中国', BillingState='上海'),
    new Account(Name='华彩百货连锁',      Industry='Retail',      Type='Customer - Direct',
                AnnualRevenue=1500000000.0, NumberOfEmployees=8500,  BillingCountry='中国', BillingState='北京'),
    new Account(Name='万家鲜生超市',      Industry='Retail',      Type='Customer - Direct',
                AnnualRevenue=900000000.0,  NumberOfEmployees=5200,  BillingCountry='中国', BillingState='广东'),
    new Account(Name='智悦数码电器',      Industry='Electronics', Type='Customer - Channel',
                AnnualRevenue=1200000000.0, NumberOfEmployees=6800,  BillingCountry='中国', BillingState='浙江'),
    new Account(Name='金都购物中心',      Industry='Retail',      Type='Customer - Direct',
                AnnualRevenue=750000000.0,  NumberOfEmployees=3500,  BillingCountry='中国', BillingState='江苏'),
    new Account(Name='优品便利店连锁',    Industry='Retail',      Type='Customer - Channel',
                AnnualRevenue=480000000.0,  NumberOfEmployees=2400,  BillingCountry='中国', BillingState='广东'),
    new Account(Name='蓝海百货商场',      Industry='Retail',      Type='Prospect',
                AnnualRevenue=620000000.0,  NumberOfEmployees=3100,  BillingCountry='中国', BillingState='四川'),
    new Account(Name='旺购超市集团',      Industry='Retail',      Type='Customer - Direct',
                AnnualRevenue=850000000.0,  NumberOfEmployees=4600,  BillingCountry='中国', BillingState='山东'),
    new Account(Name='红木家居连锁',      Industry='Retail',      Type='Prospect',
                AnnualRevenue=380000000.0,  NumberOfEmployees=1800,  BillingCountry='中国', BillingState='福建'),
    new Account(Name='安居生活家居',      Industry='Retail',      Type='Customer - Direct',
                AnnualRevenue=520000000.0,  NumberOfEmployees=2700,  BillingCountry='中国', BillingState='湖北'),
    new Account(Name='全时便利连锁',      Industry='Retail',      Type='Customer - Channel',
                AnnualRevenue=290000000.0,  NumberOfEmployees=1500,  BillingCountry='中国', BillingState='天津'),
    new Account(Name='鲜美严选超市',      Industry='Retail',      Type='Prospect',
                AnnualRevenue=420000000.0,  NumberOfEmployees=2100,  BillingCountry='中国', BillingState='重庆')
};
insert accounts;

// === 联系人：每账户 CEO + 采购经理 ===
String[][] ceoNames = new String[][]{
    new String[]{'张','伟'},  new String[]{'王','芳'},  new String[]{'李','明'},
    new String[]{'刘','强'},  new String[]{'陈','雪'},  new String[]{'杨','磊'},
    new String[]{'黄','丽'},  new String[]{'赵','涛'},  new String[]{'周','敏'},
    new String[]{'吴','勇'},  new String[]{'徐','婷'},  new String[]{'孙','华'}
};
String[][] buyerNames = new String[][]{
    new String[]{'朱','建国'}, new String[]{'胡','晓燕'}, new String[]{'郭','浩'},
    new String[]{'何','玲'},   new String[]{'高','峰'},   new String[]{'林','梅'},
    new String[]{'罗','刚'},   new String[]{'郑','红'},   new String[]{'梁','俊'},
    new String[]{'谢','娟'},   new String[]{'韩','斌'},   new String[]{'唐','丽'}
};

List<Contact> contacts = new List<Contact>();
for (Integer i = 0; i < accounts.size(); i++) {
    contacts.add(new Contact(
        AccountId = accounts[i].Id,
        LastName  = ceoNames[i][0],   FirstName = ceoNames[i][1],
        Title     = '首席执行官',
        Email     = 'ceo' + (i+1) + '@retaildemo.example.com'
    ));
    contacts.add(new Contact(
        AccountId = accounts[i].Id,
        LastName  = buyerNames[i][0], FirstName = buyerNames[i][1],
        Title     = '采购经理',
        Email     = 'buyer' + (i+1) + '@retaildemo.example.com'
    ));
}
insert contacts;

// === 15 条商机，分布 4 个阶段，总额约 300 万，2 条 > 50 万触发 Flow ===
// Q2 2026 = 2026-04-01 ~ 2026-06-30；所有 CloseDate 落在本季度内
List<Opportunity> opps = new List<Opportunity>{
    // -- Prospecting (4) | 50+80+100+120 = 350 千 --
    new Opportunity(Name='智悦数码 — 智能家居终端铺货', AccountId=accounts[3].Id,
                    StageName='Prospecting', Amount=50000,  CloseDate=Date.today().addDays(44)),
    new Opportunity(Name='优品便利 — 鲜食供应链试点',   AccountId=accounts[5].Id,
                    StageName='Prospecting', Amount=80000,  CloseDate=Date.today().addDays(40)),
    new Opportunity(Name='红木家居 — 高端实木家具展销', AccountId=accounts[8].Id,
                    StageName='Prospecting', Amount=100000, CloseDate=Date.today().addDays(35)),
    new Opportunity(Name='鲜美严选 — 自有品牌生鲜上架', AccountId=accounts[11].Id,
                    StageName='Prospecting', Amount=120000, CloseDate=Date.today().addDays(42)),

    // -- Qualification (4) | 130+150+180+200 = 660 千 --
    new Opportunity(Name='金都购物 — 节庆礼品季订单',     AccountId=accounts[4].Id,
                    StageName='Qualification', Amount=130000, CloseDate=Date.today().addDays(25)),
    new Opportunity(Name='蓝海百货 — 自有品牌服装合作',   AccountId=accounts[6].Id,
                    StageName='Qualification', Amount=150000, CloseDate=Date.today().addDays(20)),
    new Opportunity(Name='旺购超市 — 进口食品专区入驻',   AccountId=accounts[7].Id,
                    StageName='Qualification', Amount=180000, CloseDate=Date.today().addDays(18)),
    new Opportunity(Name='全时便利 — 24小时门店扩张采购', AccountId=accounts[10].Id,
                    StageName='Qualification', Amount=200000, CloseDate=Date.today().addDays(22)),

    // -- Proposal/Price Quote (4) | 260+300+520+580 = 1660 千；2 条 > 50 万 --
    new Opportunity(Name='锦绣集团 — Q2旺季商品采购', AccountId=accounts[0].Id,
                    StageName='Proposal/Price Quote', Amount=260000, CloseDate=Date.today().addDays(14)),
    new Opportunity(Name='华彩百货 — 春装新品引进',   AccountId=accounts[1].Id,
                    StageName='Proposal/Price Quote', Amount=300000, CloseDate=Date.today().addDays(10)),
    new Opportunity(Name='万家鲜生 — 生鲜冷链系统升级', AccountId=accounts[2].Id,
                    StageName='Proposal/Price Quote', Amount=520000, CloseDate=Date.today().addDays(20)),
    new Opportunity(Name='安居生活 — 智能家居样板房',   AccountId=accounts[9].Id,
                    StageName='Proposal/Price Quote', Amount=580000, CloseDate=Date.today().addDays(15)),

    // -- Closed Won (3) | 130+180+250 = 560 千 --
    new Opportunity(Name='锦绣集团 — Q2框架协议',     AccountId=accounts[0].Id,
                    StageName='Closed Won', Amount=130000, CloseDate=Date.today().addDays(-30)),
    new Opportunity(Name='智悦数码 — 5月家电采购',    AccountId=accounts[3].Id,
                    StageName='Closed Won', Amount=180000, CloseDate=Date.today().addDays(-15)),
    new Opportunity(Name='万家鲜生 — Q2生鲜直采',     AccountId=accounts[2].Id,
                    StageName='Closed Won', Amount=250000, CloseDate=Date.today().addDays(-5))
};
insert opps;

// === Summary ===
Decimal total = 0; Integer highValue = 0;
for (Opportunity o : opps) { total += o.Amount; if (o.Amount > 500000) highValue++; }
System.debug('>>> Seeded ' + accounts.size() + ' 账户, ' + contacts.size() + ' 联系人, '
             + opps.size() + ' 商机 (总额 ¥' + total + ', ' + highValue + ' 条 > 50万 触发 Flow).');
