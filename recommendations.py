"""
=============================================================================
TASK 3 — ENHANCEMENT 6: FOLLOW-UP / PREVENTION ENGINE
File: recommendations.py
Function: generate_recommendations(grade, image_quality, lesions)
=============================================================================
Provides grade-stratified clinical guidance, distinct root cause etiologies ("क्यों हुआ है"),
targeted dietary precautions ("क्या परहेज करना है"), and urgency-based doctor consultations:
  • Low Grade (Grade 0 & 1): Dietary & lifestyle Do's & Don'ts without medicines.
  • Medium Grade (Grade 2): Capillary leakage etiology, strict parhez, 2-4 week Ophthalmologist OCT referral.
  • High Grade (Grade 3 & 4): Retinal ischemia/neovascularization etiology, strict lifting/bending bans,
                              urgent 1-2 week or 24-48h emergency vitreoretinal referral.
"""

CLINICAL_DISCLAIMER = (
    "Disclaimer: This guidance is generated for automated screening assistance and triage prioritization. "
    "It does NOT constitute a confirmed medical diagnosis, prescription, or treatment plan. "
    "All findings and care timelines must be verified by a licensed ophthalmologist."
)

MEDICINE_SAFETY_DISCLAIMER = (
    "महत्वपूर्ण सुरक्षा निर्देश (Non-Prescription Safety Policy): यह केवल आहार, जीवनशैली एवं आँखों की देखभाल संबंधी "
    "सावधानियां हैं। इस रिपोर्ट में किसी भी दवा (दवाइयों/आई ड्रॉप्स) की सिफारिश नहीं की गई है। "
    "अपनी नियमित डायबिटीज़ अथवा अन्य कोई भी दवा केवल अपने योग्य चिकित्सक (MD/MBBS Doctor) के परामर्श अनुसार ही लें।"
)


