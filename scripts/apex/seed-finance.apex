// ============================================================
// seed-finance.apex
// Seeds a financial-services demo dataset onto a scratch org.
// Idempotent: keys off the marker account "Sterling Wealth Advisors".
// Uses business Account + Contact (not PersonAccount) to remain portable
// even when the org does not have PersonAccounts enabled.
// ============================================================

List<Account> marker = [SELECT Id FROM Account WHERE Name = 'Sterling Wealth Advisors' LIMIT 1];
if (!marker.isEmpty()) {
    System.debug('>>> Finance demo data already present. Skipping seed.');
    return;
}

System.debug('>>> Seeding Finance demo data...');

// --- Institutional / advisory firm accounts ---
List<Account> firms = new List<Account>{
    new Account(Name = 'Sterling Wealth Advisors',  Industry = 'Finance', Type = 'Customer - Direct',
                AnnualRevenue = 480000000, NumberOfEmployees = 620,  BillingCountry = 'United States', BillingState = 'New York'),
    new Account(Name = 'Banyan Tree Private Bank',  Industry = 'Banking', Type = 'Customer - Direct',
                AnnualRevenue = 1900000000, NumberOfEmployees = 2400, BillingCountry = 'Singapore',     BillingState = 'Singapore'),
    new Account(Name = 'Northbridge Commercial Lending', Industry = 'Banking', Type = 'Customer - Channel',
                AnnualRevenue = 740000000, NumberOfEmployees = 1100, BillingCountry = 'United States', BillingState = 'Illinois'),
    new Account(Name = 'Aegis Mutual Insurance',    Industry = 'Insurance', Type = 'Customer - Direct',
                AnnualRevenue = 2600000000.0, NumberOfEmployees = 4800, BillingCountry = 'United Kingdom', BillingState = 'England'),
    new Account(Name = 'Polestar Capital Markets',  Industry = 'Finance', Type = 'Prospect',
                AnnualRevenue = 320000000, NumberOfEmployees = 380,  BillingCountry = 'Sweden',         BillingState = 'Stockholm')
};
insert firms;

// --- Advisors / relationship managers ---
List<Contact> advisors = new List<Contact>();
advisors.add(new Contact(AccountId = firms[0].Id, FirstName = 'Priya',   LastName = 'Mehta',    Title = 'Senior Wealth Advisor',     Email = 'pmehta@sterling.example'));
advisors.add(new Contact(AccountId = firms[0].Id, FirstName = 'Jonas',   LastName = 'Lindberg', Title = 'Head of Client Onboarding', Email = 'jlindberg@sterling.example'));
advisors.add(new Contact(AccountId = firms[1].Id, FirstName = 'Mei-Ling', LastName = 'Tan',     Title = 'Private Banking Director',  Email = 'mtan@banyantree.example'));
advisors.add(new Contact(AccountId = firms[2].Id, FirstName = 'Ethan',   LastName = 'Carver',   Title = 'Commercial Lending VP',     Email = 'ecarver@northbridge.example'));
advisors.add(new Contact(AccountId = firms[3].Id, FirstName = 'Hannah',  LastName = 'Whitlock', Title = 'Underwriting Lead',         Email = 'hwhitlock@aegis.example'));
advisors.add(new Contact(AccountId = firms[4].Id, FirstName = 'Lukas',   LastName = 'Berg',     Title = 'Institutional Sales',       Email = 'lberg@polestarcm.example'));
insert advisors;

// --- "Client households" as business accounts to stay portable ---
List<Account> households = new List<Account>{
    new Account(Name = 'Anderson Family Household', Type = 'Household', BillingCountry = 'United States', BillingState = 'California'),
    new Account(Name = 'Khoury Family Household',   Type = 'Household', BillingCountry = 'United States', BillingState = 'Michigan'),
    new Account(Name = 'Yamamoto Family Household', Type = 'Household', BillingCountry = 'Japan',         BillingState = 'Tokyo')
};
insert households;

List<Contact> clients = new List<Contact>();
clients.add(new Contact(AccountId = households[0].Id, FirstName = 'Grace',  LastName = 'Anderson',  Title = 'Primary Account Holder', Email = 'grace.anderson@example.com'));
clients.add(new Contact(AccountId = households[0].Id, FirstName = 'David',  LastName = 'Anderson',  Title = 'Joint Account Holder',   Email = 'david.anderson@example.com'));
clients.add(new Contact(AccountId = households[1].Id, FirstName = 'Rami',   LastName = 'Khoury',    Title = 'Primary Account Holder', Email = 'rami.khoury@example.com'));
clients.add(new Contact(AccountId = households[2].Id, FirstName = 'Haruki', LastName = 'Yamamoto',  Title = 'Primary Account Holder', Email = 'haruki.yamamoto@example.com'));
insert clients;

// --- Opportunities = lending / wealth / underwriting pipeline ---
List<Opportunity> opps = new List<Opportunity>{
    new Opportunity(Name = 'Sterling — Anderson HNW Portfolio Onboarding', AccountId = firms[0].Id, StageName = 'Proposal/Price Quote',
                    Amount = 4800000,  CloseDate = Date.today().addDays(30)),
    new Opportunity(Name = 'Banyan — Khoury Trust Structure Setup',        AccountId = firms[1].Id, StageName = 'Negotiation/Review',
                    Amount = 1200000,  CloseDate = Date.today().addDays(18)),
    new Opportunity(Name = 'Northbridge — Mid-Market Credit Facility',     AccountId = firms[2].Id, StageName = 'Value Proposition',
                    Amount = 25000000, CloseDate = Date.today().addDays(60)),
    new Opportunity(Name = 'Aegis — Group Life Renewal',                    AccountId = firms[3].Id, StageName = 'Closed Won',
                    Amount = 3400000,  CloseDate = Date.today().addDays(-5)),
    new Opportunity(Name = 'Polestar — Institutional Equity Mandate',       AccountId = firms[4].Id, StageName = 'Qualification',
                    Amount = 7800000,  CloseDate = Date.today().addDays(95)),
    new Opportunity(Name = 'Sterling — Yamamoto Cross-Border Advisory',     AccountId = firms[0].Id, StageName = 'Prospecting',
                    Amount = 950000,   CloseDate = Date.today().addDays(120))
};
insert opps;

System.debug('>>> Seeded ' + firms.size() + ' firms, ' + households.size() + ' households, '
             + (advisors.size() + clients.size()) + ' contacts, ' + opps.size() + ' opportunities.');
