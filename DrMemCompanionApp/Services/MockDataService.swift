import Foundation
import SwiftData

struct MockDataService {
    static func populateIfNeeded(modelContext: ModelContext) {
        var descriptor = FetchDescriptor<Memory>()
        descriptor.fetchLimit = 1
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        populateMemories(modelContext: modelContext)
        populateJournalEntries(modelContext: modelContext)
        populateTasks(modelContext: modelContext)
        populateSessions(modelContext: modelContext)
        populateChatThreads(modelContext: modelContext)
    }

    private static func populateMemories(modelContext: ModelContext) {
        let memories: [(CaptureMode, MemoryType, String, String, [String], Bool)] = [
            (.education, .learningPearl, "Beck's Triad in Cardiac Tamponade",
             "Beck's triad consists of hypotension, muffled heart sounds, and jugular venous distension. Key finding in acute cardiac tamponade — don't miss it in trauma patients.",
             ["cardiology", "emergency", "clinical pearl"], true),

            (.education, .learningPearl, "Corrected Calcium Formula",
             "Corrected Ca = Measured Ca + 0.8 × (4.0 − albumin). Always correct calcium for albumin levels, especially in critically ill or malnourished patients.",
             ["endocrine", "lab values", "formula"], false),

            (.education, .feedback, "Attending Feedback: Presentation Skills",
             "Dr. Patel noted: 'Your H&P presentations are thorough but try to lead with the assessment. Start with what you think is going on, then support it with data. Think like a consultant.'",
             ["feedback", "clinical skills", "rounds"], true),

            (.education, .reference, "Antibiotic Ladder for UTI",
             "Uncomplicated: Nitrofurantoin 100mg BID x5d or TMP-SMX DS BID x3d. Complicated: Ciprofloxacin 500mg BID x7d or Ceftriaxone 1g IV. Pyelonephritis: Ceftriaxone → step down to PO based on culture.",
             ["infectious disease", "urology", "antibiotics"], false),

            (.education, .decision, "When to Use tPA in Stroke",
             "tPA (alteplase) window: within 4.5 hours of symptom onset. Contraindications: recent surgery (14d), active bleeding, BP >185/110 despite treatment, platelets <100k, INR >1.7. Always get NIHSS score first.",
             ["neurology", "emergency", "stroke"], true),

            (.brainDump, .plan, "Research Project Timeline",
             "Need to submit IRB protocol by March 15. Literature review draft due to Dr. Kim by end of month. Start data collection April 1 if approved. Abstract deadline for ACP conference is May 30.",
             ["research", "deadlines", "academic"], false),

            (.brainDump, .taskCandidate, "Board Exam Prep Schedule",
             "Focus areas: Cardiology (25%), Pulmonology (15%), GI (15%), Infectious Disease (12%). Use UWorld + Amboss. Aim for 40 questions/day starting next Monday. Schedule practice exam for April 20.",
             ["boards", "study plan", "self-assessment"], false),

            (.patientEncounter, .learningPearl, "CHF Exacerbation Management",
             "Patient presented with acute decompensated HF. Key learning: Start IV furosemide at 2x home dose, monitor strict I/O, daily weights, BMP q12h. Consider adding metolazone if diuretic resistance. Don't forget to hold ACEi if creatinine rising.",
             ["cardiology", "CHF", "inpatient"], false),

            (.education, .learningPearl, "Glasgow Coma Scale Components",
             "Eye: 4 (spontaneous) to 1 (none). Verbal: 5 (oriented) to 1 (none). Motor: 6 (obeys commands) to 1 (none). Total 3-15. Intubated patients: record as GCS 11T. Less than 8 = intubate.",
             ["neurology", "trauma", "assessment"], false),

            (.education, .reference, "Common Drug Interactions to Watch",
             "Warfarin + Amiodarone = increased INR (reduce warfarin 30-50%). Metformin + contrast dye = lactic acidosis risk. SSRIs + Triptans = serotonin syndrome. Macrolides + Statins = rhabdomyolysis risk.",
             ["pharmacology", "drug interactions", "safety"], true),

            (.brainDump, .plan, "Clinic Workflow Optimization",
             "Ideas for improving clinic flow: 1) Pre-visit planning with MA 15min before, 2) Template smart phrases for common visits, 3) Batch refill requests to end of day, 4) Delegate follow-up scheduling to front desk.",
             ["productivity", "clinic", "workflow"], false),

            (.education, .learningPearl, "Differentiating Pleural Effusions",
             "Light's criteria for exudative: protein ratio >0.5, LDH ratio >0.6, or LDH >2/3 upper normal. Common transudative: CHF, cirrhosis, nephrotic. Common exudative: infection, malignancy, PE. Always send pH, glucose, cell count, cultures.",
             ["pulmonology", "procedures", "diagnosis"], false),
        ]

        for (mode, type, title, body, tags, pinned) in memories {
            let memory = Memory(mode: mode, type: type, title: title, body: body)
            memory.tags = tags
            memory.pinned = pinned
            memory.sourceType = .session
            memory.createdAt = Date().addingTimeInterval(-Double.random(in: 3600...604800))
            modelContext.insert(memory)
        }
    }

