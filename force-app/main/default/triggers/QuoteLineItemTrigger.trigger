trigger QuoteLineItemTrigger on QuoteLineItem (after insert, after update, after delete, after undelete) {
    Set<Id> quoteIds = new Set<Id>();
    List<QuoteLineItem> records = Trigger.isDelete ? Trigger.old : Trigger.new;
    for (QuoteLineItem qli : records) {
        if (qli.QuoteId != null) quoteIds.add(qli.QuoteId);
    }
    if (quoteIds.isEmpty()) return;

    Map<Id, Decimal> totalByQuote = new Map<Id, Decimal>();
    for (Id qId : quoteIds) totalByQuote.put(qId, 0);

    for (QuoteLineItem qli : [
        SELECT QuoteId, Cost_Price__c, Quantity
        FROM QuoteLineItem
        WHERE QuoteId IN :quoteIds
    ]) {
        Decimal cp  = qli.Cost_Price__c == null ? 0 : qli.Cost_Price__c;
        Decimal qty = qli.Quantity      == null ? 0 : qli.Quantity;
        totalByQuote.put(qli.QuoteId, totalByQuote.get(qli.QuoteId) + cp * qty);
    }

    List<Quote> toUpdate = new List<Quote>();
    for (Id qId : totalByQuote.keySet()) {
        toUpdate.add(new Quote(Id = qId, Total_Cost__c = totalByQuote.get(qId)));
    }
    if (!toUpdate.isEmpty()) update toUpdate;
}
