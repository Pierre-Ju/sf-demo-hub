// ============================================================
// setup-demo-manager.apex
// Creates a demo Manager user (周雪 / 销售总监) so the Quote approval
// process has someone to route to, then sets the current admin user's
// Manager field to point at her.
//
// Idempotent: checks for an existing demo manager by a fixed marker
// username before creating.
// ============================================================

String mgrUsername = 'demo.manager+' + UserInfo.getOrganizationId() + '@retaildemo.example.com';

List<User> existing = [SELECT Id, Username FROM User WHERE Username = :mgrUsername LIMIT 1];

User mgr;
if (existing.isEmpty()) {
    Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    mgr = new User(
        Username          = mgrUsername,
        LastName          = '周',
        FirstName         = '雪',
        Title             = '销售总监',
        Email             = 'demo-manager@retaildemo.example.com',
        Alias             = 'zxue',
        CommunityNickname = 'demo-mgr-' + String.valueOf(Math.mod(System.now().getTime(), 100000)),
        TimeZoneSidKey    = 'Asia/Shanghai',
        LocaleSidKey      = 'zh_CN',
        EmailEncodingKey  = 'UTF-8',
        ProfileId         = sysAdmin.Id,
        LanguageLocaleKey = 'zh_CN'
    );
    insert mgr;
    System.debug('>>> Created demo Manager user: ' + mgr.Username + ' (Id=' + mgr.Id + ')');
} else {
    mgr = existing[0];
    System.debug('>>> Demo Manager user already exists: ' + mgrUsername);
}

// Point the running user's Manager at the demo manager
Id currentUserId = UserInfo.getUserId();
User currentUser = [SELECT Id, Username, ManagerId FROM User WHERE Id = :currentUserId LIMIT 1];
if (currentUser.ManagerId != mgr.Id) {
    currentUser.ManagerId = mgr.Id;
    update currentUser;
    System.debug('>>> Set ' + currentUser.Username + ' .ManagerId → ' + mgr.Username);
} else {
    System.debug('>>> ' + currentUser.Username + ' Manager already points to demo manager. No-op.');
}

System.debug('>>> 审批演练流程：');
System.debug('    1. 提交 Quote → 路由到周雪（demo Manager）');
System.debug('    2. Setup → Users → 点周雪行尾的 Login 图标，以她身份登入');
System.debug('    3. 在首页 / My Approvals 看到审批请求，点 Approve');
System.debug('    4. 切回 admin，看到 Quote.Status = Approved');
