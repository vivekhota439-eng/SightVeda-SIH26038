"""
=============================================================================
TASK 3 — MULTILINGUAL INDIAN AUDIO GENERATION ENGINE (7 LANGUAGES)
File: audio_generator.py
=============================================================================
Generates 100% natural, human-like Indian spoken audio using Google TTS (gTTS)
specifically crafted for Indian patients across 7 major regional languages:
  1. hi: Hindi (हिन्दी)
  2. en: Indian English (co.in)
  3. mr: Marathi (मराठी)
  4. ta: Tamil (தமிழ்)
  5. te: Telugu (తెలుగు)
  6. bn: Bengali (বাংলা)
  7. tcy / kn: Tulu & Regional Kannada (ತುಳು / ಕನ್ನಡ)
=============================================================================
"""

import os
import base64
import logging

logger = logging.getLogger("AudioGenerator")

SPOKEN_SCRIPTS = {
    "hi": {
        0: (
            "नमस्ते! ध्यान से सुनिए, यह आपकी आँखों की डायबिटिक रेटिनोपैथी जांच की रिपोर्ट है। "
            "पहली बात: आपकी आँख में क्या हुआ है? आपके लिए बहुत अच्छी और राहत की खबर है! आपकी आँखों में शुगर की कोई बीमारी नहीं पाई गई है। आपकी आँखों का पर्दा यानी रेटिना बिल्कुल साफ और स्वस्थ है। "
            "दूसरी बात: यह जोखिम क्यों नहीं है? क्योंकि आपकी आँखों की नसों में कोई सूजन नहीं है, खून का कोई रिसाव नहीं है और नसें बिल्कुल सही तरीके से काम कर रही हैं। "
            "तीसरी बात: अब आपको क्या परहेज और सावधानियां बरतनी हैं? ध्यान दें, यहाँ आपको कोई दवा नहीं दी जा रही है। आपको केवल अपनी जीवनशैली और खानपान पर नियंत्रण रखना है। "
            "चीनी, मिठाई, गुड़, कोल्ड ड्रिंक्स और ज्यादा नमक का पूरी तरह परहेज करें। हरी पत्तेदार सब्जियां, गाजर, खीरा खाएं और रोजाना तीस मिनट तेज चाल में टहलें। "
            "हर साल में एक बार अपनी आँखों के पर्दे की नियमित जांच कराते रहें। धन्यवाद!"
        ),
        1: (
            "नमस्ते! ध्यान से सुनिए, यह आपकी आँखों की डायबिटिक रेटिनोपैथी जांच रिपोर्ट है। "
            "पहली बात: आपकी आँख में क्या हुआ है? आपकी आँख में ग्रेड एक यानी हल्की डायबिटिक रेटिनोपैथी के शुरुआती लक्षण मिले हैं। अच्छी बात यह है कि यह शुरुआती स्टेज है और अभी आपकी नजर को कोई खतरा नहीं है। "
            "दूसरी बात: यह क्यों हुआ है? खून में शुगर का स्तर बढ़ने से आँख के पर्दे की बहुत बारीक नसों में हल्के उभार आ जाते हैं, जिसे माइक्रोएन्यूरिज्म कहते हैं। "
            "तीसरी बात: अब आपको क्या परहेज करना है? ध्यान रखें, इस रिपोर्ट में कोई दवा नहीं दी जा रही है। बीमारी को आगे बढ़ने से रोकने के लिए आपको सख्त परहेज करना होगा। "
            "चीनी, मिठाई, कोल्ड ड्रिंक्स, मैदा, समोसा और तला-भुना खाना बिल्कुल बंद कर दें। बीड़ी-सिगरेट और तंबाकू से दूर रहें और आँखों को हाथों से जोर से न रगड़ें। "
            "हरी सब्जियां खाएं, रोजाना तीस मिनट टहलें, पर्याप्त पानी पिएं और ब्लड शुगर व बीपी की जांच नियमित रखें। "
            "अगले छह से बारह महीने के अंदर आँखों के डॉक्टर से मिलकर पुतली फैलाकर दोबारा रेटिना की जांच जरूर कराएं ताकि यह बीमारी यहीं रुक जाए। धन्यवाद!"
        ),
        2: (
            "नमस्ते! ध्यान से सुनिए, यह आपकी आँखों की डायबिटिक रेटिनोपैथी जांच की जरूरी रिपोर्ट है। "
            "पहली बात: आपकी आँख में क्या हुआ है? आपकी आँखों की जांच में ग्रेड दो यानी मॉडरेट डायबिटिक रेटिनोपैथी पाई गई है। इसका मतलब है कि बीमारी मध्यम स्तर पर पहुंच चुकी है। "
            "दूसरी बात: यह क्यों हुआ है? काफी समय से शुगर ज्यादा रहने के कारण रेटिना की नसें कमजोर होकर लीक होने लगी हैं और खून व पीले धब्बे जमा हो रहे हैं। "
            "तीसरी बात: अब आपको क्या करना है? हमारी सबसे महत्वपूर्ण सलाह है कि आप बिना किसी देरी के, अगले दो से चार सप्ताह के भीतर किसी अच्छे नेत्र रोग विशेषज्ञ यानी आई स्पेशलिस्ट डॉक्टर से जरूर मिलें! "
            "डॉक्टर की सलाह पर मैकुलर ओसीटी जांच कराएं ताकि पर्दे में सूजन का समय पर इलाज हो सके। भारी वजन उठाने और आगे झुककर भारी काम करने से बचें। तुरंत डॉक्टर से परामर्श लें। धन्यवाद!"
        ),
        3: (
            "नमस्ते! कृपया इस रिपोर्ट को बहुत गंभीरता से सुनिए। यह एक हाई रिस्क यानी उच्च खतरे की स्थिति है। "
            "पहली बात: आपकी आँख में ग्रेड तीन यानी गंभीर डायबिटिक रेटिनोपैथी पाई गई है। "
            "दूसरी बात: यह क्यों हुआ है? आँख के पर्दे के कई हिस्सों में खून की नसें बंद हो रही हैं और काफी जगह खून का रिसाव फैल चुका है। "
            "तीसरी बात: अब आपको क्या करना है? बिल्कुल भी देर न करें! अगले एक से दो हफ्ते के भीतर किसी बड़े अस्पताल में आँखों के रेटिना स्पेशलिस्ट डॉक्टर को तुरंत दिखाएं। "
            "समय पर विशेषज्ञ द्वारा लेजर या इंजेक्शन से आँखों की रोशनी बचाई जा सकती है। सख्त चेतावनी: भारी वजन उठाना, झुकना, या जिम कसरत करना बिल्कुल बंद कर दें, क्योंकि इससे पर्दे से अचानक खून बह सकता है। तुरंत डॉक्टर से मिलें। धन्यवाद!"
        ),
        4: (
            "नमस्ते! यह एक अत्यंत जरूरी और आपातकालीन स्वास्थ्य संदेश है। आपकी आँखों में ग्रेड चार यानी प्रोलिफेरेटिव डायबिटिक रेटिनोपैथी पाई गई है। "
            "आँख के पर्दे में बहुत कमजोर और खतरनाक नई नसें बन गई हैं, जो कभी भी अचानक फट सकती हैं और रोशनी जा सकती है। "
            "आपको तुरंत अगले चौबीस से अड़तालीस घंटे के अंदर किसी बड़े आई हॉस्पिटल या रेटिना स्पेशलिस्ट के पास जाना होगा! "
            "तुरंत लेजर या इंजेक्शन का इलाज कराएं। भारी वजन उठाने या झुकने से पूरी तरह बचें। यदि अचानक आँखों के आगे अंधेरा छाए, तो तुरंत इमरजेंसी अस्पताल पहुंचे। धन्यवाद!"
        )
    },
    "en": {
        0: (
            "Hello! Please listen carefully to your Diabetic Retinopathy eye screening report. "
            "First, what happened to your eye? We have very reassuring news: no signs of diabetic retinopathy were detected. Your retina is clear and completely healthy. "
            "Second, why is there no risk? Because your retinal blood vessels show no swelling or leakage, and blood circulation is normal. "
            "Third, what precautions should you take? No medicine is required. Maintain a healthy lifestyle: strictly avoid refined sugar, sweets, and sweetened beverages. "
            "Eat fresh green leafy vegetables and take a daily thirty-minute brisk walk. Have your eyes checked once a year. Thank you!"
        ),
        1: (
            "Hello! Please listen carefully to your Diabetic Retinopathy screening report. "
            "First, what happened to your eye? Mild non-proliferative diabetic retinopathy has been detected. The good news is this is an early stage and your eyesight is safe. "
            "Second, why did this happen? Elevated blood sugar has caused tiny capillary out-pouchings called microaneurysms. "
            "Third, what must you do? No medicine is needed now, but strict lifestyle precautions are essential. Eliminate sweets, fried snacks, and sugary drinks. Do not rub your eyes. "
            "Walk daily for thirty minutes, drink plenty of water, and keep blood sugar and BP under control. Consult an eye doctor within six to twelve months for a dilated retina follow-up. Thank you!"
        ),
        2: (
            "Hello! Please listen carefully to this important Diabetic Retinopathy screening report. "
            "First, what happened to your eye? Moderate diabetic retinopathy has been detected in your retina, indicating the disease has reached an intermediate stage. "
            "Second, why did this happen? Prolonged high blood sugar has weakened retinal vessels, leading to micro-hemorrhages and yellow lipid exudates. "
            "Third, what must you do? Our most important advice is to visit an eye specialist ophthalmologist within two to four weeks without delay! "
            "Ask your doctor for a Macular OCT scan to check for retinal edema. Avoid lifting weights heavier than ten kilograms and avoid sudden physical strain. Seek medical consultation promptly. Thank you!"
        ),
        3: (
            "Hello! Please take this report very seriously. This is a high-risk retinal condition. "
            "First, Grade 3 Severe Diabetic Retinopathy has been diagnosed in your retina. "
            "Second, why did this happen? Capillary blood supply has been obstructed across multiple retinal quadrants and widespread hemorrhages have developed. "
            "Third, what must you do? Do not delay! Visit a retina specialist at a district hospital within one to two weeks. Timely laser photocoagulation or Anti-VEGF injections can preserve your vision. "
            "Strict warning: avoid lifting heavy weights, bending down, or strenuous labor. Consult an ophthalmologist immediately. Thank you!"
        ),
        4: (
            "Hello! This is an urgent and critical emergency medical advisory. "
            "Grade 4 Proliferative Diabetic Retinopathy has been diagnosed in your retina. "
            "Severe oxygen deprivation has stimulated fragile abnormal new blood vessels that can rupture at any moment and cause sudden catastrophic vision loss. "
            "You must visit a major eye hospital or vitreo-retina specialist within twenty-four to forty-eight hours! Seek urgent laser or Anti-VEGF injection treatment. "
            "Maintain complete rest and avoid any physical exertion. If you experience sudden vision loss, rush to an ophthalmic emergency room immediately. Thank you!"
        )
    },
    "mr": {
        0: (
            "नमस्कार! हा तुमच्या डोळ्यांच्या डायबेटिक रेटिनोपॅथी तपासणीचा अहवाल आहे. "
            "तुमच्यासाठी अतिशय दिलासादायक बातमी आहे! तुमच्या डोळ्यांच्या पडद्यावर साखरेचा कोणताही दुष्परिणाम नाही. तुमचा डोळ्याचा पडदा म्हणजेच रेटिना अगदी स्वच्छ आणि निरोगी आहे. "
            "डोळ्यांच्या नसांमध्ये कोणतीही सूज किंवा रक्तस्त्राव नाही. तुम्हाला फक्त आहारात आणि जीवनशैलीत नियंत्रण ठेवायचे आहे. "
            "साखर, गूळ, मिठाई आणि गोड पेये पूर्णपणे टाळा. हिरव्या भाज्या खा आणि रोज तीस मिनिटे चाला. दरवर्षी एकदा डोळ्यांची नियमित तपासणी करून घ्या. धन्यवाद!"
        ),
        1: (
            "नमस्कार! हा तुमच्या डोळ्यांच्या तपासणीचा अहवाल आहे. तुमच्या डोळ्यात ग्रेड एक म्हणजेच सौम्य डायबेटिक रेटिनोपॅथीची सुरुवातीची लक्षणे आढळली आहेत. "
            "चांगली बातमी म्हणजे ही सुरुवातीची पायरी असून दृष्टीला धोका नाही. रक्तातील साखर वाढल्यामुळे बारीक नसांवर हलके फुगोरे आले आहेत. "
            "हा आजार वाढू नये म्हणून कडक पथ्य पाळा. साखर, गोड पदार्थ, मैदा, समोसे आणि तेलकट अन्न बंद करा. डोळे चोळू नका. "
            "रोज तीस मिनिटे चाला, भरपूर पाणी प्या आणि साखर नियंत्रणात ठेवा. पुढील सहा ते बारा महिन्यांत डोळ्यांच्या डॉक्टरांकडून रेटिना तपासणी करून घ्या. धन्यवाद!"
        ),
        2: (
            "नमस्कार! हा अत्यंत महत्त्वाचा अहवाल आहे. डोळ्यांच्या तपासणीत ग्रेड दोन म्हणजेच मध्यम डायबेटिक रेटिनोपॅथी आढळली आहे. "
            "दीर्घकाळ साखर वाढल्याने डोळ्यांच्या नसांमधून रक्तस्त्राव आणि पिवळे चरबीचे डाग जमा होत आहेत. "
            "कोणताही उशीर न करता, पुढील दोन ते चार आठवड्यांत नेत्रतज्ज्ञांचा सल्ला घ्या! पडद्यावर सूज आहे का हे तपासण्यासाठी OCT स्कॅन करून घ्या. "
            "दहा किलोपेक्षा जास्त वजन उचलू नका. ताबडतोब डॉक्टरांना भेटा. धन्यवाद!"
        ),
        3: (
            "नमस्कार! कृपया हा अहवाल गांभीर्याने ऐका. ही उच्च धोक्याची परिस्थिती आहे. डोळ्यात ग्रेड तीन म्हणजेच गंभीर डायबेटिक रेटिनोपॅथी आढळली आहे. "
            "पडद्याच्या अनेक भागांत रक्तपुरवठा थांबला असून मोठ्या प्रमाणावर रक्तस्त्राव झाला आहे. "
            "अजिबात उशीर करू नका! पुढील एक ते दोन आठवड्यांत जिल्हा रुग्णालयात जाऊन रेटिना तज्ज्ञांना दाखवा. वेळेवर लेझर किंवा इंजेक्शन घेतल्यास दृष्टी वाचवता येते. "
            "वजन उचलणे किंवा वाकणे पूर्णपणे बंद करा. ताबडतोब उपचार घ्या. धन्यवाद!"
        ),
        4: (
            "नमस्कार! हा एक अत्यंत तातडीचा आणीबाणीचा वैद्यकीय संदेश आहे. तुमच्या डोळ्यात ग्रेड चार म्हणजेच प्रोलिफेरेटिव्ह रेटिनोपॅथी आढळली आहे. "
            "पडद्यावर कमकुवत नव्या रक्तवाहिन्या तयार झाल्या असून त्या फुटून अचानक दृष्टी जाण्याचा मोठा धोका आहे. "
            "तुम्हाला पुढील चोवीस ते अठ्ठेचाळीस तासांत मोठ्या रुग्णालयात रेटिना तज्ज्ञांकडे जावे लागेल! तातडीने लेझर किंवा इंजेक्शन उपचार सुरू करा. "
            "वजन उचलणे किंवा वाकणे सक्त मनाई आहे. अंधारी आल्यास लगेच इमर्जन्सीमध्ये धाव घ्या. धन्यवाद!"
        )
    },
    "ta": {
        0: (
            "வணக்கம்! உங்கள் நீரிழிவு விழித்திரை பரிசோதனை அறிக்கையை கவனமாகக் கேளுங்கள். "
            "உங்களுக்கு மகிழ்ச்சியான செய்தி! உங்கள் கண்ணில் நீரிழிவு பாதிப்பு எதுவும் இல்லை. உங்கள் விழித்திரை முற்றிலும் ஆரோக்கியமாகவும் சுத்தமாகவும் உள்ளது. "
            "ரத்தக்குழாய்களில் எந்த வீக்கமும் கசிவும் இல்லை. சர்க்கரை, இனிப்புகள் மற்றும் குளிர்பானங்களை முற்றிலும் தவிர்க்கவும். "
            "தினமும் முப்பது நிமிடங்கள் நடைப்பயிற்சி செய்யுங்கள். ஆண்டுக்கு ஒருமுறை கண் பரிசோதனை செய்து கொள்ளுங்கள். நன்றி!"
        ),
        1: (
            "வணக்கம்! உங்கள் விழித்திரை பரிசோதனை அறிக்கை. உங்கள் கண்ணில் ஆரம்ப நிலை நீரிழிவு விழித்திரை பாதிப்பு கண்டறியப்பட்டுள்ளது. பார்வைக்கு ஆபத்து இல்லை. "
            "ரத்த சர்க்கரை அதிகரிப்பால் நுண் ரத்தக்குழாய்களில் சிறிய வீக்கம் ஏற்பட்டுள்ளது. இனிப்புகள் மற்றும் வறுத்த உணவுகளை தவிர்க்கவும். கண்களை தேய்க்க வேண்டாம். "
            "தினமும் உடற்பயிற்சி செய்து ஆறு முதல் பன்னிரண்டு மாதங்களுக்குள் கண் மருத்துவரிடம் சென்று பரிசோதித்துக் கொள்ளுங்கள். நன்றி!"
        ),
        2: (
            "வணக்கம்! இது மிக முக்கியமான கண் பரிசோதனை அறிக்கை. உங்கள் கண்ணில் மிதமான நீரிழிவு விழித்திரை பாதிப்பு ஏற்பட்டுள்ளது. "
            "ரத்தக்குழாய்களில் கசிவு மற்றும் மஞ்சள் கொழுப்பு படிவுகள் தோன்றியுள்ளன. அடுத்த இரண்டு முதல் நான்கு வாரங்களுக்குள் கண் மருத்துவரை அணுகி OCT ஸ்கேன் செய்து கொள்ளவும். "
            "அதிக எடை தூக்குவதை தவிர்க்கவும். உடனடியாக மருத்துவ ஆலோசனை பெறவும். நன்றி!"
        ),
        3: (
            "வணக்கம்! இது அதிக ஆபத்து நிறைந்த நிலை. உங்கள் கண்ணில் தீவிர நீரிழிவு விழித்திரை பாதிப்பு உள்ளது. ரத்த ஓட்டம் தடைபட்டு தீவிர ரத்தக் கசிவு ஏற்பட்டுள்ளது. "
            "ஒன்று முதல் இரண்டு வாரங்களுக்குள் மாவட்ட மருத்துவமனை சென்று லேசர் சிகிச்சை குறித்து ஆலோசனை பெறுங்கள். அதிக எடையை தூக்க வேண்டாம். உடனே மருத்துவரை அணுகவும். நன்றி!"
        ),
        4: (
            "வணக்கம்! இது அவசர சிகிச்சைக்கான அறிக்கை. உங்கள் கண்ணில் அதிதீவிர ப்ரோலிஃபெரேடிவ் விழித்திரை பாதிப்பு உள்ளது. "
            "பலவீனமான புதிய ரத்தக்குழாய்கள் உருவாகி ரத்தக் கசிவை உண்டாக்கி பார்வையை பறிக்கும் ஆபத்து உள்ளது. அடுத்த இருபத்து நான்கு முதல் நாற்பத்தெட்டு மணி நேரத்திற்குள் சிறப்பு கண் மருத்துவமனைக்கு செல்லவும். லேசர் அல்லது ஊசி சிகிச்சை பெறவும். நன்றி!"
        )
    },
    "te": {
        0: (
            "నమస్కారం! మీ డయాబెటిక్ రెటినోపతి కంటి పరీక్ష నివేదికను వినండి. "
            "మీ కంటి రెటీనాలో ఎటువంటి షుగర్ వ్యాధి లక్షణాలు లేవు. మీ కంటి పర్దా పూర్తిగా ఆరోగ్యంగా ఉంది. రక్తనాళాలలో లీకేజీ లేదా వాపు లేదు. "
            "పంచదార, తీపి పదార్థాలు మరియు శీతల పానీయాలను పూర్తిగా మానండి. రోజూ ముప్పై నిమిషాలు నడవండి. ఏడాదికి ఒకసారి క్రమం తప్పకుండా కంటి పరీక్ష చేయించుకోండి. ధన్యవాదాలు!"
        ),
        1: (
            "నమస్కారం! మీ కంటి పరీక్ష నివేదిక. మీ కంటిలో తేలికపాటి డయాబెటిక్ రెటినోపతి ప్రారంభ లక్షణాలు కనిపించాయి. ప్రారంభ దశ కాబట్టి చూపుకు ప్రమాదం లేదు. "
            "షుగర్ పెరగడం వల్ల సూక్ష్మ రక్తనాళాలలో చిన్న ఉబ్బులు వచ్చాయి. నూనె పదార్థాలు, మైదా మరియు తీపి పూర్తిగా మానండి. కళ్ళను గట్టిగా రుద్దవద్దు. "
            "ఆరు నుండి పన్నెండు నెలల్లోపు కంటి వైద్యుడిని సంప్రదించండి. ధన్యవాదాలు!"
        ),
        2: (
            "నమస్కారం! ఇది ముఖ్యమైన కంటి పరీక్ష నివేదిక. మీ కంటిలో మితమైన డయాబెటిక్ రెటినోపతి ఉన్నట్లు నిర్ధారించబడింది. "
            "దీర్ఘకాలం షుగర్ వల్ల రక్తనాళాలు లీకై రక్తస్రావం మరియు పసుపు కొవ్వు పేరుకుపోతున్నాయి. ఆలస్యం చేయకుండా, రెండు నుండి నాలుగు వారాల్లో కంటి నిపుణుడిని సంప్రదించి OCT స్కాన్ చేయించుకోండి. "
            "బరువులు ఎత్తవద్దు. వెంటనే వైద్యుడిని కలవండి. ధన్యవాదాలు!"
        ),
        3: (
            "నమస్కారం! ఇది అధిక ప్రమాదకరమైన పరిస్థితి. మీ కంటిలో తీవ్రమైన డయాబెటిక్ రెటినోపతి ఉంది. రక్త ప్రసరణ తగ్గి విస్తారంగా రక్తస్రావం కనిపిస్తోంది. "
            "ఒకటి లేదా రెండు వారాల్లో జిల్లా ఆసుపత్రికి వెళ్లి లేజర్ చికిత్స తీసుకోండి. బరువులు ఎత్తడం మానండి. వెంటనే చికిత్స ప్రారంభించండి. ధన్యవాదాలు!"
        ),
        4: (
            "నమస్కారం! ఇది అత్యవసర వైద్య హెచ్చరిక. మీ కంటిలో అత్యంత తీవ్రమైన ప్రొలిఫెరేటివ్ డయాబెటిక్ రెటినోపతి ఉంది. కొత్త బలహీన నరాలు ఏర్పడి చూపు కోల్పోయే ప్రమాదం ఉంది. "
            "రాబోయే ఇరవై నాలుగు నుండి నలభై ఎనిమిది గంటల్లో పెద్ద కంటి ఆసుపత్రికి వెళ్ళండి! వెంటనే లేజర్ లేదా ఇంజెక్షన్ చికిత్స పొందండి. పూర్తి విశ్రాంతి తీసుకోండి. ధన్యవాదాలు!"
        )
    },
    "bn": {
        0: (
            "নমস্কার! আপনার ডায়াবেটিক রেটিনোপ্যাথি চক্ষু পরীক্ষার রিপোর্টটি শুনুন। "
            "আপনার চোখের পর্দায় বা রেটিনায় সুগারের কোনো প্রভাব নেই। আপনার রেটিনা সম্পূর্ণ সুস্থ ও পরিষ্কার। চোখের রক্তনালীতে কোনো রক্তপাত বা ফোলাভাব নেই। "
            "মিষ্টি, চিনি এবং কোল্ড ড্রিংকস সম্পূর্ণ এড়িয়ে চলুন। প্রতিদিন ত্রিশ মিনিট হাঁটুন। বছরে একবার চোখের নিয়মিত পরীক্ষা করান। ধন্যবাদ!"
        ),
        1: (
            "নমস্কার! এটি আপনার চোখের পরীক্ষার রিপোর্ট। আপনার চোখে প্রাথমিক পর্যায়ের ডায়াবেটিক রেটিনোপ্যাথির লক্ষণ দেখা গেছে। আপনার দৃষ্টি সম্পূর্ণ নিরাপদ। "
            "রক্তে শর্করা বৃদ্ধির কারণে সূক্ষ্ম রক্তনালীতে ছোট স্ফীতি সৃষ্টি হয়েছে। মিষ্টি ও ভাজাভুজি খাবার বন্ধ করুন। চোখ জোরে ঘষবেন না। "
            "ডায়াবেটিস নিয়ন্ত্রণে রাখুন এবং ছয় থেকে বারো মাসের মধ্যে চোখের ডাক্তার দেখান। ধন্যবাদ!"
        ),
        2: (
            "নমস্কার! এটি একটি জরুরি চক্ষু পরীক্ষার রিপোর্ট। আপনার চোখে মাঝারি ডায়াবেটিক রেটিনোপ্যাথি শনাক্ত হয়েছে। "
            "রক্তনালী ক্ষতিগ্রস্ত হয়ে রক্তপাত এবং হলুদ চর্বির দাগ তৈরি হচ্ছে। পরবর্তী দুই থেকে চার সপ্তাহের মধ্যে চোখের ডাক্তারের কাছে যান এবং OCT স্ক্যান করান। "
            "ভারী ওজন তুলবেন না। অবিলম্বে ডাক্তারের পরামর্শ নিন। ধন্যবাদ!"
        ),
        3: (
            "নমস্কার! দয়া করে এই রিপোর্টটি অত্যন্ত গুরুত্ব সহকারে নিন। এটি উচ্চ ঝুঁকির অবস্থা। আপনার চোখে গুরুতর ডায়াবেটিক রেটিনোপ্যাথি রয়েছে। রেটিনার রক্ত চলাচল ব্যাহত হয়েছে। "
            "অবিলম্বে এক থেকে দুই সপ্তাহের মধ্যে জেলা হাসপাতালে যোগাযোগ করে লেজার চিকিৎসা করান। ভারী কাজ বা ওজন তোলা সম্পূর্ণ বন্ধ রাখুন। ধন্যবাদ!"
        ),
        4: (
            "নমস্কার! এটি একটি জরুরি স্বাস্থ্য বার্তা। আপনার চোখে অতি-গুরুতর প্রলিফারেটিভ ডায়াবেটিক রেটিনোপ্যাথি ধরা পড়েছে। দুর্বল নতুন রক্তনালী ফেটে দৃষ্টিশক্তি হারানোর আশঙ্কা রয়েছে। "
            "আগামী চব্বিশ থেকে আটচল্লিশ ঘণ্টার মধ্যে বিশেষজ্ঞ হাসপাতালে যান! অবিলম্বে লেজার বা ইনজেকশন চিকিৎসা নিন। সম্পূর্ণ বিশ্রামে থাকুন। ধন্যবাদ!"
        )
    },
    "kn": {
        0: (
            "ನಮಸ್ಕಾರ! ಈರೆನ ಡಯಾಬಿಟಿಕ್ ರೆಟಿನೋಪತಿ ಕಣ್ಣ್ದ ತಪಾಸಣೆ ವರದಿನ್ ಕೇನ್ಲೆ. ಈರೆನ ಕಣ್ಣ್ದ ಪರ್ದೆ ಬಾರಿ ಸಫಾ ಬೊಕ್ಕ ಉಷಾರಾದುಂಡು. ಸಕ್ಕರೆ ಕಾಯಿಲೆದ ತೊಂದರೆ ಇಜ್ಜಿ. "
            "ಸಕ್ಕರೆ, ಬೆಲ್ಲ, ಮಿಠಾಯಿ ತಿನ್ನೊಡ್ಚಿ. ದಿನೊಲ ಮುಪ್ಪತ್ತು ನಿಮಿಷ ನಡಪುಲೆ. ವರ್ಷೊಗು ಒರ ಕಣ್ಣ್ ತಪಾಸಣೆ ಮಲ್ತೊನ್ಲೆ. ಧನ್ಯವಾದ!"
        ),
        1: (
            "ನಮಸ್ಕಾರ! ಈರೆನ ಕಣ್ಣ್ಡ್ ಸುರುತ ಹಂತದ ರೆಟಿನೋಪತಿ ತೋಜಿದ್ ಬತ್ತ್ಂಡ್. ದೃಷ್ಟಿಗ್ ದಾಲ ಅಪಾಯ ಇಜ್ಜಿ. ಸಕ್ಕರೆ ಜಾಸ್ತಿ ಆಯಿನೆರ್ದಾವರ ಎಲ್ಯ ಮಟ್ಟದ ಬಾಪು ಉಂಡು. "
            "ಎಣ್ಣೆಡ್ ಕಾಯಿತಿನ ತೆನಸ್ ತಿನ್ನೊಡ್ಚಿ. ಆಜಿರ್ದ್ ಪನ್ನೆರಡು ತಿಂಗಳುಡು ಡಾಕ್ಟ್ರನ್ ತೂಲೆ. ಧನ್ಯವಾದ!"
        ),
        2: (
            "ನಮಸ್ಕಾರ! ಈರೆನ ಕಣ್ಣ್ಡ್ ಮಧ್ಯಮ ಮಟ್ಟದ ರೆಟಿನೋಪತಿ ಉಂಡು. ರಕ್ತನಾಳೊರ್ದು ನೆತ್ತೆರ್ ಬೊಕ್ಕ ಮಂಜಲ್ ಕಲೆ ಪರ್ದೆಡ್ ತೋಜಿದ್ ಬರ್ಪುಂಡು. "
            "ರಡ್ಡ್ ರ್ದ್ ನಾಲ್ ವಾರೊಡು ಕಣ್ಣ್ದ ತಜ್ಞರೆಡ ಪೋಲೆ ಬೊಕ್ಕ ಒಸಿಟಿ ಸ್ಕ್ಯಾನ್ ಮಲ್ಪುಲೆ. ಭಾರ ದೆರ್ಪೊಡ್ಚಿ. ಧನ್ಯವಾದ!"
        ),
        3: (
            "ನಮಸ್ಕಾರ! ಉಂದು ಬಾರಿ ಜಾಸ್ತಿ ಅಪಾಯದ ಸ್ಥಿತಿ. ಗಂಭೀರ ಮಟ್ಟದ ರೆಟಿನೋಪತಿ ಉಂಡು. ಒಂಜಿರ್ದ್ ರಡ್ಡ್ ವಾರೊಡು ಜಿಲ್ಲಾ ಆಸ್ಪತ್ರೆಗ್ ಪೋದ್ ಲೇಸರ್ ಚಿಕಿತ್ಸೆ ಮಲ್ಪುಲೆ. "
            "ಭಾರೀ ಬೆಲೆ ಮಲ್ಪೊಡ್ಚಿ. ಧನ್ಯವಾದ!"
        ),
        4: (
            "ನಮಸ್ಕಾರ! ಉಂದು ತುರ್ತು ಆಸ್ಪತ್ರೆಗ್ ಪೋಪಿನ ಸ್ಥಿತಿ. ಪೊಸ ಕಂಜೋರ ನರೊಕ್ಕುಲು ಪುಡಾದ್ ಕಣ್ಣ್ದ ಬೊಲ್ಪು ಕಳೆವೊನ ಅಪಾಯ ಉಂಡು. "
            "ಇರ್ವತ್ತನಾಲ್ ರ್ದ್ ನಲ್ಪತ್ತೆನ್ಮ ಗಂಟೆಡ್ ಮಲ್ಲ ಆಸ್ಪತ್ರೆಗ್ ಪೋದ್ ಇಂಜೆಕ್ಷನ್ ಬೊಕ್ಕ ಲೇಸರ್ ಚಿಕಿತ್ಸೆ ದೆತೊನ್ಲೆ. ಧನ್ಯವಾದ!"
        )
    }
}

