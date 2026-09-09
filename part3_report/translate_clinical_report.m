function trans = translate_clinical_report(langCode)
% TRANSLATE_CLINICAL_REPORT Multilingual Clinical Vocabulary Engine.
% Supported languages:
%   'en'  - English
%   'hi'  - Hindi (हिंदी)
%   'ta'  - Tamil (தமிழ்)
%   'te'  - Telugu (తెలుగు)
%   'mr'  - Marathi (मराठी)
%   'bn'  - Bengali (বাংলা)
%   'tcy' - Tulu (ತುಳು)

    if nargin < 1 || isempty(langCode)
        langCode = 'en';
    end

    switch lower(langCode)
        case 'hi'
            trans.report_title    = 'मधुमेह रेटिनोपैथी टेली-ऑप्थाल्मोलॉजी क्लिनिकल रिपोर्ट';
            trans.patient_details = 'मरीज का विवरण (Patient Demographics)';
            trans.quality_header  = 'छवि गुणवत्ता विश्लेषण (Image Quality Assessment)';
            trans.findings        = 'जांच के मुख्य क्लिनिकल निष्कर्ष';
            trans.grade_0         = 'सामान्य (No DR - कोई बीमारी नहीं)';
            trans.grade_1         = 'हल्का (Mild Non-Proliferative DR)';
            trans.grade_2         = 'मध्यम (Moderate NPDR - रेफरल आवश्यक)';
            trans.grade_3         = 'गंभीर (Severe NPDR - तत्काल रेफरल)';
            trans.grade_4         = 'अत्यधिक गंभीर (Proliferative PDR - आपातकालीन)';
            trans.etiology_title  = 'बीमारी का मूल कारण (Etiological Root Cause)';
            trans.parhez_title    = 'दैनिक परहेज़ एवं जीवनशैली निर्देश (Dietary Parhez)';
            trans.lifting_title   = 'शारीरिक कार्य एवं वजन उठाने की सख्त चेतावनी';
            trans.doctor_sign     = 'डॉक्टर सत्यापन एवं डिजिटल हस्ताक्षर (Ophthalmologist Sign-off)';
            trans.disclaimer      = 'अस्वीकरण: यह परिणाम एआई-सहायता प्राप्त स्क्रीनिंग अनुसंधान के लिए है। यह निश्चित चिकित्सीय निदान नहीं है।';

        case 'ta'
            trans.report_title    = 'நீரிழிவு விழித்திரை பரிசோதனை அறிக்கை (Diabetic Retinopathy Report)';
            trans.patient_details = 'நோயாளி விவரங்கள் (Patient Demographics)';
            trans.quality_header  = 'படத்தின் தர மதிப்பீடு (Quality Assessment)';
            trans.findings        = 'பரிசோதனையின் முக்கிய முடிவுகள்';
            trans.grade_0         = 'பாதிப்பு இல்லை (No DR - Normal)';
            trans.grade_1         = 'லேசான விழித்திரை பாதிப்பு (Mild NPDR)';
            trans.grade_2         = 'மிதமான விழித்திரை பாதிப்பு (Moderate NPDR - Referable)';
            trans.grade_3         = 'தீவிர விழித்திரை பாதிப்பு (Severe NPDR - Urgent)';
            trans.grade_4         = 'மிகத் தீவிர விழித்திரை பாதிப்பு (Proliferative PDR - Emergency)';
            trans.etiology_title  = 'பாதிப்பின் மூலக் காரணம் (Etiology)';
            trans.parhez_title    = 'உணவு மற்றும் வாழ்க்கை முறை வழிகாட்டுதல்கள் (Dietary Precautions)';
            trans.lifting_title   = 'உடற்பயிற்சி மற்றும் பளு தூக்குதல் எச்சரிக்கை';
            trans.doctor_sign     = 'மருத்துவர் சரிபார்ப்பு மற்றும் டிஜிட்டல் கையொப்பம்';
            trans.disclaimer      = 'முக்கிய அறிவிப்பு: இந்த முடிவு AI-உதவி திரையிடல் மட்டுமே; அறுதியான மருத்துவக் கண்டறிதல் அல்ல.';

        case 'te'
            trans.report_title    = 'డయాబెటిక్ రెటినోపతి కంటి పరీక్ష నివేదిక';
            trans.patient_details = 'రోగి వివరాలు (Patient Demographics)';
            trans.quality_header  = 'చిత్ర నాణ్యత పరిశీలన (Quality Assessment)';
            trans.findings        = 'పరీక్షా ఫలితాలు';
            trans.grade_0         = 'డయాబెటిక్ రెటినోపతి లేదు (No DR - Normal)';
            trans.grade_1         = 'తేలికపాటి రెటినోపతి (Mild NPDR)';
            trans.grade_2         = 'మధ్యస్థ రెటినోపతి (Moderate NPDR - Referable)';
            trans.grade_3         = 'తీవ్రమైన రెటినోపతి (Severe NPDR - Urgent)';
            trans.grade_4         = 'ప్రమాదకరమైన ప్రొలిఫెరేటివ్ రెటినోపతి (Proliferative PDR - Emergency)';
            trans.etiology_title  = 'వ్యాధికి గల కారణాలు (Etiology)';
            trans.parhez_title    = 'ఆహార నియమాలు మరియు జీవనశైలి మార్గదర్శకాలు';
            trans.lifting_title   = 'బరువులు ఎత్తడం మరియు శారీరక శ్రమ పై హెచ్చరిక';
            trans.doctor_sign     = 'వైద్యుల ధృవీకరణ మరియు డిజిటల్ సంతకం';
            trans.disclaimer      = 'గమనిక: ఈ నివేదిక AI ఆధారిత స్క్రీనింగ్ కొరకు మాత్రమే. ఇది తుది వైద్య నిర్ధారణ కాదు.';

        case 'mr'
            trans.report_title    = 'मधुमेह रेटिनोपॅथी टेली-ऑप्थॅल्मॉलॉजी क्लिनिकल अहवाल';
            trans.patient_details = 'रुग्णाचा तपशील (Patient Demographics)';
            trans.quality_header  = 'प्रतिमा गुणवत्ता मूल्यांकन (Quality Assessment)';
            trans.findings        = 'तपासणीचे मुख्य निष्कर्ष';
            trans.grade_0         = 'सामान्य (No DR - कोणताही आजार नाही)';
            trans.grade_1         = 'सौम्य (Mild NPDR)';
            trans.grade_2         = 'मध्यम (Moderate NPDR - नेत्रतज्ज्ञ सल्ला आवश्यक)';
            trans.grade_3         = 'गंभीर (Severe NPDR - तातडीने रेफरल)';
            trans.grade_4         = 'अत्यंत गंभीर (Proliferative PDR - आणीबाणी)';
            trans.etiology_title  = 'आजाराचे मूळ कारण (Etiological Cause)';
            trans.parhez_title    = 'दैनंदिन पथ्य आणि जीवनशैली सूचना (Dietary Parhez)';
            trans.lifting_title   = 'शारीरिक हालचाली आणि वजन उचलण्याबाबत सक्त इशारा';
            trans.doctor_sign     = 'डॉक्टर पडताळणी आणि डिजिटल स्वाक्षरी';
            trans.disclaimer      = 'सूचना: हा निष्कर्ष AI-सहाय्यित स्क्रीनिंगसाठी आहे. हे अंतिम वैद्यकीय निदान नाही.';

        case 'bn'
            trans.report_title    = 'ডায়াবেটিক রেটিনোপ্যাথি চক্ষু পরীক্ষা রিপোর্ট';
            trans.patient_details = 'রোগীর বিবরণ (Patient Demographics)';
            trans.quality_header  = 'ইমেজ গুণমান মূল্যায়ন (Quality Assessment)';
            trans.findings        = 'পরীক্ষার প্রধান ফলাফল';
            trans.grade_0         = 'রেটিনোপ্যাথি নেই (No DR - Normal)';
            trans.grade_1         = 'মৃদু রেটিনোপ্যাথি (Mild NPDR)';
            trans.grade_2         = 'মাঝারি রেটিনোপ্যাথি (Moderate NPDR - Referable)';
            trans.grade_3         = 'গুরুতর রেটিনোপ্যাথি (Severe NPDR - Urgent)';
            trans.grade_4         = 'অতি গুরুতর রেটিনোপ্যাথি (Proliferative PDR - Emergency)';
            trans.etiology_title  = 'রোগের মূল কারণ (Etiological Cause)';
            trans.parhez_title    = 'দৈনন্দিন পথ্য ও জীবনযাত্রার নির্দেশিকা';
            trans.lifting_title   = 'ভারী ওজন তোলা এবং শারীরিক পরিশ্রম সংক্রান্ত সতর্কতা';
            trans.doctor_sign     = 'ডাক্তারের যাচাইকরণ এবং ডিজিটাল স্বাক্ষর';
            trans.disclaimer      = 'সতর্কতা: এই ফলাফল এআই-সহায়তাপ্রাপ্ত স্ক্রিনিং গবেষণার জন্য। এটি চূড়ান্ত চিকিৎসা নির্ণয় নয়।';

        case 'tcy'
            trans.report_title    = 'ಡಯಾಬಿಟಿಕ್ ರೆಟಿನೋಪತಿ ಟೆಲಿ-ಆಪ್ಥಾಲ್ಮಾಲಜಿ ವರದಿ';
            trans.patient_details = 'ರೋಗಿಯ ವಿವರ (Patient Demographics)';
            trans.quality_header  = 'ಚಿತ್ರದ ಗುಣಮಟ್ಟ ಪರೀಕ್ಷೆ (Quality Assessment)';
            trans.findings        = 'ತಪಾಸಣೆಯ ಮುಖ್ಯ ವಿವರಗಳು';
            trans.grade_0         = 'ಸಾಮಾನ್ಯ (No DR - ನಾರ್ಮಲ್)';
            trans.grade_1         = 'ಸ್ವಲ್ಪ (Mild NPDR)';
            trans.grade_2         = 'ಮಧ್ಯಮ (Moderate NPDR - ತಕ್ಷಣ ತಪಾಸಣೆ ಅಗತ್ಯ)';
            trans.grade_3         = 'ತೀವ್ರ (Severe NPDR - ತುರ್ತು)';
            trans.grade_4         = 'ಅತ್ಯಂತ ತೀವ್ರ (Proliferative PDR - ತುರ್ತು ಚಿಕಿತ್ಸೆ)';
            trans.etiology_title  = 'ಕಾರಣ (Etiology)';
            trans.parhez_title    = 'ಪಥ್ಯ ಮತ್ತು ದಿನಚರಿ ನಿಯಮಗಳು';
            trans.lifting_title   = 'ತೂಕ ಎತ್ತುವ ಬಗ್ಗೆ ಎಚ್ಚರಿಕೆ';
            trans.doctor_sign     = 'ವೈದ್ಯರ ಸಹಿ (Doctor Sign-off)';
            trans.disclaimer      = 'ಎಚ್ಚರಿಕೆ: ಇದು AI-ಸಹಾಯದ ತಪಾಸಣಾ ವರದಿ ಮಾತ್ರ. ಅಂತಿಮ ವೈದ್ಯಕೀಯ ನಿರ್ಧಾರವಲ್ಲ.';

        otherwise % English
            trans.report_title    = 'Diabetic Retinopathy Tele-Ophthalmology Clinical CDS Report';
            trans.patient_details = 'Patient Demographics & Examination Profile';
            trans.quality_header  = 'Image Quality Assessment & Technical Gradability';
            trans.findings        = 'Primary Diagnostic Findings & Biomarkers';
            trans.grade_0         = 'Grade 0: Normal Retina (No Diabetic Retinopathy)';
            trans.grade_1         = 'Grade 1: Mild Non-Proliferative DR';
            trans.grade_2         = 'Grade 2: Moderate NPDR (Referable DR)';
            trans.grade_3         = 'Grade 3: Severe NPDR (Urgent Specialist Referral)';
            trans.grade_4         = 'Grade 4: Proliferative DR (Emergency Vitreoretinal Triage)';
            trans.etiology_title  = 'Etiological Root Cause & Microvascular Pathology';
            trans.parhez_title    = 'Clinical Precautions & Dietary Parhez Guidelines';
            trans.lifting_title   = 'Physical Activity & Heavy Lifting Contraindications';
            trans.doctor_sign     = 'Tele-Ophthalmologist Validation & Electronic Signature';
            trans.disclaimer      = 'NOTICE: This report is an AI-assisted screening analysis. It does not replace comprehensive in-person ophthalmic clinical examination.';
    end
end