    private static func populateJournalEntries(modelContext: ModelContext) {
        let entries: [(JournalEntryType, String, [String], TimeInterval)] = [
            (.text,
             "Morning rounds were intense today. Had a complex CHF case with the attending — patient with EF 15% and rising creatinine. Learning to balance diuresis with kidney function. Dr. Chen's teaching on cardiorenal syndrome was excellent.",
             ["rounds", "cardiology", "learning"],
             -86400),

            (.text,
             "Interesting case in the ED: 45yo male with chest pain, negative troponins x2, but ECG showed subtle ST changes in aVL. Cardiology consult recommended CT angiography which showed 90% LAD stenosis. Lesson: trust the ECG patterns even when biomarkers are negative early.",
             ["emergency", "cardiology", "case study"],
             -172800),

            (.voice,
             "Quick note to self: need to follow up on Mrs. Johnson's potassium levels from yesterday. Also, remember to ask Dr. Patel about the research protocol changes during tomorrow's meeting. Pick up board review book from library.",
             ["follow-up", "reminders"],
             -259200),

            (.text,
             "Attended grand rounds on antimicrobial stewardship. Key takeaway: we're over-prescribing fluoroquinolones for uncomplicated UTIs. Nitrofurantoin should be first-line. Also learned about the new rapid diagnostic panels for blood cultures — results in 1 hour vs 48 hours.",
             ["grand rounds", "infectious disease", "stewardship"],
             -345600),

            (.text,
             "Reflected on a difficult conversation with a patient's family about goals of care. The patient has stage IV pancreatic cancer with liver mets. Family wants 'everything done' but patient had previously expressed desire for comfort care. Palliative care consult placed. Need to work on my communication skills for these situations.",
             ["palliative care", "communication", "reflection"],
             -432000),

            (.text,
             "Study session notes: Acid-base disorders. Remember the mnemonic MUDPILES for anion gap metabolic acidosis: Methanol, Uremia, DKA, Propylene glycol, Isoniazid/Iron, Lactic acidosis, Ethylene glycol, Salicylates. Also reviewed Winter's formula for expected pCO2 compensation.",
             ["study notes", "acid-base", "nephrology"],
             -518400),

            (.text,
             "Great teaching moment today: showed the med students how to properly perform a lumbar puncture. Emphasized the importance of positioning (lateral decubitus vs sitting), landmark identification, and opening pressure measurement. One student got it on first attempt!",
             ["teaching", "procedures", "mentoring"],
             -604800),
        ]

        for (type, content, tags, offset) in entries {
            let entry = JournalEntry(type: type, contentText: content)
            entry.tags = tags
            entry.createdAt = Date().addingTimeInterval(offset)
            modelContext.insert(entry)
        }
    }

    private static func populateTasks(modelContext: ModelContext) {
        let tasks: [(String, String, TaskPriority, TaskStatus, Date?, TimeInterval)] = [
            ("Follow up on Mrs. Johnson's potassium",
             "Check BMP results from yesterday. If K+ still low, increase supplementation and recheck in 48h.",
             .high, .todo, Date().addingTimeInterval(3600), -7200),

            ("Submit IRB protocol draft",
             "Final review of inclusion/exclusion criteria. Need Dr. Kim's signature. Deadline March 15.",
             .urgent, .todo, Date().addingTimeInterval(86400 * 5), -86400),

            ("Complete UWorld cardiology block",
             "40 questions on heart failure and valvular disease. Review explanations for incorrect answers.",
             .medium, .doing, Date().addingTimeInterval(86400), -172800),

            ("Schedule practice board exam",
             "Book a full-length practice exam for April 20. Need quiet study space reservation.",
             .medium, .todo, Date().addingTimeInterval(86400 * 14), -259200),

            ("Read antibiotic stewardship guidelines",
             "New IDSA guidelines on uncomplicated UTI treatment. Update my clinical reference cards.",
             .low, .todo, Date().addingTimeInterval(86400 * 7), -172800),

            ("Update patient handoff sheet",
             "Add new admissions from today. Include pending labs and overnight watch items.",
             .high, .done, nil, -43200),

            ("Prepare case presentation for M&M",
             "Mortality and Morbidity conference next Thursday. Present the delayed PE diagnosis case. Include timeline, decision points, and literature review.",
             .high, .todo, Date().addingTimeInterval(86400 * 4), -86400),

            ("Order board review flashcards",
             "Anki deck for Step 3 / board prep. Focus on high-yield topics identified from practice exams.",
             .low, .done, nil, -345600),

            ("Email Dr. Patel about research meeting",
             "Confirm availability for Thursday afternoon. Bring updated literature review draft.",
             .medium, .done, nil, -259200),

            ("Review overnight labs for team patients",
             "Check CBCs, BMPs, and cultures for all 12 patients on service. Flag critical values.",
             .urgent, .todo, Date(), -3600),
        ]

        for (title, notes, priority, status, dueAt, offset) in tasks {
            let task = TaskItem(title: title, priority: priority)
            task.notes = notes
            task.status = status
            task.dueAt = dueAt
            task.createdAt = Date().addingTimeInterval(offset)
            modelContext.insert(task)
        }
    }