# Alias tcy to kn
SPOKEN_SCRIPTS["tcy"] = SPOKEN_SCRIPTS["kn"]


def get_multilingual_spoken_script(grade: int, language: str = "hi") -> str:
    """Returns spoken patient script in requested regional language."""
    lang = (language or "hi").lower().strip()
    if lang not in SPOKEN_SCRIPTS:
        lang = "hi"
    grade = int(max(0, min(4, grade or 0)))
    return SPOKEN_SCRIPTS[lang].get(grade, SPOKEN_SCRIPTS["hi"][grade])


def get_natural_indian_hindi_script(grade: int) -> str:
    """Backward compatibility alias for Hindi script."""
    return get_multilingual_spoken_script(grade, language="hi")


def generate_multilingual_patient_audio(
    grade: int,
    language: str = "hi",
    output_dir: str = "outputs",
    audio_filename: str = None
) -> dict:
    """
    Generates regional Indian language voice MP3 using gTTS.
    Supports: hi, en, mr, ta, te, bn, tcy/kn.
    """
    os.makedirs(output_dir, exist_ok=True)
    grade = int(max(0, min(4, grade or 0)))
    lang = (language or "hi").lower().strip()
    if lang not in SPOKEN_SCRIPTS:
        lang = "hi"

    script = get_multilingual_spoken_script(grade, language=lang)

    if not audio_filename:
        audio_filename = f"report_audio_{lang}_grade{grade}.mp3"

    audio_path = os.path.join(output_dir, audio_filename)

    # Cache lookup across output_dir and default outputs/
    candidates = [
        os.path.join(output_dir, audio_filename),
        os.path.join("outputs", audio_filename),
        os.path.join(output_dir, f"audio_test_grade_{grade}_report.mp3") if lang == "hi" else None,
        os.path.join("outputs", f"report_audio_hindi_grade{grade}.mp3") if lang == "hi" else None
    ]
    for c in candidates:
        if c and os.path.exists(c):
            if c != audio_path and not os.path.exists(audio_path):
                import shutil
                try:
                    shutil.copyfile(c, audio_path)
                except Exception:
                    pass
            break

    # If file already exists (cached)
    if os.path.exists(audio_path) and os.path.getsize(audio_path) > 1000:
        try:
            with open(audio_path, "rb") as f:
                b64_audio = base64.b64encode(f.read()).decode("utf-8")
            return {
                "available": True,
                "audio_path": audio_path,
                "data_uri": f"data:audio/mp3;base64,{b64_audio}",
                "filename": audio_filename,
                "spoken_script": script,
                "language": lang
            }
        except Exception:
            pass

    # Generate via gTTS
    try:
        from gtts import gTTS
        gtts_lang = "kn" if lang in ["tcy", "kn"] else lang
        tld = "co.in" if lang == "en" else "com"
        tts = gTTS(text=script, lang=gtts_lang, tld=tld, slow=False)
        tts.save(audio_path)

        with open(audio_path, "rb") as f:
            b64_audio = base64.b64encode(f.read()).decode("utf-8")
        data_uri = f"data:audio/mp3;base64,{b64_audio}"

        return {
            "available": True,
            "audio_path": audio_path,
            "data_uri": data_uri,
            "filename": audio_filename,
            "spoken_script": script,
            "language": lang
        }
    except Exception as e:
        logger.warning(f"gTTS audio generation error for {lang}: {e}")
        # Fallback to Hindi cached audio if available
        fallback_hi = os.path.join("outputs", f"report_audio_hindi_grade{grade}.mp3")
        if os.path.exists(fallback_hi):
            try:
                with open(fallback_hi, "rb") as f:
                    b64_audio = base64.b64encode(f.read()).decode("utf-8")
                return {
                    "available": True,
                    "audio_path": fallback_hi,
                    "data_uri": f"data:audio/mp3;base64,{b64_audio}",
                    "filename": f"report_audio_hindi_grade{grade}.mp3",
                    "spoken_script": SPOKEN_SCRIPTS["hi"][grade],
                    "language": "hi (fallback)"
                }
            except Exception:
                pass

        return {
            "available": False,
            "audio_path": None,
            "data_uri": None,
            "filename": None,
            "spoken_script": script,
            "error": str(e)
        }


def generate_natural_hindi_audio(grade: int, output_dir: str = "outputs", audio_filename: str = None) -> dict:
    """Backward compatibility wrapper for Hindi audio."""
    return generate_multilingual_patient_audio(
        grade=grade,
        language="hi",
        output_dir=output_dir,
        audio_filename=audio_filename
    )
