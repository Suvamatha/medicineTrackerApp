class Loc {
  static const Map<String, Map<String, String>> dict = {
    "Dashboard": {"en": "Dashboard", "np": "ड्यासबोर्ड"},
    "Medicines": {"en": "Medicines", "np": "औषधिहरू"},
    "History": {"en": "History", "np": "इतिहास"},
    "Today's Progress": {"en": "Today's Progress", "np": "आजको प्रगति"},
    "Total": {"en": "Total", "np": "कुल"},
    "Taken": {"en": "Taken", "np": "खाइएको"},
    "Missed": {"en": "Missed", "np": "छुटेको"},
    "Pending": {"en": "Pending", "np": "बाँकी"},
    "Add Medication": {"en": "Add Medication", "np": "औषधि थप्नुहोस्"},
    "Medicine Name": {"en": "Medicine Name", "np": "औषधिको नाम"},
    "Select Time": {"en": "Select Time", "np": "समय छान्नुहोस्"},
    "Repeat Daily": {"en": "Repeat Daily", "np": "दैनिक दोहोर्याउनुहोस्"},
    "Remind me every day": {"en": "Remind me every day at this time", "np": "मलाई हरेक दिन यही समयमा सम्झाउनुहोस्"},
    "Please enter": {"en": "Please enter name and time", "np": "कृपया नाम र समय प्रविष्ट गर्नुहोस्"},
    "Save Medicine": {"en": "Save Medicine", "np": "औषधि सेभ गर्नुहोस्"},
    "Snoozed": {"en": "Snoozed for 10 minutes", "np": "१० मिनेटको लागि स्नुज गरियो"},
    "Analytics & Gamification": {"en": "Analytics & Gamification", "np": "एनालाइटिक्स र गेमिफिकेशन"},
    "Weekly Adherence": {"en": "Weekly Adherence", "np": "साप्ताहिक अनुपालन"},
    "Best Streak": {"en": "Best Streak", "np": "उत्कृष्ट निरन्तरता"},
    "No History": {"en": "No history yet", "np": "अहिलेसम्म कुनै इतिहास छैन"},
    "No Meds": {"en": "No medicines yet. Add one!", "np": "कुनै औषधि छैन। एउटा थप्नुहोस्!"},
    "Copied": {"en": "Data copied to clipboard!", "np": "डाटा क्लिपबोर्डमा कपि भयो!"},
  };

  static String get(String key, bool isNepali) {
    if (!dict.containsKey(key)) return key;
    return dict[key]![isNepali ? "np" : "en"] ?? key;
  }
}
