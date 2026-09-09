function rec = get_clinical_recommendations(grade)
% GET_CLINICAL_RECOMMENDATIONS Grade-Specific Etiology, Parhez & Precautions.
% Provides clinical root cause explanation, dietary guidelines, physical
% exertion / lifting warnings, and recommended health facility level.

    switch grade
        case 0
            urgency = 'Routine Annual Follow-up';
            etiology = 'Normal Retinal Microvasculature. No diabetic microangiopathy detected.';
            parhez = {'Maintain strict HbA1c < 7.0%', ...
                      'Annual dilated stereoscopic eye exam', ...
                      'Regular physical walking 30 mins/day', ...
                      'Avoid excessive sweets, refined sugars & saturated oils'};
            lifting = 'No lifting restrictions. Regular exercise encouraged.';
            referral = 'Primary Health Centre (PHC) Screening Registry (No urgent referral needed)';
        case 1
            urgency = 'Semi-Annual Ophthalmic Review (6-12 Months)';
            etiology = 'Early microvascular ischemia. Focal capillary dilation has produced microaneurysms.';
            parhez = {'Strict carbohydrate & glycemic control', ...
                      'Zero direct table sugar intake; high fiber diabetic diet', ...
                      'Quarterly lipid profile tracking', ...
                      'Daily blood pressure monitoring (< 130/80 mmHg)'};
            lifting = 'Light to moderate exercise permitted; avoid sudden heavy strain.';
            referral = 'Community Health Centre (CHC) Eye Clinic within 6 months';
        case 2
            urgency = 'Elevated Priority / Referral in 1-3 Months';
            etiology = 'Persistent capillary leakage with retinal edema. Multiple microaneurysms and lipid exudates threatening the macula.';
            parhez = {'Immediate strict low-glycemic, low-sodium dietary regimen', ...
                      'Strict parhez on fried food, table sugar, potatoes & sweets', ...
                      'Consult ophthalmologist for OCT macular scan', ...
                      'Adhere strictly to anti-diabetic medications'};
            lifting = 'Avoid heavy weight lifting (> 10 kg) and strenuous physical strain to prevent vitreous hemorrhage.';
            referral = 'District Hospital (DH) / Secondary Eye Care Specialist within 1 to 3 months';
        case 3
            urgency = 'High Priority Referral (2-4 Weeks)';
            etiology = 'Severe retinal ischemia and microvascular obliteration. Cotton wool spots and extensive hemorrhages indicate critical capillary non-perfusion.';
            parhez = {'Immediate diabetic dietary compliance', ...
                      'Daily home blood glucose monitoring', ...
                      'Prepare for potential retinal laser photocoagulation', ...
                      'Urgent Retina Specialist requisition'};
            lifting = 'STRICT RESTRICTION: Do not lift heavy loads, do not bend down suddenly, no gym/weight training to avoid retinal tear.';
            referral = 'Tertiary Eye Hospital / Regional Institute of Ophthalmology (RIO) within 2 to 4 weeks';
        case 4
            urgency = 'EMERGENCY IMMEDIATE REFERRAL (< 24-48 Hours)';
            etiology = 'Proliferative Diabetic Retinopathy (PDR). Severe ischemia triggered VEGF causing fragile new vessel growth (neovascularization) with critical risk of blindness.';
            parhez = {'Absolute strict medical diet & insulin optimization', ...
                      'Strict bed rest / minimal physical exertion', ...
                      'Emergency evaluation for Pan-Retinal Photocoagulation (PRP) or Anti-VEGF injections', ...
                      'Emergency vitreoretinal surgical review'};
            lifting = 'CRITICAL MEDICAL WARNING: Absolute contraindication against physical lifting, pushing, bending or coughing strain to prevent catastrophic vitreous hemorrhage.';
            referral = 'EMERGENCY Vitreoretinal Unit (Same-Day / within 24-48 Hours)';
        otherwise
            urgency = 'Clinical Evaluation Required';
            etiology = 'Clinical assessment indicated.';
            parhez = {'Consult physician'};
            lifting = 'Consult physician';
            referral = 'Eye OPD';
    end

    rec = struct();
    rec.urgency = urgency;
    rec.etiology = etiology;
    rec.parhez = parhez;
    rec.lifting_restriction = lifting;
    rec.referral_facility = referral;
end