def generate_recommendations(grade: int, image_quality: dict = None, lesions: list = None) -> dict:
    """
    Generates structured, grade-stratified recommendations differentiating
    Low, Medium, and High retinopathy risk with distinct etiologies and precautions.
    """
    grade = int(max(0, min(4, grade or 0)))
    warnings = []
    
    # 1. Quality Warning Integration
    if image_quality and image_quality.get("status") == "poor":
        warnings.append(
            "CRITICAL QUALITY ALERT: The submitted image exhibits significant blur, poor illumination, "
            "or low resolution. Automatic grading may underestimate retinopathy severity. "
            "Repeat dilated fundus photography is strongly recommended."
        )
    elif image_quality and image_quality.get("status") == "borderline":
        warnings.append(
            "QUALITY NOTE: Image quality is borderline. Clinical inspection of marginal retinal quadrants is advised."
        )

    # 2. Universal Lifestyle & Dietary Precautions for Low-Grade (No Medicines Prescribed)
    low_grade_donts = [
        "चीनी, गुड़, मिठाई, कोल्ड ड्रिंक्स और पैक्ड फ्रूट जूस का सेवन न करें। (Avoid refined sugars & sweetened beverages).",
        "मैदा, समोसा, कचौरी, तला-भुना, और जंक फ़ूड से पूरी तरह परहेज करें। (Avoid trans-fats and ultra-processed food).",
        "अत्यधिक नमक और तेज मिर्च-मसालेदार भोजन सीमित करें (ताकि नसों पर उच्च रक्तचाप का दबाव न बढ़े)।",
        "तंबाकू, बीड़ी, सिगरेट और शराब का पूर्ण परहेज करें — ये रेटिनल सूक्ष्म नसों को गंभीर नुकसान पहुंचाते हैं।",
        "आँखों को हाथों से जोर-जोर से न रगड़ें और न मलें। (Do not rub eyes forcefully).",
        "बिना डॉक्टर के पर्चे के मेडिकल स्टोर से कोई भी आई ड्रॉप या दवा खुद खरीदकर आँख में न डालें।"
    ]

    low_grade_dos = [
        "हरी पत्तेदार सब्जियां (पालक, मेथी), गाजर, पपीता, खीरा और फाइबर युक्त साबुत अनाज का नियमित सेवन करें।",
        "रोजाना 30 से 40 मिनट नियमित हल्की कसरत या तेज चाल (Brisk Walking) की आदत डालें।",
        "पर्याप्त पानी पिएं (प्रतिदिन 2.5 - 3 लीटर) और रात में 7 से 8 घंटे की गहरी नींद लें।",
        "ब्लड शुगर (फास्टिंग व पीपी) और ब्लड प्रेशर की नियमित जांच कराएं और उसकी एक डायरी बनाकर रिकॉर्ड रखें।",
        "हर 6 से 12 महीने में आँखों की पुतली फैलाकर (Dilated Fundus Exam) रेटिना की नियमित जांच जरूर कराएं।",
        "धूप में बाहर निकलते समय यूवी (UV) प्रोटेक्शन वाला धूप का चश्मा पहनें ताकि आँखों पर तेज रोशनी का तनाव न पड़े।"
    ]

    # Classify Grade Categories
    if grade <= 1:
        grade_category = "low"
    elif grade == 2:
        grade_category = "medium"
    else:
        grade_category = "high"

    is_low_grade = (grade_category == "low")
    is_medium_grade = (grade_category == "medium")
    is_high_grade = (grade_category == "high")

    # 3. Grade-Specific Detailed Profiles
    if grade == 0:
        urgency = "Routine Annual Screening (नियमित वार्षिक जांच)"
        follow_up = "12 months (Annual Dilated Eye Exam)"
        action = "आपकी आँखें स्वस्थ हैं। वार्षिक नियमित रेटिना स्क्रीनिंग जारी रखें और खानपान व जीवनशैली का परहेज बनाए रखें।"
        etiology_why = (
            "आपकी आँखों का पर्दा यानी रेटिना बिल्कुल साफ और स्वस्थ है। "
            "रक्तनलिकाओं में कोई सूजन या लीकेज नहीं है और रक्त प्रवाह सामान्य है।"
        )
        parhez_precautions = low_grade_donts
        dos = low_grade_dos
        doctor_urgency_title = "वार्षिक नियमित फॉलो-अप (Annual Review)"
        doctor_consult_timeline = "12 महीने के भीतर नियमित जांच"
        doctor_referral_steps = [
            "वार्षिक पुतली फैलाकर फंडस जांच (Annual Dilated Eye Exam)",
            "फास्टिंग एवं पोस्ट-प्रैन्डियल ब्लड शुगर रिकॉर्डिंग",
            "प्राथमिक स्वास्थ्य केंद्र पर वार्षिक स्क्रीनिंग रजिस्ट्री मेंटेन करें"
        ]
        critical_restrictions = []

    elif grade == 1:
        urgency = "Periodic Ophthalmic Monitoring (सावधानी एवं 6-12 माह में जांच)"
        follow_up = "6 to 12 months"
        action = "शुरुआती हल्के लक्षण (माइक्रोएन्यूरिज्म) मिले हैं। दवा की जगह सख्त खानपान परहेज व 6-12 महीने में दोबारा जांच आवश्यक है।"
        etiology_why = (
            "खून में शुगर का स्तर थोड़ा बढ़ जाने के कारण आँख के पर्दे की अति सूक्ष्म केशिकाओं की दीवारें हल्की कमजोर हो गई हैं, "
            "जिससे छोटे गुब्बारे जैसी हल्की सूजन (Microaneurysms) बन गई है। यह शुरुआती स्टेज है और अभी दृष्टि को कोई खतरा नहीं है।"
        )
        parhez_precautions = low_grade_donts
        dos = low_grade_dos
        doctor_urgency_title = "समयबद्ध नेत्र विशेषज्ञ परामर्श (Periodic Specialist Review)"
        doctor_consult_timeline = "6 से 12 महीने के भीतर"
        doctor_referral_steps = [
            "6 से 12 महीने में दोबारा रेटिना विशेषज्ञ से पुतली फैलाकर जांच कराएं",
            "ब्लड प्रेशर (< 130/80 mmHg) और लिपिड प्रोफाइल की जांच कराएं (सूक्ष्म नसों की सुरक्षा हेतु)",
            "यदि नजर में अचानक धुंधलापन या काले धब्बे दिखें तो तुरंत नेत्र चिकित्सक से संपर्क करें"
        ]
        critical_restrictions = []

    elif grade == 2:
        # MEDIUM GRADE (Moderate NPDR)
        urgency = "Ophthalmology Evaluation Required (मध्यम स्तर / नेत्र विशेषज्ञ परामर्श आवश्यक)"
        follow_up = "2 to 4 weeks (Prompt Evaluation)"
        action = "मध्यम स्तर की डायबिटिक रेटिनोपैथी पाई गई है। बिना किसी देरी के 2-4 सप्ताह में नेत्र रोग विशेषज्ञ (Ophthalmologist) से मिलें।"
        etiology_why = (
            "लंबे समय से ब्लड शुगर और ब्लड प्रेशर का स्तर बढ़ा रहने के कारण रेटिना की सूक्ष्म रक्तनलिकाएं (Capillaries) काफी कमजोर होकर "
            "फैलने लगी हैं। नसों की दीवारें छिद्रयुक्त (Leaky) हो जाने से रक्त प्लाज्मा और लाल कणिकाओं का रिसाव शुरू हो गया है, "
            "जिससे पर्दे पर पीले चर्बी के जमाव (Hard Lipid Exudates) और खून के धब्बे (Dot & Blot Hemorrhages) बन रहे हैं। "
            "यदि इसे अभी नियंत्रित न किया गया, तो केंद्रीय मैकुला में सूजन (Diabetic Macular Edema - DME) आ सकती है, जिससे दृष्टि धुंधली हो जाएगी।"
        )
        parhez_precautions = [
            "मीठा, चीनी, गुड़, मिठाई, कोल्ड ड्रिंक्स और पैकेज्ड जूस पूरी तरह बंद रखें (ताकि नसों से रिसाव और न बढ़े)।",
            "मैदा, समोसा, तला-भुना खाना और अत्यधिक नमक पूर्णतः सीमित करें (रक्तचाप व कोलेस्ट्रॉल नियंत्रित रखने हेतु)।",
            "आँखों को कभी भी जोर से न रगड़ें और न ही बिना डॉक्टर के पर्चे की कोई आई ड्रॉप डालें।",
            "तंबाकू, बीड़ी, सिगरेट और शराब का पूर्ण त्याग करें — यह नसों के रिसाव को कई गुना तेज कर देता है।",
            "अचानक भारी वजन उठाने या आगे झुककर भारी काम करने से बचें (ताकि नसों पर इंट्रा-ऑक्युलर दबाव न बढ़े)।"
        ]
        dos = [
            "नियमित रूप से फास्टिंग व पीपी ब्लड शुगर जांचें और बीपी को 130/80 mmHg के अंदर रखें।",
            "फाइबर युक्त हरी पत्तेदार सब्जियां, गाजर और खीरा खाएं, जो रेटिनल स्वास्थ्य को सहारा देते हैं।",
            "हल्की व मध्यम चाल में रोजाना 30 मिनट टहलें, किंतु भारी कसरत या वजन उठाने से बचें।",
            "अगले 2 से 4 सप्ताह में नेत्र रोग विशेषज्ञ से मिलकर मैकुलर ओसीटी जांच अनिवार्य रूप से कराएं।"
        ]
        doctor_urgency_title = "🚨 आवश्यक परामर्श: नेत्र रोग विशेषज्ञ (Ophthalmologist) से 2-4 सप्ताह में मिलें"
        doctor_consult_timeline = "अगले 2 से 4 सप्ताह के भीतर (Within 2 to 4 Weeks)"
        doctor_referral_steps = [
            "नेत्र रोग विशेषज्ञ (Consultant Ophthalmologist) से तत्काल अपॉइंटमेंट लें",
            "मैकुलर ओसीटी (Macular OCT) स्कैन कराएं ताकि यह जांचा जा सके कि पर्दे के केंद्र में सूजन (DME) तो नहीं है",
            "विस्तृत स्लिट-लैंप बायोमाइक्रोस्कोपी जांच करवाएं",
            "डायबिटोलॉजिस्ट से मिलकर ब्लड शुगर और बीपी की दवाओं को तुरंत री-कैलिब्रेट कराएं"
        ]
        critical_restrictions = [
            "भारी वजन उठाने, अत्यधिक झुककर भारी काम करने या जिम में वजन उठाने से बचें",
            "आँखों पर सीधा दबाव डालने वाली गतिविधियों से बचें"
        ]

    elif grade == 3:
        # HIGH GRADE (Severe NPDR)
        urgency = "Prompt Ophthalmology Referral (उच्च जोखिम / तुरंत रेटिना डॉक्टर से मिलें)"
        follow_up = "1 to 2 weeks (High Priority)"
        action = "गंभीर डायबिटिक रेटिनोपैथी (4:2:1 स्टेज)। तुरंत 1-2 सप्ताह में रेटिना स्पेशलिस्ट से मिलें; समय पर लेजर या इंजेक्शन से रोशनी बचाई जा सकती है।"
        etiology_why = (
            "रेटिना की सूक्ष्म धमनियों में व्यापक रुकावट (Pre-capillary Arteriolar Occlusion) आ गई है। "
            "पर्दे के चारों चतुर्थांशों में से कई हिस्सों में खून व ऑक्सीजन का प्रवाह लगभग रुक गया है (Retinal Ischemia)। "
            "ऑक्सीजन की भारी कमी के कारण नसों के तंतु मरने लगे हैं (Cotton Wool Spots), नसें विकृत होकर फूल रही हैं (Venous Beading), "
            "और असामान्य सूक्ष्म वाहिकाएं (IRMA) बन रही हैं। यह प्रोलिफेरेटिव स्टेज की दहलीज है जहां अचानक नजर जाने का गंभीर खतरा होता है।"
        )
        parhez_precautions = [
            "सख्त पाबंदी: भारी वजन उठाना, झुककर भारी काम करना या जिम में वजन उठाना पूर्णतः वर्जित है।",
            "सिर नीचे करने वाले योगासन (जैसे शीर्षासन) या अत्यधिक दबाव वाले व्यायाम बिल्कुल न करें।",
            "जोर से खांसने, छींकने या पेट पर अधिक दबाव डालने (Valsalva Strain) से बचें, क्योंकि इससे कमजोर नसों से अचानक रक्तस्राव हो सकता है।",
            "किसी भी प्रकार का तनाव, दौड़-भाग या थकाने वाली शारीरिक मेहनत तुरंत रोक दें।",
            "चीनी, मीठा, नमक और तंबाकू का शत-प्रतिशत त्याग करें।"
        ]
        dos = [
            "सोते समय सिर को हमेशा थोड़ा ऊंचा (2 तकियों के सहारे) रखें ताकि आँख के पर्दे पर दबाव कम रहे।",
            "शांत रहें और तुरंत अपने परिजनों को साथ लेकर रेटिना स्पेशलिस्ट के पास जाएँ।",
            "यदि आँखों के आगे तैरते हुए काले धब्बे (Floaters), रोशनी की चमक (Flashes) या लाल पर्दा दिखे, तो एक मिनट की भी देर किए बिना इमरजेंसी नेत्र केंद्र पहुंचे।"
        ]
        doctor_urgency_title = "🚨 अति आवश्यक: रेटिना विशेषज्ञ (Vitreoretinal Specialist) से 1-2 सप्ताह में मिलें!"
        doctor_consult_timeline = "अगले 1 से 2 सप्ताह के भीतर (High Priority Referral)"
        doctor_referral_steps = [
            "जिला अस्पताल या मेडिकल कॉलेज के रेटिना विशेषज्ञ (Vitreoretinal Specialist) को तुरंत दिखाएं",
            "लेजर फोटोकोएग्युलेशन (PRP) अथवा इंट्राविट्रियल इंजेक्शन (Anti-VEGF) की आवश्यकता का तत्काल मूल्यांकन कराएं",
            "मैकुलर हाई-रेजोल्यूशन ओसीटी (OCT) एवं आवश्यकतानुसार फ्लोरोसिन एंजियोग्राफी (FFA) कराएं"
        ]
        critical_restrictions = [
            "भारी वजन उठाना, झुककर भारी काम करना या जिम में वजन उठाना सख्त मना है",
            "सिर नीचे करने वाले योगासन (जैसे शीर्षासन) या तेज झटके वाली कसरत बिल्कुल न करें",
            "जोर से खांसने, छींकने या पेट पर अधिक दबाव डालने (Valsalva maneuvers) से बचें"
        ]

    else:  # grade == 4
        # HIGH EMERGENCY (Proliferative DR - PDR)
        urgency = "Immediate Emergency Consultation (आपातकालीन / 24-48 घंटे में अस्पताल जाएं)"
        follow_up = "24 to 48 hours (Urgent Emergency)"
        action = "अत्यंत गंभीर आपातकालीन स्थिति (प्रोलिफेरेटिव रेटिनोपैथी)। 24-48 घंटे के भीतर किसी बड़े आई हॉस्पिटल या रेटिना स्पेशलिस्ट के पास तुरंत जाएं।"
        etiology_why = (
            "रेटिना में लंबे समय से ऑक्सीजन की गंभीर कमी रहने के कारण आँख ने अत्यधिक मात्रा में एंजियोजेनिक केमिकल (VEGF) छोड़ दिया है। "
            "इसके परिणामस्वरूप आँख के पर्दे व ऑप्टिक नर्व पर बहुत कमजोर, असामान्य नई रक्तनलिकाएं (Neovascularization - NVD/NVE) उग आई हैं। "
            "ये नई नसें इतनी नाजुक होती हैं कि सामान्य रक्तचाप पर भी अचानक फट जाती हैं और आँख के कांच जैसे द्रव में खून भर जाता है (Vitreous Hemorrhage) "
            "या खिंचाव के कारण पर्दा अपनी जगह से अलग (Tractional Retinal Detachment) हो सकता है, जिससे स्थायी अंधापन हो सकता है।"
        )
        parhez_precautions = [
            "पूर्ण शारीरिक आराम: किसी भी प्रकार का वजन उठाना, झुकना, तेज चलना या दौड़ना पूर्णतः प्रतिबंधित है।",
            "सिर को कभी भी नीचे की ओर न झुकाएं (No head-down postures)।",
            "खांसने या शौच के समय जोर लगाने से बचें (Straining must be avoided)।",
            "बिना डॉक्टर के पर्चे की कोई भी दवा, आई ड्रॉप या घरेलू नुस्खा बिल्कुल न आजमाएं।"
        ]
        dos = [
            "तुरंत अगले 24 से 48 घंटे के भीतर किसी बड़े टर्शियरी नेत्र अस्पताल या रेटिना सेंटर पहुंचें।",
            "सिर को थोड़ा ऊंचा रखकर सोएं।",
            "यदि दृष्टि में अचानक गिरावट आए या अंधेरा छा जाए, तो बिना एक पल गंवाए आपातकालीन आई वार्ड में रिपोर्ट करें।"
        ]
        doctor_urgency_title = "🚨 आपातकालीन चेतावनी: 24 से 48 घंटे के भीतर बड़े नेत्र अस्पताल पहुंचें!"
        doctor_consult_timeline = "तत्काल 24 से 48 घंटे के भीतर (Emergency 24-48 Hours)"
        doctor_referral_steps = [
            "टर्शियरी आई हॉस्पिटल या एपेक्स रेटिना सेंटर में इमरजेंसी विट्रियो-रेटिना कंसल्टेशन लें",
            "अचानक खून के रिसाव को रोकने हेतु तत्काल एंटी-वीईजीएफ इंजेक्शन या पीआरपी लेजर कराएं",
            "यदि पर्दा धुंधला हो तो बी-स्कैन अल्ट्रासोनोग्राफी (B-Scan USG) कराएं"
        ]
        critical_restrictions = [
            "किसी भी प्रकार का शारीरिक श्रम, भारी वजन उठाना या झुकना पूर्णतः प्रतिबंधित है",
            "सिर को हमेशा थोड़ा ऊंचा रखकर सोएं",
            "यदि अचानक आँखों के आगे अंधेरा या काला पर्दा आए तो बिना एक मिनट गंवाए इमरजेंसी अस्पताल जाएं"
        ]

    # Additional lesion-specific notes
    if lesions and any("neovascularization" in str(l).lower() for l in (lesions if isinstance(lesions, list) else lesions.keys())):
        warnings.append("Neovascularization alert: Fragile abnormal new vessels pose severe risk of vitreous hemorrhage.")

    return {
        "urgency": urgency,
        "follow_up_window": follow_up,
        "clinical_action": action,
        "lifestyle_precautions": parhez_precautions,
        "warnings": warnings,
        "disclaimer": CLINICAL_DISCLAIMER,
        "grade_category": grade_category,
        "is_low_grade": is_low_grade,
        "is_medium_grade": is_medium_grade,
        "is_high_grade": is_high_grade,
        "etiology_why": etiology_why,
        "parhez_precautions": parhez_precautions,
        "donts": parhez_precautions if is_low_grade else parhez_precautions,
        "dos": dos,
        "medicine_disclaimer": MEDICINE_SAFETY_DISCLAIMER,
        "doctor_urgency_title": doctor_urgency_title,
        "doctor_consult_timeline": doctor_consult_timeline,
        "doctor_referral_steps": doctor_referral_steps,
        "critical_restrictions": critical_restrictions
    }
