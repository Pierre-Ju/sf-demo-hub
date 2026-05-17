// ============================================================
// seed-manufacturing.apex
// Seeds a manufacturing-flavoured demo dataset onto a scratch org.
// Idempotent: keys off the marker account "Atlas Precision Components".
// ============================================================

List<Account> marker = [SELECT Id FROM Account WHERE Name = 'Atlas Precision Components' LIMIT 1];
if (!marker.isEmpty()) {
    System.debug('>>> Manufacturing demo data already present. Skipping seed.');
    return;
}

System.debug('>>> Seeding Manufacturing demo data...');

List<Account> accounts = new List<Account>{
    new Account(Name = 'Atlas Precision Components', Industry = 'Manufacturing', Type = 'Customer - Direct',
                AnnualRevenue = 240000000, NumberOfEmployees = 1200, BillingCountry = 'United States', BillingState = 'Michigan'),
    new Account(Name = 'Helix Industrial Motors',    Industry = 'Manufacturing', Type = 'Customer - Direct',
                AnnualRevenue = 815000000, NumberOfEmployees = 3400, BillingCountry = 'Germany', BillingState = 'Bavaria'),
    new Account(Name = 'Northwind Heavy Equipment',  Industry = 'Manufacturing', Type = 'Customer - Channel',
                AnnualRevenue = 1200000000, NumberOfEmployees = 5800, BillingCountry = 'Canada', BillingState = 'Ontario'),
    new Account(Name = 'Kanto Robotics Co., Ltd.',   Industry = 'Manufacturing', Type = 'Prospect',
                AnnualRevenue = 96000000, NumberOfEmployees = 420, BillingCountry = 'Japan', BillingState = 'Tokyo'),
    new Account(Name = 'Stellar Aerospace Parts',    Industry = 'Aerospace',     Type = 'Customer - Direct',
                AnnualRevenue = 540000000, NumberOfEmployees = 2100, BillingCountry = 'United States', BillingState = 'California'),
    new Account(Name = 'Brightline EV Modules',      Industry = 'Automotive',    Type = 'Prospect',
                AnnualRevenue = 78000000, NumberOfEmployees = 310,  BillingCountry = 'United Kingdom', BillingState = 'England')
};
insert accounts;

List<Contact> contacts = new List<Contact>();
for (Account a : accounts) {
    contacts.add(new Contact(AccountId = a.Id, FirstName = 'Procurement', LastName = a.Name.substringBefore(' ') + ' Lead',
                             Title = 'Director of Procurement', Email = 'proc.' + a.Name.deleteWhitespace().toLowerCase() + '@example.com'));
    contacts.add(new Contact(AccountId = a.Id, FirstName = 'Plant',       LastName = a.Name.substringBefore(' ') + ' Engineer',
                             Title = 'Plant Operations Manager', Email = 'ops.'  + a.Name.deleteWhitespace().toLowerCase() + '@example.com'));
}
insert contacts;

List<Opportunity> opps = new List<Opportunity>();
opps.add(new Opportunity(Name = 'Atlas — Q3 CNC Spindle Order',      AccountId = accounts[0].Id, StageName = 'Proposal/Price Quote',
                         Amount = 420000,  CloseDate = Date.today().addDays(35)));
opps.add(new Opportunity(Name = 'Helix — Annual Bearing Contract',   AccountId = accounts[1].Id, StageName = 'Negotiation/Review',
                         Amount = 1850000, CloseDate = Date.today().addDays(20)));
opps.add(new Opportunity(Name = 'Northwind — Excavator Fleet Refit', AccountId = accounts[2].Id, StageName = 'Value Proposition',
                         Amount = 3200000, CloseDate = Date.today().addDays(75)));
opps.add(new Opportunity(Name = 'Kanto — Pilot Robot Arm POC',       AccountId = accounts[3].Id, StageName = 'Qualification',
                         Amount = 95000,   CloseDate = Date.today().addDays(60)));
opps.add(new Opportunity(Name = 'Stellar — Turbine Blade Tooling',   AccountId = accounts[4].Id, StageName = 'Closed Won',
                         Amount = 780000,  CloseDate = Date.today().addDays(-10)));
opps.add(new Opportunity(Name = 'Brightline — EV Battery Trays',     AccountId = accounts[5].Id, StageName = 'Prospecting',
                         Amount = 260000,  CloseDate = Date.today().addDays(110)));
insert opps;

System.debug('>>> Seeded ' + accounts.size() + ' accounts, ' + contacts.size() + ' contacts, ' + opps.size() + ' opportunities.');
