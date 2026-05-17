// ============================================================
// seed-healthcare.apex
// Seeds a healthcare-flavoured demo dataset onto a scratch org.
// Idempotent: keys off the marker account "Cedar Ridge Medical Center".
// Uses business Account + Contact (not PersonAccount) to remain portable
// even when the org does not have PersonAccounts enabled.
// ============================================================

List<Account> marker = [SELECT Id FROM Account WHERE Name = 'Cedar Ridge Medical Center' LIMIT 1];
if (!marker.isEmpty()) {
    System.debug('>>> Healthcare demo data already present. Skipping seed.');
    return;
}

System.debug('>>> Seeding Healthcare demo data...');

// --- Provider organizations ---
List<Account> providers = new List<Account>{
    new Account(Name = 'Cedar Ridge Medical Center',  Industry = 'Healthcare', Type = 'Customer - Direct',
                NumberOfEmployees = 4200, BillingCountry = 'United States', BillingState = 'Colorado'),
    new Account(Name = 'Brookline Children''s Hospital', Industry = 'Healthcare', Type = 'Customer - Direct',
                NumberOfEmployees = 2100, BillingCountry = 'United States', BillingState = 'Massachusetts'),
    new Account(Name = 'Harbor Bay Cardiology Group', Industry = 'Healthcare', Type = 'Customer - Channel',
                NumberOfEmployees = 180,  BillingCountry = 'United States', BillingState = 'California'),
    new Account(Name = 'Northern Lights Rehab Clinic', Industry = 'Healthcare', Type = 'Prospect',
                NumberOfEmployees = 90,   BillingCountry = 'Canada',        BillingState = 'Alberta'),
    new Account(Name = 'Meridian Health Insurance',   Industry = 'Insurance', Type = 'Customer - Direct',
                NumberOfEmployees = 6500, BillingCountry = 'United States', BillingState = 'Illinois')
};
insert providers;

// --- Clinicians / care team contacts ---
List<Contact> clinicians = new List<Contact>();
clinicians.add(new Contact(AccountId = providers[0].Id, FirstName = 'Elena',  LastName = 'Marquez', Title = 'Chief Medical Officer',  Email = 'emarquez@cedarridge.example'));
clinicians.add(new Contact(AccountId = providers[0].Id, FirstName = 'Daniel', LastName = 'Park',    Title = 'Patient Access Director', Email = 'dpark@cedarridge.example'));
clinicians.add(new Contact(AccountId = providers[1].Id, FirstName = 'Sofia',  LastName = 'Nair',    Title = 'Pediatric Oncologist',   Email = 'snair@brookline.example'));
clinicians.add(new Contact(AccountId = providers[2].Id, FirstName = 'Marcus', LastName = 'Greene',  Title = 'Interventional Cardiologist', Email = 'mgreene@harborbay.example'));
clinicians.add(new Contact(AccountId = providers[3].Id, FirstName = 'Ingrid', LastName = 'Olsen',   Title = 'Clinic Director',        Email = 'iolsen@northernlights.example'));
clinicians.add(new Contact(AccountId = providers[4].Id, FirstName = 'Aaron',  LastName = 'Webb',    Title = 'Plan Enrollment Lead',   Email = 'awebb@meridianhealth.example'));
insert clinicians;

// --- "Patient households" modeled as business accounts to stay portable ---
List<Account> households = new List<Account>{
    new Account(Name = 'Patel Family Household',   Type = 'Household', BillingCountry = 'United States', BillingState = 'Texas'),
    new Account(Name = 'Okafor Family Household',  Type = 'Household', BillingCountry = 'United States', BillingState = 'Georgia'),
    new Account(Name = 'Zhang Family Household',   Type = 'Household', BillingCountry = 'United States', BillingState = 'Washington')
};
insert households;

List<Contact> patients = new List<Contact>();
patients.add(new Contact(AccountId = households[0].Id, FirstName = 'Anika',  LastName = 'Patel',   Title = 'Patient', Birthdate = Date.newInstance(1982, 4, 12),  Email = 'anika.patel@example.com'));
patients.add(new Contact(AccountId = households[0].Id, FirstName = 'Rohan',  LastName = 'Patel',   Title = 'Patient', Birthdate = Date.newInstance(2014, 9, 30),  Email = 'rohan.patel@example.com'));
patients.add(new Contact(AccountId = households[1].Id, FirstName = 'Chiamaka', LastName = 'Okafor', Title = 'Patient', Birthdate = Date.newInstance(1959, 1, 7),   Email = 'chiamaka.okafor@example.com'));
patients.add(new Contact(AccountId = households[2].Id, FirstName = 'Wei',     LastName = 'Zhang',  Title = 'Patient', Birthdate = Date.newInstance(1991, 11, 22), Email = 'wei.zhang@example.com'));
insert patients;

// --- Cases stand in for referrals / care requests ---
List<Case> cases = new List<Case>{
    new Case(AccountId = providers[0].Id, ContactId = patients[0].Id, Subject = 'Referral — annual cardiology workup',
             Status = 'New',        Priority = 'Medium', Origin = 'Phone'),
    new Case(AccountId = providers[1].Id, ContactId = patients[1].Id, Subject = 'New patient intake — pediatric oncology consult',
             Status = 'Working',    Priority = 'High',   Origin = 'Web'),
    new Case(AccountId = providers[2].Id, ContactId = patients[2].Id, Subject = 'Pre-op evaluation — coronary stent placement',
             Status = 'Working',    Priority = 'High',   Origin = 'Phone'),
    new Case(AccountId = providers[3].Id, ContactId = patients[3].Id, Subject = 'Post-discharge physical therapy plan',
             Status = 'Escalated',  Priority = 'Medium', Origin = 'Email')
};
insert cases;

System.debug('>>> Seeded ' + providers.size() + ' providers, ' + households.size() + ' households, '
             + (clinicians.size() + patients.size()) + ' contacts, ' + cases.size() + ' cases.');
