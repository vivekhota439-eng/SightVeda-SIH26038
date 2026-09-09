"""
Generates synthetic clinical fundus presets (Grade 0 to 4 + Ungradable)
for instant testing in the PHC Web Application.
"""
import os
import cv2
import numpy as np

def make_fundus(grade=0, is_blurry=False):
    sz = 512
    img = np.zeros((sz, sz, 3), dtype=np.uint8)
    center = (sz // 2, sz // 2)
    radius = int(sz * 0.46)
    
    # 1. Base retinal background
    Y, X = np.ogrid[:sz, :sz]
    dist_from_center = np.sqrt((X - center[0])**2 + (Y - center[1])**2)
    mask = dist_from_center <= radius
    
    # Gradient orange-red fundus color
    falloff = 1.0 - 0.25 * (dist_from_center / radius)
    red = np.clip(210 * falloff, 0, 255).astype(np.uint8)
    green = np.clip(105 * falloff, 0, 255).astype(np.uint8)
    blue = np.clip(25 * falloff, 0, 255).astype(np.uint8)
    
    img[mask, 2] = red[mask]    # R
    img[mask, 1] = green[mask]  # G
    img[mask, 0] = blue[mask]   # B
    
    # 2. Optic Disc (bright yellow-orange disc on nasal side)
    od_center = (int(sz * 0.72), int(sz * 0.50))
    cv2.circle(img, od_center, int(sz * 0.08), (120, 215, 255), -1) # BGR
    cv2.circle(img, od_center, int(sz * 0.04), (160, 235, 255), -1) # physiological cup
    
    # 3. Macula / Fovea (dark avascular zone on temporal side)
    fovea_center = (int(sz * 0.40), int(sz * 0.52))
    fovea_mask = np.sqrt((X - fovea_center[0])**2 + (Y - fovea_center[1])**2) <= (sz * 0.06)
    img[fovea_mask] = (img[fovea_mask].astype(float) * 0.68).astype(np.uint8)
    
    # 4. Retinal Blood Vessels (radiating from optic disc)
    vessel_color = (15, 30, 110)
    for angle in np.linspace(0, 2*np.pi, 18, endpoint=False):
        pts = []
        cx, cy = od_center
        pts.append((cx, cy))
        cur_x, cur_y = float(cx), float(cy)
        curr_angle = angle
        for step in range(8):
            cur_x += np.cos(curr_angle) * (sz * 0.05)
            cur_y += np.sin(curr_angle) * (sz * 0.05)
            pts.append((int(cur_x), int(cur_y)))
            curr_angle += np.random.uniform(-0.15, 0.15)
        for i in range(len(pts) - 1):
            thickness = max(1, 4 - i // 2)
            cv2.line(img, pts[i], pts[i+1], vessel_color, thickness, cv2.LINE_AA)
            
    # 5. Add Pathological Biomarkers according to ICDR Grade
    np.random.seed(42 + grade)
    
    if grade >= 1: # Microaneurysms (small red dots)
        num_ma = 8 if grade == 1 else (25 if grade == 2 else 55)
        for _ in range(num_ma):
            rr = np.random.uniform(sz * 0.1, sz * 0.40)
            ang = np.random.uniform(0, 2 * np.pi)
            mx = int(center[0] + rr * np.cos(ang))
            my = int(center[1] + rr * np.sin(ang))
            if my < sz and mx < sz and mask[my, mx]:
                cv2.circle(img, (mx, my), 2, (10, 15, 90), -1)
                
    if grade >= 2: # Hard Exudates (bright yellowish lipid deposits)
        num_ex = 12 if grade == 2 else 35
        for _ in range(num_ex):
            rr = np.random.uniform(sz * 0.08, sz * 0.35)
            ang = np.random.uniform(0, 2 * np.pi)
            ex = int(center[0] + rr * np.cos(ang))
            ey = int(center[1] + rr * np.sin(ang))
            if ey < sz and ex < sz and mask[ey, ex]:
                cv2.circle(img, (ex, ey), np.random.randint(3, 7), (140, 230, 245), -1)
                
    if grade >= 3: # Blot Hemorrhages & Cotton Wool Spots
        for _ in range(20):
            hx = np.random.randint(int(sz*0.2), int(sz*0.8))
            hy = np.random.randint(int(sz*0.2), int(sz*0.8))
            if hy < sz and hx < sz and mask[hy, hx]:
                cv2.ellipse(img, (hx, hy), (np.random.randint(5, 12), np.random.randint(3, 8)), 
                            np.random.randint(0, 180), 0, 360, (10, 10, 75), -1)
        # Cotton wool spots (fluffy white lesions)
        for _ in range(6):
            cx_pos = np.random.randint(int(sz*0.25), int(sz*0.75))
            cy_pos = np.random.randint(int(sz*0.25), int(sz*0.75))
            if cy_pos < sz and cx_pos < sz and mask[cy_pos, cx_pos]:
                cv2.circle(img, (cx_pos, cy_pos), np.random.randint(8, 15), (200, 210, 220), -1)
                
    if grade >= 4: # PDR: Neovascularization and Pre-retinal / Vitreous Hemorrhage
        # Large preretinal boat-shaped hemorrhage
        cv2.ellipse(img, (int(sz*0.48), int(sz*0.62)), (70, 25), 15, 0, 180, (10, 10, 60), -1)
        # Frond-like fragile neovascular tufts near disc
        for ang in np.linspace(-0.6, 0.6, 8):
            nx = int(od_center[0] - np.cos(ang) * 45)
            ny = int(od_center[1] + np.sin(ang) * 45)
            cv2.line(img, od_center, (nx, ny), (15, 20, 120), 2)
            cv2.circle(img, (nx, ny), 3, (10, 15, 80), -1)
            
    # If is_blurry (Ungradable quality)
    if is_blurry:
        # Severe defocus blur and low illumination
        img = cv2.GaussianBlur(img, (45, 45), 18)
        img = (img.astype(float) * 0.22).astype(np.uint8) # severe underexposure
        
    return img

if __name__ == "__main__":
    out_dir1 = "static/images"
    out_dir2 = "outputs"
    os.makedirs(out_dir1, exist_ok=True)
    os.makedirs(out_dir2, exist_ok=True)
    
    presets = {
        "preset_grade_0_normal.png": (0, False),
        "preset_grade_1_mild.png": (1, False),
        "preset_grade_2_moderate.png": (2, False),
        "preset_grade_3_severe.png": (3, False),
        "preset_grade_4_pdr.png": (4, False),
        "preset_ungradable_blurry.png": (0, True),
    }
    
    for fname, (g, blur) in presets.items():
        img = make_fundus(grade=g, is_blurry=blur)
        cv2.imwrite(os.path.join(out_dir1, fname), img)
        cv2.imwrite(os.path.join(out_dir2, fname), img)
        print(f"Generated: {fname}")