    private static func populateSessions(modelContext: ModelContext) {
        let encounter1 = Session(sessionType: .encounter, mode: .patientEncounter, source: .phoneMic)
        encounter1.createdAt = Date().addingTimeInterval(-86400)
        encounter1.status = .ready
        encounter1.durationSec = 1200
        encounter1.visitType = .outpatient
        encounter1.patientAlias = "R.M."
        encounter1.consentAttested = true
        encounter1.consentTimestamp = Date().addingTimeInterval(-86400)
        encounter1.reviewedByClinician = true
        encounter1.reviewTimestamp = Date().addingTimeInterval(-85800)
        encounter1.transcriptText = "Patient is a 62-year-old male presenting for follow-up of type 2 diabetes and hypertension. Reports compliance with metformin and lisinopril. Blood sugars have been in the 130-160 range fasting. Denies polyuria, polydipsia. Blood pressure today 138/82. Recent A1c was 7.4%, up from 7.1% three months ago. We discussed adding a GLP-1 receptor agonist. Patient agreeable to starting semaglutide. Reviewed injection technique and common side effects."
        encounter1.summary = "62yo M follow-up for T2DM and HTN. A1c trending up to 7.4%. Starting semaglutide (GLP-1 RA) in addition to metformin. BP borderline at 138/82 — continue current lisinopril dose."
        encounter1.clinicianDocDraft = """
SUBJECTIVE:
62yo M presents for routine follow-up of T2DM and HTN. Reports medication compliance with metformin 1000mg BID and lisinopril 20mg daily. Home glucose logs show fasting readings 130-160 mg/dL. Denies polyuria, polydipsia, blurry vision, numbness/tingling in extremities. No medication side effects reported.

OBJECTIVE:
VS: BP 138/82, HR 74, BMI 31.2
Recent Labs: A1c 7.4% (prev 7.1%), Cr 0.9, eGFR >90
Exam: Alert, well-appearing. CV: RRR, no murmurs. Ext: no edema, monofilament sensation intact bilaterally.

ASSESSMENT & PLAN:
1. T2DM — suboptimally controlled, A1c 7.4% (goal <7%)
   - Continue metformin 1000mg BID
   - Start semaglutide 0.25mg SC weekly x4 weeks, then increase to 0.5mg
   - Reviewed injection technique, GI side effects, hypoglycemia precautions
   - Recheck A1c in 3 months

2. HTN — borderline controlled
   - Continue lisinopril 20mg daily
   - Home BP monitoring, target <130/80
   - If persistently elevated, consider uptitration

3. Health Maintenance
   - Due for diabetic eye exam — referral placed
   - Foot exam performed today — normal
   - Flu vaccine administered today

Follow-up: 3 months or sooner if concerns with new medication.
"""
        encounter1.patientAVS = """
AFTER VISIT SUMMARY

What we discussed today:
• Your diabetes numbers (A1c) went up slightly to 7.4%. Our goal is below 7%.
• We're adding a new medication called semaglutide (Ozempic) to help lower your blood sugar and may help with weight.
• Your blood pressure was slightly high today — keep monitoring at home.

New Medication:
• Semaglutide (Ozempic) — inject once weekly
  - Start with a low dose for 4 weeks, then increase
  - You may have some nausea at first — this usually improves
  - Inject in your stomach, thigh, or upper arm
  - Store in the refrigerator

Continue Taking:
• Metformin 1000mg — twice daily with meals
• Lisinopril 20mg — once daily in the morning

Follow-up:
• Return in 3 months for blood work and check-up
• Eye doctor appointment — we sent a referral

When to call us:
• Blood sugar below 70 or above 300
• Severe nausea or vomiting that won't stop
• Signs of allergic reaction to new medication
"""
        modelContext.insert(encounter1)

        let encounter2 = Session(sessionType: .encounter, mode: .patientEncounter, source: .phoneMic)
        encounter2.createdAt = Date().addingTimeInterval(-259200)
        encounter2.status = .ready
        encounter2.durationSec = 900
        encounter2.visitType = .telehealth
        encounter2.patientAlias = "S.K."
        encounter2.consentAttested = true
        encounter2.consentTimestamp = Date().addingTimeInterval(-259200)
        encounter2.reviewedByClinician = true
        encounter2.reviewTimestamp = Date().addingTimeInterval(-259000)
        encounter2.transcriptText = "Telehealth visit with 34-year-old female for anxiety and insomnia. Started sertraline 50mg three weeks ago. Reports mild improvement in anxiety but still having difficulty falling asleep. Takes 45-60 minutes to fall asleep. No suicidal ideation. Appetite okay. We discussed sleep hygiene measures and will add hydroxyzine 25mg at bedtime for sleep."
        encounter2.summary = "34yo F telehealth f/u for anxiety and insomnia. Sertraline 50mg x3 weeks with mild improvement. Adding hydroxyzine 25mg QHS for sleep. Good safety screen."
        encounter2.clinicianDocDraft = """
SUBJECTIVE:
34yo F presents via telehealth for follow-up of anxiety disorder and insomnia. Started sertraline 50mg daily 3 weeks ago. Reports mild improvement in generalized anxiety symptoms — fewer racing thoughts, slightly better ability to manage daily stressors. However, persistent difficulty with sleep onset — takes 45-60 minutes to fall asleep. Sleeping approximately 5-6 hours/night. Denies SI/HI. Appetite stable. No medication side effects noted.

OBJECTIVE:
Patient appears well-groomed, calm, making good eye contact via video. Speech normal rate and rhythm. Mood "okay, a bit tired." Affect congruent. Thought process linear. PHQ-9: 8 (mild). GAD-7: 11 (moderate). Columbia suicide screen: negative.

ASSESSMENT & PLAN:
1. Generalized Anxiety Disorder — mild improvement on sertraline
   - Continue sertraline 50mg daily
   - Consider uptitration to 100mg at next visit if partial response persists
   
2. Insomnia — persistent
   - Start hydroxyzine 25mg PO QHS PRN
   - Sleep hygiene counseling provided
   - Avoid screens 1 hour before bed, consistent sleep/wake times

Follow-up: 4 weeks via telehealth.
"""
        encounter2.patientAVS = """
AFTER VISIT SUMMARY

What we discussed today:
• Your anxiety has improved a little on sertraline — good progress!
• Sleep is still a challenge. We're adding a medication to help.

New Medication:
• Hydroxyzine 25mg — take at bedtime as needed for sleep
  - May cause drowsiness (that's the point!)
  - Don't drive after taking it

Continue Taking:
• Sertraline 50mg — once daily in the morning

Sleep Tips:
• Go to bed and wake up at the same time every day
• No screens (phone, TV) for 1 hour before bed
• Keep your bedroom cool and dark
• Avoid caffeine after 2 PM

Follow-up:
• Telehealth visit in 4 weeks
• Call us sooner if anxiety worsens or you have any concerning thoughts
"""
        modelContext.insert(encounter2)

        let session1 = Session(sessionType: .general, mode: .education, source: .phoneMic)
        session1.createdAt = Date().addingTimeInterval(-172800)
        session1.status = .ready
        session1.durationSec = 600
        session1.transcriptText = "Teaching rounds with Dr. Chen on cardiorenal syndrome. Key points: Type 1 CRS is acute cardiac decompensation leading to AKI. Manage with careful diuresis, inotropes if needed. Monitor urine output and creatinine closely. Don't withhold diuretics just because creatinine is rising if patient is still volume overloaded."
        session1.summary = "Teaching on cardiorenal syndrome Type 1. Acute cardiac failure → AKI. Key: careful diuresis, don't withhold diuretics in volume overload despite rising Cr."
        modelContext.insert(session1)

        let session2 = Session(sessionType: .general, mode: .brainDump, source: .phoneMic)
        session2.createdAt = Date().addingTimeInterval(-345600)
        session2.status = .ready
        session2.durationSec = 180
        session2.transcriptText = "Need to organize my study schedule for the next two weeks. Focus on cardiology and pulmonology — these are my weakest areas based on the practice exam. Also need to submit the abstract for ACP conference. Deadline is coming up. Remember to reach out to Dr. Kim about being a co-author."
        session2.summary = "Planning study schedule focusing on cardiology and pulmonology weak areas. ACP abstract deadline approaching. Need to coordinate with Dr. Kim on co-authorship."
        modelContext.insert(session2)

        let encounterTask1 = TaskItem(title: "Send diabetic eye exam referral for R.M.", priority: .high)
        encounterTask1.notes = "Patient due for annual diabetic retinopathy screening."
        encounterTask1.status = .done
        encounterTask1.linkedEncounterId = encounter1.id
        encounterTask1.createdAt = Date().addingTimeInterval(-85000)
        modelContext.insert(encounterTask1)

        let encounterTask2 = TaskItem(title: "Check R.M. A1c in 3 months", priority: .medium)
        encounterTask2.notes = "Follow up on semaglutide efficacy. Target A1c < 7%."
        encounterTask2.dueAt = Date().addingTimeInterval(86400 * 90)
        encounterTask2.linkedEncounterId = encounter1.id
        encounterTask2.createdAt = Date().addingTimeInterval(-85000)
        modelContext.insert(encounterTask2)

        let encounterTask3 = TaskItem(title: "Follow up S.K. in 4 weeks", priority: .medium)
        encounterTask3.notes = "Assess sertraline response, may uptitrate to 100mg. Check hydroxyzine effectiveness for sleep."
        encounterTask3.dueAt = Date().addingTimeInterval(86400 * 28)
        encounterTask3.linkedEncounterId = encounter2.id
        encounterTask3.createdAt = Date().addingTimeInterval(-259000)
        modelContext.insert(encounterTask3)
    }

    private static func populateChatThreads(modelContext: ModelContext) {
        let thread1 = ChatThread(title: "CHF Management Review")
        thread1.createdAt = Date().addingTimeInterval(-43200)
        thread1.messages = [
            ChatMessage(role: "user", content: "What are the key medications for heart failure with reduced ejection fraction?"),
            ChatMessage(role: "assistant", content: "The cornerstone medications for HFrEF (EF ≤40%) are often referred to as the \"Fantastic Four\":\n\n1. **ACE inhibitor/ARB or ARNI** (sacubitril/valsartan preferred)\n2. **Beta-blocker** (carvedilol, metoprolol succinate, or bisoprolol)\n3. **Mineralocorticoid receptor antagonist** (spironolactone or eplerenone)\n4. **SGLT2 inhibitor** (dapagliflozin or empagliflozin)\n\nAll four should be initiated and uptitrated to target doses as tolerated. Additionally, consider hydralazine/isosorbide dinitrate in Black patients or those intolerant to ACEi/ARB.\n\nFor volume management, loop diuretics (furosemide, bumetanide) are used as needed but don't have mortality benefit."),
            ChatMessage(role: "user", content: "When should I consider adding ivabradine?"),
            ChatMessage(role: "assistant", content: "Ivabradine is considered when:\n\n• Patient is already on **maximum tolerated beta-blocker dose**\n• Heart rate remains **≥70 bpm** at rest\n• Patient is in **sinus rhythm** (ivabradine doesn't work in afib)\n• EF remains **≤35%**\n\nIt works by selectively inhibiting the If (\"funny\") channel in the SA node, reducing heart rate without affecting blood pressure or contractility.\n\n**Key point:** Don't use ivabradine as a substitute for beta-blockers — it's an add-on therapy."),
        ]
        modelContext.insert(thread1)

        let thread2 = ChatThread(title: "Antibiotic Selection Help")
        thread2.createdAt = Date().addingTimeInterval(-172800)
        thread2.messages = [
            ChatMessage(role: "user", content: "My patient has a penicillin allergy (hives). What can I use for strep pharyngitis?"),
            ChatMessage(role: "assistant", content: "For strep pharyngitis with a penicillin allergy (hives = moderate risk), your options are:\n\n1. **First-line alternative:** Cephalexin 500mg BID x10 days\n   - Most penicillin-allergic patients can safely take cephalosporins\n   - Cross-reactivity risk is ~1-2% (much lower than previously thought)\n   - Avoid only if the reaction was anaphylaxis\n\n2. **If cephalosporin-averse:** Azithromycin 500mg day 1, then 250mg days 2-5\n   - Not ideal due to increasing resistance (~15-20%)\n\n3. **Alternative:** Clindamycin 300mg TID x10 days\n\nSince your patient had hives (not anaphylaxis), cephalexin is safe and preferred. Consider allergy testing/desensitization referral for future management."),
        ]
        modelContext.insert(thread2)
    }
}
